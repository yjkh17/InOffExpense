import SwiftUI

struct DebtPillView: View {
    let debt: Double

    var body: some View {
        Text("Total Debt: \(debt, format: .number)")
            .font(.title3.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            // Use white text for high debt and black for low debt
            .foregroundColor(debt > 1000 ? .white : .black)
            .background(Color.red)
            .clipShape(Capsule())
    }
}
