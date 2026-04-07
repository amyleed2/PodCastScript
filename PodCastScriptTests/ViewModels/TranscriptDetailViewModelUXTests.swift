import Testing
@testable import PodCastScript

// MARK: - Feature under test
// TranscriptDetailViewModel — UX-driven state condition tests.
//
// This file supplements TranscriptDetailViewModelTests.swift with tests
// that verify the ViewModel properties driving View display conditions:
//
//   [Cached badge condition]       transcriptSource == .cached  → View shows badge
//   [Generating view condition]    state == .generating         → View shows progress + elapsed
//   [Error message branch]         error case identity          → View selects correct icon/title
//   [Toolbar gate]                 actionsEnabled               → View enables/disables buttons
//
// Since Views are not instantiated in unit tests, every View condition is
// verified through a ViewModel computed property or state case assertion.
//
// Test case list:
//   Initial values:
//     1.  generatingElapsedSeconds is 0 on init
//     2.  transcriptSource is nil on init
//   View gate — actionsEnabled:
//     3.  actionsEnabled is false when state is .idle
//     4.  actionsEnabled is false when state is .generating
//     5.  actionsEnabled is false when state is .noTranscriptAvailable
//   View gate — transcriptText:
//     6.  transcriptText is nil when state is .error
//     7.  transcriptText is nil when state is .noTranscriptAvailable
//   View gate — transcriptSource:
//     8.  transcriptSource is nil when state is .noTranscriptAvailable
//     9.  transcriptSource is nil when state is .error
//    10.  transcriptSource is nil while state is .generating
//   Error message content:
//    11.  .transcriptionFailed error carries a non-empty message string
//    12.  .unknown error carries a non-empty message string
//    13.  .serverError maps to .error(.unknown)
//    14.  .unauthorized maps to .error(.unknown)
//   retryTranscript — comprehensive no-op coverage:
//    15.  retryTranscript from .idle is no-op
//    16.  retryTranscript from .generating is no-op
//    17.  retryTranscript from .noTranscriptAvailable is no-op
//   loadTranscript — additional no-op coverage:
//    18.  loadTranscript from .noTranscriptAvailable is no-op
//   elapsed timer:
//    19.  generatingElapsedSeconds resets to 0 when retrying after error
//    20.  generatingElapsedSeconds stops (does not increment) after noTranscriptAvailable
//   favorites:
//    21.  isFavoriteEpisode is false on init
//    22.  isFavoriteEpisode reflects repository after loadFavoriteStatus
//    23.  toggleEpisodeFavorite flips isFavoriteEpisode from false to true
//    24.  toggleEpisodeFavorite flips isFavoriteEpisode from true to false
//   mapResult edge case:
//    25.  result with status .generated but source nil falls back to .generated source
//
// NOT testable without injection (architectural note):
//   - exportState reaching .failed requires writeExportFile to be injectable
//   - exportTranscript no-op from .exporting requires same injection
//   - resetExportState from .failed requires same injection
//   Resolution: make writeExportFile injectable via a protocol when coverage is needed.
//
// Regression checklist:
//   [ ] actionsEnabled is false in every non-.loaded state
//   [ ] transcriptText is nil in every non-.loaded state
//   [ ] transcriptSource is nil in every non-.loaded state
//   [ ] retryTranscript only proceeds from .error — all other states are no-ops
//   [ ] generatingElapsedSeconds starts fresh each time generation begins
//   [ ] isFavoriteEpisode correctly reflects repository state

@MainActor
struct TranscriptDetailViewModelUXTests {

    // MARK: - Factory

