import SwiftUI
import SwiftData

/// Assembles the full dependency graph and returns ready-to-use SwiftUI views.
/// This is the only place that knows about all three layers simultaneously.
///
/// ## External API usage boundaries
/// - **Listen Notes** (via `ListenNotesTarget`): channel search and episode metadata **only**.
///   Subject to a quota limit on the FREE plan (50 req/day).
///   `ChannelSearchViewModel` debounces requests, caches results per session, and cancels
///   in-flight tasks to keep usage as low as possible.
///
/// - **AssemblyAI** (via `AssemblyAITranscriptionProvider`): transcript generation **only**.
///   Never used for metadata. Invoked only when an API transcript is unavailable.
@MainActor
enum AppCompositionRoot {

    // MARK: - Shared SwiftData container

    /// Lazily created once for the app's lifetime.
    /// Registered in `PodCastScriptApp.body` via `.modelContainer(sharedModelContainer)`.
    static let sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: CachedTranscript.self,
                     FavoriteEpisode.self,
                     FavoriteChannel.self
            )
        } catch {
            fatalError("SwiftData ModelContainer setup failed: \(error)")
        }
    }()

    // MARK: - Shared favorites repository

    /// Returns a `FavoritesRepositoryImpl` bound to the shared main context.
    /// Called by every factory that needs favorites access.
    private static func makeFavoritesRepository() -> FavoritesRepositoryImpl {
        FavoritesRepositoryImpl(context: sharedModelContainer.mainContext)
    }

    // MARK: - View factories

    static func makeChannelSearchView() -> ChannelSearchView {
        let channelRepository = ChannelRepositoryImpl(apiKey: AppConfig.listenNotesAPIKey)
        let favoritesRepository = makeFavoritesRepository()

        let searchUseCase = SearchChannelsUseCase(repository: channelRepository)
        let toggleFavoriteChannelUseCase = ToggleFavoriteChannelUseCase(repository: favoritesRepository)
        let fetchFavoriteChannelsUseCase = FetchFavoriteChannelsUseCase(repository: favoritesRepository)
        let preferences = UserDefaultsRecentSearchPreference()

        let viewModel = ChannelSearchViewModel(
            searchUseCase: searchUseCase,
            preferences: preferences,
            toggleFavoriteChannelUseCase: toggleFavoriteChannelUseCase,
            fetchFavoriteChannelsUseCase: fetchFavoriteChannelsUseCase
        )
        return ChannelSearchView(viewModel: viewModel)
    }

    static func makeEpisodeListView(channel: Channel) -> EpisodeListView {
        let episodeRepository = EpisodeRepositoryImpl(apiKey: AppConfig.listenNotesAPIKey)
        let favoritesRepository = makeFavoritesRepository()

        let fetchEpisodesUseCase = FetchEpisodesUseCase(repository: episodeRepository)
        let toggleFavoriteEpisodeUseCase = ToggleFavoriteEpisodeUseCase(repository: favoritesRepository)
        let fetchFavoriteEpisodesUseCase = FetchFavoriteEpisodesUseCase(repository: favoritesRepository)

        let viewModel = EpisodeListViewModel(
            channel: channel,
            fetchUseCase: fetchEpisodesUseCase,
            toggleFavoriteEpisodeUseCase: toggleFavoriteEpisodeUseCase,
            fetchFavoriteEpisodesUseCase: fetchFavoriteEpisodesUseCase
        )
        return EpisodeListView(viewModel: viewModel)
    }

    static func makeTranscriptDetailView(episode: Episode) -> TranscriptDetailView {
        let provider = makeTranscriptionProvider()
        let cacheStore = TranscriptCacheStore(context: sharedModelContainer.mainContext)
        let transcriptRepository = TranscriptRepositoryImpl(provider: provider, cacheStore: cacheStore)
        let favoritesRepository = makeFavoritesRepository()

        let fetchTranscriptUseCase = FetchTranscriptUseCase(repository: transcriptRepository)
        let toggleFavoriteEpisodeUseCase = ToggleFavoriteEpisodeUseCase(repository: favoritesRepository)
        let isFavoriteEpisodeUseCase = IsFavoriteEpisodeUseCase(repository: favoritesRepository)

        let viewModel = TranscriptDetailViewModel(
            episode: episode,
            fetchUseCase: fetchTranscriptUseCase,
            toggleFavoriteEpisodeUseCase: toggleFavoriteEpisodeUseCase,
            isFavoriteEpisodeUseCase: isFavoriteEpisodeUseCase
        )
        return TranscriptDetailView(viewModel: viewModel)
    }

    static func makeSettingsView() -> SettingsView {
        let cacheStore = TranscriptCacheStore(context: sharedModelContainer.mainContext)
        let fetchCacheCountUseCase = FetchTranscriptCacheCountUseCase(repository: cacheStore)
        let clearCacheUseCase = ClearTranscriptCacheUseCase(repository: cacheStore)
        let viewModel = SettingsViewModel(
            fetchCacheCountUseCase: fetchCacheCountUseCase,
            clearCacheUseCase: clearCacheUseCase
        )
        return SettingsView(viewModel: viewModel)
    }

    static func makeFavoritesView() -> FavoritesView {
        let favoritesRepository = makeFavoritesRepository()

        let fetchFavoriteChannelsUseCase = FetchFavoriteChannelsUseCase(repository: favoritesRepository)
        let fetchFavoriteEpisodesUseCase = FetchFavoriteEpisodesUseCase(repository: favoritesRepository)
        let toggleFavoriteChannelUseCase = ToggleFavoriteChannelUseCase(repository: favoritesRepository)
        let toggleFavoriteEpisodeUseCase = ToggleFavoriteEpisodeUseCase(repository: favoritesRepository)

        let viewModel = FavoritesViewModel(
            fetchFavoriteChannelsUseCase: fetchFavoriteChannelsUseCase,
            fetchFavoriteEpisodesUseCase: fetchFavoriteEpisodesUseCase,
            toggleFavoriteChannelUseCase: toggleFavoriteChannelUseCase,
            toggleFavoriteEpisodeUseCase: toggleFavoriteEpisodeUseCase
        )
        return FavoritesView(viewModel: viewModel)
    }

    // MARK: - Private helpers

    /// Selects a `TranscriptionProvider` based on available configuration.
    private static func makeTranscriptionProvider() -> TranscriptionProvider {
        if let apiKey = AppConfig.assemblyAIAPIKey {
            return AssemblyAITranscriptionProvider(apiKey: apiKey)
        }
        #if DEBUG
        return StubTranscriptionProvider()
        #else
        fatalError(
            "ASSEMBLYAI_API_KEY is not set. " +
            "Add the key to Secrets.xcconfig before making a release build."
        )
        #endif
    }
}
