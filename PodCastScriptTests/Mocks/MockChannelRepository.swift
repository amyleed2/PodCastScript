@testable import PodCastScript

final class MockChannelRepository: ChannelRepository {
    var stubbedResult: Result<[Channel], Error> = .success([])
    private(set) var searchCallCount = 0
    private(set) var lastQuery: String?

    func searchChannels(query: String) async throws -> [Channel] {
        searchCallCount += 1
        lastQuery = query
        return try stubbedResult.get()
    }

}
