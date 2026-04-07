/// Returns the number of transcripts currently stored in the local cache.
///
/// Used by `SettingsViewModel` to display cache occupancy to the user.
final class FetchTranscriptCacheCountUseCase {
    private let repository: TranscriptCacheRepository

    init(repository: TranscriptCacheRepository) {
        self.repository = repository
    }

    func execute() async throws -> Int {
        try await repository.cachedTranscriptCount()
    }
}
