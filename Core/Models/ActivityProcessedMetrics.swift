import Foundation

struct ActivityProcessedMetrics: Codable {
    let verticalSpeedVAM: Double?
    let cardiacDecoupling: Double?
    let climbSegments: [ActivitySegment]
    let descentVerticalSpeed: Double?
    let normalizedPower: Double?
    let gradeAdjustedPace: Double?
    let heartRateZoneDistribution: HeartRateZoneDistribution?
    let performanceByGrade: [PerformanceByGrade]
    let efficiencyIndex: Double?
}