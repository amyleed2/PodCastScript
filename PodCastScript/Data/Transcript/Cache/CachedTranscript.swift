import SwiftData
import Foundation

/// SwiftData model that persists a generated transcript for a single episode.
///
/// - `episodeID` carries a `unique` constraint so the store can never hold
///   two rows for the same episode. Duplicate inserts are rejected at the
///   database level and defended against in `TranscriptCacheStore`.
/// - This type must not be imported or referenced outside the Data layer.
@Model
final class CachedTranscript {
    @Attribute(.unique) var episodeID: String
    var content: String
    var createdAt: Date

    init(episodeID: String, content: String, createdAt: Date = .now) {
        self.episodeID = episodeID
        self.content = content
        self.createdAt = createdAt
    }
}