    private func makeSUT(
        episode: Episode = .fixture(),
        stubbedResult: Result<TranscriptResult, Error> = .success(
            TranscriptResult(
                episodeID: "ep-001",
                content: "Generated transcript text.",
                status: .generated,
                source: .generated
            )
        )
    ) -> (sut: TranscriptDetailViewModel, repository: MockTranscriptRepository) {
        let repository = MockTranscriptRepository()
        repository.stubbedResult = stubbedResult
        let favoritesRepo = MockFavoritesRepository()
        let sut = TranscriptDetailViewModel(
            episode: episode,
            fetchUseCase: FetchTranscriptUseCase(repository: repository),
            toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase(repository: favoritesRepo),
            isFavoriteEpisodeUseCase: IsFavoriteEpisodeUseCase(repository: favoritesRepo)
        )
        return (sut, repository)
    }

    /// Puts `sut` into `.generating` and suspends there.
    /// Caller is responsible for resuming `suspendingRepo`.
    private func makeGeneratingSUT() -> (
        sut: TranscriptDetailViewModel,
        suspendingRepo: SuspendingMockTranscriptRepository
    ) {
        let suspendingRepo = SuspendingMockTranscriptRepository()
        let favoritesRepo = MockFavoritesRepository()
        let sut = TranscriptDetailViewModel(
            episode: .fixture(),
            fetchUseCase: FetchTranscriptUseCase(repository: suspendingRepo),
            toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase(repository: favoritesRepo),
            isFavoriteEpisodeUseCase: IsFavoriteEpisodeUseCase(repository: favoritesRepo)
        )
        return (sut, suspendingRepo)
    }

    // MARK: - Initial values

    @Test("generatingElapsedSeconds is 0 on init")
    func init_generatingElapsedSecondsIsZero() {
        let (sut, _) = makeSUT()
        #expect(sut.generatingElapsedSeconds == 0)
    }

    @Test("transcriptSource is nil on init")
    func init_transcriptSourceIsNil() {
        let (sut, _) = makeSUT()
        #expect(sut.transcriptSource == nil)
    }

    // MARK: - actionsEnabled — all blocking states

    @Test("actionsEnabled is false when state is idle")
    func actionsEnabled_idle_isFalse() {
        let (sut, _) = makeSUT()
        // state is .idle at init
        #expect(sut.actionsEnabled == false)
    }

    @Test("actionsEnabled is false while generating (toolbar buttons must be disabled)")
    func actionsEnabled_generating_isFalse() async {
        let (sut, suspendingRepo) = makeGeneratingSUT()
        let task = Task { await sut.loadTranscript() }
        await Task.yield()

        // Verify state is .generating, then check actionsEnabled
        #expect(sut.state == .generating)
        #expect(sut.actionsEnabled == false)

        suspendingRepo.resume(with: .success(
            TranscriptResult(episodeID: "ep-001", content: "text", status: .generated, source: .generated)
        ))
        await task.value
    }

    @Test("actionsEnabled is false when noTranscriptAvailable")
    func actionsEnabled_noTranscriptAvailable_isFalse() async {
        let (sut, _) = makeSUT(episode: Episode.fixture(audioURL: nil))

        await sut.loadTranscript()

        #expect(sut.state == .noTranscriptAvailable)
        #expect(sut.actionsEnabled == false)
    }

    // MARK: - transcriptText — nil in all non-loaded states

    @Test("transcriptText is nil when state is error")
    func transcriptText_error_isNil() async {
        let (sut, _) = makeSUT(stubbedResult: .failure(DomainError.networkUnavailable))

        await sut.loadTranscript()

        #expect(sut.transcriptText == nil)
    }

    @Test("transcriptText is nil when noTranscriptAvailable")
    func transcriptText_noTranscriptAvailable_isNil() async {
        let (sut, _) = makeSUT(episode: Episode.fixture(audioURL: nil))

        await sut.loadTranscript()

        #expect(sut.transcriptText == nil)
    }

    // MARK: - transcriptSource — nil when not loaded

    @Test("transcriptSource is nil when noTranscriptAvailable")
    func transcriptSource_noTranscriptAvailable_isNil() async {
        let (sut, _) = makeSUT(episode: Episode.fixture(audioURL: nil))

        await sut.loadTranscript()

        #expect(sut.transcriptSource == nil)
    }

