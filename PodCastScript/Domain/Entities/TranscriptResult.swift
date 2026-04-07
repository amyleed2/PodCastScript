/// The outcome of a transcript generation attempt for a single episode.
///
/// Invariants (enforced by the Data layer):
/// - `content` is non-nil and non-empty if and only if `status == .generated`.
/// - `content` is nil if and only if `status == .unavailable`.
/// - `source` is non-nil if and only if `status == .generated`.
struct TranscriptResult: Equatable {
    let episodeID: String

    /// The generated transcript text.
    /// Non-nil only when `status == .generated`. Empty string is never a valid value.
    let content: String?

    let status: TranscriptStatus

    /// Where the transcript came from.
    /// Non-nil only when `status == .generated`; `nil` when unavailable.
    let source: TranscriptSource?
}
