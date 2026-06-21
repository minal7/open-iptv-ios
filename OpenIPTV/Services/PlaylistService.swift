import Foundation

struct PlaylistService {
    enum PlaylistError: LocalizedError, Equatable {
        case invalidURL
        case emptyResponse
        case requestFailed(Int)
        case unsupportedTextEncoding

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                "Enter a valid HTTP or HTTPS playlist URL."
            case .emptyResponse:
                "The playlist was empty."
            case .requestFailed(let statusCode):
                "The playlist server returned HTTP \(statusCode)."
            case .unsupportedTextEncoding:
                "The playlist text could not be read."
            }
        }
    }

    func fetchPlaylist(from url: URL) async throws -> String {
        guard ["http", "https"].contains(url.scheme?.lowercased()) else {
            throw PlaylistError.invalidURL
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.setValue("OpenIPTV/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-mpegURL, audio/x-mpegurl, text/plain, */*", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw PlaylistError.requestFailed(httpResponse.statusCode)
        }

        guard !data.isEmpty else {
            throw PlaylistError.emptyResponse
        }

        if let text = String(data: data, encoding: .utf8) {
            return text
        }

        if let text = String(data: data, encoding: .isoLatin1) {
            return text
        }

        throw PlaylistError.unsupportedTextEncoding
    }
}
