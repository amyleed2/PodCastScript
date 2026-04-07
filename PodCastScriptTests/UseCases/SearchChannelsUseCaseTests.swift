import Testing
@testable import PodCastScript

// MARK: - Feature under test
// SearchChannelsUseCase — executes a channel search via ChannelRepository.
//
// Missing coverage before this file: 100% (no tests existed)
//
// Test case list:
//   Blank query guard:
//     1. empty string → returns [] without hitting repository
//     2. whitespace-only string → returns [] without hitting repository
//   Success path:
//     3. valid query → delegates to repository and returns channels
//     4. trimmed query is forwarded to repository (not raw input)
//   Empty path:
//     5. repository returns [] → use case returns []
//   Error path:
//     6. repository throws DomainError.networkUnavailable → propagated
//     7. repository throws DomainError.serverError → propagated
//
// Regression checklist:
//   [ ] Blank query never calls repository
//   [ ] Whitespace is trimmed before forwarding to repository
//   [ ] Non-empty repository result is returned unchanged
//   [ ] Empty repository result is returned as-is (not converted to an error)
//   [ ] All DomainError cases propagate without wrapping

struct SearchChannelsUseCaseTests {

    // MARK: - Helpers

    private func makeSUT() -> (sut: SearchChannelsUseCase, repository: MockChannelRepository) {
        let repository = MockChannelRepository()
        let sut = SearchChannelsUseCase(repository: repository)
        return (sut, repository)
    }

    // MARK: - Blank query guard

    @Test("Empty query returns [] without calling repository")
    func execute_emptyQuery_returnsEmptyWithoutRepositoryCall() async throws {
        let (sut, repository) = makeSUT()

        let result = try await sut.execute(query: "")

        #expect(result.isEmpty)
        #expect(repository.searchCallCount == 0)
    }

    @Test("Whitespace-only query returns [] without calling repository")
    func execute_whitespaceQuery_returnsEmptyWithoutRepositoryCall() async throws {
        let (sut, repository) = makeSUT()

        let result = try await sut.execute(query: "   \t\n  ")

        #expect(result.isEmpty)
        #expect(repository.searchCallCount == 0)
    }

    // MARK: - Success path

    @Test("Valid query delegates to repository and returns channels")
    func execute_validQuery_returnsChannelsFromRepository() async throws {
        let (sut, repository) = makeSUT()
        let expected = [Channel.fixture(id: "1"), Channel.fixture(id: "2")]
        repository.stubbedResult = .success(expected)

        let result = try await sut.execute(query: "swift")

        #expect(result == expected)
        #expect(repository.searchCallCount == 1)
    }

    @Test("Query is trimmed before forwarding to repository")
    func execute_queryWithSurroundingWhitespace_forwardsTrimmedQuery() async throws {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .success([])

        _ = try await sut.execute(query: "  swift programming  ")

        #expect(repository.lastQuery == "swift programming")
    }

    // MARK: - Empty path

    @Test("Repository returning empty array is returned as-is")
    func execute_repositoryReturnsEmpty_returnsEmptyArray() async throws {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .success([])

        let result = try await sut.execute(query: "obscure-topic-xyz")

        #expect(result.isEmpty)
        #expect(repository.searchCallCount == 1)
    }

    // MARK: - Error path

    @Test("Network error from repository propagates as DomainError")
    func execute_repositoryThrowsNetworkError_propagates() async {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .failure(DomainError.networkUnavailable)

        await #expect(throws: DomainError.self) {
            try await sut.execute(query: "swift")
        }
    }

    @Test("Server error from repository propagates as DomainError")
    func execute_repositoryThrowsServerError_propagates() async {
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .failure(DomainError.serverError)

        await #expect(throws: DomainError.self) {
            try await sut.execute(query: "swift")
        }
    }
}
