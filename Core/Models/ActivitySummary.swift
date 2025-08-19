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
}
