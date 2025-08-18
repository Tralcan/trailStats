import SwiftUI
import Charts

/// A reusable chart view for displaying time-series data like cadence or heart rate.
struct TimeSeriesChartView: View {
    let data: [DataPoint]
    let title: String
    let yAxisLabel: String
    let color: Color
    let showAverage: Bool
    
    init(data: [DataPoint], title: String, yAxisLabel: String, color: Color, showAverage: Bool = true) {
        self.data = data
        self.title = title
        self.yAxisLabel = yAxisLabel
        self.color = color
        self.showAverage = showAverage
    }
    
    var averageValue: Double {
        guard !data.isEmpty else { return 0.0 }
        let total = data.reduce(0.0) { $0 + $1.value }
        return total / Double(data.count)
    }

    var unit: String {
        switch title {
        case "Cadence":
            return "RPM"
        case "Power":
            return "W"
        case "Heart Rate":
            return "BPM"
        default:
            return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if showAverage {
                    Text("Avg: \(averageValue, specifier: "%.0f") \(unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Chart(data) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.time / 60), // Convert to minutes
                    y: .value(yAxisLabel, dataPoint.value)
                )
                .foregroundStyle(color)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", dataPoint.time / 60), // Convert to minutes
                    y: .value(yAxisLabel, dataPoint.value)
                )
                .foregroundStyle(LinearGradient(colors: [color.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis { // Configure X-axis
                AxisMarks(values: .stride(by: 30.0)) { value in // Stride by 30 minutes
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel() {
                        if let timeInMinutes = value.as(Double.self) {
                            Text("\(Int(timeInMinutes)) min") // Display in minutes
                        }
                    }
                }
            }
            .frame(height: 200)
            .chartXScale(domain: [0, (data.last?.time ?? 0) / 60])
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}