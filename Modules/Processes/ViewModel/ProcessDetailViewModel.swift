import Foundation

@MainActor
class ProcessDetailViewModel: ObservableObject {
    // MARK: - Public Properties
    let process: TrainingProcess

    @Published var result: AnalyticsResult?
    @Published var isLoading: Bool = true

    // MARK: - Private Properties
    private let cacheManager = CacheManager()
    private let analyticsEngine = AnalyticsEngine()

    init(process: TrainingProcess) {
        self.process = process
    }

    func loadAnalytics() {
        isLoading = true
        
        Task.detached(priority: .userInitiated) {
            let allActivities = self.cacheManager.loadAllActivityDetails()
            
            let processActivities = allActivities.filter { activity in
                return activity.date >= self.process.startDate && activity.date <= self.process.endDate
            }
            
            let calculatedResult = self.analyticsEngine.calculate(for: processActivities)
            
            await MainActor.run {
                self.result = calculatedResult
                self.isLoading = false
            }
        }
    }
}
