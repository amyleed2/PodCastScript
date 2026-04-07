import Testing
@testable import PodCastScript

// MARK: - Feature under test
// EpisodeListViewModel — manages EpisodeList screen state and cursor-based pagination.
//
// Missing coverage before this file: 100% (ViewModel was new)
//
// Test case list:
//   Initial state:
//     1.  state == .idle on init
//     2.  pagination defaults: hasMore false, isLoadingMore false, loadMoreError nil
//   loadInitial — success:
//     3.  state transitions to .loaded with returned episodes
//     4.  pagination.hasMore == true when page has nextPublishDate
//     5.  pagination.hasMore == false when page has no nextPublishDate
//     6.  nextPublishDate cursor stored (verified via loadMore forwarding)
//   loadInitial — empty:
//     7.  state transitions to .empty when episodes array is []
//   loadInitial — error:
//     8.  state transitions to .error with non-empty message
//   loadInitial — re-entry:
//     9.  calling loadInitial twice resets pagination and cursor
//   loadMore — success:
//    10.  appends new episodes to existing loaded list
//    11.  passes stored cursor to use case
//    12.  updates pagination.hasMore from new page
//    13.  pagination.isLoadingMore is false after completion
//    14.  loadMoreError is nil after successful load
//   loadMore — last page:
//    15.  pagination.hasMore == false after loading last page
//   loadMore — error:
//    16.  state (.loaded) preserved on loadMore failure
//    17.  pagination.loadMoreError is set to non-empty message
//    18.  pagination.isLoadingMore is false after failure
//   loadMore — guard conditions:
//    19.  no-op when state is not .loaded
//    20.  no-op when pagination.hasMore == false
//
// Regression checklist:
//   [ ] loadInitial always resets cursor and pagination before fetching
//   [ ] empty episodes → .empty (not .loaded([]))
//   [ ] loadMore appends, never replaces
//   [ ] loadMore failure keeps existing episodes visible
//   [ ] loadMore skipped when hasMore == false
//   [ ] loadMore skipped when state is not .loaded
//   [ ] cursor passed to loadMore is the one stored from the previous page

