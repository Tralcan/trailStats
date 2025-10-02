
import Foundation
import SwiftUI

enum ActivityTag: String, CaseIterable, Codable, Identifiable {
    case easyRun = "Easy Run"
    case longRun = "Long Run"
    case intensityWorkout = "Intensity Workout"
    case hillWorkout = "Hill Workout"
    case technicalWorkout = "Technical Workout"
    case race = "Race or Test"

    var id: String { self.rawValue }

    var localizedName: String {
        return NSLocalizedString(self.rawValue, comment: "Activity tag")
    }

    var icon: String {
        switch self {
        case .easyRun:
            return "hare.fill"
        case .longRun:
            return "tortoise.fill"
        case .intensityWorkout:
            return "flame.fill"
        case .hillWorkout:
            return "airplane.departure"
        case .technicalWorkout:
            return "airplane.arrival"
        case .race:
            return "flag.checkered.2.crossed"
        }
    }
}
