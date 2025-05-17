import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query(FetchDescriptor<Budget>()) private var budgets: [Budget]
    @StateObject private var viewModel: DashboardViewVM
    @State private var showAddExpenseSheet = false
    @State private var isScrolling = false
    @State private var lastScrollOffset: CGFloat = 0
    
    init(modelContext: ModelContext) {
        let expenseService = ExpenseService(modelContext: modelContext)
        let budgetService = BudgetService(modelContext: modelContext)
        let viewModel = DashboardViewVM(
            expenseService: expenseService,
            budgetService: budgetService
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Chart Section
                WeeklySpendChart(
                    dailyTotals: viewModel.calculateWeeklyTotals(),
                    viewModel: viewModel,
                    onPreviousWeek: viewModel.previousWeek,
                    onNextWeek: viewModel.nextWeek,
                    onResetWeek: viewModel.resetToCurrentWeek
                )
                
                // MARK: - Content Section
                if allExpenses.isEmpty { 
                    EmptyStateView(
                        title: "No expenses yet",
                        subtitle: "Tap the + button to add your first expense",
                        systemImage: "tray.fill"
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                } else {
                    ExpensesListView(
                        expenses: viewModel.filteredExpenses,
                        onDelete: viewModel.deleteExpense,
                        onMarkAsPaid: viewModel.markAsPaid
                    )
                    .padding(.bottom, 90)
                }
            }
            .padding(.top, 12)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HeaderView(
                    budget: budgets.first?.currentBudget ?? 0,
                    spent: viewModel.dailySpent
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            ButtonsView(
                isScrolling: isScrolling,
                showAddExpenseSheet: $showAddExpenseSheet,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showAddExpenseSheet) {
            ExpenseLoggingView(modelContext: modelContext)
        }
        .sheet(isPresented: $viewModel.showDailyReport) {
            if !viewModel.todaysExpenses.isEmpty {
                DailyReportView(
                    date: Date(),
                    expenses: viewModel.todaysExpenses,
                    onDismiss: {
                        viewModel.showDailyReport = false
                    }
                )
            }
        }
        .task {
            // Initial state setup
            viewModel.allExpenses = allExpenses
            viewModel.budgets = budgets
        }
        .onChange(of: allExpenses) { _, newExpenses in
            withAnimation {
                viewModel.allExpenses = newExpenses
            }
        }
        .onChange(of: budgets) { _, newBudgets in
            withAnimation {
                viewModel.budgets = newBudgets
            }
        }
    }
}

// MARK: - Subviews

private struct HeaderView: View {
    let budget: Double
    let spent: Double
    
    var body: some View {
        HStack(spacing: 12) {
            BudgetPillView(budget: budget)
            SpentPillView(spent: spent)
        }
    }
}

private struct ButtonsView: View {
    let isScrolling: Bool
    @Binding var showAddExpenseSheet: Bool
    let viewModel: DashboardViewVM
    
    var body: some View {
        HStack(spacing: 12) {
            // Daily Report Button
            Button {
                guard !viewModel.todaysExpenses.isEmpty else { return }
                viewModel.showDailyReport = true
            } label: {
                Circle()
                    .fill(.blue)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .overlay {
                        Image(systemName: "doc.text.fill")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                    }
            }
            .buttonStyle(.bounce)
            .opacity(isScrolling ? 0.3 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isScrolling)
            
            // Add Expense Button
            Button {
                showAddExpenseSheet = true
            } label: {
                Circle()
                    .fill(.green)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                    }
            }
            .buttonStyle(.bounce)
            .opacity(isScrolling ? 0.3 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isScrolling)
        }
        .frame(maxWidth: .infinity)
        .offset(y: -25)
    }
}

private struct ExpensesListView: View {
    let expenses: [Expense]
    let onDelete: (Expense) -> Void
    let onMarkAsPaid: (Expense) -> Void
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(expenses) { expense in
                ExpenseRow(expense: expense, onDelete: onDelete, onMarkAsPaid: onMarkAsPaid)
                    .padding(.horizontal, 20)
            }
        }
    }
}

private struct ExpenseRow: View {
    let expense: Expense
    let onDelete: (Expense) -> Void
    let onMarkAsPaid: (Expense) -> Void
    @State private var showEditSheet = false
    
    var body: some View {
        Button {
            print("Tapped expense: \(expense.details)")
            showEditSheet = true
        } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.categoryColor(for: expense.category))
                    .frame(width: 4)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(expense.supplier?.name ?? "Unknown Supplier")
                            .font(.headline)
                        Text(expense.details)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(expense.amount)) IQD")
                            .font(.headline)
                            .foregroundStyle(expense.isPaid ? .green : .primary)
                        
                        Text(expense.category.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditSheet) {
            ExpenseEditingView(expense: expense)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.impactOccurred()
                withAnimation {
                    onDelete(expense)
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
                        onMarkAsPaid(expense)
                    }
                }
            } label: {
                Label(expense.isPaid ? "Paid" : "Mark as Paid", 
                      systemImage: expense.isPaid ? "checkmark.circle.fill" : "checkmark.circle")
            }
            .tint(expense.isPaid ? .gray : .green)
        }
    }
}
