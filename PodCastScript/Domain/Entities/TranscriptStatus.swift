/// The outcome of a transcript generation attempt.
///
/// Transcript is always produced by the generation pipeline.
/// There are no API-sourced transcript states in this app.
enum TranscriptStatus: Equatable {
    /// Transcript was successfully produced by the transcription pipeline.
    case generated

    /// Transcript generation is not possible — the episode has no audio URL.
    case unavailable
}
