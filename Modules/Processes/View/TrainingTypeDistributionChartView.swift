import SwiftUI
import Charts

struct TrainingTypeDistributionChartView: View {
    // Support either a process range or a rolling day count
    private let process: TrainingProcess?
    private let dayCount: Int?

    init(process: TrainingProcess) {
        self.process = process
        self.dayCount = nil
    }

    init(dayCount: Int) {
        self.process = nil
        self.dayCount = dayCount
    }

    private struct TagCount: Identifiable {
        let id = UUID()
        let tag: ActivityTag
        let label: String
        let count: Int
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tipos de Entrenamiento")
                .font(.title2).bold()
                .foregroundColor(.primary)

            Text("Cantidad de entrenamientos por tipo en el período seleccionado.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            if data.isEmpty {
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
        Chart(data) { item in
            BarMark(
                x: .value("Tipo", item.label),
                y: .value("Entrenamientos", item.count)
            )
            .foregroundStyle(.clear)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                let plotFrame = geo[proxy.plotAreaFrame]
                let xs: [CGFloat] = data.compactMap { item in
                    if let x = proxy.position(forX: item.label) { return x } else { return nil }
                }.sorted()
                let bandwidth: CGFloat = {
                    if xs.count >= 2 {
                        let diffs = zip(xs.dropFirst(), xs).map { $0 - $1 }
                        if let minDiff = diffs.min(), minDiff > 0 { return minDiff }
                    }
                    return plotFrame.width / max(CGFloat(data.count), 1)
                }()
                ForEach(data) { item in
                    if let xPos = proxy.position(forX: item.label),
                       let yTop = proxy.position(forY: item.count),
                       let yBase = proxy.position(forY: 0) {
                        let width = bandwidth * 0.6 // Make bars thinner
                        let height = abs(yBase - yTop)
                        let rect = CGRect(x: xPos - width / 2, y: min(yTop, yBase), width: width, height: height)

                        // Use a ZStack for layering and position bar and icon independently
                        ZStack {
                            // Bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color(for: item.tag).opacity(0.2))
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(color(for: item.tag), lineWidth: 2)
                        }
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX + plotFrame.origin.x, y: rect.midY + plotFrame.origin.y)

                        // Icon positioned below the bar
                        Image(systemName: item.tag.icon)
                            .font(.caption)
                            .foregroundColor(color(for: item.tag))
                            .position(
                                x: rect.midX + plotFrame.origin.x,
                                y: rect.maxY + plotFrame.origin.y - 18 // Position icon below the bar
                            )
                    }
                }
            }
        }
        .frame(height: 300)
    }

    private var emptyStateView: some View {
        VStack {
            Spacer(minLength: 50)
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No hay datos de tipos")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            Text("Aún no hay entrenamientos para el período seleccionado.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer(minLength: 50)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var data: [TagCount] {
        let cache = CacheManager()
        let allActivities = cache.loadActivities() ?? []

        // Determine date window
        let filtered: [Activity]
        if let dayCount = dayCount {
            let fromDate = Calendar.current.date(byAdding: .day, value: -dayCount, to: Date()) ?? Date()
            filtered = allActivities.filter { $0.date >= fromDate && $0.date <= Date() }
        } else if let process = process {
            filtered = allActivities.filter { $0.date >= process.startDate && $0.date <= process.endDate }
        } else {
            filtered = []
        }

        // Only consider activities with a tag
        let tagged = filtered.compactMap { activity -> ActivityTag? in
            return activity.tag
        }

        // Build counts preserving ActivityTag order
        var countsByTag: [ActivityTag: Int] = [:]
        for tag in ActivityTag.allCases { countsByTag[tag] = 0 }
        for tag in tagged { countsByTag[tag, default: 0] += 1 }

        let ordered = ActivityTag.allCases
            .compactMap { tag -> TagCount? in
                let count = countsByTag[tag, default: 0]
                guard count > 0 else { return nil }
                return TagCount(tag: tag, label: tag.rawValue, count: count)
            }

        return ordered
    }

    private func color(for tag: ActivityTag) -> Color {
        switch tag {
        case .easyRun: return .green
        case .longRun: return .orange
        case .intensityWorkout: return .red
        case .hillWorkout: return .mint
        case .technicalWorkout: return .blue
        case .race: return .yellow
        }
    }
}

#Preview {
    TrainingTypeDistributionChartView(
        process: TrainingProcess(
            name: "Proceso Demo",
            startDate: Date().addingTimeInterval(-30*24*60*60),
            endDate: Date(),
            goal: ""
        )
    )
}
