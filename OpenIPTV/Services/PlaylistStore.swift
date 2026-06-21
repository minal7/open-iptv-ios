import Foundation
import Observation

@MainActor
@Observable
final class PlaylistStore {
    enum LoadPhase: Equatable {
        case idle
        case loading(String)
        case loaded
        case failed(String)
    }

    var playlistURLText: String
    var playlists: [Playlist]
    var selectedPlaylistID: Playlist.ID?
    var favoriteChannelIDs: Set<String>
    var phase: LoadPhase

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let service: PlaylistService

    private enum DefaultsKey {
        static let library = "playlist.library.v2"
        static let favoriteIDs = "playlist.favorite-channel-ids"
        static let selectedPlaylistID = "playlist.selected-playlist-id"

        static let legacyPlaylistURL = "playlist.url"
        static let legacyChannelCache = "playlist.channel-cache"
    }

    private struct LibraryCache: Codable {
        var playlists: [Playlist]
    }

    private struct LegacyChannelCache: Codable {
        var channels: [Channel]
        var lastUpdated: Date?
    }

    init(
        defaults: UserDefaults = .standard,
        service: PlaylistService = PlaylistService()
    ) {
        self.defaults = defaults
        self.service = service
        self.playlistURLText = defaults.string(forKey: DefaultsKey.legacyPlaylistURL) ?? ""
        self.favoriteChannelIDs = Set(defaults.stringArray(forKey: DefaultsKey.favoriteIDs) ?? [])
        self.selectedPlaylistID = defaults.string(forKey: DefaultsKey.selectedPlaylistID)

        let loadedPlaylists: [Playlist]
        if let data = defaults.data(forKey: DefaultsKey.library),
           let cache = try? JSONDecoder().decode(LibraryCache.self, from: data) {
            loadedPlaylists = cache.playlists
        } else if let migratedPlaylist = Self.migrateLegacyPlaylist(defaults: defaults) {
            loadedPlaylists = [migratedPlaylist]
            self.selectedPlaylistID = nil
        } else {
            loadedPlaylists = []
        }

        self.playlists = loadedPlaylists
        self.phase = loadedPlaylists.isEmpty ? .idle : .loaded
    }

    var isLoading: Bool {
        if case .loading = phase {
            return true
        }

        return false
    }

    var errorMessage: String? {
        if case .failed(let message) = phase {
            return message
        }

        return nil
    }

    var loadingMessage: String {
        if case .loading(let message) = phase {
            return message
        }

        return "Loading"
    }

    var hasLibrary: Bool {
        !playlists.isEmpty
    }

    var canLoadPlaylist: Bool {
        !playlistURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    var activePlaylists: [Playlist] {
        if let selectedPlaylistID,
           let playlist = playlists.first(where: { $0.id == selectedPlaylistID }) {
            return [playlist]
        }

        return playlists
    }

    var channels: [Channel] {
        activePlaylists
            .flatMap(\.channels)
            .sorted { lhs, rhs in
                if lhs.playlistName == rhs.playlistName {
                    return lhs.sourceOrder < rhs.sourceOrder
                }

                return lhs.playlistName.localizedStandardCompare(rhs.playlistName) == .orderedAscending
            }
    }

    var allChannels: [Channel] {
        playlists.flatMap(\.channels)
    }

    var favoriteChannels: [Channel] {
        allChannels.filter { favoriteChannelIDs.contains($0.id) }
    }

    var categories: [String] {
        categorySummaries.map(\.name)
    }

    var categorySummaries: [CategorySummary] {
        var counts: [String: Int] = [:]
        for channel in channels {
            for category in channel.categories where !category.isEmpty {
                counts[category, default: 0] += 1
            }
        }

        return counts
            .map { CategorySummary(name: $0.key, channelCount: $0.value) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var lastUpdated: Date? {
        activePlaylists
            .compactMap(\.lastUpdated)
            .max()
    }

    var selectedPlaylistName: String {
        if let selectedPlaylistID,
           let playlist = playlists.first(where: { $0.id == selectedPlaylistID }) {
            return playlist.name
        }

        return "All Playlists"
    }

    func loadPlaylist() async {
        await addOrUpdatePlaylist(from: playlistURLText)
    }

    func addOrUpdatePlaylist(from rawURL: String) async {
        let trimmedURL = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedURL),
              ["http", "https"].contains(url.scheme?.lowercased()) else {
            phase = .failed(PlaylistService.PlaylistError.invalidURL.localizedDescription)
            return
        }

        await loadPlaylist(url: url)
    }

    func containsPlaylist(rawURL: String) -> Bool {
        let trimmedURL = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedURL) else {
            return false
        }

        return playlists.contains { $0.id == Playlist.id(for: url) }
    }

    func reload() async {
        if let selectedPlaylistID,
           let playlist = playlists.first(where: { $0.id == selectedPlaylistID }) {
            await loadPlaylist(url: playlist.sourceURL)
        } else {
            await reloadAll()
        }
    }

    func reloadAll() async {
        guard !playlists.isEmpty else { return }

        let sourceURLs = playlists.map(\.sourceURL)
        for sourceURL in sourceURLs {
            await loadPlaylist(url: sourceURL, preserveSelection: true)
        }
    }

    func removePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        favoriteChannelIDs = favoriteChannelIDs.filter { favoriteID in
            allChannels.contains { $0.id == favoriteID }
        }

        if selectedPlaylistID == playlist.id {
            selectedPlaylistID = nil
        }

        playlistURLText = playlists.first?.sourceURL.absoluteString ?? ""
        phase = playlists.isEmpty ? .idle : .loaded
        persistLibrary()
    }

