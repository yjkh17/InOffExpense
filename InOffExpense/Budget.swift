import SwiftData

@Model
class Budget {
    var currentBudget: Double

    init(currentBudget: Double) {
        self.currentBudget = currentBudget
    }
    
    // Consider adding a computed property to enforce nonnegative values:
    // var validatedBudget: Double { max(0, currentBudget) }
}
