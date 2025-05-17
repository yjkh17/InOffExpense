import SwiftUI
import SwiftData

@MainActor
protocol BudgetServiceProtocol {
    func getCurrentBudget() throws -> Budget?
    func createDefaultBudget() throws -> Budget
    func updateBudget(_ budget: Budget) throws
}

@MainActor
final class BudgetService: BudgetServiceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getCurrentBudget() throws -> Budget? {
        let descriptor = FetchDescriptor<Budget>()
        return try modelContext.fetch(descriptor).first
    }
    
    func createDefaultBudget() throws -> Budget {
        let budget = Budget(currentBudget: 1_000_000)
        modelContext.insert(budget)
        try modelContext.save()
        return budget
    }
    
    func updateBudget(_ budget: Budget) throws {
        try modelContext.save()
    }
}
