import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Namespace private var animation
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date Range Picker
                Picker("Date Range", selection: $viewModel.selectedDateRange) {
                    ForEach(StatisticsViewModel.DateRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: viewModel.selectedDateRange) { _, _ in
                    withAnimation(.snappy) {
                        viewModel.updateStatistics()
                    }
                }
                
                // Daily Totals Chart
                VStack(alignment: .leading) {
                    Text("Daily Expenses")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart(viewModel.dailyTotals) { total in
                        BarMark(
                            x: .value("Date", total.date),
                            y: .value("Amount", total.total)
                        )
                        .foregroundStyle(.blue.gradient)
                    }
                    .frame(height: 200)
                    .padding()
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // Category Distribution Chart
                VStack(alignment: .leading) {
                    Text("Category Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart(viewModel.categoryTotals) { total in
                        SectorMark(
                            angle: .value("Percentage", total.percentage),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", total.category.rawValue))
                    }
                    .frame(height: 200)
                    .padding()
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // Category Legend
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(viewModel.categoryTotals) { total in
                        HStack {
                            Circle()
                                .fill(color(for: total.category))
                                .frame(width: 12, height: 12)
                            Text(total.category.rawValue)
                            Spacer()
                            Text(String(format: "%.1f%%", total.percentage))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.setup(modelContext: modelContext)
        }
    }
    
    private func color(for category: ExpenseCategory) -> Color {
        switch category {
        case .food: return .green
        case .supplies: return .blue
        case .utilities: return .orange
        case .salary: return .purple
        case .other: return .gray
        }
    }
} 