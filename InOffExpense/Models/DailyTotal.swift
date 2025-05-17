import Foundation

public struct DailyTotal: Identifiable, Equatable {
    public let id = UUID()
    public let date: Date
    public let total: Double
    
    public init(date: Date, total: Double) {
        self.date = date
        self.total = total
    }
    
    public static func == (lhs: DailyTotal, rhs: DailyTotal) -> Bool {
        lhs.date == rhs.date && lhs.total == rhs.total
    }
}