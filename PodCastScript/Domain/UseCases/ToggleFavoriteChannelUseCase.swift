final class ToggleFavoriteChannelUseCase {
    private let repository: FavoritesRepository

    init(repository: FavoritesRepository) {
        self.repository = repository
    }

    /// Toggles the favorite state for a channel.
    /// Returns the actual persisted state after the operation — never inverts a local boolean.
    @discardableResult
    func execute(channel: Channel) async throws -> Bool {
        let isFavorite = try await repository.isFavoriteChannel(id: channel.id)
        if isFavorite {
            try await repository.removeChannel(id: channel.id)
        } else {
            try await repository.saveChannel(channel)
        }
        return try await repository.isFavoriteChannel(id: channel.id)
    }
}
