final class ToggleFavoriteEpisodeUseCase {
    private let repository: FavoritesRepository

    init(repository: FavoritesRepository) {
        self.repository = repository
    }

    /// Toggles the favorite state for an episode.
    /// Returns the actual persisted state after the operation — never inverts a local boolean.
    @discardableResult
    func execute(episode: Episode) async throws -> Bool {
        let isFavorite = try await repository.isFavoriteEpisode(id: episode.id)
        if isFavorite {
            try await repository.removeEpisode(id: episode.id)
        } else {
            try await repository.saveEpisode(episode)
        }
        return try await repository.isFavoriteEpisode(id: episode.id)
    }
}
