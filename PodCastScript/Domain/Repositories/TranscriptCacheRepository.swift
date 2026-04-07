/// Domain contract for bulk transcript cache management operations.
///
/// This protocol is intentionally separate from `TranscriptRepository`:
/// - `TranscriptRepository`   — per-episode transcript generation and retrieval
/// - `TranscriptCacheRepository` — bulk cache lifecycle (clear, count)
///
/// Presentation must only access cache management through use cases that
/// depend on this protocol. SwiftData internals must not leak upward.
protocol TranscriptCacheRepository {

    /// Returns the number of transcripts currently stored in the local cache.
    func cachedTranscriptCount() async throws -> Int

    /// Deletes every cached transcript from the local store.
    func clearAll() async throws
}
