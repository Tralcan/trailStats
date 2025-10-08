import Foundation
import WidgetKit

@MainActor
class ProcessDetailViewModel: ObservableObject {
    // MARK: - Public Properties
    @Published var process: TrainingProcess
    @Published var result: AnalyticsResult?
    @Published var isLoading: Bool = true
    @Published var isEstimatingTime: Bool = false
    @Published var raceProjection: RaceProjection?
    @Published var estimationError: String?
    @Published var goalActivity: Activity? = nil
    @Published var trainingRecommendation: String?
    @Published var isFetchingRecommendation = false
    @Published var recommendationError: String?

    // MARK: - Private Properties
    private let cacheManager = CacheManager()
    private let analyticsEngine = AnalyticsEngine()
    private let geminiCoachService = ProcessGeminiCoachService()

    init(process: TrainingProcess) {
        self.process = process
    }

    func loadAnalytics() {
        isLoading = true

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            // Load goal activity if it exists
            if let goalId = await self.process.goalActivityID {
                let loadedGoalActivity = self.cacheManager.loadActivityDetail(activityId: goalId)
                await MainActor.run { self.goalActivity = loadedGoalActivity }
            }

            let startDate = await self.process.startDate
            let endDate = await self.process.endDate
            let allActivities = self.cacheManager.loadAllActivityDetails()
            let processActivities = allActivities.filter { $0.date >= startDate && $0.date <= endDate }
            let calculatedResult = self.analyticsEngine.calculate(for: processActivities)

            await MainActor.run {
                self.result = calculatedResult
                self.isLoading = false
                // Only get estimation if there is no real race associated
                if self.goalActivity == nil && self.process.raceDistance != nil {
                    self.getGeminiEstimation(with: processActivities)
                }
                self.fetchTrainingRecommendation()
            }
        }
    }

    func loadProcess() {
        let allProcesses = cacheManager.loadTrainingProcesses()
        if let updatedProcess = allProcesses.first(where: { $0.id == process.id }) {
            self.process = updatedProcess
        }
    }
    
    func getGeminiEstimation(with activities: [Activity]) {
        isEstimatingTime = true
        estimationError = nil
        geminiCoachService.getProcessRaceEstimation(for: process, with: activities) { [weak self] result in
            DispatchQueue.main.async {
                self?.isEstimatingTime = false
                switch result {
                case .success(let response):
                    self?.raceProjection = response
                    self?.saveDataForWidget(with: response)
                case .failure(let error):
                    self?.estimationError = "Error al obtener la estimación: \(error.localizedDescription)"
                }
            }
        }
    }

    func fetchTrainingRecommendation() {
        isFetchingRecommendation = true
        recommendationError = nil

        geminiCoachService.getTrainingRecommendations(for: process) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingRecommendation = false
                switch result {
                case .success(let recommendation):
                    self?.trainingRecommendation = recommendation
                case .failure(let error):
                    self?.recommendationError = "Error al obtener la recomendación: \(error.localizedDescription)"
                }
            }
        }
    }

    func updateGoalStatus(to newStatus: GoalStatus) {
        process.goalStatus = newStatus
        saveProcess()
    }

    // MARK: - Entry Management

    enum SimpleEntryType: String {
        case kinesiologo = "Visita al Kinesiologo"
        case medico = "Visita al Medico"
        case masajes = "Sesión de Masajes"
    }

    func addSimpleEntry(type: SimpleEntryType) {
        addEntry(notes: type.rawValue)
    }
    
    func addCommentEntry(notes: String) {
        addEntry(notes: notes)
    }

    private func addEntry(notes: String) {
        let newEntry = ProcessMetricEntry(date: Date(), notes: notes)
        
        process.metricEntries.append(newEntry)
        process.metricEntries.sort(by: { $0.date > $1.date })
        saveProcess()
    }

    func deleteMetricEntry(at offsets: IndexSet) {
        process.metricEntries.remove(atOffsets: offsets)
        saveProcess()
    }
    
    private func saveProcess() {
        var allProcesses = cacheManager.loadTrainingProcesses()
        if let index = allProcesses.firstIndex(where: { $0.id == process.id }) {
            allProcesses[index] = process
            cacheManager.saveTrainingProcesses(allProcesses)
        }

        if !process.isActive {
            cacheManager.deleteProcessWidgetData()
            WidgetCenter.shared.reloadTimelines(ofKind: "ProcessWidget")
        }
    }

    private func saveDataForWidget(with projection: RaceProjection) {
        guard process.isActive, let distance = process.raceDistance, let elevation = process.raceElevation else { return }

        let isMetric = Locale.current.usesMetricSystem
        let daysRemaining = calculateDaysRemaining(until: process.endDate)
        
        let distanceValue = isMetric ? distance / 1000 : distance / 1609.34
        let distanceUnit = isMetric ? NSLocalizedString("widget.unit.distance.metric", comment: "") : NSLocalizedString("widget.unit.distance.imperial", comment: "")
        
        let elevationValue = isMetric ? elevation : elevation * 3.28084
        let elevationUnit = isMetric ? NSLocalizedString("widget.unit.elevation.metric", comment: "") : NSLocalizedString("widget.unit.elevation.imperial", comment: "")

        let widgetData = ProcessWidgetData(
            processName: process.name,
            daysRemaining: daysRemaining,
            daysRemainingText: NSLocalizedString("process_widget.days_remaining", comment: ""),
            distanceValue: distanceValue,
            distanceUnit: distanceUnit,
            elevationValue: elevationValue,
            elevationUnit: elevationUnit,
            estimatedTime: projection.tiempo
        )

        cacheManager.saveProcessForWidget(widgetData)
        WidgetCenter.shared.reloadTimelines(ofKind: "ProcessWidget")
    }

    private func calculateDaysRemaining(until endDate: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfEndDate = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfEndDate)
        return components.day ?? 0
    }
}