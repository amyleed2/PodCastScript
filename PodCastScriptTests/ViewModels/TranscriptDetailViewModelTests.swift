import Testing
@testable import PodCastScript

// MARK: - Feature under test
// TranscriptDetailViewModel — manages TranscriptDetail screen state and export lifecycle.
//
// Test case list:
//   Initial state:
//     1.  state == .idle on init
//     2.  actionsEnabled == false on init
//     3.  transcriptText == nil on init
//   loadTranscript — success:
//     4.  state transitions to .loaded with transcript content
//     5.  actionsEnabled becomes true when loaded
//     6.  transcriptText matches loaded content
//     7.  transcriptSource is .generated for newly generated transcript
//     8.  transcriptSource is .cached for cached transcript
//   loadTranscript — unavailable:
//     9.  episode without audioURL → state == .noTranscriptAvailable
//    10.  generated result with nil content → state == .noTranscriptAvailable
//    11.  generated result with empty content → state == .noTranscriptAvailable
//   loadTranscript — error:
//    12.  DomainError.transcriptionFailed → state == .error(.transcriptionFailed)
//    13.  DomainError.networkUnavailable → state == .error(.networkUnavailable)
//    14.  DomainError.transcriptionTimeout → state == .error(.timeout)
//    15.  non-DomainError → state == .error(.unknown)
//   loadTranscript — re-entry guard:
//    16.  calling loadTranscript while already loaded is no-op
//    17.  calling loadTranscript while in error state is no-op
//   loadTranscript — generating intermediate state:
//    18.  state is .generating before repository returns
//   retryTranscript:
//    19.  after error, retryTranscript reloads and transitions to .loaded on success
//    20.  after error, retryTranscript stays .error when repository fails again
//    21.  retryTranscript from loaded state is no-op
//   export:
//    22.  exportTranscript when loaded transitions exportState to .done
//    23.  exportTranscript when not loaded is no-op
//    24.  exportTranscript when export already done is no-op
//    25.  resetExportState after .done resets exportState to .idle
//   actionsEnabled:
//    26.  actionsEnabled is false when state is .error

