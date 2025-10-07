import Foundation

struct ActivitySummary: Codable {
    let activityId: Int
    let date: Date
    let distance: Double
    let elevation: Double
    let duration: Double
    let averageHeartRate: Double?
    let averagePower: Double?
    let averagePace: Double?
    let averageCadence: Double?
    let averageStrideLength: Double?
    // Puedes agregar más campos según lo que quieras mostrar

    static func placeholder() -> ActivitySummary {
        return ActivitySummary(
            activityId: 0,
            date: Date(),
            distance: 21097, // Media maratón en metros
            elevation: 1250,
            duration: 7200, // 2 horas en segundos
            averageHeartRate: 145,
            averagePower: 280,
            averagePace: 5.7,
            averageCadence: 90,
            averageStrideLength: 1.2
        )
    }
}
