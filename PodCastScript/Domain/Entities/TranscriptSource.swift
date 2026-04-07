/// Indicates where a successfully loaded transcript originated.
///
/// `source` is only meaningful when `TranscriptResult.status == .generated`.
/// It is `nil` when the episode has no audio URL (status == .unavailable).
enum TranscriptSource: Equatable {
    /// Transcript was produced by the transcription pipeline (e.g. AssemblyAI) during this session.
    case generated

    /// Transcript was retrieved from a local SwiftData cache from a previous session.
    case cached
}
