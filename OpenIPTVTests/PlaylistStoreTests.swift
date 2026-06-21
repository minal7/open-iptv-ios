import XCTest
@testable import OpenIPTV

@MainActor
final class PlaylistStoreTests: XCTestCase {
    func testDetectsExistingPlaylistURL() {
        let defaultsName = "PlaylistStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: defaultsName)!
        defer {
            defaults.removePersistentDomain(forName: defaultsName)
        }

        let sourceURL = URL(string: "https://example.com/live/playlist.m3u")!
        let store = PlaylistStore(defaults: defaults)
        store.playlists = [
            Playlist(
                id: Playlist.id(for: sourceURL),
                name: "Example",
                sourceURL: sourceURL,
                channels: [],
                lastUpdated: nil
            )
        ]

        XCTAssertTrue(store.containsPlaylist(rawURL: "  https://example.com/live/playlist.m3u  "))
        XCTAssertFalse(store.containsPlaylist(rawURL: "https://example.com/live/other.m3u"))
    }
}
