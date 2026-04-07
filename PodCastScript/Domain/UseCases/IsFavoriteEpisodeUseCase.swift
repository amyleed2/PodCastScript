final class IsFavoriteEpisodeUseCase {
    private let repository: FavoritesRepository

    init(repository: FavoritesRepository) {
        self.repository = repository
    }

    func execute(episodeID: String) async throws -> Bool {
        return try await repository.isFavoriteEpisode(id: episodeID)
    }
}
