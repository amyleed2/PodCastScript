import Foundation

/// Defines the cache lifetime policy for locally stored transcripts.
///
/// All TTL logic is contained here so it can be adjusted in one place
/// without touching `TranscriptCacheStore` or `TranscriptRepositoryImpl`.
///
/// Design notes:
/// - TTL is fixed at 30 days (podcast transcript content does not change,
///   but provider accuracy may improve; 30 days balances stability vs. freshness).
/// - Expiry is evaluated at cache-read time — no background sweep is needed.
/// - A `now` parameter is injectable for deterministic unit testing.
enum CachePolicy {

    /// Number of days a cached transcript is considered valid.
    static let ttlDays: Int = 30

    /// Derived TTL as a `TimeInterval` (seconds).
    static let ttl: TimeInterval = TimeInterval(ttlDays) * 24 * 60 * 60

    /// Returns `true` if `entry` was created more than `ttl` seconds ago.
    ///
    /// - Parameter entry: The `CachedTranscript` row to evaluate.
    /// - Parameter now:   Reference date. Defaults to `Date.now`; override in tests.
    static func isExpired(_ entry: CachedTranscript, now: Date = .now) -> Bool {
        now.timeIntervalSince(entry.createdAt) > ttl
    }
}
