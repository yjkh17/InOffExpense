import SwiftUI

extension Color {
    // MARK: - Primary Colors
    static let appPrimary = Color("Primary")
    static let appSecondary = Color("Secondary")
    
    // MARK: - Background Colors
    static let cardBackground = Color(.secondarySystemBackground)
    static let chartStart = Color("ChartStart")
    static let chartEnd = Color("ChartEnd")
    
    // MARK: - Category Colors
    static let foodCategory = Color.green
    static let suppliesCategory = Color.orange
    static let utilitiesCategory = Color.blue
    static let salaryCategory = Color.purple
    static let otherCategory = Color.gray
    
    // MARK: - Status Colors
    static let paidStatus = Color.green
    static let unpaidStatus = Color.red
    
    // MARK: - Convenience Methods
    static func categoryColor(for category: ExpenseCategory) -> Color {
        switch category {
        case .food: return .foodCategory
        case .supplies: return .suppliesCategory
        case .utilities: return .utilitiesCategory
        case .salary: return .salaryCategory
        case .other: return .otherCategory
        }
    }
} 