
import Foundation
import CoreLocation

// MARK: - Activity Model
/// Represents a single trail running activity.
/// This struct will be used throughout the app to pass activity data.
struct Activity: Identifiable, Codable {
    let id: Int
    let name: String
    let sportType: String
    let date: Date
    let distance: Double // In meters
    let duration: TimeInterval // In seconds
    let elevationGain: Double // In meters
    
    // Advanced Metrics
    let averageHeartRate: Double?
    let averageCadence: Double?
    let averagePower: Double?
    
    // Data for Charts
    let heartRateData: [DataPoint]
    let cadenceData: [DataPoint]
    let powerData: [DataPoint]
    
    // Location Data
    let startCoordinate: CLLocationCoordinate2D?
    let polyline: String? // Encoded polyline for map view
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sportType = "sport_type"
        case date = "start_date"
        case distance
        case duration = "moving_time"
        case elevationGain = "total_elevation_gain"
        case averageHeartRate = "average_heartrate"
        case averageCadence = "average_cadence"
        case averagePower = "average_watts"
        case startCoordinate = "start_latlng"
        case polyline = "map"
    }
    
    enum MapKeys: String, CodingKey {
        case summary_polyline
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        sportType = try container.decode(String.self, forKey: .sportType)
        date = try container.decode(Date.self, forKey: .date)
        distance = try container.decode(Double.self, forKey: .distance)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        elevationGain = try container.decode(Double.self, forKey: .elevationGain)
        averageHeartRate = try container.decodeIfPresent(Double.self, forKey: .averageHeartRate)
        averageCadence = try container.decodeIfPresent(Double.self, forKey: .averageCadence)
        averagePower = try container.decodeIfPresent(Double.self, forKey: .averagePower)
        
        if let latlng = try container.decodeIfPresent([Double].self, forKey: .startCoordinate), latlng.count == 2 {
            startCoordinate = CLLocationCoordinate2D(latitude: latlng[0], longitude: latlng[1])
        } else {
            startCoordinate = nil
        }
        
        if let mapContainer = try? container.nestedContainer(keyedBy: MapKeys.self, forKey: .polyline) {
            polyline = try mapContainer.decodeIfPresent(String.self, forKey: .summary_polyline)
        } else {
            polyline = nil
        }
        
        // Initialize with empty arrays as these are not part of the Strava API response
        heartRateData = []
        cadenceData = []
        powerData = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(sportType, forKey: .sportType)
        try container.encode(date, forKey: .date)
        try container.encode(distance, forKey: .distance)
        try container.encode(duration, forKey: .duration)
        try container.encode(elevationGain, forKey: .elevationGain)
        try container.encodeIfPresent(averageHeartRate, forKey: .averageHeartRate)
        try container.encodeIfPresent(averageCadence, forKey: .averageCadence)
        try container.encodeIfPresent(averagePower, forKey: .averagePower)
        
        if let coordinate = startCoordinate {
            try container.encode([coordinate.latitude, coordinate.longitude], forKey: .startCoordinate)
        }
        
        var mapContainer = container.nestedContainer(keyedBy: MapKeys.self, forKey: .polyline)
        try mapContainer.encodeIfPresent(polyline, forKey: .summary_polyline)
    }
    
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
