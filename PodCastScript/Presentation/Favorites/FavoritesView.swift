import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel: FavoritesViewModel

    init(viewModel: FavoritesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Episode.self) { episode in
                AppCompositionRoot.makeTranscriptDetailView(episode: episode)
            }
            .task {
                await viewModel.loadFavorites()
            }
    }

    // MARK: - State rendering

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            ContentUnavailableView(
                "No Favorites Yet",
                systemImage: "heart",
                description: Text("Save channels and episodes to find them here.")
            )
        case .loaded(let channels, let episodes):
            favoritesList(channels: channels, episodes: episodes)
        case .error(let message):
            ContentUnavailableView(
                "Something Went Wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }

    // MARK: - List

    private func favoritesList(channels: [Channel], episodes: [Episode]) -> some View {
        List {
            if !channels.isEmpty {
                Section("Channels") {
                    ForEach(channels) { channel in
                        channelRow(channel)
                    }
                }
            }
            if !episodes.isEmpty {
                Section("Episodes") {
                    ForEach(episodes) { episode in
                        episodeRow(episode)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func channelRow(_ channel: Channel) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: channel.artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .overlay { Image(systemName: "mic").foregroundStyle(.tertiary) }
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(channel.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(channel.publisher)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.removeChannel(channel) }
            } label: {
                Label("Remove", systemImage: "heart.slash")
            }
        }
    }

    private func episodeRow(_ episode: Episode) -> some View {
        NavigationLink(value: episode) {
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(episode.publishedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.removeEpisode(episode) }
            } label: {
                Label("Remove", systemImage: "heart.slash")
            }
        }
    }
}
