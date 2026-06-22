import SwiftUI

struct ChannelLibraryView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Bindable var store: PlaylistStore

    var body: some View {
        let channels = store.channels
        let categoryCount = store.categorySummaries.count
        let isLandscape = verticalSizeClass == .compact

        ZStack {
            AppBackground()

            List {
                LibraryHeader(
                    title: "Channels",
                    subtitle: store.selectedPlaylistName,
                    channelCount: channels.count,
                    categoryCount: categoryCount,
                    favoriteCount: store.favoriteChannelIDs.count,
                    playlistCount: store.playlists.count,
                    lastUpdated: store.lastUpdated,
                    isCompact: isLandscape,
                    refreshAction: {
                        Task { await store.reload() }
                    }
                )
                .padding(.top, 10)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .libraryClearListRow()

                CompactLibraryHeader(
                    title: store.selectedPlaylistName,
                    channelCount: channels.count,
                    categoryCount: categoryCount,
                    refreshAction: {
                        Task { await store.reload() }
                    }
                )
                .padding(.top, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 10, trailing: 16))
                .libraryClearListRow()

                if let errorMessage = store.errorMessage {
                    ErrorBanner(message: errorMessage)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                        .libraryClearListRow()
                }

                if channels.isEmpty {
                    ContentUnavailableView(
                        "No Channels",
                        systemImage: "play.tv",
                        description: Text("Add or select a playlist from the Playlists tab.")
                    )
                    .padding(.top, 40)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .libraryClearListRow()
                } else {
                    ForEach(channels) { channel in
                        NavigationLink(value: LibraryRoute.channel(channel)) {
                            ChannelRow(channel: channel, isFavorite: store.isFavorite(channel))
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 26, bottom: 0, trailing: 26))
                        .libraryClearListRow()
                    }
                }
            }
            .libraryPlainListLayout()
            .contentMargins(.bottom, 12, for: .scrollContent)
            .refreshable {
                await store.reload()
            }

            if !isLandscape {
                TopSafeAreaScrim()
            }
        }
        .overlay(alignment: .bottom) {
            LoadingToast(store: store)
        }
    }
}

private struct TopSafeAreaScrim: View {
    var body: some View {
        VStack {
            LinearGradient(
                colors: [
                    Color(uiColor: .systemGroupedBackground).opacity(0.98),
                    Color(uiColor: .systemGroupedBackground).opacity(0.88),
                    Color(uiColor: .systemGroupedBackground).opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 62)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            Spacer()
        }
    }
}

struct LibraryScreenContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 12) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }
}

struct LibraryHeader: View {
    var title: String
    var subtitle: String
    var channelCount: Int
    var categoryCount: Int
    var favoriteCount: Int
    var playlistCount: Int
    var lastUpdated: Date?
    var isCompact: Bool
    var refreshAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 10 : 14) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(isCompact ? .title2 : .largeTitle, design: .rounded, weight: .bold))
                        .lineLimit(1)

                    Text(subtitleText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 8)

                Button(action: refreshAction) {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Refresh")
            }

            if !isCompact {
                HStack(spacing: 8) {
                    StatPill(value: channelCount, label: "Channels", icon: "rectangle.stack.fill")
                    StatPill(value: categoryCount, label: "Categories", icon: "square.grid.2x2.fill")
                    StatPill(value: favoriteCount, label: "Saved", icon: "star.fill")
                    StatPill(value: playlistCount, label: "Lists", icon: "link")
                }
            }
        }
        .padding(isCompact ? 14 : 16)
        .panelBackground(cornerRadius: isCompact ? 22 : 26)
    }

    private var subtitleText: String {
        guard let lastUpdated else {
            return subtitle
        }

        return "\(subtitle) - \(lastUpdated.formatted(date: .abbreviated, time: .shortened))"
    }
}

private struct CompactLibraryHeader: View {
    var title: String
    var channelCount: Int
    var categoryCount: Int
    var refreshAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("\(compactCount(channelCount)) channels - \(compactCount(categoryCount)) categories")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: refreshAction) {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(.teal)
            .accessibilityLabel("Refresh")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .panelBackground(cornerRadius: 20)
    }
}

struct LibrarySearchField: View {
    @Binding var text: String
    var prompt: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct ChannelResultsList: View {
    var channels: [Channel]
    var store: PlaylistStore
    var emptyTitle: String
    var emptyMessage: String
    var topAnchorID = "channel-results-top"

    var body: some View {
        List {
            ListTopAnchor(anchorID: topAnchorID)

            if channels.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "magnifyingglass",
                    description: Text(emptyMessage)
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(channels) { channel in
                    NavigationLink(value: LibraryRoute.channel(channel)) {
                        ChannelRow(channel: channel, isFavorite: store.isFavorite(channel))
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .libraryPlainListLayout()
    }
}

extension View {
    func libraryPlainListLayout() -> some View {
        listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 0, for: .scrollContent)
            .environment(\.defaultMinListRowHeight, 1)
    }

    func libraryClearListRow() -> some View {
        listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

private struct ListTopAnchor: View {
    var anchorID: String

    var body: some View {
        Color.clear
            .frame(height: 0)
            .id(anchorID)
            .accessibilityHidden(true)
            .listRowInsets(EdgeInsets())
            .libraryClearListRow()
    }
}

struct StatPill: View {
    var value: Int
    var label: String
    var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.teal)

            Text(compactCount(value))
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .contentTransition(.numericText())

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ErrorBanner: View {
    var message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.red)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct LoadingToast: View {
    var store: PlaylistStore

    var body: some View {
        if store.isLoading {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(.teal)
                Text(store.loadingMessage)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .panelBackground(cornerRadius: 18)
            .padding(.bottom, 18)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

func compactCount(_ value: Int) -> String {
    if value >= 1_000_000 {
        return String(format: "%.1fM", Double(value) / 1_000_000)
    }

    if value >= 10_000 {
        return "\(value / 1_000)K"
    }

    if value >= 1_000 {
        return String(format: "%.1fK", Double(value) / 1_000)
    }

    return "\(value)"
}

#Preview {
    ChannelLibraryView(store: PlaylistStore())
}
