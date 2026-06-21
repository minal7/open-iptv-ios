import Foundation

enum M3UParser {
    enum ParserError: LocalizedError, Equatable {
        case noPlayableChannels

        var errorDescription: String? {
            switch self {
            case .noPlayableChannels:
                "No playable channel URLs were found in this playlist."
            }
        }
    }

    private struct PendingInfo {
        var name: String?
        var categories: [String]
        var logoURL: URL?
        var tvgID: String?
        var tvgName: String?
    }

    static func parse(_ text: String, sourceURL: URL? = nil) throws -> [Channel] {
        var channels: [Channel] = []
        var pendingInfo: PendingInfo?
        var seenIDs = Set<String>()

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if line.range(of: "#EXTINF", options: [.anchored, .caseInsensitive]) != nil {
                pendingInfo = parseExtInf(line, sourceURL: sourceURL)
                continue
            }

            if line.range(of: "#EXTGRP:", options: [.anchored, .caseInsensitive]) != nil {
                let rawGroup = String(line.dropFirst("#EXTGRP:".count))
                if var info = pendingInfo {
                    info.categories = parseCategories(rawGroup)
                    pendingInfo = info
                } else {
                    pendingInfo = PendingInfo(
                        name: nil,
                        categories: parseCategories(rawGroup),
                        logoURL: nil,
                        tvgID: nil,
                        tvgName: nil
                    )
                }
                continue
            }

            if line.hasPrefix("#") {
                continue
            }

            guard let streamURL = makeURL(from: line, relativeTo: sourceURL) else {
                pendingInfo = nil
                continue
            }

            let info = pendingInfo
            let displayName = firstNonEmpty(info?.name, derivedName(from: streamURL)) ?? "Untitled Channel"
            let categories = normalizedCategories(info?.categories ?? [])
            let baseID = [
                info?.tvgID ?? "",
                displayName,
                streamURL.absoluteString
            ].joined(separator: "|")

            var channelID = baseID
            var duplicateIndex = 2
            while seenIDs.contains(channelID) {
                channelID = "\(baseID)#\(duplicateIndex)"
                duplicateIndex += 1
            }
            seenIDs.insert(channelID)

            channels.append(Channel(
                id: channelID,
                name: displayName,
                streamURL: streamURL,
                logoURL: info?.logoURL,
                categories: categories,
                tvgID: info?.tvgID,
                tvgName: info?.tvgName,
                sourceOrder: channels.count
            ))
            pendingInfo = nil
        }

        guard !channels.isEmpty else {
            throw ParserError.noPlayableChannels
        }

        return channels
    }

    private static func parseExtInf(_ line: String, sourceURL: URL?) -> PendingInfo {
        let split = splitMetadataAndName(line)
        let attributes = parseAttributes(from: split.metadata)
        let tvgName = firstNonEmpty(attributes["tvg-name"], attributes["tvg_name"])
        let name = firstNonEmpty(tvgName, split.name)
        let categories = parseCategories(firstNonEmpty(attributes["group-title"], attributes["group_title"]))
        let logoURL = attributes["tvg-logo"].flatMap { makeURL(from: $0, relativeTo: sourceURL) }

        return PendingInfo(
            name: name,
            categories: categories,
            logoURL: logoURL,
            tvgID: attributes["tvg-id"],
            tvgName: tvgName
        )
    }

    private static func splitMetadataAndName(_ line: String) -> (metadata: String, name: String?) {
        var activeQuote: Character?

        for index in line.indices {
            let character = line[index]
            if character == "\"" || character == "'" {
                if activeQuote == character {
                    activeQuote = nil
                } else if activeQuote == nil {
                    activeQuote = character
                }
            } else if character == "," && activeQuote == nil {
                let metadata = String(line[..<index])
                let name = String(line[line.index(after: index)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return (metadata, name.isEmpty ? nil : name)
            }
        }

        return (line, nil)
    }

    private static func parseAttributes(from metadata: String) -> [String: String] {
        let pattern = #"([A-Za-z0-9_-]+)=("[^"]*"|'[^']*'|[^,\s]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [:]
        }

        let range = NSRange(metadata.startIndex..<metadata.endIndex, in: metadata)
        var attributes: [String: String] = [:]

        regex.enumerateMatches(in: metadata, range: range) { match, _, _ in
            guard
                let match,
                let keyRange = Range(match.range(at: 1), in: metadata),
                let valueRange = Range(match.range(at: 2), in: metadata)
            else {
                return
            }

            let key = metadata[keyRange].lowercased()
            let rawValue = String(metadata[valueRange])
            let value = rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !value.isEmpty {
                attributes[key] = value
            }
        }

        return attributes
    }

    private static func makeURL(from rawValue: String, relativeTo sourceURL: URL?) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }

        if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let url = URL(string: encoded),
           url.scheme != nil {
            return url
        }

        guard let sourceURL else {
            return nil
        }

        if let relativeURL = URL(string: trimmed, relativeTo: sourceURL)?.absoluteURL {
            return relativeURL
        }

        if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            return URL(string: encoded, relativeTo: sourceURL)?.absoluteURL
        }

        return nil
    }

    private static func derivedName(from url: URL) -> String {
        let lastPathComponent = url.deletingPathExtension().lastPathComponent
        if !lastPathComponent.isEmpty {
            return lastPathComponent
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }

        return url.host ?? "Untitled Channel"
    }

    private static func parseCategories(_ rawValue: String?) -> [String] {
        guard let rawValue else {
            return [Channel.uncategorizedGroup]
        }

        let separators = CharacterSet(charactersIn: ";|")
        let categories = rawValue
            .components(separatedBy: separators)
            .flatMap { value in
                value.components(separatedBy: " / ")
            }

        return normalizedCategories(categories)
    }

    private static func normalizedCategories(_ categories: [String]) -> [String] {
        var seen = Set<String>()
        let normalized = categories
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

        return normalized.isEmpty ? [Channel.uncategorizedGroup] : normalized
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        for value in values {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let trimmed, !trimmed.isEmpty {
                return trimmed
            }
        }

        return nil
    }
}
