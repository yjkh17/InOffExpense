import SwiftData
import SwiftUI

enum ExpenseCategory: String, CaseIterable, Codable {
    case food = "Food"
    case supplies = "Supplies"
    case utilities = "Utilities"
    case salary = "Salary"
    case other = "Other"
}

@Model
class Expense {
    @Attribute(.unique) var id: UUID
    var details: String
    var date: Date
    var amount: Double
    var isPaid: Bool
    var photoData: Data?
    var supplier: Supplier?
    var category: ExpenseCategory = ExpenseCategory.other
    var currency: String = "IQD"
    
    // If you plan to track multiple payments or attachments, consider:
    // @Relationship var payments: [Payment] = []
    // @Relationship var attachments: [Attachment] = []
    
    init(
        id: UUID = UUID(),
        details: String,
        date: Date,
        amount: Double,
        isPaid: Bool,
        photoData: Data? = nil,
        category: ExpenseCategory = ExpenseCategory.other,
        currency: String = "IQD"
    ) {
        self.id = id
        self.details = details
        self.date = date
        self.amount = amount
        self.isPaid = isPaid
        self.photoData = photoData
        self.category = category
        self.currency = currency
    }
}
