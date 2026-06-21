import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
            LinearGradient(
                colors: [
                    Color.teal.opacity(0.16),
                    Color(uiColor: .systemBackground).opacity(0.0),
                    Color.indigo.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    func panelBackground(cornerRadius: CGFloat = 28) -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
    }
}