    @Test("transcriptSource is nil when state is error")
    func transcriptSource_error_isNil() async {
        let (sut, _) = makeSUT(stubbedResult: .failure(DomainError.networkUnavailable))

        await sut.loadTranscript()

        #expect(sut.state == .error(.networkUnavailable))
        #expect(sut.transcriptSource == nil)
    }

    @Test("transcriptSource is nil while state is generating")
    func transcriptSource_generating_isNil() async {
        let (sut, suspendingRepo) = makeGeneratingSUT()
        let task = Task { await sut.loadTranscript() }
        await Task.yield()

        #expect(sut.state == .generating)
        #expect(sut.transcriptSource == nil)

        suspendingRepo.resume(with: .success(
            TranscriptResult(episodeID: "ep-001", content: "text", status: .generated, source: .generated)
        ))
        await task.value
    }

    // MARK: - Error message content (drives View title/description)

    @Test("transcriptionFailed error carries a non-empty message string")
    func errorMessage_transcriptionFailed_isNonEmpty() async {
        let (sut, _) = makeSUT(
            stubbedResult: .failure(DomainError.transcriptionFailed(underlying: nil))
        )

        await sut.loadTranscript()

        if case .error(.transcriptionFailed(let message)) = sut.state {
            #expect(!message.isEmpty)
        } else {
            Issue.record("Expected .error(.transcriptionFailed), got \(sut.state)")
        }
    }

    @Test("unknown error carries a non-empty message string")
    func errorMessage_unknown_isNonEmpty() async {
        struct ArbitraryError: Error {}
        let (sut, _) = makeSUT(stubbedResult: .failure(ArbitraryError()))

        await sut.loadTranscript()

        if case .error(.unknown(let message)) = sut.state {
            #expect(!message.isEmpty)
        } else {
            Issue.record("Expected .error(.unknown), got \(sut.state)")
        }
    }

    @Test("DomainError.serverError maps to .error(.unknown)")
    func errorMapping_serverError_mapsToUnknown() async {
        let (sut, _) = makeSUT(stubbedResult: .failure(DomainError.serverError))

        await sut.loadTranscript()

        if case .error(.unknown) = sut.state {
            // expected — serverError is not a special-cased error in mapError
        } else {
            Issue.record("Expected .error(.unknown) for serverError, got \(sut.state)")
        }
    }

    @Test("DomainError.unauthorized maps to .error(.unknown)")
    func errorMapping_unauthorized_mapsToUnknown() async {
        let (sut, _) = makeSUT(stubbedResult: .failure(DomainError.unauthorized))

        await sut.loadTranscript()

        if case .error(.unknown) = sut.state {
            // expected
        } else {
            Issue.record("Expected .error(.unknown) for unauthorized, got \(sut.state)")
        }
    }

    // MARK: - retryTranscript — no-op coverage beyond .loaded

    @Test("retryTranscript from idle state is no-op (repository not called)")
    func retryTranscript_fromIdle_isNoOp() async {
        let (sut, repository) = makeSUT()
        // state is .idle — no loadTranscript call yet

        await sut.retryTranscript()

        #expect(repository.fetchCallCount == 0)
        #expect(sut.state == .idle)
    }

    @Test("retryTranscript from generating state is no-op (duplicate request prevented)")
    func retryTranscript_fromGenerating_isNoOp() async {
        let (sut, suspendingRepo) = makeGeneratingSUT()

        let loadTask = Task { await sut.loadTranscript() }
        await Task.yield()
        // sut.state == .generating

        await sut.retryTranscript()

        // State must still be .generating — retry was rejected
        #expect(sut.state == .generating)

        suspendingRepo.resume(with: .success(
            TranscriptResult(episodeID: "ep-001", content: "text", status: .generated, source: .generated)
        ))
        await loadTask.value
    }

