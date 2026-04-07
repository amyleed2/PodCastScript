@testable import PodCastScript

final class MockTranscriptRepository: TranscriptRepository {

    /// Default stub — override per test as needed.
    var stubbedResult: Result<TranscriptResult, Error> = .success(
        TranscriptResult(episodeID: "ep-001", content: "Stub transcript content.", status: .generated, source: .generated)
    )

    private(set) var fetchCallCount = 0
    private(set) var lastEpisode: Episode?

    func fetchTranscript(for episode: Episode) async throws -> TranscriptResult {
        fetchCallCount += 1
        lastEpisode = episode
        return try stubbedResult.get()
    }
}
