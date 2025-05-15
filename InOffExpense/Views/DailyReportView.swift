import SwiftUI

struct DailyReportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("Daily Report Coming Soon!")
                    .font(.title)
                    .padding()
                Spacer()
            }
            .navigationTitle("Daily Report")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
