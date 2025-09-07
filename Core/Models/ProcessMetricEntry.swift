import Foundation

struct ProcessMetricEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    var weight: Double?
    var bodyFatPercentage: Double?
    var leanBodyMass: Double?
    var notes: String?

    init(id: UUID = UUID(), date: Date, weight: Double? = nil, bodyFatPercentage: Double? = nil, leanBodyMass: Double? = nil, notes: String? = nil) {
        self.id = id
        self.date = date
        self.weight = weight
        self.bodyFatPercentage = bodyFatPercentage
        self.leanBodyMass = leanBodyMass
        self.notes = notes
    }
}