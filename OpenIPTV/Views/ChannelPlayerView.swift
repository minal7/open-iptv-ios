import AVFoundation
import AVKit
import SwiftUI

struct ChannelPlayerView: View {
    var channel: Channel
    var store: PlaylistStore

    @State private var playbackSession = PlaybackSession()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SystemVideoPlayer(player: player)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.white.opacity(0.16), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.18), radius: 22, y: 10)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .center, spacing: 14) {
                            ChannelLogoView(channel: channel, size: 58)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(channel.name)
                                    .font(.title2.weight(.bold))
                                    .lineLimit(3)

                                Text(channel.categorySummary)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.teal)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Button {
                                store.toggleFavorite(channel)
                            } label: {
                                Image(systemName: store.isFavorite(channel) ? "star.fill" : "star")
                                    .font(.title3.weight(.semibold))
                                    .frame(width: 46, height: 46)
                                    .background(.thinMaterial, in: Circle())
                                    .foregroundStyle(store.isFavorite(channel) ? .yellow : .primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(store.isFavorite(channel) ? "Remove favorite" : "Add favorite")
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Source")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text(channel.streamURL.absoluteString)
                                .font(.footnote.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(18)
                    .panelBackground(cornerRadius: 26)
                }
                .padding(16)
            }
        }
        .navigationTitle(channel.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: channel.id) {
            playbackSession.play(channel)
        }
    }

    private var player: AVPlayer {
        playbackSession.player
    }
}

@MainActor
private final class PlaybackSession {
    let player = AVPlayer()
    private var activeURL: URL?

    deinit {
        player.pause()
        player.replaceCurrentItem(with: nil)
    }

    func play(_ channel: Channel) {
        if activeURL != channel.streamURL {
            activeURL = channel.streamURL
            let item = AVPlayerItem(url: channel.streamURL)
            item.externalMetadata = Self.metadata(for: channel)
            player.replaceCurrentItem(with: item)
        }

        player.defaultRate = 1
        player.play()
    }

    private static func metadata(for channel: Channel) -> [AVMetadataItem] {
        [
            metadataItem(identifier: .commonIdentifierTitle, value: channel.name),
            metadataItem(identifier: .commonIdentifierArtist, value: channel.categorySummary),
            metadataItem(identifier: .commonIdentifierAlbumName, value: channel.playlistName)
        ]
    }

    private static func metadataItem(identifier: AVMetadataIdentifier, value: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as NSString
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
}

struct SystemVideoPlayer: UIViewControllerRepresentable {
    var player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.delegate = context.coordinator
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.updatesNowPlayingInfoCenter = true
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player {
            controller.player = player
        }
        controller.delegate = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
        ) {
            coordinator.animate(alongsideTransition: nil) { _ in
                playerViewController.player?.defaultRate = 1
                playerViewController.player?.play()
            }
        }

        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
        ) {
            coordinator.animate(alongsideTransition: nil) { _ in
                playerViewController.player?.defaultRate = 1
                playerViewController.player?.play()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChannelPlayerView(channel: .preview, store: PlaylistStore())
    }
}
