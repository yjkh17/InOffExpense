import SwiftUI

struct SpentPillView: View {
    let spent: Double
    @State private var animateSpentChange = false

    private var validatedSpent: Double {
        max(0, spent)
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "cart.circle.fill")
                .font(.body)
            Text("\(validatedSpent, format: .number)")
                .font(.body.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        // Reduced horizontal padding from 12 to 8
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .foregroundColor(.white)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.orange.opacity(0.3)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1))
        .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
        .scaleEffect(animateSpentChange ? 1.1 : 1.0)
        // Removed .fixedSize()
        .onChange(of: spent) { _oldValue, _newValue in
            animateSpentChange = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                animateSpentChange = false
            }
        }
    }
}
