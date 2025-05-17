import SwiftUI

/// Small capsule that shows the current available budget.
struct BudgetPillView: View {
    let budget: Double
    
    private var formattedBudget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: budget)) ?? String(format: "%.0f", budget)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.body)
            Text(formattedBudget)
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
        .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1))
        .shadow(color: Color.purple.opacity(0.3), radius: 6, x: 3, y: 3)
    }
}
