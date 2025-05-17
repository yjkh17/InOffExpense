import SwiftUI
import SwiftData

@MainActor
protocol ExpenseServiceProtocol {
    func createExpense(_ expense: Expense) throws
    func updateExpense(_ expense: Expense) throws
    func deleteExpense(_ expense: Expense) throws
    func markAsPaid(_ expense: Expense) throws
}

@MainActor
final class ExpenseService: ExpenseServiceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createExpense(_ expense: Expense) throws {
        modelContext.insert(expense)
        try modelContext.save()
    }
    
    func updateExpense(_ expense: Expense) throws {
        try modelContext.save()
    }
    
    func deleteExpense(_ expense: Expense) throws {
        modelContext.delete(expense)
        try modelContext.save()
    }
    
    func markAsPaid(_ expense: Expense) throws {
        expense.isPaid = true
        try modelContext.save()
    }
}
