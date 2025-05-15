import SwiftUI
import SwiftData

struct SupplierDebtDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Query var allExpenses: [Expense]
    @Query var budgets: [Budget] // Fetch budgets to update

    let supplier: Supplier

    var body: some View {
        List {
            let myUnpaid = allExpenses.filter { $0.isPaid == false && $0.supplier?.id == supplier.id }

            if myUnpaid.isEmpty {
                Text("No unpaid expenses for this supplier.")
            } else {
                ForEach(myUnpaid) { expense in
                    HStack {
                        Text(expense.details)
                        Spacer()
                        Text("\(expense.amount, format: .number)")
                            .foregroundColor(.red)
                    }
                    .swipeActions {
                        Button("Mark Paid") {
                            markAsPaid(expense)
                        }
                        .tint(.green)
                    }
                }
            }
        }
        .navigationTitle(supplier.name)
    }

    private func markAsPaid(_ expense: Expense) {
        expense.isPaid = true
        // Subtract from the first budget.
        if let budget = budgets.first {
            budget.currentBudget -= expense.amount
        }
        try? modelContext.save()
    }
}
