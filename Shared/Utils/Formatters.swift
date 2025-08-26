import Foundation

// Extensión para formatear la duración de segundos a un formato legible (HH:MM:SS o MM:SS).
extension Int {
    func toHoursMinutesSeconds() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = (self % 3600) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// Extensión para formatear un valor Double que representa minutos/km a un formato de ritmo (M'SS").
extension Double {
    func toPaceFormat() -> String {
        if self.isInfinite || self.isNaN {
            return "--'--\"/km"
        }
        let totalSeconds = self * 60
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%d'%02d\"/km", minutes, seconds)
    }
}

// Extensión para calcular el promedio de una colección de Doubles de forma segura.
extension Collection where Element == Double {
    func averageOrNil() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}