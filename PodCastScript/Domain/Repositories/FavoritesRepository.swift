protocol FavoritesRepository {
    // MARK: - Channels
    func saveChannel(_ channel: Channel) async throws
    func removeChannel(id: String) async throws
    func fetchChannels() async throws -> [Channel]
    func isFavoriteChannel(id: String) async throws -> Bool

    // MARK: - Episodes
    func saveEpisode(_ episode: Episode) async throws
    func removeEpisode(id: String) async throws
    func fetchEpisodes() async throws -> [Episode]
    func isFavoriteEpisode(id: String) async throws -> Bool
}
