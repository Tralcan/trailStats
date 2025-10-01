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
                .foregroundStyle(.clear) // Make the original bar transparent
                .annotation(position: .top) {
                    Text(String(format: "%.1f km", week.distance / 1000))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plotFrame = geo[proxy.plotAreaFrame]
                    ForEach(weeklyData) { week in
                        if let xPos = proxy.position(forX: week.id),
                           let yTop = proxy.position(forY: week.distance / 1000),
                           let yBase = proxy.position(forY: 0) {

                            let bandwidth: CGFloat = {
                                let xValues = weeklyData.map { $0.id }
                                let uniqueXValues = Array(Set(xValues)).sorted()
                                if uniqueXValues.count > 1 {
                                    let firstPos = proxy.position(forX: uniqueXValues[0]) ?? 0
                                    let secondPos = proxy.position(forX: uniqueXValues[1]) ?? 0
                                    return abs(secondPos - firstPos) * 0.8 // 80% of the band width
                                } else {
                                    return plotFrame.width * 0.8
                                }
                            }()
                            
                            let width = bandwidth * 0.8
                            let height = abs(yBase - yTop)
                            let rect = CGRect(x: xPos - width / 2, y: yTop, width: width, height: height)

                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red.opacity(0.2))
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.red, lineWidth: 1)
                            }
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX + plotFrame.origin.x, y: rect.midY + plotFrame.origin.y)
                        }
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
    let previewData = [
        WeeklyDistanceData(id: "W33 2023", distance: 45000, weekDate: Date()),
        WeeklyDistanceData(id: "W34 2023", distance: 75000, weekDate: Date()),
        WeeklyDistanceData(id: "W35 2023", distance: 60000, weekDate: Date()),
        WeeklyDistanceData(id: "W36 2023", distance: 82000, weekDate: Date())
    ]
    return WeeklyDistanceChartView(weeklyData: previewData)
}
