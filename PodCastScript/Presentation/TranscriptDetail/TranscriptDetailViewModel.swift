import Foundation
import Combine

@MainActor
final class TranscriptDetailViewModel: ObservableObject {

    // MARK: - Transcript load error (Presentation-layer classification)

    enum TranscriptLoadError: Equatable {
        /// Device has no network connection.
        case networkUnavailable
        /// Transcript generation polling exceeded the time limit.
        case timeout
        /// Provider encountered an error during generation.
        case transcriptionFailed(String)
        /// An unexpected error occurred.
        case unknown(String)
    }

    // MARK: - State

    enum State: Equatable {
        case idle
        /// Transcript generation is actively running (may take several minutes).
        case generating
        /// Transcript loaded successfully, carrying the text and its origin.
        case loaded(String, TranscriptSource)
        /// Episode has no audio URL — generation is impossible.
        case noTranscriptAvailable
        /// A classified error occurred during generation.
        case error(TranscriptLoadError)
    }

    enum ExportState: Equatable {
        case idle
        case exporting
        /// Export succeeded — carries the temporary file URL.
        case done(URL)
        case failed(String)
    }

    // MARK: - Published

    @Published private(set) var state: State = .idle
    @Published private(set) var exportState: ExportState = .idle
    @Published private(set) var isFavoriteEpisode: Bool = false
    /// Seconds elapsed since transcript generation started.
    @Published private(set) var generatingElapsedSeconds: Int = 0

    // MARK: - Computed

    var actionsEnabled: Bool {
        if case .loaded = state { return true }
        return false
    }

    var transcriptText: String? {
        if case .loaded(let text, _) = state { return text }
        return nil
    }

    var transcriptSource: TranscriptSource? {
        if case .loaded(_, let source) = state { return source }
        return nil
    }

    // MARK: - Dependencies

    private let episode: Episode
    private let fetchUseCase: FetchTranscriptUseCase
    private let toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase
    private let isFavoriteEpisodeUseCase: IsFavoriteEpisodeUseCase

    // MARK: - Private

    private var elapsedTimerTask: Task<Void, Never>?

    // MARK: - Init

    init(
        episode: Episode,
        fetchUseCase: FetchTranscriptUseCase,
        toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase,
        isFavoriteEpisodeUseCase: IsFavoriteEpisodeUseCase
    ) {
        self.episode = episode
        self.fetchUseCase = fetchUseCase
        self.toggleFavoriteEpisodeUseCase = toggleFavoriteEpisodeUseCase
        self.isFavoriteEpisodeUseCase = isFavoriteEpisodeUseCase
    }

    // MARK: - Intents

    func loadTranscript() async {
        guard state == .idle else { return }
        state = .generating
        startElapsedTimer()

        defer { stopElapsedTimer() }

        do {
            let result = try await fetchUseCase.execute(episode: episode)
            state = mapResult(result)
        } catch let domainError as DomainError {
            state = .error(mapError(domainError))
        } catch {
            state = .error(.unknown(DomainError.unknown(underlying: error).userMessage))
        }
    }

    func retryTranscript() async {
        // Only allow retry from an error state — prevents duplicate requests.
        guard case .error = state else { return }
        state = .idle
        await loadTranscript()
    }

    func loadFavoriteStatus() async {
        do {
            isFavoriteEpisode = try await isFavoriteEpisodeUseCase.execute(episodeID: episode.id)
        } catch {
            #if DEBUG
            print("[TranscriptDetail] loadFavoriteStatus failed: \(error)")
            #endif
        }
    }

    func toggleEpisodeFavorite() async {
        do {
            isFavoriteEpisode = try await toggleFavoriteEpisodeUseCase.execute(episode: episode)
        } catch {
            #if DEBUG
            print("[TranscriptDetail] toggleEpisodeFavorite failed: \(error)")
            #endif
        }
    }

    func exportTranscript() async {
        guard let text = transcriptText else { return }
        guard exportState == .idle else { return }
        exportState = .exporting

        do {
            let url = try await writeExportFile(text: text)
            exportState = .done(url)
        } catch {
            exportState = .failed("Export failed. Please try again.")
        }
    }

    func resetExportState() {
        exportState = .idle
    }

    // MARK: - Private helpers

    private func mapResult(_ result: TranscriptResult) -> State {
        switch result.status {
        case .generated:
            guard let content = result.content, !content.isEmpty else {
                return .noTranscriptAvailable
            }
            return .loaded(content, result.source ?? .generated)
        case .unavailable:
            return .noTranscriptAvailable
        }
    }

    private func mapError(_ error: DomainError) -> TranscriptLoadError {
        switch error {
        case .networkUnavailable:
            return .networkUnavailable
        case .transcriptionTimeout:
            return .timeout
        case .transcriptionFailed:
            return .transcriptionFailed(error.userMessage)
        default:
            return .unknown(error.userMessage)
        }
    }

    private func startElapsedTimer() {
        generatingElapsedSeconds = 0
        elapsedTimerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                generatingElapsedSeconds += 1
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimerTask?.cancel()
        elapsedTimerTask = nil
    }

    private func writeExportFile(text: String) async throws -> URL {
        return try await Task.detached(priority: .utility) {
            let safeID = self.episode.id
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self.episode.id
            let fileName = "transcript-\(safeID).txt"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        }.value
    }
}
