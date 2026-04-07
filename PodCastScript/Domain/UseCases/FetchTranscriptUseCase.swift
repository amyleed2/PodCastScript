/// Orchestrates transcript generation for a single episode.
///
/// Responsibilities:
/// - Guard for nil `audioURL` — returns `.unavailable` without throwing.
/// - Delegate generation to `TranscriptRepository`.
/// - Does not know which transcription provider is used (that is a Data layer detail).
///
/// Single execution path: there is no API lookup or fallback logic.
/// Generation from audio is the only source of transcript content.
final class FetchTranscriptUseCase {
    private let repository: TranscriptRepository

    init(repository: TranscriptRepository) {
        self.repository = repository
    }

    func execute(episode: Episode) async throws -> TranscriptResult {
        guard episode.audioURL != nil else {
            return TranscriptResult(
                episodeID: episode.id,
                content: nil,
                status: .unavailable,
                source: nil
            )
        }
        return try await repository.fetchTranscript(for: episode)
    }
}
