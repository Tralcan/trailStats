import Foundation
import CoreLocation

// MARK: - Activity Model
/// Represents a single trail running activity.
/// This struct will be used throughout the app to pass activity data.
struct Activity: Identifiable, Codable {
    var id: Int
    var name: String
    var sportType: String
    var date: Date
    var distance: Double // In meters
    var duration: TimeInterval // In seconds
    var elevationGain: Double // In meters
    
    // Advanced Metrics from Strava
    var averageHeartRate: Double?
    var averageCadence: Double?
    var averagePower: Double?
    var gradeAdjustedPace: Double?
    
    // HealthKit Running Dynamics
    var verticalOscillation: Double?
    var groundContactTime: Double?
    var strideLength: Double?
    var verticalRatio: Double?
    
    // User-provided
    var rpe: Double?
    var notes: String?
    
    // Location Data
    var startCoordinate: CLLocationCoordinate2D?
    var polyline: String? // Encoded polyline for map view
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sportType = "sport_type"
        case date = "start_date"
        case distance
        case duration = "moving_time"
        case elapsedTime = "elapsed_time"
        case elevationGain = "total_elevation_gain"
        case averageHeartRate = "average_heartrate"
        case averageCadence = "average_cadence"
        case averagePower = "average_watts"
        case startCoordinate = "start_latlng"
        case polyline = "map"
        case gradeAdjustedPace = "grade_adjusted_pace"
        // HealthKit properties
        case verticalOscillation
        case groundContactTime
        case strideLength
        case verticalRatio
        case rpe
        case notes
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
        gradeAdjustedPace = try container.decodeIfPresent(Double.self, forKey: .gradeAdjustedPace)
        
        // HealthKit properties (for cache decoding)
        verticalOscillation = try container.decodeIfPresent(Double.self, forKey: .verticalOscillation)
        groundContactTime = try container.decodeIfPresent(Double.self, forKey: .groundContactTime)
        strideLength = try container.decodeIfPresent(Double.self, forKey: .strideLength)
        verticalRatio = try container.decodeIfPresent(Double.self, forKey: .verticalRatio)
        rpe = try container.decodeIfPresent(Double.self, forKey: .rpe)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
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
        try container.encodeIfPresent(gradeAdjustedPace, forKey: .gradeAdjustedPace)
        
        // HealthKit properties (for cache encoding)
        try container.encodeIfPresent(verticalOscillation, forKey: .verticalOscillation)
        try container.encodeIfPresent(groundContactTime, forKey: .groundContactTime)
        try container.encodeIfPresent(strideLength, forKey: .strideLength)
        try container.encodeIfPresent(verticalRatio, forKey: .verticalRatio)
        try container.encodeIfPresent(rpe, forKey: .rpe)
        try container.encodeIfPresent(notes, forKey: .notes)
        
        if let coordinate = startCoordinate {
            try container.encode([coordinate.latitude, coordinate.longitude], forKey: .startCoordinate)
        }
        
        var mapContainer = container.nestedContainer(keyedBy: MapKeys.self, forKey: .polyline)
        try mapContainer.encodeIfPresent(polyline, forKey: .summary_polyline)
    }
}