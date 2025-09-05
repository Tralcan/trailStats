import Foundation

@MainActor
class CreateProcessViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @Published var startWeight: String = ""
    @Published var bodyFatPercentage: String = ""
    @Published var leanBodyMass: String = ""
    @Published var notes: String = ""
    
    private let cacheManager = CacheManager()
    private let healthKitService = HealthKitService()
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && endDate > startDate
    }
    
    func fetchInitialMetrics() {
        healthKitService.requestAuthorization { [weak self] (success, error) in
            guard success, error == nil else {
                // Handle error or denial of authorization
                return
            }
            
            self?.healthKitService.fetchLatestBodyMetrics { result in
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
    
    func save() {
        guard isFormValid else { return }
        
        var allProcesses = cacheManager.loadTrainingProcesses()
        
        let newProcess = TrainingProcess(
            name: name,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            startWeight: Double(startWeight),
            startBodyFatPercentage: Double(bodyFatPercentage),
            startLeanBodyMass: Double(leanBodyMass)
        )
        
        allProcesses.append(newProcess)
        cacheManager.saveTrainingProcesses(allProcesses)
    }
}
