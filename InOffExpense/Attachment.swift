import SwiftData
import Foundation

@Model
class Attachment: Identifiable {
    // Using UUID for the id is more type-safe.
    @Attribute(.unique) var id: UUID = UUID()
    
    var imageData: Data
    var dateAdded: Date

    @Relationship var expense: Expense

    init(imageData: Data, dateAdded: Date = Date(), expense: Expense) {
        self.imageData = imageData
        self.dateAdded = dateAdded
        self.expense = expense
    }
}
