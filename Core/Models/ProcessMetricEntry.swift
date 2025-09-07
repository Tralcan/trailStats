import Foundation
import SwiftUI

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
    
    // MARK: - Computed Properties for UI
    
    enum EntryType {
        case metric
        case medico
        case kinesiologo
        case masajes
        case comentario
    }
    
    var entryType: EntryType {
        if weight != nil || bodyFatPercentage != nil || leanBodyMass != nil {
            return .metric
        }
        if let note = notes {
            switch note {
            case "Visita al Medico": return .medico
            case "Visita al Kinesiologo": return .kinesiologo
            case "Sesión de Masajes": return .masajes
            default: return .comentario
            }
        }
        return .comentario
    }
    
    var icon: (name: String, color: Color) {
        switch entryType {
        case .metric: return ("scalemass.fill", .orange)
        case .medico: return ("cross.case.fill", .red)
        case .kinesiologo: return ("figure.walk.motion", .blue)
        case .masajes: return ("hand.wave.fill", .purple)
        case .comentario: return ("text.bubble.fill", .gray)
        }
    }
}