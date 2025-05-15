import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Budget.self, Expense.self, Supplier.self, User.self], inMemory: true)
}
