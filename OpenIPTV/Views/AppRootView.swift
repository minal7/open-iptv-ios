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
    @State private var isTabBarCollapsed = false
    @State private var allowsScrollCollapse = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            currentTabView
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 92)
                }

            FloatingTabBar(
                selectedTab: $selectedTab,
                isCollapsed: $isTabBarCollapsed
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.smooth(duration: 0.32), value: selectedTab)
        .animation(.spring(response: 0.42, dampingFraction: 0.84), value: isTabBarCollapsed)
        .task(id: selectedTab) {
            allowsScrollCollapse = false
            isTabBarCollapsed = false
            try? await Task.sleep(for: .milliseconds(450))
            allowsScrollCollapse = true
        }
    }

    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case .channels:
            ChannelLibraryView(store: store) { shouldCollapse in
                updateTabBarCollapse(shouldCollapse)
            }
        case .search:
            SearchView(store: store) { shouldCollapse in
                updateTabBarCollapse(shouldCollapse)
            }
                .onAppear { isTabBarCollapsed = false }
        case .categories:
            CategoriesView(store: store) { shouldCollapse in
                updateTabBarCollapse(shouldCollapse)
            }
                .onAppear { isTabBarCollapsed = false }
        case .saved:
            SavedChannelsView(store: store) { shouldCollapse in
                updateTabBarCollapse(shouldCollapse)
            }
                .onAppear { isTabBarCollapsed = false }
        case .playlists:
            PlaylistsView(store: store) { shouldCollapse in
                updateTabBarCollapse(shouldCollapse)
            }
                .onAppear { isTabBarCollapsed = false }
        }
    }

    private func updateTabBarCollapse(_ shouldCollapse: Bool) {
        guard allowsScrollCollapse else { return }
        isTabBarCollapsed = shouldCollapse
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

private struct FloatingTabBar: View {
    @Binding var selectedTab: LibraryTab
    @Binding var isCollapsed: Bool
    @Namespace private var selectionNamespace
    private let expandedTabWidth: CGFloat = 58
    private let compactTabWidth: CGFloat = 38

    var body: some View {
        HStack(spacing: isCollapsed ? 6 : 4) {
            ForEach(LibraryTab.allCases) { tab in
                if isCollapsed {
                    compactButton(for: tab)
                } else {
                    expandedButton(for: tab)
                }
            }
        }
        .padding(.horizontal, isCollapsed ? 10 : 12)
        .padding(.vertical, isCollapsed ? 10 : 8)
        .background(.regularMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.32), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 20, y: 10)
        .accessibilityElement(children: .contain)
    }

    private func compactButton(for tab: LibraryTab) -> some View {
        Button {
            selectedTab = tab
            isCollapsed = false
        } label: {
            Image(systemName: tab.systemImage)
                .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                .foregroundStyle(selectedTab == tab ? .teal : .primary)
                .frame(width: compactTabWidth, height: compactTabWidth)
                .background {
                    if selectedTab == tab {
                        Circle()
                            .fill(Color.teal.opacity(0.14))
                            .matchedGeometryEffect(id: "selected-tab", in: selectionNamespace)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }

    private func expandedButton(for tab: LibraryTab) -> some View {
        Button {
            selectedTab = tab
            isCollapsed = false
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 21, weight: selectedTab == tab ? .semibold : .regular))

                Text(tab.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(selectedTab == tab ? .teal : .primary)
            .frame(width: expandedTabWidth, height: 52)
            .background {
                if selectedTab == tab {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.teal.opacity(0.12))
                        .matchedGeometryEffect(id: "selected-tab", in: selectionNamespace)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }
}

#Preview {
    AppRootView()
}
