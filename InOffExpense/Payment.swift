import SwiftData
import Foundation

@Model
class Payment: Identifiable {
    var date: Date
    var amount: Double

    // Relationship to Expense
    @Relationship var expense: Expense

    init(date: Date = Date(), amount: Double, expense: Expense) {
        self.date = date
        self.amount = amount
        self.expense = expense
    }
}
