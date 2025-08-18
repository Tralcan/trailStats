
import Foundation

// MARK: - DataPoint Model
/// Represents a single data point in a time series, useful for charting.
/// Conforms to Identifiable to be used in SwiftUI lists and charts.
struct DataPoint: Identifiable {
    let id = UUID()
    let time: Double // Represents time in seconds from the start
    let value: Double // The value of the metric (e.g., cadence, power)
}
