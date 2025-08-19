


import SwiftUI
import Charts

struct AdvancedAnalyticsView: View {
    @StateObject private var viewModel = AdvancedAnalyticsViewModel()

    enum DateRange: String, CaseIterable, Identifiable {
        case week = "7D"
        case twoWeeks = "15D"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case year = "1Y"
        var id: String { rawValue }
        var description: String { rawValue }
        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 15
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .year: return 365
            }
        }
    }

    @State private var selectedRange: DateRange = .week

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Selector de rango de fechas
                    HStack(spacing: 8) {
                        ForEach(DateRange.allCases) { range in
                            Button(action: {
                                selectedRange = range
                                viewModel.filterByDateRange(days: range.days)
                            }) {
                                Text(range.description)
                                    .font(.subheadline)
                                    .fontWeight(selectedRange == range ? .semibold : .regular)
                                    .foregroundColor(selectedRange == range ? .accentColor : .primary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedRange == range ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .center)

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
                }
            }
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
            Chart(metrics, id: \ .activityId) { metric in
                BarMark(
                    x: .value("ID", metric.activityId),
                    y: .value(label, metric[keyPath: keyPath])
                )
                .foregroundStyle(color)
                .annotation(position: .top, alignment: .center) {
                    Text(String(format: "%.2f %@", metric[keyPath: keyPath], label))
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
        var body: some View {
            Chart(activities) { activity in
                BarMark(
                    x: .value("Fecha", activity.date, unit: .day),
                    y: .value("Elevación", activity.elevationGain)
                )
                .foregroundStyle(barColor)
                .annotation(position: .top, alignment: .center) {
                    Text("\(Int(activity.elevationGain))m")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
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
        var body: some View {
            Chart(activities) { activity in
                BarMark(
                    x: .value("Fecha", activity.date, unit: .day),
                    y: .value("Distancia", activity.distance / 1000)
                )
                .foregroundStyle(barColor)
                .annotation(position: .top, alignment: .center) {
                    Text(String(format: "%.1f km", activity.distance / 1000))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
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
        var body: some View {
            Chart(activities) { activity in
                BarMark(
                    x: .value("Fecha", activity.date, unit: .day),
                    y: .value("Tiempo", activity.duration / 60)
                )
                .foregroundStyle(barColor)
                .annotation(position: .top, alignment: .center) {
                    Text(durationString(activity.duration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
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

    #Preview {
        AdvancedAnalyticsView()
    }


