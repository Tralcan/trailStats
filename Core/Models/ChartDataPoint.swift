import Foundation

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let time: Int
    let value: Double
}
