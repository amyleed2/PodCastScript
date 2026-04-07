final class FetchFavoriteChannelsUseCase {
    private let repository: FavoritesRepository

    init(repository: FavoritesRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Channel] {
        return try await repository.fetchChannels()
    }
}
