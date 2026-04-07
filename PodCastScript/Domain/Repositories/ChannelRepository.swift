protocol ChannelRepository {
    func searchChannels(query: String) async throws -> [Channel]
}
