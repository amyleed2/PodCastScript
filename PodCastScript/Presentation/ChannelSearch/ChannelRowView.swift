import SwiftUI

struct ChannelRowView: View {
    let channel: Channel
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            artwork
            labels
            Spacer(minLength: 8)
            Button {
                onToggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavorite ? .red : .secondary)
                    .imageScale(.medium)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var artwork: some View {
        AsyncImage(url: channel.artworkURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "mic")
                            .foregroundStyle(.tertiary)
                    }
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(channel.name)
                .font(.headline)
                .lineLimit(1)
            Text(channel.publisher)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
