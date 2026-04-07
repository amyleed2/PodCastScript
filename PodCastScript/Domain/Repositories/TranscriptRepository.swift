/// Generates transcript content for an episode from its audio source.
///
/// Contract:
/// - Caller (`FetchTranscriptUseCase`) guarantees `episode.audioURL` is non-nil before calling.
/// - Returns `TranscriptResult` with `status == .generated` and non-empty `content` on success.
/// - Throws `DomainError.transcriptionFailed` on provider failure, timeout, or empty result.
protocol TranscriptRepository {
    func fetchTranscript(for episode: Episode) async throws -> TranscriptResult
}
