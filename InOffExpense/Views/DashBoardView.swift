#if canImport(Charts)
import Charts
#endif
import SwiftUI
import SwiftData

// MARK: - UIImage Extension for Cropping to a 3:4 Portrait Ratio
/// UIImage extension providing image utility methods.
extension UIImage {
    /// Crops the image to a 3:4 portrait aspect ratio, centering the crop rect.
    func cropToPortrait() -> UIImage? {
        let targetAspect: CGFloat = 3.0 / 4.0
        let imageAspect = size.width / size.height
        let cropRect: CGRect
        
        if imageAspect > targetAspect {
            let newWidth = size.height * targetAspect
            let xOffset = (size.width - newWidth) / 2.0
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: size.height)
        } else {
            let newHeight = size.width / targetAspect
            let yOffset = (size.height - newHeight) / 2.0
            cropRect = CGRect(x: 0, y: yOffset, width: size.width, height: newHeight)
        }
        
        guard let cgImage = self.cgImage?.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
}



// MARK: - Deleted Expense Record (for Undo)
private struct DeletedExpenseRecord {
    let expense: Expense
    let wasPaid: Bool
    let budgetBeforeDelete: Double
}

// MARK: - DashboardViewModel (Business Logic)
/// ViewModel that manages budget and expense data for the dashboard.
@MainActor final class DashboardViewModel: ObservableObject {
    // Published properties for binding with the view
    @Published var searchText: String = ""
    @Published var showChart: Bool = false
    @Published var editingExpense: Expense?
    @Published var displayedExpenses: [Expense] = []
    @Published var displayedBudget: Double = 0.0
    @Published var showTopUpNotification: Bool = false
    @Published var showUndoBanner: Bool = false
    @Published var showFullScreenPhoto: Bool = false
    @Published var fullScreenPhoto: UIImage? = nil
    @Published var selectedCategory: ExpenseCategory?
    @Published var dateRange: Date = Date()

    private static let dateFilterFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // Data collections
    var budgets: [Budget] = []
    var allExpenses: [Expense] = []
    
    // Reference to ModelContext and persistent storage info
    var modelContext: ModelContext?
    var lastDailyTopUpDate: Date?
    
    // Constants
    let dailyTopUpAmount = 1_000_000.0
    let batchSize = 20
    
    // Stack for undo operations
    private var undoStack: [DeletedExpenseRecord] = []
    