    func selectPlaylist(_ playlistID: Playlist.ID?) {
        selectedPlaylistID = playlistID
        if let playlistID {
            defaults.set(playlistID, forKey: DefaultsKey.selectedPlaylistID)
        } else {
            defaults.removeObject(forKey: DefaultsKey.selectedPlaylistID)
        }
    }

    func clearLibrary() {
        playlistURLText = ""
        playlists = []
        selectedPlaylistID = nil
        favoriteChannelIDs = []
        phase = .idle
        defaults.removeObject(forKey: DefaultsKey.library)
        defaults.removeObject(forKey: DefaultsKey.favoriteIDs)
        defaults.removeObject(forKey: DefaultsKey.selectedPlaylistID)
        defaults.removeObject(forKey: DefaultsKey.legacyPlaylistURL)
        defaults.removeObject(forKey: DefaultsKey.legacyChannelCache)
    }

    func isFavorite(_ channel: Channel) -> Bool {
        favoriteChannelIDs.contains(channel.id)
    }

    func toggleFavorite(_ channel: Channel) {
        if favoriteChannelIDs.contains(channel.id) {
            favoriteChannelIDs.remove(channel.id)
        } else {
            favoriteChannelIDs.insert(channel.id)
        }

        persistFavorites()
    }

    func channels(
        searchText: String,
        category: String? = nil,
        favoritesOnly: Bool = false
    ) -> [Channel] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let sourceChannels = favoritesOnly ? favoriteChannels : channels

        return sourceChannels.filter { channel in
            if let category, !channel.categories.contains(category) {
                return false
            }

            guard !query.isEmpty else {
                return true
            }

            return channel.name.lowercased().contains(query)
                || channel.categorySummary.lowercased().contains(query)
                || channel.playlistName.lowercased().contains(query)
                || channel.streamHost.lowercased().contains(query)
                || (channel.tvgID?.lowercased().contains(query) ?? false)
        }
    }

    private func loadPlaylist(url: URL, preserveSelection: Bool = false) async {
        let playlistID = Playlist.id(for: url)
        let existingName = playlists.first(where: { $0.id == playlistID })?.name
        let playlistName = existingName ?? Playlist.displayName(for: url)

        phase = .loading("Loading \(playlistName)")

        do {
            let playlistText = try await service.fetchPlaylist(from: url)
            let parsedChannels = try await Task.detached(priority: .userInitiated) {
                try M3UParser.parse(playlistText, sourceURL: url)
                    .map { $0.tagged(playlistID: playlistID, playlistName: playlistName) }
            }.value

            let playlist = Playlist(
                id: playlistID,
                name: playlistName,
                sourceURL: url,
                channels: parsedChannels,
                lastUpdated: Date()
            )

            if let existingIndex = playlists.firstIndex(where: { $0.id == playlistID }) {
                playlists[existingIndex] = playlist
            } else {
                playlists.append(playlist)
            }

            playlistURLText = url.absoluteString
            if !preserveSelection {
                selectedPlaylistID = nil
            }
            phase = .loaded
            persistLibrary()
        } catch is CancellationError {
            phase = playlists.isEmpty ? .idle : .loaded
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func persistLibrary() {
        let cache = LibraryCache(playlists: playlists)
        if let data = try? JSONEncoder().encode(cache) {
            defaults.set(data, forKey: DefaultsKey.library)
        }

        defaults.set(playlistURLText, forKey: DefaultsKey.legacyPlaylistURL)
        if let selectedPlaylistID {
            defaults.set(selectedPlaylistID, forKey: DefaultsKey.selectedPlaylistID)
        } else {
            defaults.removeObject(forKey: DefaultsKey.selectedPlaylistID)
        }
        persistFavorites()
    }

    private func persistFavorites() {
        defaults.set(Array(favoriteChannelIDs), forKey: DefaultsKey.favoriteIDs)
    }

    private static func migrateLegacyPlaylist(defaults: UserDefaults) -> Playlist? {
        guard let data = defaults.data(forKey: DefaultsKey.legacyChannelCache),
              let cache = try? JSONDecoder().decode(LegacyChannelCache.self, from: data),
              !cache.channels.isEmpty
        else {
            return nil
        }

        let rawURL = defaults.string(forKey: DefaultsKey.legacyPlaylistURL) ?? "https://local.playlist"
        let sourceURL = URL(string: rawURL) ?? URL(string: "https://local.playlist")!
        let playlistID = Playlist.id(for: sourceURL)
        let playlistName = Playlist.displayName(for: sourceURL)

        return Playlist(
            id: playlistID,
            name: playlistName,
            sourceURL: sourceURL,
            channels: cache.channels.map { $0.tagged(playlistID: playlistID, playlistName: playlistName) },
            lastUpdated: cache.lastUpdated
        )
    }
}
