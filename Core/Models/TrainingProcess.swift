import Foundation

enum GoalStatus: String, Codable {
    case pending
    case met
    case notMet
}

struct TrainingProcess: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var goal: String
    var raceDistance: Double?
    var raceElevation: Double?
    var goalActivityID: Int?
    var metricEntries: [ProcessMetricEntry]
    var goalStatus: GoalStatus = .pending

    var isActive: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return today >= start && today <= end
    }

    var isCompleted: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: endDate)
        return today > end
    }

    init(id: UUID = UUID(),
         name: String,
         startDate: Date,
         endDate: Date,
         goal: String,
         raceDistance: Double? = nil,
         raceElevation: Double? = nil,
         goalActivityID: Int? = nil,
         metricEntries: [ProcessMetricEntry] = [],
         goalStatus: GoalStatus = .pending) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.goal = goal
        self.raceDistance = raceDistance
        self.raceElevation = raceElevation
        self.goalActivityID = goalActivityID
        self.metricEntries = metricEntries
        self.goalStatus = goalStatus
    }
}