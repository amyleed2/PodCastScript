import SwiftUI

struct ChannelSearchView: View {
    @StateObject private var viewModel: ChannelSearchViewModel

    init(viewModel: ChannelSearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                content
            }
            .navigationTitle("Search Channels")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        NavigationLink(value: FavoritesRoute.favorites) {
                            Image(systemName: "heart")
                        }
                        NavigationLink(value: SettingsRoute.settings) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .navigationDestination(for: Channel.self) { channel in
                AppCompositionRoot.makeEpisodeListView(channel: channel)
            }
            .navigationDestination(for: Episode.self) { episode in
                AppCompositionRoot.makeTranscriptDetailView(episode: episode)
            }
            .navigationDestination(for: FavoritesRoute.self) { _ in
                AppCompositionRoot.makeFavoritesView()
            }
            .navigationDestination(for: SettingsRoute.self) { _ in
                AppCompositionRoot.makeSettingsView()
            }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search podcasts...", text: $viewModel.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.search() }
                }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - State rendering

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            idlePlaceholder
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let channels):
            channelList(channels)
        case .empty:
            ContentUnavailableView(
                "No Results",
                systemImage: "magnifyingglass",
                description: Text("Try searching with a different keyword.")
            )
        case .error(let message):
            ContentUnavailableView(
                "Something Went Wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }

    private var idlePlaceholder: some View {
        ContentUnavailableView(
            "Search Podcasts",
            systemImage: "mic",
            description: Text("Enter a keyword to find podcast channels.")
        )
    }

    private func channelList(_ channels: [Channel]) -> some View {
        List(channels) { channel in
            NavigationLink(value: channel) {
                ChannelRowView(
                    channel: channel,
                    isFavorite: viewModel.isFavorite(channelID: channel.id),
                    onToggleFavorite: { Task { await viewModel.toggleFavorite(channel: channel) } }
                )
            }
        }
        .listStyle(.plain)
    }
}
