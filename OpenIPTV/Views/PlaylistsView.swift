import SwiftUI

struct PlaylistsView: View {
    @Bindable var store: PlaylistStore
    var onScrollCollapseChange: (Bool) -> Void = { _ in }
    @State private var showingPlaylistEditor = false
    @State private var showingClearConfirmation = false

    var body: some View {
        LibraryScreenContainer {
            PageTitleHeader(
                title: "Playlists",
                subtitle: "\(store.playlists.count) playlist sources",
                systemImage: "list.bullet.rectangle.fill"
            )

            PlaylistActionsRow(
                showingPlaylistEditor: $showingPlaylistEditor,
                showingClearConfirmation: $showingClearConfirmation
            )

            List {
                ScrollOffsetProbe(coordinateSpaceName: "playlists-scroll")

                Button {
                    store.selectPlaylist(nil)
                } label: {
                    PlaylistScopeRow(
                        title: "All Playlists",
                        subtitle: "\(compactCount(store.allChannels.count)) channels",
                        isSelected: store.selectedPlaylistID == nil,
                        systemImage: "rectangle.stack.fill"
                    )
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)

                ForEach(store.playlists) { playlist in
                    Button {
                        store.selectPlaylist(playlist.id)
                    } label: {
                        PlaylistScopeRow(
                            title: playlist.name,
                            subtitle: "\(compactCount(playlist.channelCount)) channels - \(playlist.host)",
                            isSelected: store.selectedPlaylistID == playlist.id,
                            systemImage: "link"
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            withAnimation(.smooth(duration: 0.35)) {
                                store.removePlaylist(playlist)
                            }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }

                        Button {
                            Task { await store.addOrUpdatePlaylist(from: playlist.sourceURL.absoluteString) }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .tint(.teal)
                    }
                }
            }
            .libraryPlainListLayout()
            .coordinateSpace(name: "playlists-scroll")
            .onVerticalScrollDirectionChange(onScrollCollapseChange)
        }
        .sheet(isPresented: $showingPlaylistEditor) {
            PlaylistEditorSheet(store: store)
                .presentationDetents([.height(420), .large])
        }
        .alert("Clear all playlists?", isPresented: $showingClearConfirmation) {
            Button("Clear Library", role: .destructive) {
                withAnimation(.smooth(duration: 0.45)) {
                    store.clearLibrary()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every playlist URL, cached channel, and saved channel from this device.")
        }
        .overlay(alignment: .bottom) {
            LoadingToast(store: store)
        }
    }
}

private struct PlaylistActionsRow: View {
    @Binding var showingPlaylistEditor: Bool
    @Binding var showingClearConfirmation: Bool

    var body: some View {
        HStack(spacing: 10) {
            Button {
                showingPlaylistEditor = true
            } label: {
                Label("Add Playlist", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 18))
            .tint(.teal)

            Button(role: .destructive) {
                showingClearConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.headline)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 18))
            .accessibilityLabel("Clear library")
        }
    }
}

private struct PlaylistScopeRow: View {
    var title: String
    var subtitle: String
    var isSelected: Bool
    var systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(isSelected ? .white : .teal)
                .frame(width: 42, height: 42)
                .background(isSelected ? Color.teal.gradient : Color.clear.gradient, in: Circle())
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.teal)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    PlaylistsView(store: PlaylistStore())
}
