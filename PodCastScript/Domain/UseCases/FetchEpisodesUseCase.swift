final class FetchEpisodesUseCase {
    private let repository: EpisodeRepository

    init(repository: EpisodeRepository) {
        self.repository = repository
    }

    func execute(channelID: String, nextPublishDate: Int? = nil) async throws -> EpisodePage {
        return try await repository.fetchEpisodes(channelID: channelID, nextPublishDate: nextPublishDate)
    }
}