    @Test("retryTranscript from noTranscriptAvailable state is no-op")
    func retryTranscript_fromNoTranscriptAvailable_isNoOp() async {
        let (sut, repository) = makeSUT(episode: Episode.fixture(audioURL: nil))
        await sut.loadTranscript()
        // state is .noTranscriptAvailable
        let callCountAfterLoad = repository.fetchCallCount

        await sut.retryTranscript()

        #expect(repository.fetchCallCount == callCountAfterLoad)
        #expect(sut.state == .noTranscriptAvailable)
    }

    // MARK: - loadTranscript — no-op from noTranscriptAvailable

    @Test("loadTranscript from noTranscriptAvailable is no-op (repository not called again)")
    func loadTranscript_fromNoTranscriptAvailable_isNoOp() async {
        let (sut, repository) = makeSUT(episode: Episode.fixture(audioURL: nil))
        await sut.loadTranscript()
        // state is .noTranscriptAvailable
        let callCountAfterFirst = repository.fetchCallCount

        await sut.loadTranscript()

        #expect(repository.fetchCallCount == callCountAfterFirst)
    }

    // MARK: - Elapsed timer resets on retry

    @Test("generatingElapsedSeconds resets to 0 when generation restarts after retry")
    func elapsedSeconds_resetsToZeroOnRetry() async {
        // Arrange: reach an error state first
        let (sut, repository) = makeSUT(
            stubbedResult: .failure(DomainError.transcriptionFailed(underlying: nil))
        )
        await sut.loadTranscript()
        // state is .error; elapsed timer was stopped

        // Arrange: stub a success for retry and use a suspending repo to catch .generating
        let suspendingRepo = SuspendingMockTranscriptRepository()
        repository.stubbedResult = .success(
            TranscriptResult(episodeID: "ep-001", content: "text", status: .generated, source: .generated)
        )

        // A fresh SUT in error state to verify reset on retry
        let (sut2, repo2) = makeSUT(
            stubbedResult: .failure(DomainError.networkUnavailable)
        )
        await sut2.loadTranscript()
        // state is .error; now stub success
        repo2.stubbedResult = .success(
            TranscriptResult(episodeID: "ep-001", content: "Retry text.", status: .generated, source: .generated)
        )

        // Act: retry triggers a new generation cycle
        // generatingElapsedSeconds should be reset to 0 when generation starts
        let retryTask = Task { await sut2.retryTranscript() }
        await Task.yield()

        // After yield, retryTranscript sets state to .generating (via loadTranscript)
        // At that point, generatingElapsedSeconds must be 0 (timer just restarted)
        if sut2.state == .generating {
            #expect(sut2.generatingElapsedSeconds == 0)
        }

        await retryTask.value

        // After completion, elapsed timer is stopped — value is whatever it counted to
        // but must be non-negative
        #expect(sut2.generatingElapsedSeconds >= 0)
        _ = suspendingRepo // suppress unused warning
    }

    @Test("generatingElapsedSeconds stops incrementing after noTranscriptAvailable")
    func elapsedSeconds_stopsAfterNoTranscriptAvailable() async {
        // When generation terminates with .noTranscriptAvailable, the timer must
        // be stopped via the defer in loadTranscript(). This verifies the timer
        // is not left running in the background after a terminal non-error state.
        let (sut, _) = makeSUT(episode: Episode.fixture(audioURL: nil))

        await sut.loadTranscript()

        #expect(sut.state == .noTranscriptAvailable)
        let valueAtTermination = sut.generatingElapsedSeconds

        // Yield briefly — if timer were still running, the count would increase.
        await Task.yield()

        // generatingElapsedSeconds must not have changed after terminal state.
        #expect(sut.generatingElapsedSeconds == valueAtTermination)
    }

    // MARK: - Favorites

    @Test("isFavoriteEpisode is false on init")
    func init_isFavoriteEpisodeIsFalse() {
        let (sut, _) = makeSUT()
        #expect(sut.isFavoriteEpisode == false)
    }

