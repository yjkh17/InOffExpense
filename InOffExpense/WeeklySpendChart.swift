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
    
    var maxTotal: Double {
        dailyTotals.map(\.total).max() ?? 1000
    }
    
    var averageTotal: Double {
        dailyTotals.isEmpty ? 0 : weeklyTotal / Double(dailyTotals.count)
    }
    
    private func yAxisTicks() -> [Double] {
        let max = maxTotal * 1.2
        let step = max / 4
        return stride(from: 0, through: max, by: step).map { $0 }
    }
    
    var body: some View {
        Chart {
            ForEach(dailyTotals) { total in
                LineMark(
                    x: .value("Day", total.date),
                    y: .value("Amount", total.total)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .foregroundStyle(Color.accentColor.opacity(0.8))
                
                AreaMark(
                    x: .value("Day", total.date),
                    y: .value("Amount", total.total)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                PointMark(
                    x: .value("Day", total.date),
                    y: .value("Amount", total.total)
                )
                .annotation(position: .top, spacing: 2) {
                    Text("\(Int(total.total)) IQD")
                        .font(.caption2.bold())
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .foregroundStyle(Color.accentColor)
                .symbolSize(30)
            }
            
            if !dailyTotals.isEmpty {
                RuleMark(y: .value("Average", averageTotal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.orange.opacity(0.5))
                    .annotation(position: .leading) {
                        Text("Avg: \(Int(averageTotal)) IQD")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
            }
        }
        .chartYScale(domain: 0...maxTotal * 1.2)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.weekday(.narrow))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisGridLine()
                    .foregroundStyle(.secondary.opacity(0.15))
            }
        }
        .chartYAxis {
            AxisMarks(values: yAxisTicks()) { value in
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(doubleValue)) IQD")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    AxisGridLine()
                        .foregroundStyle(.secondary.opacity(0.15))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
}
