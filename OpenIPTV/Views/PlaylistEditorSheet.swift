import SwiftUI
import UIKit

struct PlaylistEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: PlaylistStore
    @FocusState private var isURLFieldFocused: Bool
    @State private var draftURL = ""
    @State private var duplicateMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Playlist")
                            .font(.system(.title, design: .rounded, weight: .bold))

                        Text("Paste an M3U playlist URL. The app streams directly from the source.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Playlist URL")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField("https://example.com/playlist.m3u", text: $draftURL, axis: .vertical)
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
                            .onChange(of: draftURL) { _, _ in
                                duplicateMessage = nil
                            }

                        if let duplicateMessage {
                            Label(duplicateMessage, systemImage: "checkmark.circle.fill")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.teal)
                                .transition(.opacity)
                        } else if let errorMessage = store.errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.red)
                                .transition(.opacity)
                        }
                    }
                    .padding(18)
                    .panelBackground(cornerRadius: 24)

                    Spacer(minLength: 0)

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
                            addPlaylist()
                        } label: {
                            Label(store.isLoading ? "Loading" : "Add", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 16))
                        .disabled(draftURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading)
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            draftURL = ""
            duplicateMessage = nil
        }
    }

    private func pasteFromClipboard() {
        guard let pastedString = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !pastedString.isEmpty else {
            return
        }

        draftURL = pastedString
    }

    private func addPlaylist() {
        if store.containsPlaylist(rawURL: draftURL) {
            duplicateMessage = "That playlist is already in your library."
            return
        }

        Task {
            await store.addOrUpdatePlaylist(from: draftURL)
            if store.errorMessage == nil {
                dismiss()
            }
        }
    }
}

#Preview {
    PlaylistEditorSheet(store: PlaylistStore())
}
