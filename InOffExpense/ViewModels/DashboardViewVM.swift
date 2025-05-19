import SwiftUI
import SwiftData
import os

@MainActor
final class DashboardViewVM: ObservableObject {
    @Published var showChart: Bool = false
    @Published var editingExpense: Expense?
    @Published var selectedCategory: ExpenseCategory? = nil
    @Published var dateRange: Date
    @Published var displayedBudget: Double = 0.0
    @Published var showUndoBanner = false
    @Published var showFullScreenPhoto: Bool = false
    @Published var fullScreenPhoto: UIImage? = nil
    @Published var weekOffset: Int = 0
    @Published var showDailyReport = false
    
    private let expenseService: ExpenseServiceProtocol
    private let budgetService: BudgetServiceProtocol
    private var undoStack: [DeletedExpenseRecord] = []
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "InOffExpense", category: "DashboardViewVM")
    
    @Published var allExpenses: [Expense] = []
    @Published var budgets: [Budget] = []
    
    init(expenseService: ExpenseServiceProtocol, budgetService: BudgetServiceProtocol) {
        self.expenseService = expenseService
        self.budgetService = budgetService
        self._dateRange = Published(initialValue: Calendar.current.startOfDay(for: Date()))
    }
    
    var filteredExpenses: [Expense] {
        // Only filter by category, ignore date range for now
        allExpenses.filter { expense in
            selectedCategory == nil || expense.category == selectedCategory
        }
        .sorted { $0.date > $1.date }
    }
    
    var dailySpent: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allExpenses
            .filter { calendar.isDate($0.date, inSameDayAs: today) && $0.isPaid }
            .reduce(0) { $0 + $1.amount }
    }
    
    var todaysExpenses: [Expense] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allExpenses.filter { calendar.isDate($0.date, inSameDayAs: today) }
    }
    
    func createDefaultBudgetIfNeeded() async {
        do {
            guard try budgetService.getCurrentBudget() == nil else { return }
            let budget = try budgetService.createDefaultBudget()
            displayedBudget = budget.currentBudget
        } catch {
            logger.error("Error creating default budget: \(error.localizedDescription)")
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        guard let budget = budgets.first else { return }
        let wasPaid = expense.isPaid
        let currentBudget = budget.currentBudget
        
        do {
            if expense.isPaid {
                budget.currentBudget += expense.amount
                displayedBudget = budget.currentBudget
            }
            
            try expenseService.deleteExpense(expense)
            let record = DeletedExpenseRecord(expense: expense, wasPaid: wasPaid, budgetBeforeDelete: currentBudget)
            undoStack.append(record)
            showUndoBanner = true
        } catch {
            logger.error("Error deleting expense: \(error.localizedDescription)")
        }
    }
    
    func markAsPaid(_ expense: Expense) {
        guard let budget = budgets.first else { return }
        
        do {
            expense.isPaid = true
            budget.currentBudget -= expense.amount
            displayedBudget = budget.currentBudget
            
            try expenseService.updateExpense(expense)
            try budgetService.updateBudget(budget)
        } catch {
            logger.error("Error marking as paid: \(error.localizedDescription)")
        }
    }
    
    func undoLastDelete() {
        guard let record = undoStack.popLast(),
              let budget = budgets.first else { return }
        
        do {
            if record.wasPaid {
                budget.currentBudget = record.budgetBeforeDelete
                displayedBudget = budget.currentBudget
                try budgetService.updateBudget(budget)
            }
            
            try expenseService.createExpense(record.expense)
        } catch {
            logger.error("Error undoing delete: \(error.localizedDescription)")
        }
    }
    
    func calculateWeeklyTotals() -> [DailyTotal] {
        let calendar = Calendar.current
        let selectedDate = calendar.startOfDay(for: dateRange)
        
        var weekStart = selectedDate
        weekStart = calendar.date(byAdding: .day, value: weekOffset * 7, to: weekStart)!
        while calendar.component(.weekday, from: weekStart) != 2 { // 2 is Monday
            weekStart = calendar.date(byAdding: .day, value: -1, to: weekStart)!
        }
        
        var dailyTotals: [DailyTotal] = []
        
        for dayOffset in 0...6 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            let dayTotal = filteredExpenses
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.amount }
            dailyTotals.append(DailyTotal(date: date, total: dayTotal))
        }
        
        return dailyTotals
    }
    
    func previousWeek() {
        weekOffset -= 1
    }
    
    func nextWeek() {
        weekOffset += 1
    }
    
    func resetToCurrentWeek() {
        weekOffset = 0
    }
}

private struct DeletedExpenseRecord {
    let expense: Expense
    let wasPaid: Bool
    let budgetBeforeDelete: Double
}
