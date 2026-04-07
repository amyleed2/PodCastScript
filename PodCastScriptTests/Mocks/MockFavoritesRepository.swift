@testable import PodCastScript

/// Stateful stub `FavoritesRepository` for use in unit tests.
///
/// Maintains in-memory sets of saved episode/channel IDs so that
/// `ToggleFavoriteEpisodeUseCase` / `ToggleFavoriteChannelUseCase` — which call
/// `isFavorite`, then `save`/`remove`, then `isFavorite` again — produce correct
/// results without requiring a real persistence layer.
///
/// Override `savedEpisodeIDs` / `savedChannelIDs` directly to set up preconditions,
/// e.g.:
/// ```swift
/// let repo = MockFavoritesRepository()
/// repo.savedEpisodeIDs = ["ep-001"]   // pre-populate as favorite
/// ```
final class MockFavoritesRepository: FavoritesRepository {

    // MARK: - In-memory state

    var savedEpisodeIDs: Set<String> = []
    var savedChannelIDs: Set<String> = []

    // MARK: - Episodes

    func saveEpisode(_ episode: Episode) async throws {
        savedEpisodeIDs.insert(episode.id)
    }

    func removeEpisode(id: String) async throws {
        savedEpisodeIDs.remove(id)
    }

    func fetchEpisodes() async throws -> [Episode] { [] }

    func isFavoriteEpisode(id: String) async throws -> Bool {
        savedEpisodeIDs.contains(id)
    }

    // MARK: - Channels

    func saveChannel(_ channel: Channel) async throws {
        savedChannelIDs.insert(channel.id)
    }

    func removeChannel(id: String) async throws {
        savedChannelIDs.remove(id)
    }

    func fetchChannels() async throws -> [Channel] { [] }

    func isFavoriteChannel(id: String) async throws -> Bool {
        savedChannelIDs.contains(id)
    }
}
