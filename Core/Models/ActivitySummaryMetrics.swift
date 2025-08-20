import Foundation

struct ActivitySummaryMetrics: Codable {
    let activityId: Int
    let distance: Double // in meters
    let elevation: Double // in meters

    // Averages of the charts
    let elevationAverage: Double
    let verticalEnergyCostAverage: Double
    let positiveVerticalSpeedAverage: Double
    let negativeVerticalSpeedAverage: Double
    let heartRateAverage: Double
    let powerAverage: Double
    let paceAverage: Double
    let strideLengthAverage: Double
    let cadenceAverage: Double
}