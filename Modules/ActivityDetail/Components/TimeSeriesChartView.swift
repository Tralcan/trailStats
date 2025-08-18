
import SwiftUI
import Charts

/// A reusable chart view for displaying time-series data like cadence or heart rate.
struct TimeSeriesChartView: View {
    let data: [DataPoint]
    let title: String
    let yAxisLabel: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            Chart(data) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.time),
                    y: .value(yAxisLabel, dataPoint.value)
                )
                .foregroundStyle(color)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", dataPoint.time),
                    y: .value(yAxisLabel, dataPoint.value)
                )
                .foregroundStyle(LinearGradient(colors: [color.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
            .padding()
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}


