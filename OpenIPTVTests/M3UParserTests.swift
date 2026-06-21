import XCTest
@testable import OpenIPTV

final class M3UParserTests: XCTestCase {
    func testParsesExtInfAttributesAndStreamURL() throws {
        let playlist = """
        #EXTM3U
        #EXTINF:-1 tvg-id="news.one" tvg-name="News One" tvg-logo="https://cdn.example.com/news.png" group-title="News",Fallback Name
        https://stream.example.com/news/index.m3u8
        """

        let channels = try M3UParser.parse(playlist, sourceURL: URL(string: "https://example.com/playlist.m3u")!)

        XCTAssertEqual(channels.count, 1)
        XCTAssertEqual(channels[0].name, "News One")
        XCTAssertEqual(channels[0].group, "News")
        XCTAssertEqual(channels[0].categories, ["News"])
        XCTAssertEqual(channels[0].tvgID, "news.one")
        XCTAssertEqual(channels[0].logoURL?.absoluteString, "https://cdn.example.com/news.png")
        XCTAssertEqual(channels[0].streamURL.absoluteString, "https://stream.example.com/news/index.m3u8")
    }

    func testResolvesRelativeStreamAndLogoURLs() throws {
        let playlist = """
        #EXTM3U
        #EXTINF:-1 tvg-logo="logos/movie.png" group-title="Movies",Cinema House
        live/cinema.m3u8
        """

        let channels = try M3UParser.parse(playlist, sourceURL: URL(string: "https://example.com/iptv/playlist.m3u")!)

        XCTAssertEqual(channels[0].name, "Cinema House")
        XCTAssertEqual(channels[0].streamURL.absoluteString, "https://example.com/iptv/live/cinema.m3u8")
        XCTAssertEqual(channels[0].logoURL?.absoluteString, "https://example.com/iptv/logos/movie.png")
    }

    func testBareURLBecomesPlayableChannel() throws {
        let playlist = """
        #EXTM3U
        https://example.com/live/city-sports.m3u8
        """

        let channels = try M3UParser.parse(playlist)

        XCTAssertEqual(channels.count, 1)
        XCTAssertEqual(channels[0].name, "City Sports")
        XCTAssertEqual(channels[0].group, Channel.uncategorizedGroup)
    }

    func testSplitsSemicolonSeparatedCategories() throws {
        let playlist = """
        #EXTM3U
        #EXTINF:-1 group-title="Animation;Comedy",Cartoons Live
        https://example.com/live/cartoons.m3u8
        """

        let channels = try M3UParser.parse(playlist)

        XCTAssertEqual(channels[0].categories, ["Animation", "Comedy"])
        XCTAssertEqual(channels[0].categorySummary, "Animation, Comedy")
    }

    func testUsesExtGrpForCategoryWhenPresent() throws {
        let playlist = """
        #EXTM3U
        #EXTINF:-1,World Feed
        #EXTGRP:News;International
        https://example.com/live/world.m3u8
        """

        let channels = try M3UParser.parse(playlist)

        XCTAssertEqual(channels[0].categories, ["News", "International"])
    }

    func testDecodingLegacyGroupSplitsCategories() throws {
        let json = """
        {
          "id": "legacy",
          "name": "Legacy Channel",
          "streamURL": "https://example.com/live.m3u8",
          "group": "Animation;Comedy",
          "sourceOrder": 0
        }
        """

        let channel = try JSONDecoder().decode(Channel.self, from: Data(json.utf8))

        XCTAssertEqual(channel.categories, ["Animation", "Comedy"])
    }

    func testThrowsWhenNoChannelsExist() {
        XCTAssertThrowsError(try M3UParser.parse("#EXTM3U\n# This is empty")) { error in
            XCTAssertEqual(error as? M3UParser.ParserError, .noPlayableChannels)
        }
    }
}
