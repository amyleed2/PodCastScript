protocol EpisodeRepository {
    /// Fetches a page of episodes for the given channel.
    /// - Parameter nextPublishDate: Cursor from the previous page (millisecond timestamp).
    ///   Pass nil for the first load.
    func fetchEpisodes(channelID: String, nextPublishDate: Int?) async throws -> EpisodePage
}
