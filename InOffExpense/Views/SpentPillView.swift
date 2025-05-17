import SwiftUI

struct SpentPillView: View {
    let spent: Double
    
    private var formattedSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: spent)) ?? String(format: "%.0f", spent)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "cart.circle.fill")
                .font(.body)
            Text(formattedSpent)
                .font(.body.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
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
    }
}
