import SwiftUI

struct DailyReportView: View {
    let date: Date
    let expenses: [Expense]
    let onDismiss: () -> Void
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var paidExpenses: [Expense] {
        expenses.filter(\.isPaid)
    }
    
    private var unpaidExpenses: [Expense] {
        expenses.filter { !$0.isPaid }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 12) {
                        Text(formattedDate)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(totalAmount)) IQD")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.blue)
                        
                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Text("\(paidExpenses.count)")
                                    .font(.title3.bold())
                                    .foregroundStyle(.green)
                                Text("Paid")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Divider()
                                .frame(height: 24)
                            
                            VStack(spacing: 4) {
                                Text("\(unpaidExpenses.count)")
                                    .font(.title3.bold())
                                    .foregroundStyle(.red)
                                Text("Unpaid")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
                    
                    // Expenses List
                    LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                        // Paid Expenses
                        if !paidExpenses.isEmpty {
                            Section {
                                ForEach(paidExpenses) { expense in
                                    ExpenseRow(expense: expense)
                                }
                            } header: {
                                SectionHeader(title: "Paid", count: paidExpenses.count)
                            }
                        }
                        
                        // Unpaid Expenses
                        if !unpaidExpenses.isEmpty {
                            Section {
                                ForEach(unpaidExpenses) { expense in
                                    ExpenseRow(expense: expense)
                                }
                            } header: {
                                SectionHeader(title: "Unpaid", count: unpaidExpenses.count)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Daily Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

private struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
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
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }
}

private struct SectionHeader: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Text("(\(count))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
}
