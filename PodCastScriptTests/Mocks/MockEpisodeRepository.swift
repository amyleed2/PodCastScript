@testable import PodCastScript

final class MockEpisodeRepository: EpisodeRepository {
    var stubbedResult: Result<EpisodePage, Error> = .success(.fixture())
    private(set) var fetchCallCount = 0
    private(set) var lastChannelID: String?
    private(set) var lastNextPublishDate: Int?
    /// Ordered results — each call pops the next stub, falling back to stubbedResult.
    var stubbedSequence: [Result<EpisodePage, Error>] = []

    func fetchEpisodes(channelID: String, nextPublishDate: Int?) async throws -> EpisodePage {
        fetchCallCount += 1
        lastChannelID = channelID
        lastNextPublishDate = nextPublishDate
        let result = stubbedSequence.isEmpty ? stubbedResult : stubbedSequence.removeFirst()
        return try result.get()
    }
}
