import Foundation

@MainActor
class RacePrepViewModel: ObservableObject {
    @Published var raceActivities: [Activity] = []
    @Published var isLoading: Bool = false
    private let cacheManager = CacheManager()

    func loadRaceActivities() async {
        self.isLoading = true
        let allActivities = cacheManager.loadAllActivityDetails()
        
        self.raceActivities = allActivities
            .filter { $0.tag == .race }
            .sorted { $0.date > $1.date }
        self.isLoading = false
    }
}
