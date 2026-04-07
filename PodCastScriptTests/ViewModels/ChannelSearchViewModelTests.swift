import Testing
@testable import PodCastScript

// MARK: - Feature under test
// ChannelSearchViewModel — manages ChannelSearch screen state.
//
// Missing coverage before this file: 100% (ViewModel did not exist)
//
// Test case list:
//   Initial state:
//     1. idle state on init
//     2. query pre-populated from recent search preference
//     3. query is empty string when no recent search exists
//   search() — blank query:
//     4. empty query sets state to idle (no network call)
//     5. whitespace-only query sets state to idle (no network call)
//   search() — success path:
//     6. state transitions loading → loaded([channels]) on success
//     7. saves trimmed query to preferences on search
//   search() — empty path:
//     8. state transitions loading → empty when results are []
//   search() — error path:
//     9. state transitions loading → error(_) on thrown error
//   clearSearch():
//    10. resets query to "" and state to idle
//
// Regression checklist:
//   [ ] init reads recentSearchQuery from preferences into query
//   [ ] Blank/whitespace query never enters loading state
//   [ ] Successful search saves query to preferences
//   [ ] state == .loaded only when channels.count > 0
//   [ ] state == .empty when repository returns []
//   [ ] state == .error on any thrown error
//   [ ] clearSearch() resets both query and state

@MainActor
struct ChannelSearchViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        recentQuery: String? = nil,
        stubbedChannels: [Channel] = [],
        stubbedError: Error? = nil
    ) -> (
        sut: ChannelSearchViewModel,
        repository: MockChannelRepository,
        preferences: MockRecentSearchPreferenceStore
    ) {
        let repository = MockChannelRepository()
        if let error = stubbedError {
            repository.stubbedResult = .failure(error)
        } else {
            repository.stubbedResult = .success(stubbedChannels)
        }

        let preferences = MockRecentSearchPreferenceStore()
        preferences.recentSearchQuery = recentQuery

        let useCase = SearchChannelsUseCase(repository: repository)
        let sut = ChannelSearchViewModel(searchUseCase: useCase, preferences: preferences)
        return (sut, repository, preferences)
    }

    // MARK: - Initial state

    @Test("Initial state is idle")
    func init_stateIsIdle() {
        let (sut, _, _) = makeSUT()
        #expect(sut.state == .idle)
    }

    @Test("Query pre-populated from recent search preference")
    func init_recentQueryExists_queryIsPrePopulated() {
        let (sut, _, _) = makeSUT(recentQuery: "swift concurrency")
        #expect(sut.query == "swift concurrency")
    }

    @Test("Query is empty when no recent search stored")
    func init_noRecentQuery_queryIsEmpty() {
        let (sut, _, _) = makeSUT(recentQuery: nil)
        #expect(sut.query == "")
    }

    // MARK: - Blank query

    @Test("Empty query keeps state idle without searching")
    func search_emptyQuery_stateRemainsIdle() async {
        let (sut, repository, _) = makeSUT()
        sut.query = ""

        await sut.search()

        #expect(sut.state == .idle)
        #expect(repository.searchCallCount == 0)
    }

    @Test("Empty query does not write to recent search preferences")
    func search_emptyQuery_doesNotWritePreferences() async {
        let (sut, _, preferences) = makeSUT(recentQuery: nil)
        sut.query = ""

        await sut.search()

        #expect(preferences.recentSearchQuery == nil)
    }

    @Test("Whitespace-only query keeps state idle without searching")
    func search_whitespaceQuery_stateRemainsIdle() async {
        let (sut, repository, _) = makeSUT()
        sut.query = "   "

        await sut.search()

        #expect(sut.state == .idle)
        #expect(repository.searchCallCount == 0)
    }

    @Test("Whitespace-only query does not write to recent search preferences")
    func search_whitespaceQuery_doesNotWritePreferences() async {
        let (sut, _, preferences) = makeSUT(recentQuery: nil)
        sut.query = "   "

        await sut.search()

        #expect(preferences.recentSearchQuery == nil)
    }

    // MARK: - Success path

    @Test("Successful search transitions to loaded with returned channels")
    func search_success_stateIsLoaded() async {
        let channels = [Channel.fixture(id: "1"), Channel.fixture(id: "2")]
        let (sut, _, _) = makeSUT(stubbedChannels: channels)
        sut.query = "swift"

        await sut.search()

        #expect(sut.state == .loaded(channels))
    }

    @Test("Successful search saves trimmed query to preferences")
    func search_success_savesQueryToPreferences() async {
        let (sut, _, preferences) = makeSUT(stubbedChannels: [Channel.fixture()])
        sut.query = "  swift  "

        await sut.search()

        #expect(preferences.recentSearchQuery == "swift")
    }

    // MARK: - Empty path

    @Test("Empty results transition state to empty")
    func search_emptyResults_stateIsEmpty() async {
        let (sut, _, _) = makeSUT(stubbedChannels: [])
        sut.query = "unknown-channel-xyz"

        await sut.search()

        #expect(sut.state == .empty)
    }

    // MARK: - Error path

    @Test("Network error transitions state to error")
    func search_networkError_stateIsError() async {
        let (sut, _, _) = makeSUT(stubbedError: DomainError.networkUnavailable)
        sut.query = "swift"

        await sut.search()

        if case .error = sut.state { } else {
            Issue.record("Expected state .error, got \(sut.state)")
        }
    }

    @Test("Server error transitions state to error")
    func search_serverError_stateIsError() async {
        let (sut, _, _) = makeSUT(stubbedError: DomainError.serverError)
        sut.query = "swift"

        await sut.search()

        if case .error = sut.state { } else {
            Issue.record("Expected state .error, got \(sut.state)")
        }
    }

    @Test("Error message is non-empty")
    func search_error_messageIsNonEmpty() async {
        let (sut, _, _) = makeSUT(stubbedError: DomainError.networkUnavailable)
        sut.query = "swift"

        await sut.search()

        if case .error(let message) = sut.state {
            #expect(!message.isEmpty)
        } else {
            Issue.record("Expected state .error, got \(sut.state)")
        }
    }

    // MARK: - clearSearch

    @Test("clearSearch resets query and state to idle")
    func clearSearch_resetsQueryAndState() async {
        let channels = [Channel.fixture()]
        let (sut, _, _) = makeSUT(stubbedChannels: channels)
        sut.query = "swift"
        await sut.search()

        sut.clearSearch()

        #expect(sut.query == "")
        #expect(sut.state == .idle)
    }
}
