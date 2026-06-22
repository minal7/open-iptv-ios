import SwiftUI

struct SavedChannelsView: View {
    @Bindable var store: PlaylistStore
    @State private var searchText = ""

    private var savedChannels: [Channel] {
        store.channels(searchText: searchText, favoritesOnly: true)
    }

    var body: some View {
        LibraryScreenContainer {
            PageTitleHeader(
                title: "Saved",
                subtitle: "\(store.favoriteChannelIDs.count) favorite channels",
                systemImage: "star.fill"
            )

            LibrarySearchField(text: $searchText, prompt: "Search saved channels")

            ChannelResultsList(
                channels: savedChannels,
                store: store,
                emptyTitle: "No Saved Channels",
                emptyMessage: "Tap the star on a channel to save it here."
            )
        }
        .overlay(alignment: .bottom) {
            LoadingToast(store: store)
        }
    }
}

#Preview {
    SavedChannelsView(store: PlaylistStore())
}
