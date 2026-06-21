import SwiftUI

struct AnimatedSignalBadge: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.teal.opacity(isPulsing ? 0.14 : 0.24))
                .frame(width: 104, height: 104)
                .scaleEffect(isPulsing ? 1.08 : 0.92)

            Circle()
                .fill(.regularMaterial)
                .frame(width: 82, height: 82)
                .overlay {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.teal)
                        .scaleEffect(isPulsing ? 1.06 : 0.96)
                }
        }
        .frame(width: 124, height: 124)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
