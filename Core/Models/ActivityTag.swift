
import Foundation
import SwiftUI

enum ActivityTag: String, CaseIterable, Codable, Identifiable {
    case easyRun = "Carrera Fáciln"
    case longRun = "Carrera Larga"
    case intensityWorkout = "Entreno de Intensidad"
    case hillWorkout = "Entreno en Subidas"
    case technicalWorkout = "Entreno en Bajadas"
    case race = "Carrera o Test"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .easyRun:
            return "hare.fill"
        case .longRun:
            return "tortoise.fill"
        case .intensityWorkout:
            return "flame.fill"
        case .hillWorkout:
            return "mountain.2.fill"
        case .technicalWorkout:
            return "airplane.arrival"
        case .race:
            return "flag.checkered.2.crossed"
        }
    }
}
