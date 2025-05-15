import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityLabel("Empty state icon")
            
            Text(title)
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .transition(.opacity.combined(with: .scale))
    }
} 