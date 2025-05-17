import SwiftUI
import SwiftData
import PhotosUI

struct ExpenseLoggingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let expenseService: ExpenseServiceProtocol
    private let budgetService: BudgetServiceProtocol

    @Query private var budgets: [Budget]
    @Query private var allSuppliers: [Supplier]

    @State private var supplierName = ""
    @State private var details = ""
    @State private var amount: Double? = nil
    @State private var isPaid = true
    @State private var date = Date()
    @State private var category: ExpenseCategory = .food
    @State private var showDatePicker = false
    @FocusState private var amountFocused: Bool

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var formError: String? = nil
    @State private var showSuggestions = false

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    init(modelContext: ModelContext) {
        self.expenseService = ExpenseService(modelContext: modelContext)
        self.budgetService = BudgetService(modelContext: modelContext)
    }

    private var trimmedSupplierName: String {
        supplierName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var suggestedSuppliers: [Supplier] {
        let lower = supplierName.lowercased()
        guard !lower.isEmpty else { return [] }
        return allSuppliers
            .filter { $0.name.lowercased().contains(lower) }
            .prefix(5)
            .map { $0 }
    }
    
    private var isFormValid: Bool {
        !trimmedSupplierName.isEmpty && amount != nil && (amount ?? 0) > 0
    }

    private func updateValidation() {
        if trimmedSupplierName.isEmpty {
            formError = "Supplier name is required."
            return
        }
        guard let validAmount = amount, validAmount > 0 else {
            formError = "Amount must be greater than zero."
            return
        }
        formError = nil
    }
    
    private func getOrCreateSupplier(_ name: String) -> Supplier {
        if let existingSupplier = allSuppliers.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return existingSupplier
        }
        let newSupplier = Supplier(name: name)
        modelContext.insert(newSupplier)
        return newSupplier
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    // MARK: - Supplier Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SUPPLIER")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        TextField("Supplier", text: $supplierName)
                            .font(.title3)
                            .textInputAutocapitalization(.words)
                            .onChange(of: supplierName) { _, newValue in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    supplierName = newValue
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                        .filter { $0.isLetter || $0.isWhitespace }
                                    updateValidation()
                                    showSuggestions = !supplierName.isEmpty
                                }
                            }
                            .padding(.bottom, 4)

                        if let error = formError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.bottom, 4)
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)
                        .opacity(showSuggestions ? 0 : 1)

                    if !suggestedSuppliers.isEmpty && showSuggestions {
                        VStack(spacing: 1) {
                            ForEach(suggestedSuppliers) { supplier in
                                Button(action: {
                                    supplierName = supplier.name
                                    showSuggestions = false
                                    updateValidation()
                                }) {
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color.categoryColor(for: category))
                                            .frame(width: 4)
                                        
                                        Text(supplier.name)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                            .padding(.horizontal, 16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .frame(height: 44)
                                    }
                                    .frame(height: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .background(Color(.systemBackground))
                                .overlay(alignment: .bottom) {
                                    if supplier.id != suggestedSuppliers.last?.id {
                                        Divider()
                                            .padding(.leading, 4)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        let generator = UIImpactFeedbackGenerator(style: .rigid)
                                        generator.impactOccurred()
                                        withAnimation {
                                            modelContext.delete(supplier)
                                            try? modelContext.save()
                                            showSuggestions = false
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // MARK: - Details Section
                    VStack(spacing: 0) {
                        // Category
                        NavigationLink {
                            List(ExpenseCategory.allCases, id: \.self) { cat in
                                Button {
                                    category = cat
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(cat.rawValue)
                                        Spacer()
                                        if cat == category {
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
                                Rectangle()
                                    .fill(Color.categoryColor(for: category))
                                    .frame(width: 4, height: 44)
                                
                                HStack {
                                    Text("Category")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(category.rawValue)
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "chevron.right")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .padding(.leading, 4)
                        
                        // Details
                        TextField("Details", text: $details)
                            .font(.title3)
                            .padding(.horizontal)
                            .frame(height: 44)
                        
                        Divider()
                            .padding(.leading, 4)
                        
                        // Amount
                        HStack {
                            TextField("Amount", value: $amount, format: .number)
                                .keyboardType(.decimalPad)
                                .focused($amountFocused)
                                .onChange(of: amount) { _, _ in updateValidation() }
                                .font(.title3)
                            Spacer()
                            Text("IQD")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .frame(height: 44)
                        
                        Divider()
                            .padding(.leading, 4)
                        
                        // Paid Toggle
                        HStack {
                            HStack {
                                Text("Paid")
                                if isPaid {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            Spacer()
                            Toggle("", isOn: $isPaid)
                        }
                        .padding(.horizontal)
                        .frame(height: 44)
                        
                        Divider()
                            .padding(.leading, 4)
                        
                        // Date
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            HStack {
                                Text("Date")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(dateFormatter.string(from: date))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .frame(height: 44)
                        }
                        .sheet(isPresented: $showDatePicker) {
                            NavigationStack {
                                DatePicker("Select Date", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .navigationTitle("Select Date")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .toolbar {
                                        ToolbarItem(placement: .confirmationAction) {
                                            Button("Done") {
                                                showDatePicker = false
                                            }
                                        }
                                    }
                            }
                            .presentationDetents([.height(400)])
                        }
                    }
                    .background(Color(.systemBackground))
                    
                    // MARK: - Photo Section
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                    }
                    
                    PhotosPicker("Select Photo", selection: $selectedPhotoItem, matching: .images)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImage = uiImage
                                }
                            }
                        }
                }
                .padding(.vertical)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            guard isFormValid, let validAmount = amount else { return }
                            let supplierToUse = getOrCreateSupplier(trimmedSupplierName)
                            
                            do {
                                if isPaid, let budget = try budgetService.getCurrentBudget() {
                                    budget.currentBudget -= validAmount
                                    try budgetService.updateBudget(budget)
                                }
                                
                                let newExpense = Expense(
                                    details: details,
                                    date: date,
                                    amount: validAmount,
                                    isPaid: isPaid,
                                    category: category
                                )
                                newExpense.supplier = supplierToUse
                                
                                if let selectedImage {
                                    newExpense.photoData = selectedImage.jpegData(compressionQuality: 0.8)
                                }
                                
                                try expenseService.createExpense(newExpense)
                                dismiss()
                            } catch {
                                formError = "Failed to save: \(error.localizedDescription)"
                            }
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .task { updateValidation() }
        }
    }
}
