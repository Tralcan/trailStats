import Foundation
import Combine

// MARK: - Data Structures for Charts

struct WeeklyZoneData: Identifiable {
    let id: String
    var timeInZones: [TimeInterval] = Array(repeating: 0, count: 5)
    var weekDate: Date
}

struct WeeklyDistanceData: Identifiable {
    let id: String
    var distance: Double
    var weekDate: Date
}

struct WeeklyDecouplingData: Identifiable {
    let id: String
    var averageDecoupling: Double
    var weekDate: Date
}

@MainActor
class ProgressAnalyticsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var timeFrame: Int = 30
    
    // Data for Charts
    @Published var efficiencyData: [ChartDataPoint] = []
    @Published var weeklyZoneDistribution: [WeeklyZoneData] = []
    @Published var weeklyDistanceData: [WeeklyDistanceData] = []
    @Published var weeklyDecouplingData: [WeeklyDecouplingData] = []
    @Published var performanceByGradeData: [PerformanceByGrade] = []

    // Data for KPI Cards
    @Published var totalDistance: Double = 0
    @Published var totalElevation: Double = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var totalActivities: Int = 0
    @Published var averageVAM: Double = 0
    @Published var averageGAP: Double = 0
    @Published var averageDescentVAM: Double = 0
    @Published var averageNormalizedPower: Double = 0
    @Published var averageEfficiencyIndex: Double = 0
    @Published var averageDecoupling: Double = 0

    // Running Dynamics
    @Published var averageVerticalOscillation: Double = 0
    @Published var averageGroundContactTime: Double = 0
    @Published var averageStrideLength: Double = 0
    @Published var averageVerticalRatio: Double = 0
    @Published var hasRunningDynamics: Bool = false

    // MARK: - Private Properties
    private let cacheManager = CacheManager()
    private let analyticsEngine = AnalyticsEngine()
    private var allActivities: [Activity] = []
    private var lastProcessedActivitiesCount: Int = -1
    private var lastProcessedActivityDate: Date = .distantPast
    
    init() {
        recalculateAnalyticsIfNeeded()
    }
    
    // MARK: - Public Methods
    func timeFrameChanged(newTimeFrame: Int) {
        self.timeFrame = newTimeFrame
        processDataForTimeFrame()
    }

    func recalculateAnalyticsIfNeeded() {
        self.allActivities = cacheManager.loadAllActivityDetails()
        guard !allActivities.isEmpty else { return }

        let currentActivityCount = allActivities.count
        let latestActivityDate = allActivities.map { $0.date }.max() ?? .distantPast

        if currentActivityCount != lastProcessedActivitiesCount || latestActivityDate > lastProcessedActivityDate {
            print("Analytics data has changed. Recalculating...")
            processDataForTimeFrame()
        }
    }
    
    // MARK: - Private Methods
    private func processDataForTimeFrame() {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -timeFrame, to: Date()) else {
            return
        }
        
        let recentActivities = allActivities.filter { $0.date >= cutoffDate }
        
        // Use the engine to perform calculations
        let result = analyticsEngine.calculate(for: recentActivities)
        
        // Update published properties with the results
        self.totalDistance = result.totalDistance
        self.totalElevation = result.totalElevation
        self.totalDuration = result.totalDuration
        self.totalActivities = result.totalActivities
        self.averageVAM = result.averageVAM
        self.averageGAP = result.averageGAP
        self.averageDescentVAM = result.averageDescentVAM
        self.averageNormalizedPower = result.averageNormalizedPower
        self.averageEfficiencyIndex = result.averageEfficiencyIndex
        self.averageDecoupling = result.averageDecoupling
        self.averageVerticalOscillation = result.averageVerticalOscillation
        self.averageGroundContactTime = result.averageGroundContactTime
        self.averageStrideLength = result.averageStrideLength
        self.averageVerticalRatio = result.averageVerticalRatio
        self.hasRunningDynamics = result.hasRunningDynamics
        self.efficiencyData = result.efficiencyData
        self.weeklyZoneDistribution = result.weeklyZoneDistribution
        self.weeklyDistanceData = result.weeklyDistanceData
        self.weeklyDecouplingData = result.weeklyDecouplingData
        self.performanceByGradeData = result.performanceByGradeData
        
        // Update the state to prevent unnecessary recalculations
        self.lastProcessedActivitiesCount = allActivities.count
        self.lastProcessedActivityDate = allActivities.map { $0.date }.max() ?? .distantPast

        print("Processed data for time frame: \(timeFrame) days. Found \(totalActivities) activities.")
    }
}

// Helper to get the start of the week for grouping
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)!
    }
}