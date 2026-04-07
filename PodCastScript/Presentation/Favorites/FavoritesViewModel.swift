import Combine

@MainActor
final class FavoritesViewModel: ObservableObject {

    // MARK: - State

    enum State {
        case loading
        case loaded(channels: [Channel], episodes: [Episode])
        case empty
        case error(String)
    }

    // MARK: - Published

    @Published private(set) var state: State = .loading

    // MARK: - Dependencies

    private let fetchFavoriteChannelsUseCase: FetchFavoriteChannelsUseCase
    private let fetchFavoriteEpisodesUseCase: FetchFavoriteEpisodesUseCase
    private let toggleFavoriteChannelUseCase: ToggleFavoriteChannelUseCase
    private let toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase

    // MARK: - Init

    init(
        fetchFavoriteChannelsUseCase: FetchFavoriteChannelsUseCase,
        fetchFavoriteEpisodesUseCase: FetchFavoriteEpisodesUseCase,
        toggleFavoriteChannelUseCase: ToggleFavoriteChannelUseCase,
        toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase
    ) {
        self.fetchFavoriteChannelsUseCase = fetchFavoriteChannelsUseCase
        self.fetchFavoriteEpisodesUseCase = fetchFavoriteEpisodesUseCase
        self.toggleFavoriteChannelUseCase = toggleFavoriteChannelUseCase
        self.toggleFavoriteEpisodeUseCase = toggleFavoriteEpisodeUseCase
    }

    // MARK: - Load

    func loadFavorites() async {
        state = .loading
        do {
            async let channels = fetchFavoriteChannelsUseCase.execute()
            async let episodes = fetchFavoriteEpisodesUseCase.execute()
            let (fetchedChannels, fetchedEpisodes) = try await (channels, episodes)
            if fetchedChannels.isEmpty && fetchedEpisodes.isEmpty {
                state = .empty
            } else {
                state = .loaded(channels: fetchedChannels, episodes: fetchedEpisodes)
            }
        } catch {
            state = .error("Failed to load favorites.")
        }
    }

    // MARK: - Remove

    func removeChannel(_ channel: Channel) async {
        guard case .loaded(var channels, let episodes) = state else { return }
        do {
            try await toggleFavoriteChannelUseCase.execute(channel: channel)
            channels.removeAll { $0.id == channel.id }
            state = channels.isEmpty && episodes.isEmpty
                ? .empty
                : .loaded(channels: channels, episodes: episodes)
        } catch {
            // best-effort: reload on failure
            await loadFavorites()
        }
    }

    func removeEpisode(_ episode: Episode) async {
        guard case .loaded(let channels, var episodes) = state else { return }
        do {
            try await toggleFavoriteEpisodeUseCase.execute(episode: episode)
            episodes.removeAll { $0.id == episode.id }
            state = channels.isEmpty && episodes.isEmpty
                ? .empty
                : .loaded(channels: channels, episodes: episodes)
        } catch {
            await loadFavorites()
        }
    }
}