@MainActor
struct TranscriptDetailViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        episode: Episode = .fixture(),
        stubbedResult: Result<TranscriptResult, Error> = .success(
            TranscriptResult(episodeID: "ep-001", content: "Generated transcript text.", status: .generated, source: .generated)
        )
    ) -> (sut: TranscriptDetailViewModel, repository: MockTranscriptRepository) {
        let repository = MockTranscriptRepository()
        repository.stubbedResult = stubbedResult
        let transcriptUseCase = FetchTranscriptUseCase(repository: repository)
        let favoritesRepository = MockFavoritesRepository()
        let toggleUseCase = ToggleFavoriteEpisodeUseCase(repository: favoritesRepository)
        let isFavoriteUseCase = IsFavoriteEpisodeUseCase(repository: favoritesRepository)
        let sut = TranscriptDetailViewModel(
            episode: episode,
            fetchUseCase: transcriptUseCase,
            toggleFavoriteEpisodeUseCase: toggleUseCase,
            isFavoriteEpisodeUseCase: isFavoriteUseCase
        )
        return (sut, repository)
    }

    private func generatedResult(
        episodeID: String = "ep-001",
        content: String? = "Generated transcript text.",
        source: TranscriptSource = .generated
    ) -> Result<TranscriptResult, Error> {
        .success(TranscriptResult(episodeID: episodeID, content: content, status: .generated, source: source))
    }

    private func unavailableResult(episodeID: String = "ep-001") -> Result<TranscriptResult, Error> {
        .success(TranscriptResult(episodeID: episodeID, content: nil, status: .unavailable, source: nil))
    }

    // MARK: - Initial state

    @Test("state is idle on init")
    func init_stateIsIdle() {
        let (sut, _) = makeSUT()
        #expect(sut.state == .idle)
    }

    @Test("actionsEnabled is false on init")
    func init_actionsEnabledIsFalse() {
        let (sut, _) = makeSUT()
        #expect(sut.actionsEnabled == false)
    }

    @Test("transcriptText is nil on init")
    func init_transcriptTextIsNil() {
        let (sut, _) = makeSUT()
        #expect(sut.transcriptText == nil)
    }

    // MARK: - loadTranscript — success

    @Test("loadTranscript with generated content transitions to loaded")
    func loadTranscript_generatedContent_transitionsToLoaded() async {
        let (sut, _) = makeSUT(stubbedResult: generatedResult(content: "Hello transcript."))

        await sut.loadTranscript()

        #expect(sut.state == .loaded("Hello transcript.", .generated))
    }

    @Test("actionsEnabled is true when state is loaded")
    func loadTranscript_generatedContent_actionsEnabledIsTrue() async {
        let (sut, _) = makeSUT()

        await sut.loadTranscript()

        #expect(sut.actionsEnabled == true)
    }

    @Test("transcriptText matches loaded content")
    func loadTranscript_generatedContent_transcriptTextMatchesContent() async {
        let (sut, _) = makeSUT(stubbedResult: generatedResult(content: "Exact content."))

        await sut.loadTranscript()

        #expect(sut.transcriptText == "Exact content.")
    }

    @Test("transcriptSource is .generated for a newly generated transcript")
    func loadTranscript_generatedContent_sourceIsGenerated() async {
        let (sut, _) = makeSUT(stubbedResult: generatedResult(source: .generated))

        await sut.loadTranscript()

        #expect(sut.transcriptSource == .generated)
    }

    @Test("transcriptSource is .cached for a cached transcript")
    func loadTranscript_cachedContent_sourceIsCached() async {
        let (sut, _) = makeSUT(stubbedResult: generatedResult(source: .cached))

        await sut.loadTranscript()

        #expect(sut.transcriptSource == .cached)
    }

    // MARK: - loadTranscript — unavailable

    @Test("episode without audioURL transitions to noTranscriptAvailable")
    func loadTranscript_episodeWithoutAudioURL_noTranscriptAvailable() async {
        let episode = Episode.fixture(audioURL: nil)
        let (sut, _) = makeSUT(episode: episode)

        await sut.loadTranscript()

        #expect(sut.state == .noTranscriptAvailable)
    }

    @Test("generated result with nil content transitions to noTranscriptAvailable")
    func loadTranscript_generatedWithNilContent_noTranscriptAvailable() async {
        let (sut, _) = makeSUT(stubbedResult: generatedResult(content: nil))

        await sut.loadTranscript()

        #expect(sut.state == .noTranscriptAvailable)
    }

    @Test("generated result with empty content transitions to noTranscriptAvailable")
    func loadTranscript_generatedWithEmptyContent_noTranscriptAvailable() async {
        let (sut, _) = makeSUT(stubbedResult: generatedResult(content: ""))

        await sut.loadTranscript()

        #expect(sut.state == .noTranscriptAvailable)
    }

    // MARK: - loadTranscript — error classification

    @Test("DomainError.transcriptionFailed maps to .error(.transcriptionFailed)")
    func loadTranscript_transcriptionFailed_mapsToTranscriptionFailedError() async {
        let (sut, _) = makeSUT(
            stubbedResult: .failure(DomainError.transcriptionFailed(underlying: nil))
        )

        await sut.loadTranscript()

        if case .error(.transcriptionFailed) = sut.state {
            // expected
        } else {
            Issue.record("Expected .error(.transcriptionFailed), got \(sut.state)")
        }
    }

    @Test("DomainError.networkUnavailable maps to .error(.networkUnavailable)")
    func loadTranscript_networkUnavailable_mapsToNetworkError() async {
        let (sut, _) = makeSUT(stubbedResult: .failure(DomainError.networkUnavailable))

        await sut.loadTranscript()

        #expect(sut.state == .error(.networkUnavailable))
    }

    @Test("DomainError.transcriptionTimeout maps to .error(.timeout)")
    func loadTranscript_transcriptionTimeout_mapsToTimeoutError() async {
        let (sut, _) = makeSUT(stubbedResult: .failure(DomainError.transcriptionTimeout))

        await sut.loadTranscript()

        #expect(sut.state == .error(.timeout))
    }

    @Test("non-DomainError maps to .error(.unknown)")
    func loadTranscript_nonDomainError_mapsToUnknownError() async {
        struct SomeUnexpectedError: Error {}
        let (sut, _) = makeSUT(stubbedResult: .failure(SomeUnexpectedError()))

        await sut.loadTranscript()

        if case .error(.unknown) = sut.state {
            // expected
        } else {
            Issue.record("Expected .error(.unknown), got \(sut.state)")
        }
    }

    // MARK: - loadTranscript — generating intermediate state

    @Test("loadTranscript sets state to generating before awaiting repository")
    func loadTranscript_setsGeneratingStateBeforeRepositoryReturns() async {
        let suspendingRepository = SuspendingMockTranscriptRepository()
        let favoritesRepository = MockFavoritesRepository()
        let useCase = FetchTranscriptUseCase(repository: suspendingRepository)
        let sut = TranscriptDetailViewModel(
            episode: .fixture(),
            fetchUseCase: useCase,
            toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase(repository: favoritesRepository),
            isFavoriteEpisodeUseCase: IsFavoriteEpisodeUseCase(repository: favoritesRepository)
        )

        let task = Task { await sut.loadTranscript() }

        // Yield the main actor so loadTranscript() can start, set .generating,
        // then suspend at the repository await.
        await Task.yield()
        #expect(sut.state == .generating)

        // Resume the mock so the task can finish cleanly.
        suspendingRepository.resume(with: .success(
            TranscriptResult(episodeID: "ep-001", content: "text", status: .generated, source: .generated)
        ))
        await task.value
    }

    // MARK: - loadTranscript — re-entry guard

    @Test("loadTranscript when already loaded is no-op")
    func loadTranscript_whenAlreadyLoaded_isNoOp() async {
        let (sut, repository) = makeSUT()
        await sut.loadTranscript()
        let callCountAfterFirst = repository.fetchCallCount

        await sut.loadTranscript()

        #expect(repository.fetchCallCount == callCountAfterFirst)
    }

    @Test("loadTranscript when state is error is no-op")
    func loadTranscript_whenStateIsError_isNoOp() async {
        let (sut, repository) = makeSUT(
            stubbedResult: .failure(DomainError.transcriptionFailed(underlying: nil))
        )
        await sut.loadTranscript()
        let callCountAfterFirst = repository.fetchCallCount

        await sut.loadTranscript()

        #expect(repository.fetchCallCount == callCountAfterFirst)
    }

    // MARK: - retryTranscript

    @Test("retryTranscript after error reloads and transitions to loaded on success")
    func retryTranscript_afterError_reloadsSuccessfully() async {
        let (sut, repository) = makeSUT(
            stubbedResult: .failure(DomainError.transcriptionFailed(underlying: nil))
        )
        await sut.loadTranscript()
        // state is now .error

        repository.stubbedResult = .success(
            TranscriptResult(episodeID: "ep-001", content: "Retry transcript.", status: .generated, source: .generated)
        )
        await sut.retryTranscript()

        #expect(sut.state == .loaded("Retry transcript.", .generated))
    }

    @Test("retryTranscript stays in error when repository fails again")
    func retryTranscript_afterError_thenFailsAgain_staysError() async {
        let (sut, _) = makeSUT(stubbedResult: .failure(DomainError.networkUnavailable))
        await sut.loadTranscript()

        await sut.retryTranscript()

        if case .error = sut.state {
            // expected
        } else {
            Issue.record("Expected .error, got \(sut.state)")
        }
    }

    @Test("retryTranscript from loaded state is no-op")
    func retryTranscript_whenLoaded_isNoOp() async {
        let (sut, repository) = makeSUT()
        await sut.loadTranscript()
        let callCountAfterLoad = repository.fetchCallCount

        await sut.retryTranscript()

        #expect(repository.fetchCallCount == callCountAfterLoad)
    }

    // MARK: - actionsEnabled

    @Test("actionsEnabled is false when state is error")
    func actionsEnabled_whenError_isFalse() async {
        let (sut, _) = makeSUT(
            stubbedResult: .failure(DomainError.transcriptionFailed(underlying: nil))
        )
        await sut.loadTranscript()

        #expect(sut.actionsEnabled == false)
    }

    // MARK: - exportTranscript

    @Test("exportTranscript when loaded transitions exportState to done")
    func exportTranscript_whenLoaded_exportStateDone() async {
        let (sut, _) = makeSUT()
        await sut.loadTranscript()

        await sut.exportTranscript()

        if case .done = sut.exportState {
            // expected
        } else {
            Issue.record("Expected exportState == .done, got \(sut.exportState)")
        }
    }

    @Test("exportTranscript when not loaded is no-op")
    func exportTranscript_whenNotLoaded_isNoOp() async {
        let (sut, _) = makeSUT()

        await sut.exportTranscript()

        #expect(sut.exportState == .idle)
    }

    @Test("exportTranscript when export already done is no-op")
    func exportTranscript_whenExportAlreadyDone_isNoOp() async {
        let (sut, _) = makeSUT()
        await sut.loadTranscript()
        await sut.exportTranscript()

        await sut.exportTranscript()

        if case .done = sut.exportState {
            // expected
        } else {
            Issue.record("Expected exportState == .done, got \(sut.exportState)")
        }
    }

    @Test("resetExportState after done resets exportState to idle")
    func resetExportState_afterDone_resetsToIdle() async {
        let (sut, _) = makeSUT()
        await sut.loadTranscript()
        await sut.exportTranscript()

        sut.resetExportState()

        #expect(sut.exportState == .idle)
    }

    @Test("resetExportState from idle is safe no-op")
    func resetExportState_fromIdle_isNoOp() async {
        let (sut, _) = makeSUT()

        sut.resetExportState()

        #expect(sut.exportState == .idle)
    }
}
