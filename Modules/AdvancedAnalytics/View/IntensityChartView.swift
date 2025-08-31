import SwiftUI
import Charts

struct IntensityChartView: View {
    let weeklyData: [WeeklyZoneData]

    private let zoneColors: [Color] = [.gray, .blue, .green, .orange, .red]
    private let zoneDomains: [String] = ["Z1", "Z2", "Z3", "Z4", "Z5"]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Intensidad Semanal")
                .font(.title2).bold()
                .padding(.bottom, 5)

            Text("Muestra el porcentaje de tiempo que pasas en cada Zona de Frecuencia Cardíaca cada semana. Ideal para ver el balance entre entrenamientos suaves y duros.")
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
        .chartForegroundStyleScale(domain: zoneDomains, range: zoneColors)
        .chartXAxis {
            AxisMarks(values: .automatic) {
                AxisValueLabel(centered: false)
            }
        }
        .chartYAxis {
            AxisMarks(format: FloatingPointFormatStyle<Double>.Percent())
        }
        .frame(height: 300)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer(minLength: 50)
            Image(systemName: "waveform.path.ecg.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No hay datos de intensidad")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            Text("Las actividades necesitan datos de frecuencia cardíaca para calcular la intensidad.")
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
                x: .value("Semana", week.id),
                y: .value("Porcentaje", percentage)
            )
            .foregroundStyle(by: .value("Zona", zoneName))
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