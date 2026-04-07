import Foundation

/// Domain-level abstraction for audio-to-text transcript generation.
///
/// Implementations belong in the Data layer and must not expose provider-specific
/// request/response types through this protocol.
///
/// Contract:
/// - Must not return an empty string. If the provider produces no usable content,
///   throw `DomainError.transcriptionFailed(underlying:)` instead.
/// - Must not expose raw provider errors — map them to `DomainError.transcriptionFailed`
///   before throwing.
protocol TranscriptionProvider {
    /// Generates a full transcript from the given episode audio URL.
    ///
    /// - Parameter audioURL: A URL pointing to the episode's audio stream or file.
    /// - Returns: A non-empty transcript string.
    /// - Throws: `DomainError.transcriptionFailed` on provider error, timeout,
    ///           rate limit, unsupported source, or empty result.
    func generateTranscript(from audioURL: URL) async throws -> String
}
