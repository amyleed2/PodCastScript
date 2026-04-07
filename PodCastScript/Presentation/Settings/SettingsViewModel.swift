import Combine

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - State

    enum State: Equatable {
        case loading
        case loaded(cachedCount: Int)
        case error(String)
    }

    // MARK: - Published

    @Published private(set) var state: State = .loading
    /// True while a clear-cache operation is in flight.
    @Published private(set) var isClearing: Bool = false

    // MARK: - Dependencies

    private let fetchCacheCountUseCase: FetchTranscriptCacheCountUseCase
    private let clearCacheUseCase: ClearTranscriptCacheUseCase

    // MARK: - Init

    init(
        fetchCacheCountUseCase: FetchTranscriptCacheCountUseCase,
        clearCacheUseCase: ClearTranscriptCacheUseCase
    ) {
        self.fetchCacheCountUseCase = fetchCacheCountUseCase
        self.clearCacheUseCase = clearCacheUseCase
    }

    // MARK: - Intents

    func loadCacheInfo() async {
        state = .loading
        do {
            let count = try await fetchCacheCountUseCase.execute()
            state = .loaded(cachedCount: count)
        } catch {
            state = .error("Failed to load cache information.")
        }
    }

    func clearCache() async {
        guard !isClearing else { return }
        isClearing = true
        defer { isClearing = false }

        do {
            try await clearCacheUseCase.execute()
            // Immediately reflect the cleared state without a second network round-trip.
            state = .loaded(cachedCount: 0)
        } catch {
            state = .error("Failed to clear transcript cache. Please try again.")
        }
    }
}
