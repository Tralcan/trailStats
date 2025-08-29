
import SwiftUI

/// Data model for the KPI popover info view
struct KpiInfo: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
}

struct KpiInfoPopoverView: View {
    let info: KpiInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(info.title)
                .font(.headline)
                .foregroundColor(.white)
            Text(info.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 20)
        .padding()
    }
}
