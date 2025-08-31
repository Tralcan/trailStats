import SwiftUI
import Charts

struct WeeklyDistanceChartView: View {
    let weeklyData: [WeeklyDistanceData]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Distancia Semanal")
                .font(.title2).bold()
                .padding(.bottom, 5)

            Text("Visualiza el volumen total de kilómetros recorridos cada semana en el período seleccionado.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)

            Chart(weeklyData) { week in
                BarMark(
                    x: .value("Semana", week.id),
                    y: .value("Distancia", week.distance / 1000) // Convert to km
                )
                .foregroundStyle(Color.red.gradient)
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text(String(format: "%.1f km", week.distance / 1000))
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
    let previewData = [
        WeeklyDistanceData(id: "W33 2023", distance: 45000, weekDate: Date()),
        WeeklyDistanceData(id: "W34 2023", distance: 75000, weekDate: Date()),
        WeeklyDistanceData(id: "W35 2023", distance: 60000, weekDate: Date()),
        WeeklyDistanceData(id: "W36 2023", distance: 82000, weekDate: Date())
    ]
    return WeeklyDistanceChartView(weeklyData: previewData)
}
