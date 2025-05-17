import SwiftUI
import Charts

struct WeeklySpendChart: View {
    let dailyTotals: [DailyTotal]
    let viewModel: DashboardViewVM
    var onPreviousWeek: () -> Void = {}
    var onNextWeek: () -> Void = {}
    var onResetWeek: () -> Void = {}
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDayData: SelectedDayData?
    @State private var selectedX: Date?
    @State private var chartSize: CGSize = .zero
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            WeekNavigationView(
                isCurrentWeek: isCurrentWeek(),
                weekRangeText: weekRangeText(),
                onPrevious: onPreviousWeek,
                onNext: onNextWeek,
                onReset: onResetWeek
            )
            
            // Chart
            ChartContainer(
                dailyTotals: dailyTotals,
                selectedDate: $selectedX,
                size: $chartSize,
                onDateSelected: handleDateSelection
            )
            
            // Info
            if let dayData = selectedDayData {
                SelectionInfoView(
                    date: dayData.date,
                    expenseCount: dayData.expenses.count,
                    onClear: clearSelection
                )
            }
        }
        .sheet(item: $selectedDayData) { dayData in
            DailyReportView(
                date: dayData.date,
                expenses: dayData.expenses,
                onDismiss: clearSelection
            )
        }
    }
    
    private func handleDateSelection(_ date: Date) {
        guard let selectedTotal = dailyTotals.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
              selectedTotal.total > 0 else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedX = date
            let expenses = viewModel.filteredExpenses.filter {
                calendar.isDate($0.date, inSameDayAs: date)
            }
            selectedDayData = SelectedDayData(date: date, expenses: expenses)
        }
    }
    
    private func clearSelection() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDayData = nil
            selectedX = nil
        }
    }
    
    private func isCurrentWeek() -> Bool {
        guard let firstDate = dailyTotals.first?.date else { return true }
        return calendar.isDate(firstDate, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    private func weekRangeText() -> String {
        guard let lastDate = dailyTotals.last?.date else { return "" }
        let weekStart = calendar.date(byAdding: .day, value: -6, to: lastDate)!
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        
        let startMonth = monthFormatter.string(from: weekStart)
        let endMonth = monthFormatter.string(from: lastDate)
        let startDay = dayFormatter.string(from: weekStart)
        let endDay = dayFormatter.string(from: lastDate)
        
        if startMonth == endMonth {
            return "\(startMonth) \(startDay)-\(endDay)"
        } else {
            return "\(startMonth) \(startDay) - \(endMonth) \(endDay)"
        }
    }
}

// MARK: - Models

private struct SelectedDayData: Identifiable {
    let id = UUID()
    let date: Date
    let expenses: [Expense]
}

// MARK: - Subviews

private struct ChartContainer: View {
    let dailyTotals: [DailyTotal]
    @Binding var selectedDate: Date?
    @Binding var size: CGSize
    let onDateSelected: (Date) -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ChartView(
                dailyTotals: dailyTotals,
                selectedDate: selectedDate
            )
            
            // Tap Areas
            HStack(spacing: 0) {
                ForEach(dailyTotals) { total in
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onDateSelected(total.date)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 180)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
        .padding(.horizontal)
    }
}

private struct ChartView: View {
    let dailyTotals: [DailyTotal]
    let selectedDate: Date?
    
    var body: some View {
        Chart {
            ForEach(dailyTotals) { total in
                AreaMark(
                    x: .value("Day", total.date, unit: .day),
                    y: .value("Amount", total.total)
                )
                .interpolationMethod(.stepEnd)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.15),
                            Color.accentColor.opacity(0.05),
                            Color.accentColor.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LineMark(
                    x: .value("Day", total.date, unit: .day),
                    y: .value("Amount", total.total)
                )
                .interpolationMethod(.stepEnd)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .foregroundStyle(Color.accentColor)
                
                if total.total > 0 {
                    PointMark(
                        x: .value("Day", total.date, unit: .day),
                        y: .value("Amount", total.total)
                    )
                    .foregroundStyle(Color.accentColor)
                    .symbolSize(selectedDate == total.date ? 50 : 40)
                    .opacity(selectedDate == total.date ? 1 : 0.8)
                    
                    PointMark(
                        x: .value("Day", total.date, unit: .day),
                        y: .value("Amount", total.total)
                    )
                    .annotation(position: .top, spacing: 4) {
                        Text(formatAmount(total.total))
                            .font(.caption2.bold())
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .foregroundStyle(.white)
                    .symbolSize(25)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let y = value.as(Double.self) {
                    AxisValueLabel {
                        Text(formatAmount(y))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    AxisGridLine()
                        .foregroundStyle(.secondary.opacity(0.15))
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatDay(date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize()
                            .frame(width: 30)
                    }
                    AxisGridLine()
                        .foregroundStyle(.secondary.opacity(0.15))
                }
            }
        }
        .animation(.spring(response: 0.3), value: selectedDate)
    }
    
    private func formatAmount(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.0fK", value / 1000)
        }
        return String(format: "%.0f", value)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

private struct WeekNavigationView: View {
    let isCurrentWeek: Bool
    let weekRangeText: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onPrevious()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bounce)
            
            Spacer()
            
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onReset()
            }) {
                Text(isCurrentWeek ? "Current Week" : weekRangeText)
                    .font(.caption)
                    .foregroundColor(isCurrentWeek ? .secondary : .blue)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6))
                            .opacity(isCurrentWeek ? 1 : 0)
                    )
            }
            .buttonStyle(.bounce)
            .opacity(isCurrentWeek ? 0.6 : 1)
            
            Spacer()
            
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onNext()
            }) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bounce)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

private struct SelectionInfoView: View {
    let date: Date
    let expenseCount: Int
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onClear) {
                Text("Clear Selection")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            Divider()
            
            Text(formatDate(date))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Divider()
            
            Text("\(expenseCount) expense\(expenseCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
