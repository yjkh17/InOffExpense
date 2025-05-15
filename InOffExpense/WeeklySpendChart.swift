import SwiftUI
import Charts

struct WeeklySpendChart: View {
    let dailyTotals: [DailyTotal]
    @Namespace private var animation
    
    struct DailyTotal: Identifiable {
        let id = UUID()
        let date: Date
        let total: Double
    }
    
    var weeklyTotal: Double {
        dailyTotals.reduce(0) { $0 + $1.total }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Total")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(String(format: "%.0f IQD", weeklyTotal))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Chart(dailyTotals) { total in
                LineMark(
                    x: .value("Day", total.date),
                    y: .value("Amount", total.total)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.chartStart, .chartEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                AreaMark(
                    x: .value("Day", total.date),
                    y: .value("Amount", total.total)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.chartStart.opacity(0.3), .chartEnd.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .frame(height: 100)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 2, y: 2)
        .transaction { transaction in
            transaction.animation = .spring()
        }
    }
} 