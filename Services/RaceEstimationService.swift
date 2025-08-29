import Foundation

class RaceEstimationService {
    private let cacheManager = CacheManager()

    func estimateRaceTime(for race: Race) -> TimeInterval? {
        guard let activities = cacheManager.loadActivities() else {
            return nil
        }

        var totalAdjustedPace: Double = 0
        var activityCount: Int = 0

        for activity in activities {
            // We need the full activity detail to check for RPE
            if let detailedActivity = cacheManager.loadActivityDetail(activityId: activity.id),
               let summary = cacheManager.loadSummary(activityId: activity.id),
               let pace = summary.averagePace {
                
                let adjustmentFactor = rpeAdjustmentFactor(for: detailedActivity.rpe)
                totalAdjustedPace += pace * adjustmentFactor
                activityCount += 1
            }
        }

        guard activityCount > 0 else {
            return nil
        }

        let averageAdjustedPace = totalAdjustedPace / Double(activityCount) // Pace in seconds per meter

        // Estimated time in seconds
        let estimatedTime = race.distance * averageAdjustedPace

        return estimatedTime
    }

    private func rpeAdjustmentFactor(for rpe: Double?) -> Double {
        guard let rpe = rpe else {
            return 1.0 // No RPE, no adjustment
        }

        switch rpe {
        case 1...4:
            return 0.95 // Easier than average, adjust pace to be slightly faster
        case 7...8:
            return 1.05 // Harder than average, adjust pace to be slightly slower
        case 9...10:
            return 1.10 // Max effort, adjust pace to be significantly slower
        default: // 5-6 and any other case
            return 1.0 // Average effort, no adjustment
        }
    }
}
