import Foundation

struct TrainingProcess: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var goalActivityID: Int?
    var metricEntries: [ProcessMetricEntry] // Nuevo array para los registros

    var isActive: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return today >= start && today <= end
    }

    init(id: UUID = UUID(),
         name: String,
         startDate: Date,
         endDate: Date,
         goalActivityID: Int? = nil,
         metricEntries: [ProcessMetricEntry] = []) { // Inicializador actualizado
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.goalActivityID = goalActivityID
        self.metricEntries = metricEntries
    }
}