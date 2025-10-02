import SwiftUI
import Charts

struct EfficiencyChartView: View {
    let data: [ChartDataPoint]

    var body: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("Aerobic Efficiency Evolution", comment: "Aerobic Efficiency Evolution chart title"))
                .font(.title2).bold()
                .padding(.bottom, 5)
            
            Text(NSLocalizedString("Shows how your speed evolves in relation to your heart rate. An upward trend is a sign of improvement in your fitness.", comment: "Aerobic Efficiency Evolution chart description"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)

            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value(NSLocalizedString("Date", comment: "Date axis label"), Date(timeIntervalSince1970: TimeInterval(point.time))),
                        y: .value(NSLocalizedString("Index", comment: "Index axis label"), point.value)
                    )
                    .foregroundStyle(Color.accentColor)
                    
                    PointMark(
                        x: .value(NSLocalizedString("Date", comment: "Date axis label"), Date(timeIntervalSince1970: TimeInterval(point.time))),
                        y: .value(NSLocalizedString("Index", comment: "Index axis label"), point.value)
                    )
                    .foregroundStyle(Color.accentColor)
                    .annotation(position: .top) {
                        Text(String(format: "%.2f", point.value))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 300)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    // Generates placeholder data for the preview
    let placeholderData = (0..<30).compactMap { i -> ChartDataPoint? in
        guard i % 4 != 0 else { return nil } // Create some gaps
        let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
        let progressFactor = Double(i) / 30.0
        let randomFluctuation = Double.random(in: -0.05...0.05)
        let efficiency = 1.5 + (progressFactor * 0.5) + randomFluctuation
        return ChartDataPoint(time: Int(date.timeIntervalSince1970), value: efficiency)
    }.sorted(by: { $0.time < $1.time })
    
    return EfficiencyChartView(data: placeholderData)
}