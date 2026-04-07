import Foundation
@testable import PodCastScript

extension Episode {
    static func fixture(
        id: String = "ep-001",
        channelID: String = "ch-001",
        title: String = "Test Episode",
        description: String = "A test episode description.",
        audioURL: URL? = URL(string: "https://example.com/audio.mp3"),
        publishedAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> Episode {
        Episode(
            id: id,
            channelID: channelID,
            title: title,
            description: description,
            audioURL: audioURL,
            publishedAt: publishedAt
        )
    }
}

extension EpisodePage {
    static func fixture(
        episodes: [Episode] = [.fixture()],
        nextPublishDate: Int? = nil
    ) -> EpisodePage {
        EpisodePage(episodes: episodes, nextPublishDate: nextPublishDate)
    }
}
