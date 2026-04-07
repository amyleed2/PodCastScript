import SwiftData
import Foundation

/// Provides read, write, and management access to the `CachedTranscript` SwiftData store.
///
/// This class is `@MainActor` because it operates exclusively on
/// `ModelContainer.mainContext`, which must only be accessed from the main actor.
///
/// Rules enforced by this store:
/// - Empty content is never written. Callers receive an early guard failure.
/// - A duplicate episodeID performs an in-place update (upsert), not a second insert.
///   This works in tandem with the `@Attribute(.unique)` constraint on `CachedTranscript`.
/// - Conforms to `TranscriptCacheRepository` for use by Domain-layer use cases.
@MainActor
final class TranscriptCacheStore: TranscriptCacheRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Read

    /// Returns the cached transcript for `episodeID`, or `nil` if none exists.
    func fetchCachedTranscript(for episodeID: String) throws -> CachedTranscript? {
        let predicate = #Predicate<CachedTranscript> { $0.episodeID == episodeID }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    /// Returns the total number of cached transcripts in the store.
    func cachedTranscriptCount() throws -> Int {
        let descriptor = FetchDescriptor<CachedTranscript>()
        return try context.fetchCount(descriptor)
    }

    // MARK: - Write

    /// Persists a transcript for `episodeID`.
    ///
    /// - If a row already exists for this `episodeID`, the content is updated in place
    ///   (upsert). The `@Attribute(.unique)` constraint guarantees no duplicates exist.
    /// - Silently returns without writing if `content` is empty.
    func saveTranscript(episodeID: String, content: String) throws {
        guard !content.isEmpty else { return }

        if let existing = try fetchCachedTranscript(for: episodeID) {
            existing.content = content
            existing.createdAt = .now
        } else {
            context.insert(CachedTranscript(episodeID: episodeID, content: content))
        }

        try context.save()
    }

    // MARK: - Delete

    /// Deletes the cached transcript for a specific episode, if it exists.
    ///
    /// Used when an expired entry is discovered at read time: the stale row is
    /// removed before the caller falls through to regenerate from the provider.
    func deleteTranscript(for episodeID: String) throws {
        guard let existing = try fetchCachedTranscript(for: episodeID) else { return }
        context.delete(existing)
        try context.save()
    }

    /// Deletes every cached transcript from the store.
    ///
    /// Satisfies `TranscriptCacheRepository.clearAll()`.
    /// After this call, every subsequent `TranscriptRepositoryImpl.fetchTranscript`
    /// will be a cache MISS and will trigger fresh generation.
    func clearAll() throws {
        try context.delete(model: CachedTranscript.self)
        try context.save()
    }
}
