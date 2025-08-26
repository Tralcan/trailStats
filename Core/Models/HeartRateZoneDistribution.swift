import Foundation

/// Represents the distribution of time spent in different heart rate zones during an activity.
struct HeartRateZoneDistribution: Codable {
    let timeInZone1: TimeInterval
    let timeInZone2: TimeInterval
    let timeInZone3: TimeInterval
    let timeInZone4: TimeInterval
    let timeInZone5: TimeInterval
    
    var totalTime: TimeInterval {
        timeInZone1 + timeInZone2 + timeInZone3 + timeInZone4 + timeInZone5
    }
}
