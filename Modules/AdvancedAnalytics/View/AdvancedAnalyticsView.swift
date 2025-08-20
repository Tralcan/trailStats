import SwiftUI
import Charts

struct AdvancedAnalyticsView: View {
    @StateObject private var viewModel = AdvancedAnalyticsViewModel()
    @State private var reloadKey = UUID()
    
    enum TrainingRange: String, CaseIterable, Identifiable {
        case last7 = "7"
        case last15 = "15"
        case last30 = "30"
        case last60 = "60"
        case last90 = "90"
        var id: String { rawValue }
        var description: String {
            switch self {
            case .last7: return "7"
            case .last15: return "15"
            case .last30: return "30"
            case .last60: return "60"
            case .last90: return "90"
            }
        }
        var count: Int {
            switch self {
            case .last7: return 7
            case .last15: return 15
            case .last30: return 30
            case .last60: return 60
            case .last90: return 90
            }
        }
    }
    
    @State private var selectedRange: TrainingRange = .last7
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select number of trainings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                        Picker("Select number of trainings", selection: $selectedRange) {
                            ForEach(TrainingRange.allCases) { range in
                                Text(range.description).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 8)
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !viewModel.filteredActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            AnalyticsCard(title: "Distance per Activity", systemImage: "figure.walk", color: .red) {
                                DistanceBarChart(activities: viewModel.filteredActivities, barColor: .red, trendLineCalculator: calculateTrendLine)
                                    .frame(height: 180)
                            }
                            AnalyticsCard(title: "Elevation per Activity", systemImage: "mountain.2", color: .green) {
                                ElevationBarChart(activities: viewModel.filteredActivities, barColor: .green, trendLineCalculator: calculateTrendLine)
                                    .frame(height: 180)
                            }
                            AnalyticsCard(title: "Duration per Activity", systemImage: "hourglass", color: .blue) {
                                DurationBarChart(activities: viewModel.filteredActivities, barColor: .blue, trendLineCalculator: calculateTrendLine)
                                    .frame(height: 180)
                            }
                            ForEach(advancedMetricCards, id: \.title) { card in
                                AnalyticsCard(title: card.title, systemImage: card.systemImage, color: card.color) {
                                    MetricBarChart(metrics: viewModel.filteredMetrics, keyPath: card.keyPath, label: card.label, color: card.color, trendLineCalculator: calculateTrendLine)
                                        .frame(height: 180)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    viewModel.filterByTrainings(count: selectedRange.count)
                }
                .onChange(of: selectedRange) { newValue in
                    reloadKey = UUID()
                }
            }
            .id(reloadKey)
            .navigationTitle("Analytics")
        }
    }
    
    private func calculateTrendLine(data: [(x: Double, y: Double)]) -> [(x: Double, y: Double)] {
        guard data.count > 1 else { return [] }
        
        let n = Double(data.count)
        let sumX = data.reduce(0) { $0 + $1.x }
        let sumY = data.reduce(0) { $0 + $1.y }
        let sumXY = data.reduce(0) { $0 + $1.x * $1.y }
        let sumX2 = data.reduce(0) { $0 + $1.x * $1.x }
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        guard let firstX = data.first?.x, let lastX = data.last?.x else { return [] }
        
        return [
            (x: firstX, y: slope * firstX + intercept),
            (x: lastX, y: slope * lastX + intercept)
        ]
    }
    
    struct AdvancedMetricCard {
        let title: String
        let systemImage: String
        let color: Color
        let keyPath: KeyPath<ActivitySummaryMetrics, Double>
        let label: String
    }
    
    let advancedMetricCards: [AdvancedMetricCard] = [
        AdvancedMetricCard(title: "Vertical Energy Cost (W/m)", systemImage: "bolt.fill", color: .brown, keyPath: \.verticalEnergyCostAverage, label: "W/m"),
        AdvancedMetricCard(title: "Vertical Speed (Ascent) (km/h)", systemImage: "arrow.up.right", color: .cyan, keyPath: \.positiveVerticalSpeedAverage, label: "km/h"),
        AdvancedMetricCard(title: "Vertical Speed (Descent) (km/h)", systemImage: "arrow.down.right", color: .cyan, keyPath: \.negativeVerticalSpeedAverage, label: "km/h"),
        AdvancedMetricCard(title: "Power (W)", systemImage: "bolt.circle", color: .green, keyPath: \.powerAverage, label: "W"),
        AdvancedMetricCard(title: "Pace (min/km)", systemImage: "speedometer", color: .purple, keyPath: \.paceAverage, label: "min/km"),
        AdvancedMetricCard(title: "Heart Rate (BPM)", systemImage: "heart.fill", color: .red, keyPath: \.heartRateAverage, label: "BPM"),
        AdvancedMetricCard(title: "Stride Length (m)", systemImage: "figure.run", color: .orange, keyPath: \.strideLengthAverage, label: "m"),
        AdvancedMetricCard(title: "Cadence (RPM)", systemImage: "metronome.fill", color: .blue, keyPath: \.cadenceAverage, label: "RPM")
    ]
    
    struct MetricBarChart: View {
        let metrics: [ActivitySummaryMetrics]
        let keyPath: KeyPath<ActivitySummaryMetrics, Double>
        let label: String
        let color: Color
        let trendLineCalculator: ([(x: Double, y: Double)]) -> [(x: Double, y: Double)]
        
        private var trendLine: [(x: Double, y: Double)] {
            let data = metrics.enumerated().map { (index, metric) in
                return (x: Double(index + 1), y: metric[keyPath: keyPath])
            }
            return trendLineCalculator(data)
        }
        
        var body: some View {
            Chart {
                ForEach(Array(metrics.enumerated()), id: \.element.activityId) { (index, metric) in
                    BarMark(
                        x: .value("Training", index + 1),
                        y: .value(label, metric[keyPath: keyPath])
                    )
                    .foregroundStyle(color)
                    .annotation(position: .top) {
                        Text(String(format: "%.2f %@", metric[keyPath: keyPath], label))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !trendLine.isEmpty {
                    ForEach(trendLine, id: \.x) { point in
                        LineMark(
                            x: .value("Training", point.x),
                            y: .value("Trend", point.y)
                        )
                        .foregroundStyle(.yellow)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel(centered: true) {
                        Text("#\(value.as(Int.self) ?? 0)")
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
    
    struct AnalyticsCard<Content: View>: View {
        let title: String
        let systemImage: String
        let color: Color
        let content: Content
        init(title: String, systemImage: String, color: Color, @ViewBuilder content: () -> Content) {
            self.title = title
            self.systemImage = systemImage
            self.color = color
            self.content = content()
        }
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .foregroundColor(color)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                content
            }
            .padding(16)
            .background(.thinMaterial)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
    
    struct ElevationBarChart: View {
        let activities: [Activity]
        var barColor: Color = .green
        let trendLineCalculator: ([(x: Double, y: Double)]) -> [(x: Double, y: Double)]
        
        private var trendLine: [(x: Double, y: Double)] {
            let data = activities.enumerated().map { (index, activity) in
                return (x: Double(index + 1), y: activity.elevationGain)
            }
            return trendLineCalculator(data)
        }
        
        var body: some View {
            Chart {
                ForEach(Array(activities.enumerated()), id: \.element.id) { (index, activity) in
                    BarMark(
                        x: .value("Training", index + 1),
                        y: .value("Elevación", activity.elevationGain)
                    )
                    .foregroundStyle(barColor)
                    .annotation(position: .top) {
                        Text("\(Int(activity.elevationGain))m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !trendLine.isEmpty {
                    ForEach(trendLine, id: \.x) { point in
                        LineMark(
                            x: .value("Training", point.x),
                            y: .value("Trend", point.y)
                        )
                        .foregroundStyle(.yellow)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel(centered: true) {
                        Text("#\(value.as(Int.self) ?? 0)")
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
    
    struct DistanceBarChart: View {
        let activities: [Activity]
        var barColor: Color = .orange
        let trendLineCalculator: ([(x: Double, y: Double)]) -> [(x: Double, y: Double)]
        
        private var trendLine: [(x: Double, y: Double)] {
            let data = activities.enumerated().map { (index, activity) in
                return (x: Double(index + 1), y: activity.distance / 1000)
            }
            return trendLineCalculator(data)
        }
        
        var body: some View {
            Chart {
                ForEach(Array(activities.enumerated()), id: \.element.id) { (index, activity) in
                    BarMark(
                        x: .value("Training", index + 1),
                        y: .value("Distancia", activity.distance / 1000)
                    )
                    .foregroundStyle(barColor)
                    .annotation(position: .top) {
                        Text(String(format: "%.1f km", activity.distance / 1000))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !trendLine.isEmpty {
                    ForEach(trendLine, id: \.x) { point in
                        LineMark(
                            x: .value("Training", point.x),
                            y: .value("Trend", point.y)
                        )
                        .foregroundStyle(.yellow)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel(centered: true) {
                        Text("#\(value.as(Int.self) ?? 0)")
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
    
    struct DurationBarChart: View {
        let activities: [Activity]
        var barColor: Color = .blue
        let trendLineCalculator: ([(x: Double, y: Double)]) -> [(x: Double, y: Double)]
        
        private var trendLine: [(x: Double, y: Double)] {
            let data = activities.enumerated().map { (index, activity) in
                return (x: Double(index + 1), y: activity.duration / 60)
            }
            return trendLineCalculator(data)
        }
        
        var body: some View {
            Chart {
                ForEach(Array(activities.enumerated()), id: \.element.id) { (index, activity) in
                    BarMark(
                        x: .value("Training", index + 1),
                        y: .value("Tiempo", activity.duration / 60)
                    )
                    .foregroundStyle(barColor)
                    .annotation(position: .top) {
                        Text(durationString(activity.duration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !trendLine.isEmpty {
                    ForEach(trendLine, id: \.x) { point in
                        LineMark(
                            x: .value("Training", point.x),
                            y: .value("Trend", point.y)
                        )
                        .foregroundStyle(.yellow)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel(centered: true) {
                        Text("#\(value.as(Int.self) ?? 0)")
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        
        func durationString(_ seconds: Double) -> String {
            let minutes = Int(seconds) / 60
            let hours = minutes / 60
            let mins = minutes % 60
            if hours > 0 {
                return "\(hours)h \(mins)m"
            } else {
                return "\(mins)m"
            }
        }
    }
}