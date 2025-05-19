import SwiftUI
import SwiftData
import PhotosUI
import os

struct ExpenseEditingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var expense: Expense
    @State private var originalAmount: Double
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCategoryPicker = false
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "InOffExpense", category: "ExpenseEditingView")

    init(expense: Expense) {
        self.expense = expense
        _originalAmount = State(initialValue: expense.amount)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Info") {
                    TextField("Details", text: $expense.details)
                    
                    TextField("Amount", value: $expense.amount, format: .number)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date",
                             selection: Binding<Date>(
                                get: { expense.date },
                                set: { expense.date = $0 }
                             ),
                             displayedComponents: .date)
                    
                    NavigationLink {
                        List(ExpenseCategory.allCases, id: \.self) { category in
                            Button {
                                expense.category = category
                                dismiss()
                            } label: {
                                HStack {
                                    Text(category.rawValue)
                                    Spacer()
                                    if category == expense.category {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                        .navigationTitle("Category")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(expense.category.rawValue)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let supplier = expense.supplier {
                        HStack {
                            Text("Supplier")
                            Spacer()
                            Text(supplier.name)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Photo (Optional)") {
                    if let data = expense.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    }
                    PhotosPicker(expense.photoData == nil ? "Add Photo" : "Change Photo",
                               selection: $selectedPhotoItem,
                               matching: .images)
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            if let newItem {
                                Task {
                                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                                        expense.photoData = data
                                    }
                                }
                            }
                        }
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveChanges() }
                }
            }
        }
    }

    private func saveChanges() {
        let difference = expense.amount - originalAmount
        if abs(difference) > 0.00001 {
            if let budget = try? modelContext.fetch(FetchDescriptor<Budget>()).first {
                budget.currentBudget -= difference
            }
        }

        do {
            try modelContext.save()
            NotificationCenter.default.post(name: Notification.Name("ExpenseUpdated"), object: nil)
            dismiss()
        } catch {
            logger.error("Error saving edited expense: \(error.localizedDescription)")
        }
    }
}
