
import Foundation
import CoreLocation

// MARK: - MockDataService
/// A service to generate mock `Activity` data for UI development and testing.
/// This helps in building the UI without needing a live connection to Strava.
class MockDataService {
    
    static func generateActivities() -> [Activity] {
        var activities: [Activity] = []
        
        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: -i * 3, to: Date())!
            let distance = Double.random(in: 5000...21000) // 5k to 21k
            let duration = distance / Double.random(in: 2.5...4.5) // m/s
            let elevation = Double.random(in: 200...1100)
            
            let activity = Activity(
                id: UUID(),
                name: "Trail Run - Sierra de Guadarrama \(i+1)",
                date: date,
                distance: distance,
                duration: duration,
                elevationGain: elevation,
                averageHeartRate: Int.random(in: 135...165),
                averageCadence: Int.random(in: 165...180),
                averagePower: Int.random(in: 280...350),
                heartRateData: generateDataPoints(count: 100, range: 120...170),
                cadenceData: generateDataPoints(count: 100, range: 160...185),
                powerData: generateDataPoints(count: 100, range: 250...400),
                startCoordinate: CLLocationCoordinate2D(latitude: 40.78, longitude: -3.98),
                polyline: "some_encoded_polyline_string"
            )
            activities.append(activity)
        }
        return activities
    }
    
    /// Generates a series of data points for charts.
    private static func generateDataPoints(count: Int, range: ClosedRange<Double>) -> [DataPoint] {
        var dataPoints: [DataPoint] = []
        for i in 0..<count {
            let value = Double.random(in: range)
            dataPoints.append(DataPoint(time: Double(i), value: value))
        }
        return dataPoints
    }
}
