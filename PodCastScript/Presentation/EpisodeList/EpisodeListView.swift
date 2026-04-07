import SwiftUI

struct EpisodeListView: View {
    @StateObject private var viewModel: EpisodeListViewModel

    init(viewModel: EpisodeListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle(viewModel.channel.name)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadInitial() }
    }

    // MARK: - State rendering

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Color.clear
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let episodes):
            episodeList(episodes)
        case .empty:
            ContentUnavailableView(
                "No Episodes",
                systemImage: "headphones",
                description: Text("This channel has no episodes yet.")
            )
        case .error(let message):
            ContentUnavailableView(
                "Something Went Wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }

    // MARK: - Episode list with pagination footer

    private func episodeList(_ episodes: [Episode]) -> some View {
        List {
            ForEach(episodes) { episode in
                NavigationLink(value: episode) {
                    EpisodeRowView(
                        episode: episode,
                        isFavorite: viewModel.isFavorite(episodeID: episode.id),
                        onToggleFavorite: {
                            Task { await viewModel.toggleFavorite(episode: episode) }
                        }
                    )
                }
            }

            paginationFooter
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if let error = viewModel.pagination.loadMoreError {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.red)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .listRowSeparator(.hidden)
        }

        if viewModel.pagination.isLoadingMore {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .listRowSeparator(.hidden)
        } else if viewModel.pagination.hasMore {
            Button {
                Task { await viewModel.loadMore() }
            } label: {
                Text("Load More")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .listRowSeparator(.hidden)
        }
    }
}