    // Computed property for today's spent amount
    var dailySpent: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return allExpenses
            .filter { $0.isPaid && Calendar.current.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.amount }
    }
    
    // Filtered expenses based on search query
    var filteredExpenses: [Expense] {
        let lower = searchText.lowercased()
        guard !lower.isEmpty else { return allExpenses }
        let lookingForPaid = lower.contains("paid")
        let lookingForUnpaid = lower.contains("unpaid")
        return allExpenses.filter { expense in
            let detailsMatch = expense.details.lowercased().contains(lower)
            let supplierMatch = (expense.supplier?.name.lowercased() ?? "").contains(lower)
            let dateMatch = Self.dateFilterFormatter.string(from: expense.date).lowercased().contains(lower)
            let amountMatch = String(format: "%.2f", expense.amount).lowercased().contains(lower)
            let paidMatch: Bool = {
                if lookingForPaid && expense.isPaid { return true }
                if lookingForUnpaid && !expense.isPaid { return true }
                return false
            }()
            return detailsMatch || supplierMatch || dateMatch || amountMatch || paidMatch
        }
    }
    
    // MARK: - Business Logic Methods
    
    /// Creates a default budget record if none exists.
    func createDefaultBudgetIfNeeded() {
        guard budgets.isEmpty, let context = modelContext else { return }
        let defaultBudget = Budget(currentBudget: 1_000_000)
        context.insert(defaultBudget)
        do {
            try context.save()
            budgets.append(defaultBudget)
        } catch {
            print("Error saving default budget: \(error)")
        }
    }
    
    /// Tops up the daily budget by a fixed amount and shows a notification.
    func topUpBudgetDaily() {
        guard let context = modelContext, let budget = budgets.first else { return }
        let now = Date()
        if let lastTopUp = lastDailyTopUpDate, Calendar.current.isDate(lastTopUp, inSameDayAs: now) {
            return
        }
        withAnimation(.spring()) {
            budget.currentBudget += dailyTopUpAmount
            displayedBudget = budget.currentBudget
        }
        do {
            try context.save()
            lastDailyTopUpDate = now
            showTopUpNotification = true
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation(.spring()) {
                    self?.showTopUpNotification = false
                }
            }
        } catch {
            print("Error topping up budget: \(error)")
        }
    }
    
    /// Loads the first batch of filtered expenses into view.
    func loadInitialExpenses() {
        let allFiltered = filteredExpenses
        displayedExpenses = Array(allFiltered.prefix(batchSize))
    }
    
    /// Appends more expenses when the user scrolls to the last item.
    func loadMoreIfNeeded(currentExpense: Expense) {
        guard let last = displayedExpenses.last else { return }
        if currentExpense.id == last.id {
            let allFiltered = filteredExpenses
            let nextIndex = displayedExpenses.count
            let nextBatch = allFiltered.dropFirst(nextIndex).prefix(batchSize)
            displayedExpenses.append(contentsOf: nextBatch)
        }
    }
    
    /// Deletes an expense, updates budget if paid, and pushes undo record.
    func deleteExpense(_ expense: Expense) {
        guard let context = modelContext, let budget = budgets.first else { return }
        let wasPaid = expense.isPaid
        let currentBudget = budget.currentBudget
        
        if expense.isPaid {
            withAnimation(.spring()) {
                budget.currentBudget += expense.amount
                displayedBudget = budget.currentBudget
            }
        }
        context.delete(expense)
        do {
            try context.save()
            let record = DeletedExpenseRecord(expense: expense, wasPaid: wasPaid, budgetBeforeDelete: currentBudget)
            undoStack.append(record)
            showUndoBanner = true
        } catch {
            print("Error deleting expense: \(error)")
        }
    }
    
    /// Restores the last deleted expense and reverts budget changes.
    func undoLastDelete() {
        guard let record = undoStack.popLast(), let context = modelContext, let budget = budgets.first else { return }
        if record.wasPaid {
            withAnimation(.spring()) {
                budget.currentBudget = record.budgetBeforeDelete
                displayedBudget = budget.currentBudget
            }
        }
        context.insert(record.expense)
        do {
            try context.save()
            loadInitialExpenses()
        } catch {
            print("Error undoing delete: \(error)")
        }
    }
    
    /// Marks an expense as paid, deducts amount from budget, and saves context.
    func markAsPaid(_ expense: Expense) {
        guard let context = modelContext, let budget = budgets.first else {
            expense.isPaid = true
            return
        }
        withAnimation(.spring()) {
            expense.isPaid = true
            budget.currentBudget -= expense.amount
            displayedBudget = budget.currentBudget
        }
        do {
            try context.save()
        } catch {
            print("Error marking as paid: \(error)")
        }
    }
    
    func saveExpense(_ expense: Expense) {
        guard let context = modelContext else { return }
        context.insert(expense)
        do {
            try context.save()
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // Update displayed expenses
            loadInitialExpenses()
        } catch {
            print("Error saving expense: \(error)")
        }
    }
}

