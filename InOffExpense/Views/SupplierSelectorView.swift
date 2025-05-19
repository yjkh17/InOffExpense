import SwiftUI
import SwiftData

struct SupplierSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query var suppliers: [Supplier]

    // Callback for when a supplier is chosen
    var onSupplierChosen: (Supplier) -> Void
    
    @State private var newSupplierName: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Choose Existing Supplier") {
                    ForEach(suppliers) { supplier in
                        Button {
                            onSupplierChosen(supplier)
                            dismiss()
                        } label: {
                            Text(supplier.name)
                        }
                    }
                }
                Section("Add New Supplier") {
                    TextField("New Supplier Name", text: $newSupplierName)
                    Button("Create") {
                        createSupplier()
                    }
                }
            }
            .navigationTitle("Select Supplier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func createSupplier() {
        guard !newSupplierName.isEmpty else { return }
        let newSup = Supplier(name: newSupplierName)
        modelContext.insert(newSup)
        try? modelContext.save()

        onSupplierChosen(newSup)
        dismiss()
    }
}
