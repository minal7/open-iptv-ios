# Open IPTV

Open IPTV is a native SwiftUI IPTV player for iPhone and iPad. It has no server dependency: users paste their own M3U playlist URL, the app parses channels locally, and streams media directly from the playlist sources with Apple's built-in playback stack.

## Features

- Paste any M3U/M3U8 playlist URL and browse available channels.
- Search channels, categories, playlist names, and stream hosts.
- Browse categories, save favorite channels, and manage multiple playlist sources.
- Native AVKit playback with full-screen support.
- Modern SwiftUI interface with animated onboarding and a collapsible floating tab bar.

## Build

The project is generated with XcodeGen and checked in as an Xcode project.

```sh
xcodegen generate
open OpenIPTV.xcodeproj
```

The app does not include or host any IPTV content. Users are responsible for providing playlist URLs they have the right to access.
