import Foundation

enum EpisodeMapper {
    static func map(_ dto: EpisodeDTO, channelID: String) -> Episode {
        // pub_date_ms is Unix milliseconds; Date(timeIntervalSince1970:) expects seconds.
        let publishedAt = dto.pubDateMs
            .map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
            ?? Date.distantPast

        return Episode(
            id: dto.id,
            channelID: channelID,
            title: dto.title ?? "",
            description: dto.description ?? "",
            audioURL: dto.audio.flatMap { URL(string: $0) },
            publishedAt: publishedAt
        )
    }
}
