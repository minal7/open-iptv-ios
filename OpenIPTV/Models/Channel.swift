import Foundation

struct Channel: Identifiable, Codable, Hashable, Sendable {
    static let uncategorizedGroup = "Ungrouped"

    var id: String
    var playlistID: String
    var playlistName: String
    var name: String
    var streamURL: URL
    var logoURL: URL?
    var categories: [String]
    var tvgID: String?
    var tvgName: String?
    var sourceOrder: Int

    var group: String {
        categories.first ?? Self.uncategorizedGroup
    }

    var categorySummary: String {
        categories.joined(separator: ", ")
    }

    var streamHost: String {
        streamURL.host ?? streamURL.absoluteString
    }

    init(
        id: String,
        playlistID: String = Playlist.defaultID,
        playlistName: String = Playlist.defaultName,
        name: String,
        streamURL: URL,
        logoURL: URL?,
        categories: [String],
        tvgID: String?,
        tvgName: String?,
        sourceOrder: Int
    ) {
        self.id = id
        self.playlistID = playlistID
        self.playlistName = playlistName
        self.name = name
        self.streamURL = streamURL
        self.logoURL = logoURL
        self.categories = Self.normalizedCategories(categories)
        self.tvgID = tvgID
        self.tvgName = tvgName
        self.sourceOrder = sourceOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        playlistID = try container.decodeIfPresent(String.self, forKey: .playlistID) ?? Playlist.defaultID
        playlistName = try container.decodeIfPresent(String.self, forKey: .playlistName) ?? Playlist.defaultName
        name = try container.decode(String.self, forKey: .name)
        streamURL = try container.decode(URL.self, forKey: .streamURL)
        logoURL = try container.decodeIfPresent(URL.self, forKey: .logoURL)

        if let decodedCategories = try container.decodeIfPresent([String].self, forKey: .categories) {
            categories = Self.normalizedCategories(decodedCategories)
        } else if let decodedGroup = try container.decodeIfPresent(String.self, forKey: .legacyGroup) {
            categories = Self.normalizedCategories([decodedGroup])
        } else {
            categories = [Self.uncategorizedGroup]
        }

        tvgID = try container.decodeIfPresent(String.self, forKey: .tvgID)
        tvgName = try container.decodeIfPresent(String.self, forKey: .tvgName)
        sourceOrder = try container.decode(Int.self, forKey: .sourceOrder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(playlistID, forKey: .playlistID)
        try container.encode(playlistName, forKey: .playlistName)
        try container.encode(name, forKey: .name)
        try container.encode(streamURL, forKey: .streamURL)
        try container.encodeIfPresent(logoURL, forKey: .logoURL)
        try container.encode(categories, forKey: .categories)
        try container.encodeIfPresent(tvgID, forKey: .tvgID)
        try container.encodeIfPresent(tvgName, forKey: .tvgName)
        try container.encode(sourceOrder, forKey: .sourceOrder)
    }

    func tagged(playlistID: String, playlistName: String) -> Channel {
        Channel(
            id: id.hasPrefix("\(playlistID)|") ? id : "\(playlistID)|\(id)",
            playlistID: playlistID,
            playlistName: playlistName,
            name: name,
            streamURL: streamURL,
            logoURL: logoURL,
            categories: categories,
            tvgID: tvgID,
            tvgName: tvgName,
            sourceOrder: sourceOrder
        )
    }

    private static func normalizedCategories(_ categories: [String]) -> [String] {
        var seen = Set<String>()
        let normalized = categories
            .flatMap { category in
                category
                    .components(separatedBy: CharacterSet(charactersIn: ";|"))
                    .flatMap { $0.components(separatedBy: " / ") }
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { category in
                let key = category.lowercased()
                if seen.contains(key) {
                    return false
                }
                seen.insert(key)
                return true
            }

        return normalized.isEmpty ? [Self.uncategorizedGroup] : normalized
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case playlistID
        case playlistName
        case name
        case streamURL
        case logoURL
        case categories
        case legacyGroup = "group"
        case tvgID
        case tvgName
        case sourceOrder
    }
}

extension Channel {
    static let preview = Channel(
        id: "preview-news",
        playlistID: "preview",
        playlistName: "Preview",
        name: "Northline News",
        streamURL: URL(string: "https://example.com/live/news.m3u8")!,
        logoURL: nil,
        categories: ["News"],
        tvgID: "northline.news",
        tvgName: "Northline News",
        sourceOrder: 0
    )

    static let previews: [Channel] = [
        .preview,
        Channel(
            id: "preview-sports",
            playlistID: "preview",
            playlistName: "Preview",
            name: "City Sports",
            streamURL: URL(string: "https://example.com/live/sports.m3u8")!,
            logoURL: nil,
            categories: ["Sports"],
            tvgID: "city.sports",
            tvgName: "City Sports",
            sourceOrder: 1
        ),
        Channel(
            id: "preview-cinema",
            playlistID: "preview",
            playlistName: "Preview",
            name: "Cinema House",
            streamURL: URL(string: "https://example.com/live/cinema.m3u8")!,
            logoURL: nil,
            categories: ["Movies"],
            tvgID: "cinema.house",
            tvgName: "Cinema House",
            sourceOrder: 2
        )
    ]
}
