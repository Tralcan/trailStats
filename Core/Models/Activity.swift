
import Foundation
import CoreLocation

// MARK: - Activity Model
/// Represents a single trail running activity.
/// This struct will be used throughout the app to pass activity data.
struct Activity: Identifiable {
    let id: UUID
    let name: String
    let date: Date
    let distance: Double // In meters
    let duration: TimeInterval // In seconds
    let elevationGain: Double // In meters
    
    // Advanced Metrics
    let averageHeartRate: Int?
    let averageCadence: Int?
    let averagePower: Int?
    
    // Data for Charts
    let heartRateData: [DataPoint]
    let cadenceData: [DataPoint]
    let powerData: [DataPoint]
    
    // Location Data
    let startCoordinate: CLLocationCoordinate2D?
    let polyline: String? // Encoded polyline for map view
    
    // Formatted Properties for UI
    var formattedDistance: String {
        return String(format: "%.2f km", distance / 1000)
    }
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    var formattedElevation: String {
        return String(format: "%.0f m", elevationGain)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
