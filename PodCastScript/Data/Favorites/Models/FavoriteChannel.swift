import SwiftData
import Foundation

/// SwiftData persistence model for a favorited channel.
///
/// Stores a snapshot of the channel at save time.
/// Mapped to/from the Domain `Channel` entity via `init(from:)` and `toDomain()`.
/// Must not be referenced outside the Data layer.
@Model
final class FavoriteChannel {
    @Attribute(.unique) var id: String
    var name: String
    var publisher: String
    /// Stored as a String to avoid SwiftData URL transformer complexity.
    var artworkURLString: String?
    var channelDescription: String
    var savedAt: Date

    init(from channel: Channel, savedAt: Date = .now) {
        self.id = channel.id
        self.name = channel.name
        self.publisher = channel.publisher
        self.artworkURLString = channel.artworkURL?.absoluteString
        self.channelDescription = channel.description
        self.savedAt = savedAt
    }

    func toDomain() -> Channel {
        Channel(
            id: id,
            name: name,
            publisher: publisher,
            artworkURL: artworkURLString.flatMap { URL(string: $0) },
            description: channelDescription
        )
    }
}
