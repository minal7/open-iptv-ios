import AVFoundation
import SwiftUI

@main
struct OpenIPTVApp: App {
    init() {
        MediaPlaybackSession.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

enum MediaPlaybackSession {
    static func configure() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(
                .playback,
                mode: .moviePlayback,
                policy: .longFormVideo,
                options: []
            )
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("Unable to configure media playback audio session: \(error)")
            #endif
        }
    }
}
