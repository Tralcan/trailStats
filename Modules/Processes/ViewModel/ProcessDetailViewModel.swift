import Foundation

@MainActor
class ProcessDetailViewModel: ObservableObject {
    // MARK: - Public Properties
    @Published var process: TrainingProcess
    @Published var result: AnalyticsResult?
    @Published var isLoading: Bool = true // Corregido el error de sintaxis

    // MARK: - Private Properties
    private let cacheManager = CacheManager()
    private let analyticsEngine = AnalyticsEngine()

    init(process: TrainingProcess) {
        self.process = process
    }

    func loadAnalytics() {
        isLoading = true

        Task.detached(priority: .userInitiated) { [weak self] in // Capturar self como weak
            guard let self = self else { return } // Asegurar que self no sea nil

            // Acceder a process en el MainActor
            let startDate = await self.process.startDate
            let endDate = await self.process.endDate

            let allActivities = self.cacheManager.loadAllActivityDetails()

            let processActivities = allActivities.filter { activity in
                return activity.date >= startDate && activity.date <= endDate
            }

            let calculatedResult = self.analyticsEngine.calculate(for: processActivities)

            await MainActor.run {
                self.result = calculatedResult
                self.isLoading = false
            }
        }
    }

    // Nuevo método para recargar el proceso
    func loadProcess() {
        // Recargar todos los procesos y encontrar la versión más reciente de este proceso
        let allProcesses = cacheManager.loadTrainingProcesses()
        if let updatedProcess = allProcesses.first(where: { $0.id == process.id }) {
            self.process = updatedProcess
        }
    }
}