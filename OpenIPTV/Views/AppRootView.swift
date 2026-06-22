import SwiftUI

struct AppRootView: View {
    @State private var store = PlaylistStore()
    @State private var navigationPath: [LibraryRoute] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                if !store.hasLibrary {
                    OnboardingView(store: store)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    LibraryTabView(store: store)
                        .transition(.opacity.combined(with: .scale(scale: 1.01)))
                }
            }
            .navigationDestination(for: LibraryRoute.self) { route in
                switch route {
                case .category(let category):
                    CategoryChannelsView(store: store, category: category)
                case .channel(let channel):
                    ChannelPlayerView(channel: channel, store: store)
                }
            }
        }
        .tint(.teal)
        .animation(.smooth(duration: 0.45), value: store.hasLibrary)
    }
}

enum LibraryRoute: Hashable {
    case category(String)
    case channel(Channel)
}

private struct LibraryTabView: View {
    @Bindable var store: PlaylistStore
    @State private var selectedTab: LibraryTab = .channels

    var body: some View {
        tabView
            .nativeTabBarBehavior()
            .toolbar(.hidden, for: .navigationBar)
            .animation(.smooth(duration: 0.32), value: selectedTab)
    }

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            ChannelLibraryView(store: store)
                .tabItem {
                    Label(LibraryTab.channels.title, systemImage: LibraryTab.channels.systemImage)
                }
                .tag(LibraryTab.channels)

            SearchView(store: store)
                .tabItem {
                    Label(LibraryTab.search.title, systemImage: LibraryTab.search.systemImage)
                }
                .tag(LibraryTab.search)

            CategoriesView(store: store)
                .tabItem {
                    Label(LibraryTab.categories.title, systemImage: LibraryTab.categories.systemImage)
                }
                .tag(LibraryTab.categories)

            SavedChannelsView(store: store)
                .tabItem {
                    Label(LibraryTab.saved.title, systemImage: LibraryTab.saved.systemImage)
                }
                .tag(LibraryTab.saved)

            PlaylistsView(store: store)
                .tabItem {
                    Label(LibraryTab.playlists.title, systemImage: LibraryTab.playlists.systemImage)
                }
                .tag(LibraryTab.playlists)
        }
    }
}

private enum LibraryTab: String, CaseIterable, Identifiable {
    case channels
    case search
    case categories
    case saved
    case playlists

    var id: String { rawValue }

    var title: String {
        switch self {
        case .channels:
            "Channels"
        case .search:
            "Search"
        case .categories:
            "Categories"
        case .saved:
            "Saved"
        case .playlists:
            "Playlists"
        }
    }

    var systemImage: String {
        switch self {
        case .channels:
            "play.tv"
        case .search:
            "magnifyingglass"
        case .categories:
            "square.grid.2x2"
        case .saved:
            "star.fill"
        case .playlists:
            "list.bullet.rectangle"
        }
    }
}

private extension View {
    @ViewBuilder
    func nativeTabBarBehavior() -> some View {
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}

#Preview {
    AppRootView()
}
