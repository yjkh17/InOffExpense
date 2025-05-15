import SwiftUI

struct BudgetPillView: View {
    let budget: Double
    @State private var animateChange = false

    private var validatedBudget: Double {
        max(0, budget)
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.body)
            Text("\(validatedBudget, format: .number)")
                .font(.body.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        // Updated horizontal and vertical padding for more breathing room
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .foregroundColor(.white)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.accentColor.opacity(0.8), Color.purple.opacity(0.6)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1)) // Added semi-transparent white stroke
        .shadow(color: Color.purple.opacity(0.3), radius: 6, x: 3, y: 3) // Enhanced shadow for a softer lift
        .scaleEffect(animateChange ? 1.1 : 1.0)
        // Modified scale animation to use spring effect
        .onChange(of: budget) { _oldValue, _newValue in
            animateChange = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                animateChange = false
            }
        }
    }
}
