import Foundation

class RaceEstimationService {
    private let cacheManager = CacheManager()

    func estimateRaceTime(for race: Race) -> TimeInterval? {
        guard let activities = cacheManager.loadActivities() else {
            return nil
        }

        var totalPace: Double = 0
        var activityCount: Int = 0

        for activity in activities {
            if let summary = cacheManager.loadSummary(activityId: activity.id), let pace = summary.averagePace {
                totalPace += pace
                activityCount += 1
            }
        }

        guard activityCount > 0 else {
            return nil
        }

        let averagePace = totalPace / Double(activityCount) // Pace in seconds per meter

        // Estimated time in seconds
        let estimatedTime = race.distance * averagePace

        return estimatedTime
    }
}
