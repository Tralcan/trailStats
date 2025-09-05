import Foundation

/// A struct to hold the results of analytics calculations.
struct AnalyticsResult {
    // Data for KPI Cards
    let totalDistance: Double
    let totalElevation: Double
    let totalDuration: TimeInterval
    let totalActivities: Int
    let averageVAM: Double
    let averageGAP: Double
    let averageDescentVAM: Double
    let averageNormalizedPower: Double
    let averageEfficiencyIndex: Double
    let averageDecoupling: Double

    // Running Dynamics
    let averageVerticalOscillation: Double
    let averageGroundContactTime: Double
    let averageStrideLength: Double
    let averageVerticalRatio: Double
    let hasRunningDynamics: Bool
    
    // Data for Charts
    let efficiencyData: [ChartDataPoint]
    let weeklyZoneDistribution: [WeeklyZoneData]
    let weeklyDistanceData: [WeeklyDistanceData]
    let weeklyDecouplingData: [WeeklyDecouplingData]
    let performanceByGradeData: [PerformanceByGrade]
}
