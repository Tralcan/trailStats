import SwiftUI
import Charts

struct IntensityChartView: View {
    let weeklyData: [WeeklyZoneData]

    private let zoneColors: [Color] = [.gray, .blue, .green, .orange, .red]
    private let zoneDomains: [String] = ["Z1", "Z2", "Z3", "Z4", "Z5"]

    var body: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("Weekly Intensity", comment: "Weekly Intensity chart title"))
                .font(.title2).bold()
                .padding(.bottom, 5)

            Text(NSLocalizedString("Shows the percentage of time you spend in each Heart Rate Zone each week. Ideal for seeing the balance between easy and hard workouts.", comment: "Weekly Intensity chart description"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)

            if weeklyData.isEmpty {
                emptyStateView
            } else {
                chartView
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var chartView: some View {
        Chart(weeklyData) { week in
            WeeklyBarMarks(week: week)
        }
        .chartForegroundStyleScale(domain: zoneDomains, range: zoneColors.map { $0.opacity(0.4) })
        .chartXAxis {
            AxisMarks(values: .automatic) {
                AxisValueLabel(centered: false)
            }
        }
        .chartYAxis {
            AxisMarks(format: FloatingPointFormatStyle<Double>.Percent())
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                let plotFrame = geo[proxy.plotAreaFrame]
                ForEach(weeklyData) { week in
                    if let xPos = proxy.position(forX: week.id),
                       let yMax = proxy.position(forY: 1.0),
                       let yMin = proxy.position(forY: 0.0) {

                        let bandwidth: CGFloat = {
                            let xValues = weeklyData.map { $0.id }
                            let uniqueXValues = Array(Set(xValues)).sorted()
                            if uniqueXValues.count > 1 {
                                let firstPos = proxy.position(forX: uniqueXValues[0]) ?? 0
                                let secondPos = proxy.position(forX: uniqueXValues[1]) ?? 0
                                return abs(secondPos - firstPos) * 0.8
                            } else {
                                return plotFrame.width * 0.8
                            }
                        }()

                        let rect = CGRect(x: xPos - bandwidth / 2, y: yMax, width: bandwidth, height: yMin - yMax)

                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.5), lineWidth: 1)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX + plotFrame.origin.x, y: rect.midY + plotFrame.origin.y)
                    }
                }
            }
        }
        .frame(height: 300)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer(minLength: 50)
            Image(systemName: "waveform.path.ecg.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(NSLocalizedString("No intensity data", comment: "Empty state title for intensity chart"))
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            Text(NSLocalizedString("Activities need heart rate data to calculate intensity.", comment: "Empty state message for intensity chart"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer(minLength: 50)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// Helper struct conforming to ChartContent to simplify the main chart view
private struct WeeklyBarMarks: ChartContent {
    let week: WeeklyZoneData
    
    private var totalTime: Double {
        let total = week.timeInZones.reduce(0, +)
        return total > 0 ? total : 1
    }
    
    var body: some ChartContent {
        ForEach(Array(week.timeInZones.enumerated()), id: \.offset) { index, timeInZone in
            let zoneName = "Z\(index + 1)"
            let percentage = timeInZone / totalTime
            
            BarMark(
                x: .value(NSLocalizedString("Week", comment: "Week axis label"), week.id),
                y: .value(NSLocalizedString("Percentage", comment: "Percentage axis label"), percentage)
            )
            .foregroundStyle(by: .value(NSLocalizedString("Zone", comment: "Zone legend label"), zoneName))
        }
    }
}


#Preview {
    let previewData = [
        WeeklyZoneData(id: "W33 2023", timeInZones: [1800, 3600, 1200, 600, 100], weekDate: Date()),
        WeeklyZoneData(id: "W34 2023", timeInZones: [2200, 4000, 1500, 800, 150], weekDate: Date()),
        WeeklyZoneData(id: "W35 2023", timeInZones: [1500, 3300, 1100, 500, 50], weekDate: Date()),
        WeeklyZoneData(id: "W36 2023", timeInZones: [2500, 4500, 1800, 900, 200], weekDate: Date())
    ]
    return IntensityChartView(weeklyData: previewData)
}
