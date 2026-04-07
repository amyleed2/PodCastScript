import Testing
@testable import PodCastScript

// MARK: - Feature under test
// FetchTranscriptUseCase — guards nil audioURL and delegates generation to TranscriptRepository.
//
// Missing coverage before this file: 100%
//
// Test case list:
//   audioURL present:
//     1.  Calls repository when episode has an audioURL
//     2.  Returns TranscriptResult from repository unchanged
//     3.  Forwards the full episode value to repository
//   audioURL absent:
//     4.  Returns .unavailable without calling repository
//     5.  Returns nil content when audioURL is absent
//     6.  Returns matching episodeID when audioURL is absent
//   Error propagation:
//     7.  Propagates DomainError.transcriptionFailed from repository
//     8.  Propagates DomainError.networkUnavailable from repository
//
// Regression checklist:
//   [ ] nil audioURL → no repository call, no throw, status == .unavailable
//   [ ] non-nil audioURL → repository called exactly once
//   [ ] repository result returned without modification
//   [ ] episode forwarded verbatim (not reconstructed)
//   [ ] errors propagate without additional wrapping

struct FetchTranscriptUseCaseTests {

    private func makeSUT() -> (sut: FetchTranscriptUseCase, repository: MockTranscriptRepository) {
        let repository = MockTranscriptRepository()
        let sut = FetchTranscriptUseCase(repository: repository)
        return (sut, repository)
    }

    private func generatedResult(
        episodeID: String = "ep-001",
        content: String = "Generated transcript."
    ) -> TranscriptResult {
        TranscriptResult(episodeID: episodeID, content: content, status: .generated, source: .generated)
    }

    // MARK: - audioURL present

    @Test("Calls repository when episode has an audioURL")
    func execute_episodeWithAudioURL_callsRepository() async throws {
        let (sut, repository) = makeSUT()
        let episode = Episode.fixture(audioURL: URL(string: "https://example.com/audio.mp3"))

        _ = try await sut.execute(episode: episode)

        #expect(repository.fetchCallCount == 1)
    }

    @Test("Returns TranscriptResult from repository unchanged")
    func execute_episodeWithAudioURL_returnsRepositoryResult() async throws {
        let (sut, repository) = makeSUT()
        let expected = generatedResult(content: "Exact content from provider.")
        repository.stubbedResult = .success(expected)
        let episode = Episode.fixture()

        let result = try await sut.execute(episode: episode)

        #expect(result == expected)
    }

    @Test("Forwards the full episode value to repository")
    func execute_episodeWithAudioURL_forwardsEpisodeToRepository() async throws {
        let (sut, repository) = makeSUT()
        let episode = Episode.fixture(id: "ep-xyz")

        _ = try await sut.execute(episode: episode)

        #expect(repository.lastEpisode == episode)
    }

    // MARK: - audioURL absent

    @Test("Returns .unavailable without calling repository when audioURL is nil")
    func execute_episodeWithoutAudioURL_returnsUnavailableAndSkipsRepository() async throws {
        let (sut, repository) = makeSUT()
        let episode = Episode.fixture(audioURL: nil)

        let result = try await sut.execute(episode: episode)

        #expect(result.status == .unavailable)
        #expect(repository.fetchCallCount == 0)
    }

    @Test("Returns nil content when audioURL is nil")
    func execute_episodeWithoutAudioURL_contentIsNil() async throws {
        let (sut, _) = makeSUT()
        let episode = Episode.fixture(audioURL: nil)

        let result = try await sut.execute(episode: episode)

        #expect(result.content == nil)
    }

    @Test("Returns matching episodeID when audioURL is nil")
    func execute_episodeWithoutAudioURL_episodeIDMatches() async throws {
        let (sut, _) = makeSUT()
        let episode = Episode.fixture(id: "ep-no-audio", audioURL: nil)

        let result = try await sut.execute(episode: episode)

        #expect(result.episodeID == "ep-no-audio")
    }

    // MARK: - Error propagation

    @Test("Propagates DomainError.transcriptionFailed without wrapping")
    func execute_repositoryThrowsTranscriptionFailed_propagatesExactCase() async {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .failure(DomainError.transcriptionFailed(underlying: nil))
        let episode = Episode.fixture()

        do {
            _ = try await sut.execute(episode: episode)
            Issue.record("Expected DomainError.transcriptionFailed to be thrown")
        } catch let error as DomainError {
            if case .transcriptionFailed = error {
                // expected
            } else {
                Issue.record("Expected .transcriptionFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected DomainError, got \(error)")
        }
    }

    @Test("Propagates DomainError.networkUnavailable without wrapping")
    func execute_repositoryThrowsNetworkError_propagatesExactCase() async {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .failure(DomainError.networkUnavailable)
        let episode = Episode.fixture()

        do {
            _ = try await sut.execute(episode: episode)
            Issue.record("Expected DomainError.networkUnavailable to be thrown")
        } catch let error as DomainError {
            #expect(error == .networkUnavailable)
        } catch {
            Issue.record("Expected DomainError, got \(error)")
        }
    }
}
