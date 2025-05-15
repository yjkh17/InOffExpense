import SwiftUI
import SwiftData


// MARK: - ContentView
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Query your Item objects
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            // Master (sidebar) list
            List {
                ForEach(items) { item in
                    // HStack for left + spacer + right
                    HStack {
                        // Left: date/time
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        
                        Spacer()
                        
                        // Right: amount
                        Text("\(item.amount, format: .number.precision(.fractionLength(2)))")
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Items")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    // MARK: - Add Item
    private func addItem() {
        withAnimation {
            // For demonstration, create a random amount
            let randomAmount = Double.random(in: 5...100)
            let newItem = Item(timestamp: Date(), amount: randomAmount)
            
            modelContext.insert(newItem)
            // No need to call modelContext.save() manually, SwiftData
            // will track it. If you want explicit saving, you can do:
            // try? modelContext.save()
        }
    }

    // MARK: - Delete Items
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
            // Optionally: try? modelContext.save()
        }
    }
}

// MARK: - Preview
#Preview {
    // Provide in-memory storage for quick testing
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
