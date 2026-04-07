struct EpisodePage {
    let episodes: [Episode]
    /// Cursor for the next batch. nil means no further pages exist.
    /// This is the raw `next_episode_pub_date` millisecond timestamp returned by the API.
    let nextPublishDate: Int?

    var hasMore: Bool { nextPublishDate != nil }
}
