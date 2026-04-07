struct EpisodeResponseDTO: Decodable {
    let episodes: [EpisodeDTO]
    /// Cursor for the next batch. nil or absent when no more episodes exist.
    /// Pass this value as `next_episode_pub_date` in the next request.
    let nextEpisodePubDate: Int?

    enum CodingKeys: String, CodingKey {
        case episodes
        case nextEpisodePubDate = "next_episode_pub_date"
    }
}
