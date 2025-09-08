import Foundation

@MainActor
class RacePrepViewModel: ObservableObject {
    @Published var raceActivities: [Activity] = []
    @Published var isLoading = false

    private let cacheManager = CacheManager()

    func loadRaceActivities() {
        self.isLoading = true
        
        Task {
            let allProcesses = cacheManager.loadTrainingProcesses()
            let raceActivityIDs = allProcesses.compactMap { $0.goalActivityID }
            
            // Load all activities from cache and filter them
            let allActivities = cacheManager.loadAllActivityDetails()
            let races = allActivities.filter { raceActivityIDs.contains($0.id) }
            
            // Sort races by date, most recent first
            self.raceActivities = races.sorted(by: { $0.date > $1.date })
            self.isLoading = false
        }
    }
}