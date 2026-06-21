import SwiftUI

struct CategoriesView: View {
    @Bindable var store: PlaylistStore
    var onScrollCollapseChange: (Bool) -> Void = { _ in }

    var body: some View {
        let summaries = store.categorySummaries

        ZStack {
            AppBackground()

            List {
                ScrollOffsetProbe(coordinateSpaceName: "categories-scroll")

                Section {
                    ForEach(summaries) { category in
                        NavigationLink {
                            CategoryChannelsView(store: store, category: category.name)
                        } label: {
                            CategoryRow(category: category)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Categories")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("\(compactCount(summaries.count)) categories from \(store.selectedPlaylistName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                            .lineLimit(1)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .coordinateSpace(name: "categories-scroll")
            .onVerticalScrollDirectionChange(onScrollCollapseChange)
        }
        .toolbar(.hidden, for: .navigationBar)
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

private struct CategoryChannelsView: View {
    var store: PlaylistStore
    var category: String

    private var channels: [Channel] {
        store.channels(searchText: "", category: category)
    }

    var body: some View {
        ZStack {
            AppBackground()

            ChannelResultsList(
                channels: channels,
                store: store,
                emptyTitle: "No Channels",
                emptyMessage: "This category has no channels in the selected playlist.",
                refreshAction: {
                    await store.reload()
                }
            )
            .padding(.top, 6)
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
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
