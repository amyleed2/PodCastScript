import Foundation

/// MVP stub for TranscriptionProvider.
///
/// Returns a fixed placeholder string so the full transcript generation pipeline
/// can be exercised end-to-end before a real provider is integrated.
///
/// Replace this with a concrete provider (e.g. WhisperTranscriptionProvider)
/// when real transcription integration is ready. Do not use in production builds.
#if DEBUG
final class StubTranscriptionProvider: TranscriptionProvider {
    func generateTranscript(from audioURL: URL) async throws -> String {
        // Simulate a short async delay representative of a real API round-trip.
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        return """
            [Stub transcript — generated from audio]

            This is a placeholder transcript produced by StubTranscriptionProvider. \
            It confirms that the transcript generation pipeline is wired correctly \
            end-to-end. Replace this provider with a real implementation to generate \
            actual transcript content from episode audio.

            Audio source: \(audioURL.lastPathComponent)
            """
    }
}
#endif
