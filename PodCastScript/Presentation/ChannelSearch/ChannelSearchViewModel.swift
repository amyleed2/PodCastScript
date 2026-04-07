import Foundation
import Combine

@MainActor
final class ChannelSearchViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded([Channel])
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published var query: String
    /// Set of favorited channel IDs. Used by the View to render per-row favorite state.
    @Published private(set) var favoriteChannelIDs: Set<String> = []

    private let searchUseCase: SearchChannelsUseCase
    private let toggleFavoriteChannelUseCase: ToggleFavoriteChannelUseCase
    private let fetchFavoriteChannelsUseCase: FetchFavoriteChannelsUseCase
    private var preferences: RecentSearchPreferenceStore

    /// In-flight search task. Cancelled when a new search begins (debounce + cancellation).
    private var searchTask: Task<Void, Never>?
    /// Session-scoped cache. Avoids a network round-trip for a query already seen this session.
    private var searchCache: [String: [Channel]] = [:]
    /// The query that produced the currently displayed results.
    /// Used to skip identical re-submissions without touching the network.
    private var lastSearchedQuery: String?

    init(
        searchUseCase: SearchChannelsUseCase,
        preferences: RecentSearchPreferenceStore,
        toggleFavoriteChannelUseCase: ToggleFavoriteChannelUseCase,
        fetchFavoriteChannelsUseCase: FetchFavoriteChannelsUseCase
    ) {
        self.searchUseCase = searchUseCase
        self.preferences = preferences
        self.toggleFavoriteChannelUseCase = toggleFavoriteChannelUseCase
        self.fetchFavoriteChannelsUseCase = fetchFavoriteChannelsUseCase
        self.query = preferences.recentSearchQuery ?? ""
    }

    // MARK: - Computed

    func isFavorite(channelID: String) -> Bool {
        favoriteChannelIDs.contains(channelID)
    }

    // MARK: - Actions

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }

        // Cancel any previously in-flight search so the old result never
        // overwrites a newer one, and we don't burn a quota request.
        searchTask?.cancel()

        searchTask = Task {
            // Debounce: absorb rapid re-submissions (e.g. accidental double-tap).
            // The sleep is cancelled if another search fires within the window.
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            // Dedup: the user re-submitted the exact same query and results are
            // already on screen — nothing to do.
            if trimmed == lastSearchedQuery, case .loaded = state { return }

            // Cache hit: serve the previous result immediately, no network call.
            if let cached = searchCache[trimmed] {
                lastSearchedQuery = trimmed
                state = cached.isEmpty ? .empty : .loaded(cached)
                return
            }

            // --- Network path ---
            state = .loading
            preferences.recentSearchQuery = trimmed

            // Favorites refresh runs in the background; it is non-critical and
            // should not block the search result from appearing.
            Task { await self.refreshFavoriteIDs() }

            do {
                let channels = try await searchUseCase.execute(query: trimmed)
                guard !Task.isCancelled else { return }
                searchCache[trimmed] = channels
                lastSearchedQuery = trimmed
                state = channels.isEmpty ? .empty : .loaded(channels)
            } catch {
                guard !Task.isCancelled else { return }
                let message = (error as? DomainError)?.userMessage
                    ?? DomainError.unknown(underlying: error).userMessage
                state = .error(message)
            }
        }

        // Await the task so the caller's async context stays alive for the
        // full search lifecycle (matches the previous async signature).
        await searchTask?.value
    }

    func clearSearch() {
        searchTask?.cancel()
        query = ""
        state = .idle
        lastSearchedQuery = nil
    }

    func toggleFavorite(channel: Channel) async {
        do {
            let isNowFavorite = try await toggleFavoriteChannelUseCase.execute(channel: channel)
            if isNowFavorite {
                favoriteChannelIDs.insert(channel.id)
            } else {
                favoriteChannelIDs.remove(channel.id)
            }
        } catch {
            #if DEBUG
            print("[ChannelSearch] toggleFavorite failed for \(channel.id): \(error)")
            #endif
        }
    }

    // MARK: - Private helpers

    private func refreshFavoriteIDs() async {
        do {
            let favorites = try await fetchFavoriteChannelsUseCase.execute()
            favoriteChannelIDs = Set(favorites.map(\.id))
        } catch {
            #if DEBUG
            print("[ChannelSearch] refreshFavoriteIDs failed: \(error)")
            #endif
        }
    }
}
