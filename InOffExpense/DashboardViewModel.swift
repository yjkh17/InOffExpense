import SwiftUI
import SwiftData

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedCategory: ExpenseCategory?
    @Published var dateRange = Date()
    @Published var displayedBudget: Double = 0.0
    @Published var showTopUpNotification = false
    @Published var showUndoBanner = false
    
    var modelContext: ModelContext?
    private let dailyTopUpAmount = 1_000_000.0
    
    func createDefaultBudgetIfNeeded() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Budget>()
        guard (try? context.fetch(descriptor))?.isEmpty ?? true else { return }
        
        let defaultBudget = Budget(currentBudget: 1_000_000)
        context.insert(defaultBudget)
        do {
            try context.save()
            displayedBudget = defaultBudget.currentBudget
        } catch {
            print("Error saving default budget: \(error)")
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Budget>()
        guard let budget = try? context.fetch(descriptor).first else { return }
        
        if expense.isPaid {
            budget.currentBudget += expense.amount
            displayedBudget = budget.currentBudget
        }
        
        context.delete(expense)
        do {
            try context.save()
        } catch {
            print("Error deleting expense: \(error)")
        }
    }
}