@MainActor
struct EpisodeListViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        channelID: String = "ch-001",
        stubbedPages: [Result<EpisodePage, Error>] = []
    ) -> (sut: EpisodeListViewModel, repository: MockEpisodeRepository) {
        let repository = MockEpisodeRepository()
        repository.stubbedSequence = stubbedPages
        let useCase = FetchEpisodesUseCase(repository: repository)
        let channel = Channel.fixture(id: channelID)
        let sut = EpisodeListViewModel(channel: channel, fetchUseCase: useCase)
        return (sut, repository)
    }

    private func page(
        _ episodes: [Episode],
        cursor: Int? = nil
    ) -> Result<EpisodePage, Error> {
        .success(EpisodePage(episodes: episodes, nextPublishDate: cursor))
    }

    // MARK: - Initial state

    @Test("Initial state is idle")
    func init_stateIsIdle() {
        let (sut, _) = makeSUT()
        #expect(sut.state == .idle)
    }

    @Test("Initial pagination has all defaults")
    func init_paginationDefaults() {
        let (sut, _) = makeSUT()
        #expect(sut.pagination == EpisodeListViewModel.PaginationState())
    }

    // MARK: - loadInitial — success

    @Test("loadInitial success transitions to loaded")
    func loadInitial_success_stateIsLoaded() async throws {
        let episodes = [Episode.fixture(id: "1"), Episode.fixture(id: "2")]
        let (sut, _) = makeSUT(stubbedPages: [page(episodes)])

        await sut.loadInitial()

        #expect(sut.state == .loaded(episodes))
    }

    @Test("loadInitial success with cursor sets hasMore true")
    func loadInitial_pageHasCursor_hasMoreIsTrue() async {
        let (sut, _) = makeSUT(stubbedPages: [page([.fixture()], cursor: 1_700_000_000)])

        await sut.loadInitial()

        #expect(sut.pagination.hasMore == true)
    }

    @Test("loadInitial success without cursor sets hasMore false")
    func loadInitial_pageHasNoCursor_hasMoreIsFalse() async {
        let (sut, _) = makeSUT(stubbedPages: [page([.fixture()], cursor: nil)])

        await sut.loadInitial()

        #expect(sut.pagination.hasMore == false)
    }

    @Test("loadInitial stores cursor for subsequent loadMore")
    func loadInitial_storesCursorForPagination() async {
        let firstEpisodes = [Episode.fixture(id: "1")]
        let secondEpisodes = [Episode.fixture(id: "2")]
        let (sut, repository) = makeSUT(stubbedPages: [
            page(firstEpisodes, cursor: 1_700_000_000),
            page(secondEpisodes, cursor: nil)
        ])

        await sut.loadInitial()
        await sut.loadMore()

        #expect(repository.lastNextPublishDate == 1_700_000_000)
    }

    // MARK: - loadInitial — empty

    @Test("loadInitial with empty episodes transitions to empty")
    func loadInitial_emptyEpisodes_stateIsEmpty() async {
        let (sut, _) = makeSUT(stubbedPages: [page([])])

        await sut.loadInitial()

        #expect(sut.state == .empty)
    }

    // MARK: - loadInitial — error

    @Test("loadInitial error transitions to error state")
    func loadInitial_error_stateIsError() async {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .failure(DomainError.networkUnavailable)

        await sut.loadInitial()

        if case .error(let message) = sut.state {
            #expect(!message.isEmpty)
        } else {
            Issue.record("Expected .error, got \(sut.state)")
        }
    }

    // MARK: - loadInitial — re-entry guard

    @Test("loadInitial is no-op when state is already loaded (navigation re-appearance)")
    func loadInitial_alreadyLoaded_isNoOp() async {
        let (sut, repository) = makeSUT(stubbedPages: [
            page([.fixture()], cursor: 1_700_000_000)
        ])
        await sut.loadInitial()
        let stateAfterFirst = sut.state

        // Simulate NavigationStack re-appearance firing .task again
        await sut.loadInitial()

        #expect(sut.state == stateAfterFirst)
        #expect(repository.fetchCallCount == 1)
    }

    // MARK: - loadMore — success

    @Test("loadMore appends episodes to existing list")
    func loadMore_success_appendsEpisodes() async {
        let first = [Episode.fixture(id: "1")]
        let second = [Episode.fixture(id: "2"), Episode.fixture(id: "3")]
        let (sut, _) = makeSUT(stubbedPages: [
            page(first, cursor: 1_700_000_000),
            page(second, cursor: nil)
        ])

        await sut.loadInitial()
        await sut.loadMore()

        #expect(sut.state == .loaded(first + second))
    }

    @Test("loadMore updates hasMore from new page")
    func loadMore_lastPage_hasMoreBecomeFalse() async {
        let (sut, _) = makeSUT(stubbedPages: [
            page([.fixture(id: "1")], cursor: 9999),
            page([.fixture(id: "2")], cursor: nil)  // last page
        ])

        await sut.loadInitial()
        await sut.loadMore()

        #expect(sut.pagination.hasMore == false)
    }

    @Test("loadMore clears loadMoreError on success")
    func loadMore_success_clearsLoadMoreError() async {
        let (sut, repository) = makeSUT(stubbedPages: [
            page([.fixture(id: "1")], cursor: 9999)
        ])
        await sut.loadInitial()

        // First loadMore fails
        repository.stubbedResult = .failure(DomainError.networkUnavailable)
        await sut.loadMore()

        // Second loadMore succeeds
        repository.stubbedResult = .success(EpisodePage(episodes: [.fixture(id: "2")], nextPublishDate: nil))
        await sut.loadMore()

        #expect(sut.pagination.loadMoreError == nil)
    }

    @Test("loadMore isLoadingMore is false after success")
    func loadMore_success_isLoadingMoreIsFalse() async {
        let (sut, _) = makeSUT(stubbedPages: [
            page([.fixture()], cursor: 9999),
            page([.fixture()], cursor: nil)
        ])
        await sut.loadInitial()
        await sut.loadMore()

        #expect(sut.pagination.isLoadingMore == false)
    }

    // MARK: - loadMore — error (non-destructive)

    @Test("loadMore error preserves existing loaded state")
    func loadMore_error_stateUnchanged() async {
        let existingEpisodes = [Episode.fixture(id: "1")]
        let (sut, repository) = makeSUT(stubbedPages: [
            page(existingEpisodes, cursor: 9999)
        ])
        await sut.loadInitial()

        repository.stubbedResult = .failure(DomainError.serverError)
        await sut.loadMore()

        #expect(sut.state == .loaded(existingEpisodes))
    }

    @Test("loadMore error sets non-empty loadMoreError message")
    func loadMore_error_setsLoadMoreError() async {
        let (sut, repository) = makeSUT(stubbedPages: [
            page([.fixture()], cursor: 9999)
        ])
        await sut.loadInitial()

        repository.stubbedResult = .failure(DomainError.networkUnavailable)
        await sut.loadMore()

        if let errorMessage = sut.pagination.loadMoreError {
            #expect(!errorMessage.isEmpty)
        } else {
            Issue.record("Expected loadMoreError to be set")
        }
    }

    @Test("loadMore error sets isLoadingMore back to false")
    func loadMore_error_isLoadingMoreIsFalse() async {
        let (sut, repository) = makeSUT(stubbedPages: [
            page([.fixture()], cursor: 9999)
        ])
        await sut.loadInitial()

        repository.stubbedResult = .failure(DomainError.serverError)
        await sut.loadMore()

        #expect(sut.pagination.isLoadingMore == false)
    }

    // MARK: - loadMore — guard conditions

    @Test("loadMore is no-op when state is not loaded")
    func loadMore_stateNotLoaded_doesNothing() async {
        let (sut, repository) = makeSUT()
        // state is .idle — loadMore should be ignored

        await sut.loadMore()

        #expect(repository.fetchCallCount == 0)
    }

    @Test("loadMore is no-op when hasMore is false")
    func loadMore_hasMoreFalse_doesNothing() async {
        let (sut, repository) = makeSUT(stubbedPages: [
            page([.fixture()], cursor: nil)   // last page — hasMore will be false
        ])
        await sut.loadInitial()

        await sut.loadMore()

        // Only 1 call total — loadInitial's call; loadMore was skipped
        #expect(repository.fetchCallCount == 1)
    }
}

// MARK: - Helpers

private extension Result {
    var successValue: Success? {
        guard case .success(let value) = self else { return nil }
        return value
    }
}
