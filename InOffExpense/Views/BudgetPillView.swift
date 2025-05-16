import SwiftUI

/// Small capsule that shows the current available budget.
struct BudgetPillView: View {
    let budget: Double
    @State private var animateChange = false

    private var validatedBudget: Double { max(0, budget) }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.body)

            Text(validatedBudget, format: .number)
                .font(.body.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .foregroundColor(.white)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.8), Color.purple.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.purple.opacity(0.3), radius: 6, x: 3, y: 3)
        .scaleEffect(animateChange ? 1.1 : 1.0)
        .onChange(of: budget) { _, _ in
            animateChange = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                animateChange = false
            }
        }
    }
}
