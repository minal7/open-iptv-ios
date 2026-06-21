import SwiftUI
import UIKit

struct OnboardingView: View {
    @Bindable var store: PlaylistStore
    @FocusState private var isURLFieldFocused: Bool

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 24)

                    VStack(spacing: 16) {
                        AnimatedSignalBadge()

                        VStack(spacing: 8) {
                            Text("Open IPTV")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .multilineTextAlignment(.center)

                            Text("Paste your M3U playlist link to begin.")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 18) {
                        Text("Playlist URL")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField("https://example.com/playlist.m3u", text: $store.playlistURLText, axis: .vertical)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.go)
                            .focused($isURLFieldFocused)
                            .lineLimit(1...3)
                            .font(.body.monospaced())
                            .padding(16)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(isURLFieldFocused ? Color.teal : Color.primary.opacity(0.08), lineWidth: 1.5)
                            }
                            .onSubmit {
                                Task { await store.loadPlaylist() }
                            }

                        HStack(spacing: 12) {
                            Button {
                                pasteFromClipboard()
                            } label: {
                                Label("Paste", systemImage: "doc.on.clipboard")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.roundedRectangle(radius: 16))

                            Button {
                                Task { await store.loadPlaylist() }
                            } label: {
                                Label(store.isLoading ? "Loading" : "Load", systemImage: "play.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.roundedRectangle(radius: 16))
                            .disabled(!store.canLoadPlaylist)
                        }

                        if let errorMessage = store.errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.red)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(20)
                    .panelBackground()

                    Spacer(minLength: 28)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if store.isLoading {
                LoadingOverlay(message: "Reading playlist")
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.28), value: store.phase)
    }

    private func pasteFromClipboard() {
        guard let pastedString = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !pastedString.isEmpty else {
            return
        }

        store.playlistURLText = pastedString
    }
}

struct LoadingOverlay: View {
    var message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.16)
                .ignoresSafeArea()

            HStack(spacing: 12) {
                ProgressView()
                    .tint(.teal)
                Text(message)
                    .font(.headline)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .panelBackground(cornerRadius: 20)
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingView(store: PlaylistStore())
    }
}
