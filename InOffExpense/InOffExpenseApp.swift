import SwiftUI
import SwiftData

@main
struct InOffExpenseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Budget.self, Expense.self, Supplier.self, User.self])
    }
}
