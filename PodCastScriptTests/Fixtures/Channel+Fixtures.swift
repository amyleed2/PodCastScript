import Foundation
@testable import PodCastScript

extension Channel {
    static func fixture(
        id: String = "ch-001",
        name: String = "Swift by Sundell",
        publisher: String = "John Sundell",
        artworkURL: URL? = URL(string: "https://example.com/artwork.jpg"),
        description: String = "A podcast about Swift development."
    ) -> Channel {
        Channel(
            id: id,
            name: name,
            publisher: publisher,
            artworkURL: artworkURL,
            description: description
        )
    }
}