// MARK: - DashboardView
/// Main SwiftUI view displaying budget pills, expense list, and charts.
private enum SidebarItem: Hashable {
    case dashboard, statistics
}

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext
    @Namespace private var animation
    @State private var selection: SidebarItem? = .dashboard
    @State private var showAddExpenseSheet = false
    
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
            .navigationTitle("In Off Expense")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddExpenseSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            switch selection {
            case .dashboard, .none:
                ScrollView {
                    VStack(spacing: 20) {
                        // Weekly Spend Chart
                        if !viewModel.displayedExpenses.isEmpty {
                            WeeklySpendChart(dailyTotals: calculateWeeklyTotals())
                                .padding(.horizontal)
                        }
                        
                        // Quick Filters
                        HStack {
                            Picker("Category", selection: $viewModel.selectedCategory) {
                                Text("All Categories").tag(Optional<ExpenseCategory>.none)
                                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                    Text(category.rawValue).tag(Optional(category))
                                }
                            }
                            .pickerStyle(.menu)
                            
                            DatePicker("Date", selection: $viewModel.dateRange, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .padding(.horizontal)
                        
                        // Expense List
                        if viewModel.displayedExpenses.isEmpty {
                            EmptyStateView(
                                title: "No expenses yet",
                                subtitle: "Tap the + button to add your first expense",
                                systemImage: "tray.fill"
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.displayedExpenses) { expense in
                                    ExpenseCard(expense: expense, namespace: animation)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                viewModel.editingExpense = expense
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            case .statistics:
                StatisticsView()
            }
        }
        .sheet(isPresented: $showAddExpenseSheet) {
            ExpenseLoggingView()
                .modelContainer(modelContext.container)
        }
        .task {
            viewModel.modelContext = modelContext
            do {
                viewModel.budgets = try modelContext.fetch(FetchDescriptor<Budget>())
                viewModel.allExpenses = try modelContext.fetch(FetchDescriptor<Expense>())
                viewModel.createDefaultBudgetIfNeeded()
                viewModel.loadInitialExpenses()
            } catch {
                print("Dashboard init fetch error: \(error)")
            }
        }
    }
    
    private func calculateWeeklyTotals() -> [WeeklySpendChart.DailyTotal] {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(byAdding: .day, value: -7, to: today)!
        
        var dailyTotals: [Date: Double] = [:]
        
        for expense in viewModel.displayedExpenses {
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
    let namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            // Category Color Stripe
            Rectangle()
                .fill(Color.categoryColor(for: expense.category))
                .frame(width: 4)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.details)
                        .font(.headline)
                    
                    if let supplier = expense.supplier {
                        Text(supplier.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(expense.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.0f IQD", expense.amount))
                        .font(.headline)
                    
                    Image(systemName: expense.isPaid ? "checkmark.seal.fill" : "xmark.seal")
                        .foregroundStyle(expense.isPaid ? Color.paidStatus : Color.unpaidStatus)
                        .accessibilityLabel(expense.isPaid ? "Paid" : "Unpaid")
                }
            }
            .padding()
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.12), radius: 2, y: 2)
    }
}

// MARK: - Full Screen Image View
struct FullScreenImageView: View {
    var image: UIImage?
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .onTapGesture { onDismiss() }
    }
}

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var container: ModelContainer = {
        let container = try! ModelContainer(for: Schema([Budget.self, Expense.self]))
        let context = container.mainContext
        let budget = Budget(currentBudget: 1_000_000)
        context.insert(budget)
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let expense1 = Expense(details: "Coffee", date: today, amount: 3000, isPaid: true)
        let expense2 = Expense(details: "Lunch", date: today, amount: 8000, isPaid: true)
        let expense3 = Expense(details: "Dinner", date: yesterday, amount: 12000, isPaid: false)
        context.insert(expense1)
        context.insert(expense2)
        context.insert(expense3)
        try? context.save()
        return container
    }()
    
    static var previews: some View {
        Group {
            DashboardView()
                .modelContainer(container)
                .previewDevice("iPhone 14 Pro")
                .previewDisplayName("Dashboard - Light Mode")
            DashboardView()
                .modelContainer(container)
                .preferredColorScheme(.dark)
                .previewDevice("iPhone 14 Pro")
                .previewDisplayName("Dashboard - Dark Mode")
        }
    }
}
#endif
