import Foundation

struct CoachingHistory: Codable, Identifiable {
    var id: UUID
    let activityId: String
    let date: Date
    let recommendationsToImprove: [String]
    let positives: [String]

    init(activityId: String, date: Date, recommendationsToImprove: [String], positives: [String]) {
        self.id = UUID()
        self.activityId = activityId
        self.date = date
        self.recommendationsToImprove = recommendationsToImprove
        self.positives = positives
    }
}
