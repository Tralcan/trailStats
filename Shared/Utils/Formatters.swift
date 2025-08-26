import Foundation

// Extensión para formatear la duración de segundos a un formato legible (HH:MM:SS o MM:SS).
public extension Int {
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
public extension Double {
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
public extension Collection where Element == Double {
    func averageOrNil() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}

// Clase de utilidad para formatear diferentes tipos de datos de la aplicación.
public class Formatters {
    
    // Formateador de fecha para mostrar en las vistas.
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // Formatea la distancia de metros a kilómetros con dos decimales.
    public static func formatDistance(_ distance: Double) -> String {
        let distanceInKm = distance / 1000.0
        return String(format: "%.2f km", distanceInKm)
    }
    
    // Formatea la elevación en metros, añadiendo "m" al final.
    public static func formatElevation(_ elevation: Double) -> String {
        return String(format: "%.0f m", elevation)
    }
    
    // Formatea la duración de segundos a un formato legible (HH:MM:SS o MM:SS).
    public static func formatTime(_ time: Int) -> String {
        return time.toHoursMinutesSeconds()
    }
    
    // Formatea el ritmo de minutos/km a un formato de ritmo (M'SS").
    public static func formatPace(_ pace: Double) -> String {
        return pace.toPaceFormat()
    }
    
    // Formatea la frecuencia cardíaca, añadiendo "lpm" (latidos por minuto).
    public static func formatHeartRate(_ hr: Double) -> String {
        return String(format: "%.0f lpm", hr)
    }
    
    // Formatea la cadencia, añadiendo "ppm" (pasos por minuto).
    public static func formatCadence(_ cadence: Double) -> String {
        return String(format: "%.0f ppm", cadence)
    }
    
    // Formatea la potencia, añadiendo "W" (vatios).
    public static func formatPower(_ power: Double) -> String {
        return String(format: "%.0f W", power)
    }
    
    // Formatea la velocidad vertical en metros por hora, añadiendo "m/h".
    public static func formatVerticalSpeed(_ speed: Double) -> String {
        return String(format: "%.0f m/h", speed)
    }
    
    // Formatea el porcentaje de desacoplamiento cardíaco.
    public static func formatDecoupling(_ decoupling: Double) -> String {
        return String(format: "%.1f%%", decoupling)
    }
    
    // Formatea el índice de eficiencia.
    public static func formatEfficiencyIndex(_ index: Double) -> String {
        return String(format: "%.3f", index)
    }
    
    // Formatea el porcentaje de pendiente.
    public static func formatGrade(_ grade: Double) -> String {
        return String(format: "%.1f%%", grade)
    }
}
