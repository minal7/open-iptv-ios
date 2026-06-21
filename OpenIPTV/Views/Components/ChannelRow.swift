import SwiftUI

struct ChannelRow: View {
    var channel: Channel
    var isFavorite: Bool

    var body: some View {
        HStack(spacing: 14) {
            ChannelLogoView(channel: channel)

            VStack(alignment: .leading, spacing: 5) {
                Text(channel.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(channel.categorySummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(channel.playlistName)
                    Text(channel.streamHost)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favorite")
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

struct ChannelLogoView: View {
    var channel: Channel
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)

            if let logoURL = channel.logoURL {
                AsyncImage(url: logoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(6)
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.7)
                    case .failure:
                        fallbackImage
                    @unknown default:
                        fallbackImage
                    }
                }
            } else {
                fallbackImage
            }
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
    }

    private var fallbackImage: some View {
        Image(systemName: "play.tv")
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.teal)
    }
}

#Preview {
    List {
        ChannelRow(channel: .preview, isFavorite: true)
    }
}
