import SwiftUI
import Charts

/// A reusable chart view for displaying time-series data like cadence or heart rate.
struct TimeSeriesChartView: View {
    let data: [ChartDataPoint]
    let title: String
    let yAxisLabel: String
    let color: Color
    let showAverage: Bool
    let normalize: Bool

    init(data: [ChartDataPoint], title: String, yAxisLabel: String, color: Color, showAverage: Bool = true, normalize: Bool = true) {
        self.data = data
        self.title = title
        self.yAxisLabel = yAxisLabel
        self.color = color
        self.showAverage = showAverage
        self.normalize = normalize
    }
    
    var averageValue: Double {
        guard !data.isEmpty else { return 0.0 }
        if title == "Vertical Speed" {
            let positiveValues = data.filter { $0.value > 0 }.map { $0.value }
            guard !positiveValues.isEmpty else { return 0.0 }
            let total = positiveValues.reduce(0.0) { $0 + $1 }
            return total / Double(positiveValues.count)
        } else {
            let total = data.reduce(0.0) { $0 + $1.value }
            return total / Double(data.count)
        }
    }

    var unit: String {
        switch title {
        case "Cadence": return "RPM"
        case "Power": return "W"
        case "Heart Rate": return "BPM"
        case "Vertical Energy Cost": return "W/m"
        case "Vertical Speed": return "km/h"
        case "Stride Length": return "m"
        case "Pace": return "min/km"
        default: return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            if !title.isEmpty {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    if showAverage {
                        if title == "Pace" || title == "Vertical Speed" {
                            Text("Avg: " + String(format: "%.2f", averageValue) + " \(unit)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Avg: " + String(format: "%.0f", averageValue) + " \(unit)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            if normalize, let min = data.map({ $0.value }).min(), let max = data.map({ $0.value }).max(), min != max {
                Chart(data) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.time / 60),
                        y: .value(yAxisLabel, dataPoint.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                    AreaMark(
                        x: .value("Time", dataPoint.time / 60),
                        y: .value(yAxisLabel, dataPoint.value)
                    )
                    .foregroundStyle(LinearGradient(colors: [color.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 30.0)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel() {
                            if let timeInMinutes = value.as(Double.self) {
                                Text("\(Int(timeInMinutes)) min")
                            }
                        }
                    }
                }
                .chartXScale(domain: [0, (data.last?.time ?? 0) / 60])
                .chartYScale(domain: min...max)
            } else {
                Chart(data) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.time / 60),
                        y: .value(yAxisLabel, dataPoint.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                    AreaMark(
                        x: .value("Time", dataPoint.time / 60),
                        y: .value(yAxisLabel, dataPoint.value)
                    )
                    .foregroundStyle(LinearGradient(colors: [color.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 30.0)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel() {
                            if let timeInMinutes = value.as(Double.self) {
                                Text("\(Int(timeInMinutes)) min")
                            }
                        }
                    }
                }
                .chartXScale(domain: [0, (data.last?.time ?? 0) / 60])
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
