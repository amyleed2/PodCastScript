import Foundation

/// Concrete implementation of `TranscriptRepository`.
///
/// Cache strategy:
/// 1. Check `TranscriptCacheStore` for an existing transcript.
/// 2. On cache **HIT**: evaluate TTL via `CachePolicy`.
///    - Fresh  → return immediately (source: .cached).
///    - Expired → delete the stale row, treat as MISS, fall through to generation.
/// 3. On cache **MISS**: generate via `TranscriptionProvider`, persist the result,
///    then return it (source: .generated).
///
/// `@MainActor` is required because `TranscriptCacheStore` operates on
/// `ModelContainer.mainContext`, which is bound to the main actor.
/// URLSession async calls inside the provider are awaited normally — they suspend
/// without blocking the main thread.
@MainActor
final class TranscriptRepositoryImpl: TranscriptRepository {

    private let provider: TranscriptionProvider
    private let cacheStore: TranscriptCacheStore

    init(provider: TranscriptionProvider, cacheStore: TranscriptCacheStore) {
        self.provider = provider
        self.cacheStore = cacheStore
    }

    // MARK: - TranscriptRepository

    func fetchTranscript(for episode: Episode) async throws -> TranscriptResult {
        guard let audioURL = episode.audioURL else {
            return TranscriptResult(episodeID: episode.id, content: nil, status: .unavailable, source: nil)
        }

        // 1. Cache lookup + TTL check
        if let cached = try? cacheStore.fetchCachedTranscript(for: episode.id),
           !cached.content.isEmpty {

            if CachePolicy.isExpired(cached) {
                #if DEBUG
                let age = Int(-cached.createdAt.timeIntervalSinceNow / 86400)
                print("[TranscriptCache] EXPIRED — episode: \(episode.id) (age: \(age)d, TTL: \(CachePolicy.ttlDays)d) — deleting and regenerating")
                #endif
                // Remove stale row; fall through to generation below.
                try? cacheStore.deleteTranscript(for: episode.id)
            } else {
                #if DEBUG
                let age = Int(-cached.createdAt.timeIntervalSinceNow / 86400)
                print("[TranscriptCache] HIT — episode: \(episode.id) (\(cached.content.count) chars, age: \(age)d)")
                #endif
                return TranscriptResult(
                    episodeID: episode.id,
                    content: cached.content,
                    status: .generated,
                    source: .cached
                )
            }
        } else {
            #if DEBUG
            print("[TranscriptCache] MISS — episode: \(episode.id), starting generation…")
            #endif
        }

        // 2. Generate
        do {
            let text = try await provider.generateTranscript(from: audioURL)

            guard !text.isEmpty else {
                throw DomainError.transcriptionFailed(underlying: nil)
            }

            // 3. Persist (best-effort — a save failure must not break the UX)
            do {
                try cacheStore.saveTranscript(episodeID: episode.id, content: text)
                #if DEBUG
                print("[TranscriptCache] SAVED — episode: \(episode.id) (\(text.count) chars)")
                #endif
            } catch {
                #if DEBUG
                print("[TranscriptCache] SAVE FAILED — episode: \(episode.id), error: \(error)")
                #endif
            }

            return TranscriptResult(
                episodeID: episode.id,
                content: text,
                status: .generated,
                source: .generated
            )

        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.transcriptionFailed(underlying: error)
        }
    }
}
