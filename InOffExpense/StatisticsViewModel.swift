import SwiftUI
import SwiftData
import Charts

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var dailyTotals: [DailyTotal] = []
    @Published var categoryTotals: [CategoryTotal] = []
    @Published var selectedDateRange: DateRange = .last30Days
    
    private var modelContext: ModelContext?
    
    enum DateRange: String, CaseIterable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case custom = "Custom"
    }
    
    struct DailyTotal: Identifiable {
        let id = UUID()
        let date: Date
        let total: Double
    }
    
    struct CategoryTotal: Identifiable {
        let id = UUID()
        let category: ExpenseCategory
        let total: Double
        let percentage: Double
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        updateStatistics()
    }
    
    func updateStatistics() {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch selectedDateRange {
        case .last7Days:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        case .last90Days:
            startDate = calendar.date(byAdding: .day, value: -90, to: endDate)!
        case .custom:
            // Handle custom date range
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        }
        
        // Fetch expenses in date range
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { expense in
                expense.date >= startDate && expense.date <= endDate
            }
        )
        
        guard let expenses = try? context.fetch(descriptor) else { return }
        
        // Calculate daily totals
        var dailyTotalsDict: [Date: Double] = [:]
        var categoryTotalsDict: [ExpenseCategory: Double] = [:]
        let totalAmount = expenses.reduce(0) { $0 + $1.amount }
        
        for expense in expenses {
            // Daily totals
            let dayStart = calendar.startOfDay(for: expense.date)
            dailyTotalsDict[dayStart, default: 0] += expense.amount
            
            // Category totals
            categoryTotalsDict[expense.category, default: 0] += expense.amount
        }
        
        // Convert to arrays
        dailyTotals = dailyTotalsDict.map { DailyTotal(date: $0.key, total: $0.value) }
            .sorted { $0.date < $1.date }
        
        categoryTotals = categoryTotalsDict.map { category, total in
            CategoryTotal(
                category: category,
                total: total,
                percentage: totalAmount > 0 ? (total / totalAmount) * 100 : 0
            )
        }.sorted { $0.total > $1.total }
    }
} 
