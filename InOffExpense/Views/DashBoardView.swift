import SwiftUI
import SwiftData
import Charts

enum SidebarItem: Hashable {
    case dashboard, statistics
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [Budget]
    @StateObject private var viewModel = DashboardViewVM()
    
    @State private var selection: SidebarItem? = .dashboard
    @State private var showAddExpenseSheet = false
    
    private var filteredExpenses: [Expense] {
        viewModel.filteredExpenses
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: SidebarItem.dashboard) {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                NavigationLink(value: SidebarItem.statistics) {
                    Label("Statistics", systemImage: "chart.pie.fill")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("In Off Expense")
        } detail: {
            NavigationStack {
                Group {
                    switch selection {
                    case .dashboard, .none:
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                HStack(spacing: 12) {
                                    BudgetPillView(budget: budgets.first?.currentBudget ?? 0)
                                    SpentPillView(spent: viewModel.dailySpent)
                                }
                                .padding(.horizontal)
                                
                                // Weekly Spend Chart
                                if !viewModel.filteredExpenses.isEmpty {
                                    WeeklySpendChart(dailyTotals: calculateWeeklyTotals())
                                        .padding(.horizontal)
                                }
                                
                                // Quick Filters
                                VStack(spacing: 0) {
                                    HStack(spacing: 12) {
                                        Menu {
                                            Picker("Category", selection: $viewModel.selectedCategory) {
                                                Text("All Categories").tag(Optional<ExpenseCategory>.none)
                                                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                                    Text(category.rawValue).tag(Optional(category))
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text(viewModel.selectedCategory?.rawValue ?? "All Categories")
                                                    .foregroundColor(.primary)
                                                    .font(.subheadline)
                                                Image(systemName: "chevron.up.chevron.down")
                                                    .foregroundColor(.secondary)
                                                    .font(.caption2)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.gray.opacity(0.05))
                                            .clipShape(Capsule())
                                        }
                                        
                                        Spacer()
                                        
                                        DatePicker("", selection: $viewModel.dateRange, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .scaleEffect(0.9)
                                            .frame(maxWidth: 120)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 12)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.gray.opacity(0.05))
                                )
                                .padding(.horizontal)
                                
                                // Expense List
                                if filteredExpenses.isEmpty {
                                    EmptyStateView(
                                        title: "No expenses yet",
                                        subtitle: "Tap the + button to add your first expense",
                                        systemImage: "tray.fill"
                                    )
                                    .padding(.top, 32)
                                } else {
                                    ScrollView {
                                        LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                                            Section {
                                                ForEach(filteredExpenses) { expense in
                                                    ExpenseCard(expense: expense) {
                                                        viewModel.deleteExpense(expense)
                                                    }
                                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                        Button(role: .destructive) {
                                                            let generator = UIImpactFeedbackGenerator(style: .rigid)
                                                            generator.impactOccurred()
                                                            withAnimation {
                                                                viewModel.deleteExpense(expense)
                                                            }
                                                        } label: {
                                                            Label("Delete", systemImage: "trash")
                                                        }
                                                        .tint(.red)
                                                    }
                                                    .swipeActions(edge: .leading) {
                                                        Button {
                                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                                            generator.impactOccurred()
                                                            if !expense.isPaid {
                                                                withAnimation {
                                                                    viewModel.markAsPaid(expense)
                                                                }
                                                            }
                                                        } label: {
                                                            Label(expense.isPaid ? "Paid" : "Mark as Paid", 
                                                                  systemImage: expense.isPaid ? "checkmark.circle.fill" : "checkmark.circle")
                                                        }
                                                        .tint(expense.isPaid ? .gray : .green)
                                                    }
                                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                                                }
                                            } header: {
                                                HStack {
                                                    Text("\(filteredExpenses.count) Expense\(filteredExpenses.count == 1 ? "" : "s")")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                    Spacer()
                                                }
                                                .padding(.horizontal)
                                                .padding(.vertical, 8)
                                                .background(.ultraThinMaterial)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.top, 8)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                        .navigationTitle("Dashboard")
                    case .statistics:
                        StatisticsView()
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if selection == .dashboard {
                        Button {
                            showAddExpenseSheet = true
                        } label: {
                            Circle()
                                .fill(.green)
                                .frame(width: 56, height: 56)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                .overlay {
                                    Image(systemName: "plus")
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(.white)
                                }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddExpenseSheet) {
            ExpenseLoggingView()
        }
        .task {
            viewModel.modelContext = modelContext
            viewModel.allExpenses = allExpenses
            if budgets.isEmpty {
                viewModel.createDefaultBudgetIfNeeded()
            }
        }
        .onChange(of: allExpenses) { _, newExpenses in
            viewModel.allExpenses = newExpenses
        }
    }

    private func calculateWeeklyTotals() -> [WeeklySpendChart.DailyTotal] {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(byAdding: .day, value: -7, to: today)!
        
        var dailyTotals: [Date: Double] = [:]
        
        for expense in viewModel.filteredExpenses {
            let dayStart = calendar.startOfDay(for: expense.date)
            if dayStart >= weekStart {
                dailyTotals[dayStart, default: 0] += expense.amount
            }
        }
        
        return dailyTotals.map { WeeklySpendChart.DailyTotal(date: $0.key, total: $0.value) }
            .sorted { $0.date < $1.date }
    }
}

struct ExpenseCard: View {
    let expense: Expense
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.categoryColor(for: expense.category))
                    .frame(width: 4)
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center, spacing: 6) {
                            Text(expense.details)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if expense.isPaid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                        }
                        
                        if let supplier = expense.supplier {
                            Text(supplier.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(expense.amount)) \(expense.currency)")
                            .font(.headline)
                            .foregroundStyle(expense.isPaid ? .green : .primary)
                        
                        Text(expense.category.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
        }
        .contentShape(Rectangle())
    }
}
