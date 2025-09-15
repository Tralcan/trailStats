
import Foundation
import SwiftUI

enum ActivityTag: String, CaseIterable, Codable, Identifiable {
    case easyRun = "Carrera Fácil / Recuperación"
    case longRun = "Carrera Larga"
    case intensityWorkout = "Entrenamiento de Intensidad"
    case hillWorkout = "Entrenamiento en Subidas"
    case technicalWorkout = "Entrenamiento en Bajadas / Técnico"
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
            return "wrench.and.screwdriver.fill"
        case .race:
            return "flag.checkered.2.crossed"
        }
    }
}
