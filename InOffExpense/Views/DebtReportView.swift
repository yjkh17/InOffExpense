#if canImport(Charts)
import Charts
#endif
import SwiftUI
import SwiftData

enum DebtViewMode: String, CaseIterable {
    case list = "List"
    case chart = "Chart"
}

struct DebtReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var viewMode: DebtViewMode = .list
    @Query(filter: #Predicate<Expense> { $0.isPaid == false }) var unpaidExpenses: [Expense]
    private let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                VStack {
                    DebtPillView(debt: overallDebt)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(DebtViewMode.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    if filteredUnpaidExpenses.isEmpty {
                        Text("No suppliers have unpaid (debt) expenses.")
                            .font(.subheadline)
                            .padding()
                        Spacer()
                    } else {
                        switch viewMode {
                        case .list:
                            debtListView
                        case .chart:
                            #if canImport(Charts)
                            chartView
                            #else
                            debtListView
                            #endif
                        }
                    }
                }
            }
            .navigationTitle("Debt Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        withAnimation(.interactiveSpring()) {
                            dismiss()
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Suppliers")
        .onAppear {
            withAnimation(.spring(
                response: 0.6,
                dampingFraction: 0.8,
                blendDuration: 0.1
            )) {
            }
        }
    }

    private var debtListView: some View {
        let suppliersWithDebt = distinctSuppliers(from: filteredUnpaidExpenses)
        return List {
            ForEach(suppliersWithDebt, id: \.self) { supplier in
                let supplierTotal = totalDebtForSupplier(supplier, in: filteredUnpaidExpenses)
                NavigationLink {
                    SupplierDebtDetailView(supplier: supplier)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } label: {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                supplierTotal > 500
                                ? Color.red.opacity(0.1)
                                : Color(.systemBackground)
                            )
                            .shadow(radius: 2)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(supplier.name)
                                .font(.headline)
                            Text("Debt: \(supplierTotal, format: .number)")
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                        .padding()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.inset)
        .transition(.slide)
        .animation(.interactiveSpring(), value: filteredUnpaidExpenses.count)
    }

    #if canImport(Charts)
    private var chartView: some View {
        let chartData = chartDataForSuppliers
        return ScrollView {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 2, y: 2)
                    Chart {
                        ForEach(chartData) { dataPoint in
                            BarMark(
                                x: .value("Debt", dataPoint.amount),
                                y: .value("Supplier", dataPoint.name)
                            )
                            .foregroundStyle(
                                dataPoint.amount > 500 ? Color.red : Color.blue
                            )
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .padding()
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .transition(.slide)
    }
    #endif

    private var filteredUnpaidExpenses: [Expense] {
        let lower = searchText.lowercased()
        if lower.isEmpty {
            return unpaidExpenses
        } else {
            return unpaidExpenses.filter {
                if let s = $0.supplier {
                    return s.name.lowercased().contains(lower)
                }
                return false
            }
        }
    }

    private var overallDebt: Double {
        filteredUnpaidExpenses.reduce(0) { $0 + $1.amount }
    }

    private func distinctSuppliers(from expenses: [Expense]) -> [Supplier] {
        let allSuppliers = expenses.compactMap { $0.supplier }
        let uniqueSet = Set(allSuppliers)
        return Array(uniqueSet)
    }

    private func totalDebtForSupplier(_ supplier: Supplier, in expenses: [Expense]) -> Double {
        expenses
            .filter { $0.supplier?.id == supplier.id }
            .reduce(0) { $0 + $1.amount }
    }

    #if canImport(Charts)
    struct SupplierDebtData: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
    }

    private var chartDataForSuppliers: [SupplierDebtData] {
        let suppliers = distinctSuppliers(from: filteredUnpaidExpenses)
        return suppliers.map {
            SupplierDebtData(
                name: $0.name,
                amount: totalDebtForSupplier($0, in: filteredUnpaidExpenses)
            )
        }
    }
    #endif
    
}

