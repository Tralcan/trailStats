import Foundation

@MainActor
class ProcessesViewModel: ObservableObject {
    @Published var processes: [TrainingProcess] = []
    private let cacheManager = CacheManager()
    
    func loadProcesses() {
        self.processes = cacheManager.loadTrainingProcesses().sorted(by: { $0.startDate > $1.startDate })
    }

    func deleteProcess(at offsets: IndexSet) {
        offsets.forEach { index in
            let processToDelete = processes[index]
            cacheManager.deleteTrainingProcess(processToDelete)
        }
        processes.remove(atOffsets: offsets)
    }
}
