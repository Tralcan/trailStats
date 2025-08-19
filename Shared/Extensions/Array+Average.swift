// Extensión global para calcular el promedio seguro de un array de Double
import Foundation

extension Array where Element == Double {
    func averageOrNil() -> Double? {
        guard !self.isEmpty else { return nil }
        return self.reduce(0, +) / Double(self.count)
    }
}
