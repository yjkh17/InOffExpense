import SwiftUI
import SwiftData

@main
struct InOffExpenseApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Expense.self,
                Budget.self,
                Supplier.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Create initial budget if needed
            let context = container.mainContext
            let budgetDescriptor = FetchDescriptor<Budget>()
            if (try? context.fetch(budgetDescriptor))?.isEmpty ?? true {
                let budget = Budget(currentBudget: 1_000_000)
                context.insert(budget)
                try context.save()
            }
            
            self.modelContainer = container
            
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
