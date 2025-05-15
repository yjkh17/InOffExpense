import SwiftUI
import SwiftData

struct PaymentHistoryView: View {
    @Environment(\.modelContext) private var modelContext

    // We store the Expense reference if needed, but crucially store its ID for queries.
    let expense: Expense
    private let expenseID: String

    // Query for Payment objects referencing expenseID
    @Query var payments: [Payment]

    var body: some View {
        NavigationView {
            List {
                ForEach(payments, id: \.id) { payment in
                    HStack {
                        // If you want to allow editing payment.amount:
                        TextField("",
                            value: Binding(
                                get: { payment.amount },
                                set: { newValue in
                                    payment.amount = newValue
                                    try? modelContext.save()
                                }
                            ),
                            format: .number
                        )
                        .keyboardType(.decimalPad)
                        
                        Spacer()
                        
                        Button("Delete") {
                            modelContext.delete(payment)
                            try? modelContext.save()
                        }
                    }
                }
            }
            .navigationTitle("Payment History")
        }
    }

    init(expense: Expense) {
        self.expense = expense
        self.expenseID = expense.id.uuidString
        _payments = Query(filter: #Predicate<Payment> {
            $0.expense.id.uuidString == expenseID
        })
    }
}
