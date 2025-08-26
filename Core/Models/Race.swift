import Foundation

struct Race: Identifiable, Codable {
    let id = UUID()
    var name: String
    var distance: Double // in meters
    var elevationGain: Double // in meters
    var date: Date // New field for race date
}
