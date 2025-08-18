
import SwiftUI

/// A reusable view that displays a summary of a single activity.
/// Used in the `DashboardView` list.
struct ActivityRowView: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text(activity.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(activity.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text(activity.formattedDistance)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(activity.formattedElevation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ActivityRowView(activity: MockDataService.generateActivities().first!)
        .padding()
}
