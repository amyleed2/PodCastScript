/// Deletes all cached transcripts from the local store.
///
/// Called from `SettingsViewModel` when the user confirms "Clear Transcript Cache".
/// After this executes, the next `FetchTranscriptUseCase` call for any episode
/// will trigger a fresh generation from the provider.
final class ClearTranscriptCacheUseCase {
    private let repository: TranscriptCacheRepository

    init(repository: TranscriptCacheRepository) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.clearAll()
    }
}
