final class FetchFavoriteEpisodesUseCase {
    private let repository: FavoritesRepository

    init(repository: FavoritesRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Episode] {
        return try await repository.fetchEpisodes()
    }
}
