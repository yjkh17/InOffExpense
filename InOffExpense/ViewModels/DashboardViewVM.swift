import SwiftUI
import SwiftData

private struct DeletedExpenseRecord {
    let expense: Expense
    let wasPaid: Bool
    let budgetBeforeDelete: Double
}

@MainActor
final class DashboardViewVM: ObservableObject {
    @Published var searchText: String = ""
    @Published var showChart: Bool = false
    @Published var editingExpense: Expense?
    @Published var displayedExpenses: [Expense] = []
    @Published var displayedBudget: Double = 0.0
    @Published var showTopUpNotification = false
    @Published var showUndoBanner = false
    @Published var showFullScreenPhoto: Bool = false
    @Published var fullScreenPhoto: UIImage? = nil
    @Published var selectedCategory: ExpenseCategory?
    @Published var dateRange: Date = Date()

    private static let dateFilterFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // Data collections
    var budgets: [Budget] = []
    var allExpenses: [Expense] = []
    
    // Reference to ModelContext and persistent storage info
    var modelContext: ModelContext?
    var lastDailyTopUpDate: Date?
    
    // Constants
    let dailyTopUpAmount = 1_000_000.0
    let batchSize = 20
    
    // Stack for undo operations
    private var undoStack: [DeletedExpenseRecord] = []
    
    // Computed property for today's spent amount
    var dailySpent: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return allExpenses
            .filter { $0.isPaid && Calendar.current.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.amount }
    }
    
    // Filtered expenses based on search query
    var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        return allExpenses.filter { expense in
            let categoryMatch = selectedCategory == nil || expense.category == selectedCategory
            let dateMatch = calendar.isDate(expense.date, inSameDayAs: dateRange)
            return categoryMatch && dateMatch
        }
    }
    
    // MARK: - Business Logic Methods
    
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
    
    func topUpBudgetDaily() {
        guard let context = modelContext, let budget = budgets.first else { return }
        let now = Date()
        if let lastTopUp = lastDailyTopUpDate, Calendar.current.isDate(lastTopUp, inSameDayAs: now) {
            return
        }
        withAnimation(.spring()) {
            budget.currentBudget += dailyTopUpAmount
            displayedBudget = budget.currentBudget
        }
        do {
            try context.save()
            lastDailyTopUpDate = now
            showTopUpNotification = true
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation(.spring()) {
                    self?.showTopUpNotification = false
                }
            }
        } catch {
            print("Error topping up budget: \(error)")
        }
    }
    
    func loadInitialExpenses() {
        let allFiltered = filteredExpenses
        displayedExpenses = Array(allFiltered.prefix(batchSize))
    }
    
    func loadMoreIfNeeded(currentExpense: Expense) {
        guard let last = displayedExpenses.last else { return }
        if currentExpense.id == last.id {
            let allFiltered = filteredExpenses
            let nextIndex = displayedExpenses.count
            let nextBatch = allFiltered.dropFirst(nextIndex).prefix(batchSize)
            displayedExpenses.append(contentsOf: nextBatch)
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        guard let context = modelContext, let budget = budgets.first else { return }
        let wasPaid = expense.isPaid
        let currentBudget = budget.currentBudget
        
        if expense.isPaid {
            withAnimation(.spring()) {
                budget.currentBudget += expense.amount
                displayedBudget = budget.currentBudget
            }
        }
        context.delete(expense)
        do {
            try context.save()
            let record = DeletedExpenseRecord(expense: expense, wasPaid: wasPaid, budgetBeforeDelete: currentBudget)
            undoStack.append(record)
            showUndoBanner = true
        } catch {
            print("Error deleting expense: \(error)")
        }
    }
    
    func undoLastDelete() {
        guard let record = undoStack.popLast(), let context = modelContext, let budget = budgets.first else { return }
        if record.wasPaid {
            withAnimation(.spring()) {
                budget.currentBudget = record.budgetBeforeDelete
                displayedBudget = budget.currentBudget
            }
        }
        context.insert(record.expense)
        do {
            try context.save()
            loadInitialExpenses()
        } catch {
            print("Error undoing delete: \(error)")
        }
    }
    
    func markAsPaid(_ expense: Expense) {
        guard let context = modelContext, let budget = budgets.first else {
            expense.isPaid = true
            return
        }
        withAnimation(.spring()) {
            expense.isPaid = true
            budget.currentBudget -= expense.amount
            displayedBudget = budget.currentBudget
        }
        do {
            try context.save()
        } catch {
            print("Error marking as paid: \(error)")
        }
    }
    
    func saveExpense(_ expense: Expense) {
        guard let context = modelContext else { return }
        context.insert(expense)
        do {
            try context.save()
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // Update displayed expenses
            loadInitialExpenses()
        } catch {
            print("Error saving expense: \(error)")
        }
    }
}