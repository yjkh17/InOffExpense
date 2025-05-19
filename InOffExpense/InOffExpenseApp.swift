import SwiftUI
import SwiftData

@main
struct InOffExpenseApp: App {
    let modelContainer: ModelContainer?
    @State private var initializationError: Error?

    init() {
        var container: ModelContainer?
        var initError: Error?
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
            
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Create initial budget if needed
            if let container = container {
                let context = container.mainContext
                let budgetDescriptor = FetchDescriptor<Budget>()
                if (try? context.fetch(budgetDescriptor))?.isEmpty ?? true {
                    let budget = Budget(currentBudget: 1_000_000)
                    context.insert(budget)
                    try context.save()
                }
            }

            self.modelContainer = container

        } catch {
            self.modelContainer = nil
            initError = error
        }

        _initializationError = State(initialValue: initError)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let container = modelContainer {
                    ContentView()
                        .modelContainer(container)
                } else {
                    Text("Unable to start application.")
                }
            }
            .alert("Initialization Error",
                   isPresented: Binding(
                    get: { initializationError != nil },
                    set: { if !$0 { initializationError = nil } }
                   )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(initializationError?.localizedDescription ?? "")
            }
        }
    }
}
