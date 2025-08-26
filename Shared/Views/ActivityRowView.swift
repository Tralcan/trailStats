
import SwiftUI

/// A reusable view that displays a summary of a single activity.
/// Used in the `DashboardView` list.
struct ActivityRowView: View {
    let activity: Activity
    let isCached: Bool
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(activity.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(dateFormatter.string(from: activity.date))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 15) {
                    // Distance
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.red)
                        Text(String(format: "%.2f km", activity.distance / 1000))
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    // Elevation
                    HStack(spacing: 4) {
                        Image(systemName: "mountain.2")
                            .foregroundColor(.green)
                        Text(String(format: "%.0f m", activity.elevationGain))
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "hourglass")
                            .foregroundColor(.blue)
                        Text(Int(activity.duration).toHoursMinutesSeconds())
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            Circle()
                .fill(isCached ? .green : .red)
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}


