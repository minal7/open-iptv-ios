import SwiftUI

struct CategoriesView: View {
    @Bindable var store: PlaylistStore
    var onScrollCollapseChange: (Bool) -> Void = { _ in }

    var body: some View {
        let summaries = store.categorySummaries

        LibraryScreenContainer {
            PageTitleHeader(
                title: "Categories",
                subtitle: "\(compactCount(summaries.count)) categories from \(store.selectedPlaylistName)",
                systemImage: "square.grid.2x2.fill"
            )

            List {
                ScrollOffsetProbe(coordinateSpaceName: "categories-scroll")

                if summaries.isEmpty {
                    ContentUnavailableView(
                        "No Categories",
                        systemImage: "square.grid.2x2",
                        description: Text("Add a playlist with grouped channels to browse categories.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(summaries) { category in
                        NavigationLink(value: LibraryRoute.category(category.name)) {
                            CategoryRow(category: category)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .coordinateSpace(name: "categories-scroll")
            .onVerticalScrollDirectionChange(onScrollCollapseChange)
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottom) {
            LoadingToast(store: store)
        }
    }
}

private struct CategoryRow: View {
    var category: CategorySummary

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.headline)
                .foregroundStyle(.teal)
                .frame(width: 42, height: 42)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(compactCount(category.channelCount)) channels")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct CategoryChannelsView: View {
    var store: PlaylistStore
    var category: String

    private var channels: [Channel] {
        store.channels(searchText: "", category: category)
    }

    var body: some View {
        LibraryScreenContainer {
            PageTitleHeader(
                title: category,
                subtitle: "\(compactCount(channels.count)) channels in \(store.selectedPlaylistName)",
                systemImage: "square.grid.2x2.fill"
            )

            ChannelResultsList(
                channels: channels,
                store: store,
                emptyTitle: "No Channels",
                emptyMessage: "This category has no channels in the selected playlist.",
                topAnchorID: "category-\(category)-top",
                refreshAction: {
                    await store.reload()
                }
            )
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            LoadingToast(store: store)
        }
    }
}

struct PageTitleHeader: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(isCompact ? .title2 : .largeTitle, design: .rounded, weight: .bold))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 8)

            Image(systemName: systemImage)
                .font((isCompact ? Font.headline : Font.title2).weight(.bold))
                .foregroundStyle(.teal)
                .frame(width: isCompact ? 38 : 46, height: isCompact ? 38 : 46)
                .background(.thinMaterial, in: Circle())
        }
        .padding(isCompact ? 12 : 18)
        .panelBackground(cornerRadius: isCompact ? 20 : 26)
    }

    private var isCompact: Bool {
        verticalSizeClass == .compact
    }
}

#Preview {
    CategoriesView(store: PlaylistStore())
}
