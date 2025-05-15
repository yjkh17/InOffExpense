import SwiftUI
import SwiftData
import PhotosUI

struct ExpenseEditingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var expense: Expense

    @State private var originalAmount: Double
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(expense: Expense) {
        self.expense = expense
        _originalAmount = State(initialValue: expense.amount)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Info")) {
                    TextField("Details", text: $expense.details)
                    TextField("Amount", value: $expense.amount, format: .number)
                        .keyboardType(.decimalPad)
                    
                    // Custom binding for the date
                    DatePicker("Date",
                               selection: Binding<Date>(
                                   get: { expense.date },
                                   set: { expense.date = $0 }
                               ),
                               displayedComponents: .date)
                }
                
                Section(header: Text("Photo (Optional)")) {
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
                            guard let newItem = newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self) {
                                    expense.photoData = data
                                }
                            }
                        }
                }
            }
            .navigationTitle("Edit Expense")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveChanges() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
            // Post notification so the dashboard updates immediately.
            NotificationCenter.default.post(name: Notification.Name("ExpenseUpdated"), object: nil)
            dismiss()
        } catch {
            print("Error saving edited expense: \(error)")
        }
    }
}
