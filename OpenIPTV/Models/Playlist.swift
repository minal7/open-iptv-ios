import Foundation

struct Playlist: Identifiable, Codable, Hashable, Sendable {
    static let defaultID = "default-playlist"
    static let defaultName = "Playlist"

    var id: String
    var name: String
    var sourceURL: URL
    var channels: [Channel]
    var lastUpdated: Date?

    var channelCount: Int {
        channels.count
    }

    var host: String {
        sourceURL.host ?? sourceURL.absoluteString
    }

    static func id(for url: URL) -> String {
        url.absoluteString
    }

    static func displayName(for url: URL) -> String {
        if let host = url.host, !host.isEmpty {
            return host.replacingOccurrences(of: "www.", with: "")
        }

        let lastPathComponent = url.deletingPathExtension().lastPathComponent
        return lastPathComponent.isEmpty ? defaultName : lastPathComponent
    }
}

struct CategorySummary: Identifiable, Hashable {
    var name: String
    var channelCount: Int

    var id: String { name }
}
