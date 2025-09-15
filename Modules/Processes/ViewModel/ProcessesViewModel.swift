import Foundation

struct ProcessDisplayData: Identifiable {
    var id: UUID { process.id }
    let process: TrainingProcess
    let name: String
    let dates: String
    let distance: String
    let elevation: String
    let time: String
    let isActive: Bool
    let hasGoalActivity: Bool
}

@MainActor
class ProcessesViewModel: ObservableObject {
    @Published var processes: [ProcessDisplayData] = []
    private let cacheManager = CacheManager()
    
    func loadProcesses() async {
        let allProcesses = cacheManager.loadTrainingProcesses().sorted(by: { $0.startDate > $1.startDate })
        var displayData: [ProcessDisplayData] = []

        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter
        }()

        for process in allProcesses {
            var distance = "--"
            var elevation = "--"
            var time = "--"
            var hasGoalActivity = false

            if let goalActivityID = process.goalActivityID,
               let activity = cacheManager.loadActivityDetail(activityId: goalActivityID) {
                distance = Formatters.formatDistance(activity.distance)
                elevation = Formatters.formatElevation(activity.elevationGain)
                time = Int(activity.duration).toHoursMinutesSeconds()
                hasGoalActivity = true
            } else if let raceDistance = process.raceDistance, let raceElevation = process.raceElevation {
                distance = Formatters.formatDistance(raceDistance)
                elevation = Formatters.formatElevation(raceElevation)
                if let projection = cacheManager.loadProcessGeminiCoachResponse(processId: process.id) {
                    time = projection.tiempo
                } else {
                    time = "N/A"
                }
            }

            let dates = "\(dateFormatter.string(from: process.startDate)) - \(dateFormatter.string(from: process.endDate))"
            
            displayData.append(ProcessDisplayData(
                process: process,
                name: process.name,
                dates: dates,
                distance: distance,
                elevation: elevation,
                time: time,
                isActive: process.isActive,
                hasGoalActivity: hasGoalActivity
            ))
        }
        
        self.processes = displayData
    }

    func deleteProcess(at offsets: IndexSet) {
        let processesToDelete = offsets.map { processes[$0].process }
        for process in processesToDelete {
            cacheManager.deleteTrainingProcess(process)
        }
        processes.remove(atOffsets: offsets)
    }
}
