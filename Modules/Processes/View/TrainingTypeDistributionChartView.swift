import SwiftUI
import Charts

struct TrainingTypeDistributionChartView: View {
    let process: TrainingProcess
    
    private struct TagCount: Identifiable {
        let id = UUID()
        let tag: ActivityTag
        let label: String
        let count: Int
    }
    
    private var data: [TagCount] {
        let activities = CacheManager().loadActivities()
        
        // Filter activities by date range and tag not nil
        let filtered = activities.filter {
            guard let tag = $0.tag else { return false }
            return (process.startDate...process.endDate).contains($0.date)
        }
        
        // Group by ActivityTag and count
        var countsDict: [ActivityTag: Int] = [:]
        for activity in filtered {
            if let tag = activity.tag {
                countsDict[tag, default: 0] += 1
            }
        }
        
        // Build array ordered by ActivityTag.allCases and only counts > 0
        return ActivityTag.allCases.compactMap { tag in
            guard let count = countsDict[tag], count > 0 else { return nil }
            return TagCount(tag: tag, label: tag.description, count: count)
        }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tipos de Entrenamiento")
                .font(.title2)
                .bold()
            Text("Distribución de los tipos de entrenamiento en el rango de fechas seleccionado.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if data.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.bargraph.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.secondary)
                    Text("No hay datos")
                        .font(.title3)
                        .bold()
                    Text("No se encontraron entrenamientos para el rango de fechas seleccionado.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Tipo", item.label),
                        y: .value("Entrenamientos", item.count)
                    )
                    .foregroundStyle(color(for: item.tag).opacity(0.2))
                }
                .chartXAxis {
                    AxisMarks()
                }
                .chartYAxis {
                    AxisMarks(values: .stride(by: 1)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .frame(height: 300)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

#Preview {
    let now = Date()
    let oneDay: TimeInterval = 24 * 60 * 60
    let demoProcess = TrainingProcess(
        startDate: now.addingTimeInterval(-oneDay * 5),
        endDate: now.addingTimeInterval(oneDay * 5)
    )
    TrainingTypeDistributionChartView(process: demoProcess)
}
