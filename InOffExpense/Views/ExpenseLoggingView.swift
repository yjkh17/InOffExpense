import SwiftUI
import SwiftData
import PhotosUI

struct ExpenseLoggingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var budgets: [Budget]
    @Query private var allSuppliers: [Supplier]

    @State private var supplierName = ""
    @State private var details = ""
    @State private var amount: Double? = nil
    @State private var isPaid = true
    @State private var date = Date()
    @FocusState private var amountFocused: Bool

    @State private var isPresentingCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil

    @State private var formError: String? = nil
    @State private var showSuggestions = false
    @State private var showCustomCamera = false

    private var trimmedSupplierName: String {
        supplierName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack {
                    Form {
                        Section("Supplier (Required)") {
                            TextField("Supplier", text: $supplierName)
                                .onChange(of: supplierName) { _oldValue, newValue in
                                    // Keep only letters and spaces, and trim whitespace.
                                    supplierName = newValue
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                        .filter { $0.isLetter || $0.isWhitespace }
                                    updateValidation()
                                    showSuggestions = !supplierName.isEmpty
                                }
                                .onTapGesture {
                                    if !supplierName.isEmpty { showSuggestions = true }
                                }
                            
                            if showSuggestions && !suggestedSuppliers.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Suggested Suppliers")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 4)
                                    ForEach(suggestedSuppliers) { sup in
                                        HStack {
                                            Text(sup.name)
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            supplierName = sup.name
                                            formError = nil
                                            showSuggestions = false
                                        }
                                        Divider()
                                    }
                                }
                                .transition(.opacity)
                            }
                        }

                        Section("Expense Info") {
                            TextField("Details (Optional)", text: $details)
                            TextField("Amount", value: $amount, format: .number)
                                .keyboardType(.decimalPad)
                                .focused($amountFocused)
                                .onChange(of: amount) { _oldValue, _newValue in
                                    updateValidation()
                                }
                            
                            Toggle("Paid?", isOn: $isPaid)
                                .onChange(of: isPaid) { _oldValue, _newValue in
                                    updateValidation()
                                }
                            
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                        }

                        Section("Photo (Optional)") {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                            }
                            PhotosPicker("Select Photo", selection: $selectedPhotoItem, matching: .images)
                            .onChange(of: selectedPhotoItem) { _oldItem, newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            selectedImage = uiImage
                                        }
                                    }
                                }
                            
                            Button("Take Photo") {
                                guard !isPresentingCamera else { return }
                                showCustomCamera = true
                                isPresentingCamera = true
                            }
                        }
                        .disabled(isPresentingCamera)

                        if let error = formError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
                .navigationTitle("Add Expense")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            withAnimation(.easeInOut) {
                                handleDismiss()
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            Task {
                                // Check that the form is valid and amount is available.
                                if isFormValid, let validAmount = amount {
                                    let trimmedSupplier = trimmedSupplierName
                                    let supplierToUse = getOrCreateSupplier(trimmedSupplier)
                                    
                                    // Adjust the budget if the expense is paid.
                                    if isPaid, let budget = budgets.first {
                                        budget.currentBudget -= validAmount
                                    }
                                    
                                    // Create the new expense.
                                    let newExpense = Expense(details: details, date: date, amount: validAmount, isPaid: isPaid)
                                    newExpense.supplier = supplierToUse
                                    
                                    if let selectedImage {
                                        newExpense.photoData = selectedImage.jpegData(compressionQuality: 0.8)
                                    }
                                    
                                    modelContext.insert(newExpense)
                                    do {
                                        // Use await if save is asynchronous.
                                        try modelContext.save()
                                    } catch {
                                        DispatchQueue.main.async {
                                            formError = "Failed to save the expense. Please try again: \(error.localizedDescription)"
                                        }
                                        print("Save error: \(error)")
                                    }
                                    // Dismiss the view after saving.
                                    DispatchQueue.main.async {
                                        handleDismiss()
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        handleDismiss()
                                    }
                                }
                            }
                        }
                        .disabled(!isFormValid)
                    }
                }
            }
            .task { updateValidation() }
        }
    }

    // MARK: - Supplier Suggestions
    private var suggestedSuppliers: [Supplier] {
        let lower = supplierName.lowercased()
        guard !lower.isEmpty else { return [] }
        let filteredSuppliers = allSuppliers.filter {
            $0.name.lowercased().contains(lower)
        }
        return Array(filteredSuppliers.prefix(10))
    }

    // MARK: - Validation
    private func updateValidation() {
        if trimmedSupplierName.isEmpty {
            formError = "Supplier name is required and cannot contain only whitespace."
            return
        }
        guard let validAmount = amount, validAmount > 0 else {
            formError = "Amount must be greater than zero."
            return
        }
        formError = nil
    }

    private var isFormValid: Bool {
        formError == nil
    }

    // MARK: - Saving Helper
    private func performSave() {
        // Now handled within the Task in the Save button.
    }

    private func getOrCreateSupplier(_ name: String) -> Supplier {
        if let existingSupplier = allSuppliers.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return existingSupplier
        } else {
            let newSupplier = Supplier(name: name)
            modelContext.insert(newSupplier)
            return newSupplier
        }
    }

    // MARK: - Budget Adjustments
    private func handleBudgetAdjustment(amount: Double) {
        // Now handled within the Task in the Save button.
    }

    private func handleDismiss() {
        dismiss()
    }
}
