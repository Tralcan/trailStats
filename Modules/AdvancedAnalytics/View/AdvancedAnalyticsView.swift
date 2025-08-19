


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
                    Text("Analytics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    // Selector de rango de entrenamientos
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select trainings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Picker("Select trainings", selection: $selectedRange) {
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
                                DistanceBarChart(activities: viewModel.filteredActivities, barColor: .red)
                                    .frame(height: 180)
                            }
                            AnalyticsCard(title: "Elevation per Activity", systemImage: "mountain.2", color: .green) {
                                ElevationBarChart(activities: viewModel.filteredActivities, barColor: .green)
                                    .frame(height: 180)
                            }
                            AnalyticsCard(title: "Duration per Activity", systemImage: "hourglass", color: .blue) {
                                DurationBarChart(activities: viewModel.filteredActivities, barColor: .blue)
                                    .frame(height: 180)
                            }
                            // NUEVOS GRÁFICOS DE MÉTRICAS AVANZADAS
                            ForEach(advancedMetricCards, id: \.title) { card in
                                AnalyticsCard(title: card.title, systemImage: card.systemImage, color: card.color) {
                                    MetricBarChart(metrics: viewModel.filteredMetrics, keyPath: card.keyPath, label: card.label, color: card.color)
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
                    // Forzar recarga del ViewModel para obtener datos nuevos del caché
                    reloadKey = UUID()
                }
            }
            .id(reloadKey)
        }
    }
    
    
    // Definición de las tarjetas de métricas avanzadas fuera de la vista y con keyPath correcto
    struct AdvancedMetricCard {
        let title: String
        let systemImage: String
        let color: Color
        let keyPath: KeyPath<ActivitySummaryMetrics, Double>
        let label: String
    }
    
    let advancedMetricCards: [AdvancedMetricCard] = [
        AdvancedMetricCard(title: "Vertical Energy Cost (W/m)", systemImage: "bolt.fill", color: .purple, keyPath: \ActivitySummaryMetrics.verticalEnergyCostAverage, label: "W/m"),
        AdvancedMetricCard(title: "Vertical Speed (km/h)", systemImage: "arrow.up.right", color: .teal, keyPath: \ActivitySummaryMetrics.verticalSpeedAverage, label: "km/h"),
        AdvancedMetricCard(title: "Power (W)", systemImage: "bolt.circle", color: .orange, keyPath: \ActivitySummaryMetrics.powerAverage, label: "W"),
        AdvancedMetricCard(title: "Pace (min/km)", systemImage: "speedometer", color: .pink, keyPath: \ActivitySummaryMetrics.paceAverage, label: "min/km"),
        AdvancedMetricCard(title: "Heart Rate (BPM)", systemImage: "heart.fill", color: .red, keyPath: \ActivitySummaryMetrics.heartRateAverage, label: "BPM"),
        AdvancedMetricCard(title: "Stride Length (m)", systemImage: "figure.run", color: .indigo, keyPath: \ActivitySummaryMetrics.strideLengthAverage, label: "m"),
        AdvancedMetricCard(title: "Cadence (RPM)", systemImage: "metronome.fill", color: .cyan, keyPath: \ActivitySummaryMetrics.cadenceAverage, label: "RPM")
    ]
    
    // Gráfico genérico para métricas avanzadas
    struct MetricBarChart: View {
        let metrics: [ActivitySummaryMetrics]
        let keyPath: KeyPath<ActivitySummaryMetrics, Double>
        let label: String
        let color: Color
        var body: some View {
            Chart(Array(metrics.enumerated()), id: \ .element.activityId) { (index, metric) in
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
            //
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
            //
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
        var body: some View {
            Chart(Array(activities.enumerated()), id: \ .element.id) { (index, activity) in
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
            //
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
            //
        }
    }
    
    struct DistanceBarChart: View {
        let activities: [Activity]
        var barColor: Color = .orange
        var body: some View {
            Chart(Array(activities.enumerated()), id: \ .element.id) { (index, activity) in
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
            //
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
            //
        }
    }
    
    struct DurationBarChart: View {
        let activities: [Activity]
        var barColor: Color = .blue
        var body: some View {
            Chart(Array(activities.enumerated()), id: \ .element.id) { (index, activity) in
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
            //
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
            //
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
    
    //
    
    
}
