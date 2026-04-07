import SwiftData
import Foundation

/// SwiftData persistence model for a favorited episode.
///
/// Stores a snapshot of the episode at save time.
/// Mapped to/from the Domain `Episode` entity via `init(from:)` and `toDomain()`.
/// Must not be referenced outside the Data layer.
@Model
final class FavoriteEpisode {
    @Attribute(.unique) var id: String
    var channelID: String
    var title: String
    var episodeDescription: String
    /// Stored as a String to avoid SwiftData URL transformer complexity.
    var audioURLString: String?
    var publishedAt: Date
    var savedAt: Date

    init(from episode: Episode, savedAt: Date = .now) {
        self.id = episode.id
        self.channelID = episode.channelID
        self.title = episode.title
        self.episodeDescription = episode.description
        self.audioURLString = episode.audioURL?.absoluteString
        self.publishedAt = episode.publishedAt
        self.savedAt = savedAt
    }

    func toDomain() -> Episode {
        Episode(
            id: id,
            channelID: channelID,
            title: title,
            description: episodeDescription,
            audioURL: audioURLString.flatMap { URL(string: $0) },
            publishedAt: publishedAt
        )
    }
}
