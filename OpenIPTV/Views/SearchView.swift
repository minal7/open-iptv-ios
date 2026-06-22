import SwiftUI

struct SearchView: View {
    @Bindable var store: PlaylistStore
    @State private var searchText = ""
    private let topAnchorID = "search-results-top"

    private var results: [Channel] {
        store.channels(searchText: searchText)
    }

    var body: some View {
        ScrollViewReader { proxy in
            LibraryScreenContainer {
                PageTitleHeader(
                    title: "Search",
                    subtitle: searchSubtitle,
                    systemImage: "magnifyingglass"
                )

                LibrarySearchField(text: $searchText, prompt: "Search channels, categories, playlists")

                ChannelResultsList(
                    channels: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : results,
                    store: store,
                    emptyTitle: searchText.isEmpty ? "Start Searching" : "No Matches",
                    emptyMessage: searchText.isEmpty ? "Search by channel, category, playlist, or host." : "Try a shorter search.",
                    topAnchorID: topAnchorID
                )
            }
            .onChange(of: searchText) { _, _ in
                DispatchQueue.main.async {
                    withAnimation(.smooth(duration: 0.2)) {
                        proxy.scrollTo(topAnchorID, anchor: .top)
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            LoadingToast(store: store)
        }
    }

    private var searchSubtitle: String {
        "\(compactCount(store.channels.count)) channels in \(store.selectedPlaylistName)"
    }
}

#Preview {
    SearchView(store: PlaylistStore())
}
