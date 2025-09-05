
import Foundation

struct TrainingProcess: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var goalActivityID: Int?
    var notes: String?
    
    var isActive: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return today >= start && today <= end
    }

    // Start of process metrics
    var startWeight: Double?
    var startBodyFatPercentage: Double?
    var startLeanBodyMass: Double?

    // End of process metrics
    var endWeight: Double?
    var endBodyFatPercentage: Double?
    var endLeanBodyMass: Double?

    init(id: UUID = UUID(), 
         name: String, 
         startDate: Date, 
         endDate: Date, 
         goalActivityID: Int? = nil, 
         notes: String? = nil, 
         startWeight: Double? = nil,
         startBodyFatPercentage: Double? = nil,
         startLeanBodyMass: Double? = nil,
         endWeight: Double? = nil,
         endBodyFatPercentage: Double? = nil,
         endLeanBodymass: Double? = nil) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.goalActivityID = goalActivityID
        self.notes = notes
        self.startWeight = startWeight
        self.startBodyFatPercentage = startBodyFatPercentage
        self.startLeanBodyMass = startLeanBodyMass
        self.endWeight = endWeight
        self.endBodyFatPercentage = endBodyFatPercentage
        self.endLeanBodyMass = endLeanBodymass
    }
}
