final class IsFavoriteChannelUseCase {
    private let repository: FavoritesRepository

    init(repository: FavoritesRepository) {
        self.repository = repository
    }

    func execute(channelID: String) async throws -> Bool {
        return try await repository.isFavoriteChannel(id: channelID)
    }
}
