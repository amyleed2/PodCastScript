import Foundation
import Combine

@MainActor
final class EpisodeListViewModel: ObservableObject {

    // MARK: - State

    enum State: Equatable {
        case idle
        case loading
        case loaded([Episode])
        case empty
        case error(String)
    }

    /// Bundles all pagination indicators into a single published value,
    /// preventing partial-update rendering glitches from multiple @Published properties.
    struct PaginationState: Equatable {
        var hasMore: Bool = false
        var isLoadingMore: Bool = false
        var loadMoreError: String? = nil
    }

    // MARK: - Published

    @Published private(set) var state: State = .idle
    @Published private(set) var pagination: PaginationState = PaginationState()
    /// Set of favorited episode IDs. Used by the View to render per-row favorite state.
    @Published private(set) var favoriteEpisodeIDs: Set<String> = []

    // MARK: - Public (read-only for View title)

    let channel: Channel

    // MARK: - Private

    private let fetchUseCase: FetchEpisodesUseCase
    private let toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase
    private let fetchFavoriteEpisodesUseCase: FetchFavoriteEpisodesUseCase
    /// Raw millisecond cursor from the API. Not published — implementation detail only.
    private var nextPublishDate: Int? = nil

    // MARK: - Init

    init(
        channel: Channel,
        fetchUseCase: FetchEpisodesUseCase,
        toggleFavoriteEpisodeUseCase: ToggleFavoriteEpisodeUseCase,
        fetchFavoriteEpisodesUseCase: FetchFavoriteEpisodesUseCase
    ) {
        self.channel = channel
        self.fetchUseCase = fetchUseCase
        self.toggleFavoriteEpisodeUseCase = toggleFavoriteEpisodeUseCase
        self.fetchFavoriteEpisodesUseCase = fetchFavoriteEpisodesUseCase
    }

    // MARK: - Computed

    func isFavorite(episodeID: String) -> Bool {
        favoriteEpisodeIDs.contains(episodeID)
    }

    // MARK: - Actions

    func loadInitial() async {
        // Prevent .task from discarding loaded data on navigation re-appearance.
        guard state == .idle else { return }
        state = .loading
        pagination = PaginationState()
        nextPublishDate = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshFavoriteIDs() }
            group.addTask {
                do {
                    let page = try await self.fetchUseCase.execute(
                        channelID: self.channel.id,
                        nextPublishDate: nil
                    )
                    await MainActor.run {
                        self.nextPublishDate = page.nextPublishDate
                        self.pagination = PaginationState(hasMore: page.hasMore)
                        self.state = page.episodes.isEmpty ? .empty : .loaded(page.episodes)
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(self.domainMessage(from: error))
                    }
                }
            }
        }
    }

    func loadMore() async {
        guard case .loaded(let current) = state,
              pagination.hasMore,
              !pagination.isLoadingMore
        else { return }

        let priorHasMore = pagination.hasMore
        pagination = PaginationState(hasMore: priorHasMore, isLoadingMore: true, loadMoreError: nil)

        do {
            let page = try await fetchUseCase.execute(
                channelID: channel.id,
                nextPublishDate: nextPublishDate
            )
            nextPublishDate = page.nextPublishDate
            pagination = PaginationState(hasMore: page.hasMore)
            state = .loaded(current + page.episodes)
        } catch {
            pagination = PaginationState(
                hasMore: priorHasMore,
                isLoadingMore: false,
                loadMoreError: domainMessage(from: error)
            )
        }
    }

    func toggleFavorite(episode: Episode) async {
        do {
            let isNowFavorite = try await toggleFavoriteEpisodeUseCase.execute(episode: episode)
            if isNowFavorite {
                favoriteEpisodeIDs.insert(episode.id)
            } else {
                favoriteEpisodeIDs.remove(episode.id)
            }
        } catch {
            // Toggle failure is non-fatal: leave the current state unchanged.
            #if DEBUG
            print("[EpisodeList] toggleFavorite failed for \(episode.id): \(error)")
            #endif
        }
    }

    // MARK: - Private helpers

    private func refreshFavoriteIDs() async {
        do {
            let favorites = try await fetchFavoriteEpisodesUseCase.execute()
            favoriteEpisodeIDs = Set(favorites.map(\.id))
        } catch {
            #if DEBUG
            print("[EpisodeList] refreshFavoriteIDs failed: \(error)")
            #endif
        }
    }

    private func domainMessage(from error: Error) -> String {
        (error as? DomainError)?.userMessage
            ?? DomainError.unknown(underlying: error).userMessage
    }
}
