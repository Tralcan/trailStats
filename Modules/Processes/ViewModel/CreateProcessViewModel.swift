import Foundation

@MainActor
class CreateProcessViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @Published var goal: String = ""
    @Published var raceDistance: String = ""
    @Published var raceElevation: String = ""
    @Published var startWeight: String = ""
    @Published var bodyFatPercentage: String = ""
    @Published var leanBodyMass: String = ""

    private var processToEdit: TrainingProcess?
    private let cacheManager = CacheManager()
    private let healthKitService = HealthKitService()

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !goal.trimmingCharacters(in: .whitespaces).isEmpty && endDate > startDate
    }

    var navigationTitle: String {
        processToEdit == nil ? "Nuevo Proceso" : "Editar Proceso"
    }

    init(processToEdit: TrainingProcess? = nil) {
        self.processToEdit = processToEdit
        if let process = processToEdit {
            // Populate fields for editing
            name = process.name
            startDate = process.startDate
            endDate = process.endDate
            goal = process.goal
            if let distance = process.raceDistance {
                raceDistance = String(format: "%.1f", distance / 1000)
            }
            if let elevation = process.raceElevation {
                raceElevation = String(format: "%.0f", elevation)
            }
            // Note: We don't re-populate the initial metrics as they are a one-time record.
        }
    }

    func fetchInitialMetrics() {
        // Only fetch if creating a new process
        guard processToEdit == nil else { return }

        healthKitService.requestAuthorization { [weak self] (success, error) in
            guard success, error == nil else {
                return
            }

            DispatchQueue.main.async {
                self?.healthKitService.fetchLatestBodyMetrics { result in
                    DispatchQueue.main.async {
                        if case .success(let metrics) = result {
                            if let weight = metrics.weight {
                                self?.startWeight = String(format: "%.1f", weight)
                            }
                            if let bodyFat = metrics.bodyFatPercentage {
                                self?.bodyFatPercentage = String(format: "%.1f", bodyFat)
                            }
                            if let leanMass = metrics.leanBodyMass {
                                self?.leanBodyMass = String(format: "%.1f", leanMass)
                            }
                        }
                    }
                }
            }
        }
    }

    func save() {
        guard isFormValid else { return }

        var allProcesses = cacheManager.loadTrainingProcesses()

        if let processToEdit = processToEdit {
            // Update existing process
            if let index = allProcesses.firstIndex(where: { $0.id == processToEdit.id }) {
                allProcesses[index].name = name
                allProcesses[index].startDate = startDate
                allProcesses[index].endDate = endDate
                allProcesses[index].goal = goal
                allProcesses[index].raceDistance = Double(raceDistance) != nil ? (Double(raceDistance) ?? 0) * 1000 : nil
                allProcesses[index].raceElevation = Double(raceElevation)
            }
        } else {
            // Create new process
            let initialMetricEntry = ProcessMetricEntry(
                date: Date(),
                weight: Double(startWeight),
                bodyFatPercentage: Double(bodyFatPercentage),
                leanBodyMass: Double(leanBodyMass),
                notes: nil
            )

            let newProcess = TrainingProcess(
                name: name,
                startDate: startDate,
                endDate: endDate,
                goal: goal,
                raceDistance: Double(raceDistance) != nil ? (Double(raceDistance) ?? 0) * 1000 : nil, // km to meters
                raceElevation: Double(raceElevation),
                metricEntries: [initialMetricEntry].filter { $0.weight != nil || $0.bodyFatPercentage != nil || $0.leanBodyMass != nil }
            )
            allProcesses.append(newProcess)
        }

        cacheManager.saveTrainingProcesses(allProcesses)
    }
}
