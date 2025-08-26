import Foundation

/// Represents performance metrics for a specific grade bucket.
struct PerformanceByGrade: Identifiable {
    let id = UUID()
    let gradeBucket: String
    let distance: Double
    let time: TimeInterval
    let elevation: Double
    let weightedCadenceSum: Double
    let timeWithCadence: TimeInterval
    
    var averagePace: Double {
        guard distance > 0, time > 0 else { return 0 }
        return (time / 60.0) / (distance / 1000.0)
    }
    
    var verticalSpeed: Double? {
        guard elevation > 0, time > 0 else { return nil }
        let timeInHours = time / 3600.0
        return elevation / timeInHours
    }
    
    var averageCadence: Double? {
        guard timeWithCadence > 0 else { return nil }
        return weightedCadenceSum / timeWithCadence
    }
}