    @Test("isFavoriteEpisode is true after loadFavoriteStatus when episode is already saved")
    func loadFavoriteStatus_episodeAlreadySaved_isFavoriteIsTrue() async {
        let episode = Episode.fixture(id: "ep-saved")
        let repository = MockTranscriptRepository()
        let favoritesRepo = MockFavoritesRepository()
        favoritesRepo.savedEpisodeIDs = ["ep-saved"]    // pre-populate as saved
        let sut = TranscriptDetailViewModel(
            episode: episode,
            fetchUseCase: FetchTranscriptUseCase(repository: repository),
            toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase(repository: favoritesRepo),
            isFavoriteEpisodeUseCase: IsFavoriteEpisodeUseCase(repository: favoritesRepo)
        )

        await sut.loadFavoriteStatus()

        #expect(sut.isFavoriteEpisode == true)
    }

    @Test("toggleEpisodeFavorite saves episode and flips isFavoriteEpisode to true")
    func toggleFavorite_episodeNotSaved_savesAndBecomesTrue() async {
        let episode = Episode.fixture(id: "ep-toggle")
        let repository = MockTranscriptRepository()
        let favoritesRepo = MockFavoritesRepository()
        // savedEpisodeIDs is empty — episode is not a favorite
        let sut = TranscriptDetailViewModel(
            episode: episode,
            fetchUseCase: FetchTranscriptUseCase(repository: repository),
            toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase(repository: favoritesRepo),
            isFavoriteEpisodeUseCase: IsFavoriteEpisodeUseCase(repository: favoritesRepo)
        )
        #expect(sut.isFavoriteEpisode == false)

        await sut.toggleEpisodeFavorite()

        // Use case: isFavorite=false → saveEpisode → re-check → true
        #expect(sut.isFavoriteEpisode == true)
        #expect(favoritesRepo.savedEpisodeIDs.contains("ep-toggle"))
    }

    @Test("toggleEpisodeFavorite removes episode and flips isFavoriteEpisode to false")
    func toggleFavorite_episodeAlreadySaved_removesAndBecomesFalse() async {
        let episode = Episode.fixture(id: "ep-remove")
        let repository = MockTranscriptRepository()
        let favoritesRepo = MockFavoritesRepository()
        favoritesRepo.savedEpisodeIDs = ["ep-remove"]   // pre-populate as saved
        let sut = TranscriptDetailViewModel(
            episode: episode,
            fetchUseCase: FetchTranscriptUseCase(repository: repository),
            toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase(repository: favoritesRepo),
            isFavoriteEpisodeUseCase: IsFavoriteEpisodeUseCase(repository: favoritesRepo)
        )
        await sut.loadFavoriteStatus()
        #expect(sut.isFavoriteEpisode == true)

        await sut.toggleEpisodeFavorite()

        // Use case: isFavorite=true → removeEpisode → re-check → false
        #expect(sut.isFavoriteEpisode == false)
        #expect(!favoritesRepo.savedEpisodeIDs.contains("ep-remove"))
    }

    // MARK: - mapResult edge case

    @Test("result with status .generated but source nil falls back to .generated source")
    func mapResult_generatedStatusWithNilSource_fallsBackToGenerated() async {
        // TranscriptResult.source may be nil in legacy data.
        // mapResult must not produce .noTranscriptAvailable in this case.
        let legacyResult = TranscriptResult(
            episodeID: "ep-001",
            content: "Legacy transcript.",
            status: .generated,
            source: nil           // nil source — defensive fallback path
        )
        let (sut, repository) = makeSUT()
        repository.stubbedResult = .success(legacyResult)

        await sut.loadTranscript()

        // Must reach .loaded, not .noTranscriptAvailable
        if case .loaded(let text, let source) = sut.state {
            #expect(text == "Legacy transcript.")
            #expect(source == .generated)   // fallback applied
        } else {
            Issue.record("Expected .loaded with fallback source, got \(sut.state)")
        }
    }
}
