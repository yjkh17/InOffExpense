import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Namespace private var animation
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Date Range Picker
                VStack(spacing: 4) {
                    Text("DATE RANGE")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    
                    Picker("Date Range", selection: $viewModel.selectedDateRange) {
                        ForEach(StatisticsViewModel.DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 20)
                .onChange(of: viewModel.selectedDateRange) { _, _ in
                    withAnimation(.snappy) {
                        viewModel.updateStatistics()
                    }
                }
                
                // Daily Totals Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Expenses")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Chart(viewModel.dailyTotals) { total in
                        BarMark(
                            x: .value("Date", total.date, unit: .hour),
                            y: .value("Amount", total.total)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .annotation(position: .top) {
                            if total.total.isFinite {
                                Text("\(Int(round(total.total)))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            if let doubleValue = value.as(Double.self), doubleValue.isFinite {
                                AxisValueLabel {
                                    Text("\(Int(round(doubleValue)))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            AxisGridLine()
                        }
                    }
                    .frame(height: 200)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
                .padding(.horizontal, 20)
                
                // Category Distribution Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category Distribution")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Chart(viewModel.categoryTotals) { total in
                        SectorMark(
                            angle: .value("Percentage", total.percentage),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .foregroundStyle(Color.categoryColor(for: total.category))
                        .annotation(position: .overlay) {
                            if total.percentage >= 10 {
                                Text(String(format: "%.0f%%", total.percentage))
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(height: 200)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
                .padding(.horizontal, 20)
                
                // Category Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.categoryTotals) { total in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.categoryColor(for: total.category))
                                .frame(width: 8, height: 8)
                            Text(total.category.rawValue)
                                .font(.footnote)
                            Spacer()
                            Text(String(format: "%.1f%%", total.percentage))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Statistics")
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }
}
