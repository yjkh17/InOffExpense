import SwiftData
import Foundation

@Model
class Item: Identifiable {
    var timestamp: Date
    var amount: Double  // New field as required

    init(timestamp: Date, amount: Double = 0.0) {
        self.timestamp = timestamp
        self.amount = amount
    }
}
