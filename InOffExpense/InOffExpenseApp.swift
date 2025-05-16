import SwiftUI
import SwiftData

@main
struct InOffExpenseApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: Budget.self, Expense.self, Supplier.self, User.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
