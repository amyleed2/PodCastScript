import Foundation

final class SearchChannelsUseCase {
    private let repository: ChannelRepository

    init(repository: ChannelRepository) {
        self.repository = repository
    }

    /// Returns an empty array (not an error) for blank or whitespace-only queries.
    func execute(query: String) async throws -> [Channel] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return try await repository.searchChannels(query: trimmed)
    }
}
