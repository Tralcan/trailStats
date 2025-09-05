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
    private func loadActivitiesFromCache() {
        self.allActivities = cacheManager.loadAllActivityDetails()
    }
    
    private func processDataForTimeFrame() {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -timeFrame, to: Date()) else {
            return
        }
        
        let recentActivities = allActivities.filter { $0.date >= cutoffDate }
        
        // --- Calculations ---
        calculateTotals(for: recentActivities)
        calculateEfficiencyData(for: recentActivities)
        calculateIntensityDistribution(for: recentActivities)
        calculateWeeklyDistance(for: recentActivities)
        calculateWeeklyDecoupling(for: recentActivities)
        calculateMountainPerformance(for: recentActivities)
        calculatePerformanceByGrade(for: recentActivities)
        calculateRunningDynamics(for: recentActivities)
        
        // Update the state to prevent unnecessary recalculations
        self.lastProcessedActivitiesCount = allActivities.count
        self.lastProcessedActivityDate = allActivities.map { $0.date }.max() ?? .distantPast

        print("Processed data for time frame: \(timeFrame) days. Found \(totalActivities) activities.")
    }
    
    private func calculateTotals(for activities: [Activity]) {
        totalDistance = activities.reduce(0) { $0 + $1.distance }
        totalElevation = activities.reduce(0) { $0 + $1.elevationGain }
        totalDuration = activities.reduce(0) { $0 + $1.duration }
        totalActivities = activities.count
    }
    
    private func calculateEfficiencyData(for activities: [Activity]) {
        let dataPoints = activities.compactMap { activity -> ChartDataPoint? in
            guard let avgHR = activity.averageHeartRate, avgHR > 0, activity.duration > 0 else { return nil }
            let distanceInKm = activity.distance / 1000
            let durationInHours = activity.duration / 3600
            guard durationInHours > 0 else { return nil }
            let speed = distanceInKm / durationInHours
            let efficiencyIndex = speed / avgHR
            guard !efficiencyIndex.isNaN && !efficiencyIndex.isInfinite else { return nil }
            return ChartDataPoint(time: Int(activity.date.timeIntervalSince1970), value: efficiencyIndex)
        }
        self.efficiencyData = dataPoints.sorted(by: { $0.time < $1.time })
    }
    
    private func calculateIntensityDistribution(for activities: [Activity]) {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: activities) { calendar.startOfWeek(for: $0.date) }
        
        var weeklyData: [WeeklyZoneData] = []
        for (weekStartDate, activitiesInWeek) in groupedByWeek {
            let weekOfYear = calendar.component(.weekOfYear, from: weekStartDate)
            let weekID = "W\(weekOfYear)"
            var weeklyZone = WeeklyZoneData(id: weekID, weekDate: weekStartDate)
            
            for activity in activitiesInWeek {
                if let metrics = cacheManager.loadProcessedMetrics(activityId: activity.id), let distribution = metrics.heartRateZoneDistribution {
                    weeklyZone.timeInZones[0] += distribution.timeInZone1
                    weeklyZone.timeInZones[1] += distribution.timeInZone2
                    weeklyZone.timeInZones[2] += distribution.timeInZone3
                    weeklyZone.timeInZones[3] += distribution.timeInZone4
                    weeklyZone.timeInZones[4] += distribution.timeInZone5
                }
            }
            weeklyData.append(weeklyZone)
        }
        self.weeklyZoneDistribution = weeklyData.sorted(by: { $0.weekDate < $1.weekDate })
    }
    
    private func calculateWeeklyDistance(for activities: [Activity]) {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: activities) { calendar.startOfWeek(for: $0.date) }
        
        var weeklyData: [WeeklyDistanceData] = []
        for (weekStartDate, activitiesInWeek) in groupedByWeek {
            let weekOfYear = calendar.component(.weekOfYear, from: weekStartDate)
            let weekID = "W\(weekOfYear)"
            
            let totalDistance = activitiesInWeek.reduce(0) { $0 + $1.distance }
            weeklyData.append(WeeklyDistanceData(id: weekID, distance: totalDistance, weekDate: weekStartDate))
        }
        self.weeklyDistanceData = weeklyData.sorted(by: { $0.weekDate < $1.weekDate })
    }
    
    private func calculateWeeklyDecoupling(for activities: [Activity]) {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: activities) { calendar.startOfWeek(for: $0.date) }
        
        var weeklyData: [WeeklyDecouplingData] = []
        for (weekStartDate, activitiesInWeek) in groupedByWeek {
            let weekOfYear = calendar.component(.weekOfYear, from: weekStartDate)
            let weekID = "W\(weekOfYear)"
            
            let decouplingValues = activitiesInWeek.compactMap {
                cacheManager.loadProcessedMetrics(activityId: $0.id)?.cardiacDecoupling
            }
            
            if !decouplingValues.isEmpty {
                let averageDecoupling = decouplingValues.reduce(0, +) / Double(decouplingValues.count)
                weeklyData.append(WeeklyDecouplingData(id: weekID, averageDecoupling: averageDecoupling, weekDate: weekStartDate))
            }
        }
        self.weeklyDecouplingData = weeklyData.sorted(by: { $0.weekDate < $1.weekDate })
    }
    
    private func calculateMountainPerformance(for activities: [Activity]) {
        let metrics = activities.compactMap { cacheManager.loadProcessedMetrics(activityId: $0.id) }
        
        let vamValues = metrics.compactMap { $0.verticalSpeedVAM }
        self.averageVAM = vamValues.isEmpty ? 0 : vamValues.reduce(0, +) / Double(vamValues.count)
        
        let gapValues = metrics.compactMap { $0.gradeAdjustedPace }
        self.averageGAP = gapValues.isEmpty ? 0 : gapValues.reduce(0, +) / Double(gapValues.count)
        
        let descentVAMValues = metrics.compactMap { $0.descentVerticalSpeed }
        self.averageDescentVAM = descentVAMValues.isEmpty ? 0 : descentVAMValues.reduce(0, +) / Double(descentVAMValues.count)

        let npValues = metrics.compactMap { $0.normalizedPower }
        self.averageNormalizedPower = npValues.isEmpty ? 0 : npValues.reduce(0, +) / Double(npValues.count)

        let efficiencyValues = metrics.compactMap { $0.efficiencyIndex }
        self.averageEfficiencyIndex = efficiencyValues.isEmpty ? 0 : efficiencyValues.reduce(0, +) / Double(efficiencyValues.count)
        
        let decouplingValues = metrics.compactMap { $0.cardiacDecoupling }
        self.averageDecoupling = decouplingValues.isEmpty ? 0 : decouplingValues.reduce(0, +) / Double(decouplingValues.count)
    }
    
    private func calculatePerformanceByGrade(for activities: [Activity]) {
        var aggregatedData: [String: (totalDistance: Double, totalTime: TimeInterval, totalElevation: Double, weightedCadenceSum: Double, timeWithCadence: TimeInterval)] = [:] 

        let allMetrics = activities.compactMap { cacheManager.loadProcessedMetrics(activityId: $0.id) }

        for metrics in allMetrics {
            for gradePerformance in metrics.performanceByGrade {
                var bucket = aggregatedData[gradePerformance.gradeBucket] ?? (0, 0, 0, 0, 0)
                bucket.totalDistance += gradePerformance.distance
                bucket.totalTime += gradePerformance.time
                bucket.totalElevation += gradePerformance.elevation
                bucket.weightedCadenceSum += gradePerformance.weightedCadenceSum
                bucket.timeWithCadence += gradePerformance.timeWithCadence
                aggregatedData[gradePerformance.gradeBucket] = bucket
            }
        }

        let finalData = aggregatedData.map { bucketName, totals -> PerformanceByGrade in
            return PerformanceByGrade(
                id: UUID(),
                gradeBucket: bucketName,
                distance: totals.totalDistance,
                time: totals.totalTime,
                elevation: totals.totalElevation,
                weightedCadenceSum: totals.weightedCadenceSum,
                timeWithCadence: totals.timeWithCadence
            )
        }
        
        let sortOrder = ["<-15%", "-15% to -10%", "-10% to -5%", "-5% to 0%", "0% to 5%", "5% to 10%", "10% to 15%", ">15%"]
        self.performanceByGradeData = finalData.sorted { first, second in
            guard let firstIndex = sortOrder.firstIndex(of: first.gradeBucket), let secondIndex = sortOrder.firstIndex(of: second.gradeBucket) else {
                return false
            }
            return firstIndex < secondIndex
        }
    }
    
    private func calculateRunningDynamics(for activities: [Activity]) {
        let voValues = activities.compactMap { $0.verticalOscillation }
        let gctValues = activities.compactMap { $0.groundContactTime }
        let slValues = activities.compactMap { $0.strideLength }
        let vrValues = activities.compactMap { $0.verticalRatio }
        
        self.hasRunningDynamics = !voValues.isEmpty
        
        self.averageVerticalOscillation = voValues.isEmpty ? 0 : voValues.reduce(0, +) / Double(voValues.count)
        self.averageGroundContactTime = gctValues.isEmpty ? 0 : gctValues.reduce(0, +) / Double(gctValues.count)
        self.averageStrideLength = slValues.isEmpty ? 0 : slValues.reduce(0, +) / Double(slValues.count)
        self.averageVerticalRatio = vrValues.isEmpty ? 0 : vrValues.reduce(0, +) / Double(vrValues.count)
    }
}

// Helper to get the start of the week for grouping
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)!
    }
}
