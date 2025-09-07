import Foundation

@MainActor
class AddMetricEntryViewModel: ObservableObject {
    @Published var date: Date = Date()
    @Published var weight: String = ""
    @Published var bodyFatPercentage: String = ""
    @Published var leanBodyMass: String = ""

    private var process: TrainingProcess
    private let cacheManager = CacheManager()
    private let healthKitService = HealthKitService()

    init(process: TrainingProcess) {
        self.process = process
    }

    var isFormValid: Bool {
        // Al menos un campo de métrica debe estar lleno
        !weight.isEmpty || !bodyFatPercentage.isEmpty || !leanBodyMass.isEmpty
    }

    func fetchLatestMetrics() {
        healthKitService.requestAuthorization { [weak self] (success, error) in
            guard success, error == nil else {
                // Handle error or denial of authorization
                return
            }

            self?.healthKitService.fetchLatestBodyMetrics { result in
                if case .success(let metrics) = result {
                    DispatchQueue.main.async {
                        if let weight = metrics.weight {
                            self?.weight = String(format: "%.1f", weight)
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

    func saveMetricEntry() {
        guard isFormValid else { return }

        let newEntry = ProcessMetricEntry(
            date: date,
            weight: Double(weight.replacingOccurrences(of: ",", with: ".")),
            bodyFatPercentage: Double(bodyFatPercentage.replacingOccurrences(of: ",", with: ".")),
            leanBodyMass: Double(leanBodyMass.replacingOccurrences(of: ",", with: "."))
        )

        // Cargar todos los procesos, encontrar el actual y actualizarlo
        var allProcesses = cacheManager.loadTrainingProcesses()
        if let index = allProcesses.firstIndex(where: { $0.id == process.id }) {
            allProcesses[index].metricEntries.append(newEntry)
            // Ordenar las entradas por fecha descendente
            allProcesses[index].metricEntries.sort { $0.date > $1.date }
            cacheManager.saveTrainingProcesses(allProcesses)
            self.process = allProcesses[index] // Actualizar la referencia local del proceso
        }
    }
}