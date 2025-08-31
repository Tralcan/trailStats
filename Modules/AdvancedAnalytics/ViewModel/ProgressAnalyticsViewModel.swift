import Foundation
import Combine

@MainActor
class ProgressAnalyticsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var timeFrame: Int = 30 // Default to 30 days
    
    // Data for Charts
    @Published var efficiencyData: [ChartDataPoint] = []
    
    // Data for KPI Cards
    @Published var totalDistance: Double = 0
    @Published var totalElevation: Double = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var totalActivities: Int = 0
    
    // MARK: - Private Properties
    private let cacheManager = CacheManager()
    private var allActivities: [Activity] = []
    
    init() {
        loadActivitiesFromCache()
        processDataForTimeFrame()
    }
    
    // MARK: - Public Methods
    func timeFrameChanged(newTimeFrame: Int) {
        self.timeFrame = newTimeFrame
        processDataForTimeFrame()
    }
    
    // MARK: - Private Methods
    private func loadActivitiesFromCache() {
        self.allActivities = cacheManager.loadAllActivityDetails()
    }
    
    private func processDataForTimeFrame() {
        // 1. Filter activities based on the selected timeFrame
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -timeFrame, to: Date()) else {
            return
        }
        
        let recentActivities = allActivities.filter { $0.date >= cutoffDate }
        
        // 2. Calculate totals for KPI cards
        totalDistance = recentActivities.reduce(0) { $0 + $1.distance }
        totalElevation = recentActivities.reduce(0) { $0 + $1.elevationGain }
        totalDuration = recentActivities.reduce(0) { $0 + $1.duration }
        totalActivities = recentActivities.count
        
        // 3. Process these activities to get the real efficiency index for the chart
        let dataPoints = recentActivities.compactMap { activity -> ChartDataPoint? in
            guard let avgHR = activity.averageHeartRate, avgHR > 0, activity.duration > 0 else {
                return nil
            }
            
            let distanceInKm = activity.distance / 1000
            let durationInHours = activity.duration / 3600
            
            // Avoid division by zero if duration is very short
            guard durationInHours > 0 else { return nil }
            
            // Speed in km/h
            let speed = distanceInKm / durationInHours
            
            // Efficiency Index: Speed per Heart Rate beat
            let efficiencyIndex = speed / avgHR
            
            // We only want to show valid data
            guard !efficiencyIndex.isNaN && !efficiencyIndex.isInfinite else {
                return nil
            }
            
            return ChartDataPoint(time: Int(activity.date.timeIntervalSince1970), value: efficiencyIndex)
        }
        
        self.efficiencyData = dataPoints.sorted(by: { $0.time < $1.time })
        
        print("Processed data for time frame: \(timeFrame) days. Found \(efficiencyData.count) real data points and \(totalActivities) activities.")
    }
}
