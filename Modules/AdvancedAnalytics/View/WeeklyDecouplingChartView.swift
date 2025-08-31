import SwiftUI
import Charts

struct WeeklyDecouplingChartView: View {
    let weeklyData: [WeeklyDecouplingData]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Desacople Cardíaco Semanal (Promedio)")
                .font(.title2).bold()
                .padding(.bottom, 5)

            Text("Muestra la evolución de tu resistencia. Un valor consistentemente bajo o en descenso indica una fuerte base aeróbica.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)

            Chart(weeklyData) { week in
                LineMark(
                    x: .value("Semana", week.id),
                    y: .value("Desacople", week.averageDecoupling)
                )
                .foregroundStyle(Color.blue)
                .symbol(Circle().strokeBorder(lineWidth: 2))
                
                PointMark(
                    x: .value("Semana", week.id),
                    y: .value("Desacople", week.averageDecoupling)
                )
                .foregroundStyle(Color.blue)
                .annotation(position: .top) {
                    Text(String(format: "%.1f%%", week.averageDecoupling))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisValueLabel(format: FloatingPointFormatStyle<Double>().precision(.fractionLength(1)))
                }
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
        WeeklyDecouplingData(id: "W33", averageDecoupling: 5.5, weekDate: Date()),
        WeeklyDecouplingData(id: "W34", averageDecoupling: 5.1, weekDate: Date()),
        WeeklyDecouplingData(id: "W35", averageDecoupling: 4.8, weekDate: Date()),
        WeeklyDecouplingData(id: "W36", averageDecoupling: 4.9, weekDate: Date())
    ]
    return WeeklyDecouplingChartView(weeklyData: previewData)
}