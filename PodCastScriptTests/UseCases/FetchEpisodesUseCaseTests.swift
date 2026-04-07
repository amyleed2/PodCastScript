import Testing
@testable import PodCastScript

// MARK: - Feature under test
// FetchEpisodesUseCase — delegates episode fetching to EpisodeRepository.
//
// Missing coverage before this file: 100%
//
// Test case list:
//   Delegation:
//     1. Passes channelID to repository unchanged
//     2. Passes nil nextPublishDate (first load) to repository
//     3. Passes non-nil nextPublishDate (pagination cursor) to repository
//   Success path:
//     4. Returns EpisodePage unchanged from repository
//     5. hasMore == true when page has nextPublishDate
//     6. hasMore == false when page has no nextPublishDate
//   Error path:
//     7. Propagates DomainError.networkUnavailable
//     8. Propagates DomainError.unauthorized
//
// Regression checklist:
//   [ ] channelID forwarded without transformation
//   [ ] nil cursor = first load (no sentinel magic numbers)
//   [ ] non-nil cursor forwarded verbatim to repository
//   [ ] EpisodePage returned unchanged
//   [ ] All errors propagate without wrapping

struct FetchEpisodesUseCaseTests {

    private func makeSUT() -> (sut: FetchEpisodesUseCase, repository: MockEpisodeRepository) {
        let repository = MockEpisodeRepository()
        let sut = FetchEpisodesUseCase(repository: repository)
        return (sut, repository)
    }

    // MARK: - Delegation

    @Test("Forwards channelID to repository")
    func execute_forwardsChannelIDToRepository() async throws {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .success(.fixture())

        _ = try await sut.execute(channelID: "ch-abc")

        #expect(repository.lastChannelID == "ch-abc")
    }

    @Test("Passes nil nextPublishDate for first load")
    func execute_firstLoad_passesNilCursor() async throws {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .success(.fixture())

        _ = try await sut.execute(channelID: "ch-001", nextPublishDate: nil)

        #expect(repository.lastNextPublishDate == nil)
    }

    @Test("Passes non-nil nextPublishDate for pagination")
    func execute_pagination_passesCursorToRepository() async throws {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .success(.fixture())

        _ = try await sut.execute(channelID: "ch-001", nextPublishDate: 1_700_000_000)

        #expect(repository.lastNextPublishDate == 1_700_000_000)
    }

    // MARK: - Success path

    @Test("Returns EpisodePage unchanged from repository")
    func execute_returnsPageFromRepository() async throws {
        let (sut, repository) = makeSUT()
        let episodes = [Episode.fixture(id: "1"), Episode.fixture(id: "2")]
        let expected = EpisodePage(episodes: episodes, nextPublishDate: nil)
        repository.stubbedResult = .success(expected)

        let result = try await sut.execute(channelID: "ch-001")

        #expect(result.episodes == episodes)
        #expect(result.nextPublishDate == nil)
    }

    @Test("hasMore is true when page has nextPublishDate")
    func execute_pageWithCursor_hasMoreIsTrue() async throws {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .success(EpisodePage(episodes: [.fixture()], nextPublishDate: 1_700_000_000))

        let result = try await sut.execute(channelID: "ch-001")

        #expect(result.hasMore == true)
    }

    @Test("hasMore is false when page has no nextPublishDate")
    func execute_pageWithoutCursor_hasMoreIsFalse() async throws {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .success(EpisodePage(episodes: [.fixture()], nextPublishDate: nil))

        let result = try await sut.execute(channelID: "ch-001")

        #expect(result.hasMore == false)
    }

    // MARK: - Error path

    @Test("Propagates network error from repository")
    func execute_networkError_propagates() async {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .failure(DomainError.networkUnavailable)

        await #expect(throws: DomainError.self) {
            try await sut.execute(channelID: "ch-001")
        }
    }

    @Test("Propagates unauthorized error from repository")
    func execute_unauthorizedError_propagates() async {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .failure(DomainError.unauthorized)

        await #expect(throws: DomainError.self) {
            try await sut.execute(channelID: "ch-001")
        }
    }
}
