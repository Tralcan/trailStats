import SwiftUI

/// A view that displays the distribution of time spent in different heart rate zones as a donut chart.
struct HeartRateZoneView: View {
    let distribution: HeartRateZoneDistribution

    private let zoneColors: [Color] = [
        .gray, .blue, .green, .orange, .red
    ]
    
    private let zoneShortLabels = ["Z1", "Z2", "Z3", "Z4", "Z5"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Análisis por Zonas de FC")
                .font(.title2).bold()
                .foregroundColor(.primary)

            if distribution.totalTime > 0 {
                VStack(alignment: .center, spacing: 16) {
                    donutChartView
                        .padding(.horizontal, 50) // Reduces the size to about 75%
                    
                    legendView
                }
            } else {
                Text("No hay datos de frecuencia cardíaca para analizar las zonas.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var donutChartView: some View {
        let times = [
            distribution.timeInZone1,
            distribution.timeInZone2,
            distribution.timeInZone3,
            distribution.timeInZone4,
            distribution.timeInZone5
        ]
        let totalTime = distribution.totalTime
        
        var angles: [(start: Angle, end: Angle)] = []
        var currentAngle = Angle.degrees(-90)
        for time in times {
            let percentage = time / totalTime
            let endAngle = currentAngle + Angle(degrees: 360 * percentage)
            angles.append((start: currentAngle, end: endAngle))
            currentAngle = endAngle
        }

        return ZStack {
            // The donut slices
            ForEach(times.indices, id: \.self) { i in
                if times[i] > 0 {
                    DonutSliceView(
                        startAngle: angles[i].start,
                        endAngle: angles[i].end,
                        color: zoneColors[i],
                        percentage: times[i] / totalTime,
                        time: times[i]
                    )
                }
            }
            
            // Text in the center
            VStack {
                Text("\(Int(totalTime / 60))")
                    .font(.largeTitle).bold()
                    .fontDesign(.rounded)
                Text("min")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundColor(.secondary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var legendView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(0..<5) { i in
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(zoneColors[i].opacity(0.2))
                            .overlay(Rectangle().stroke(zoneColors[i], lineWidth: 2))
                            .frame(width: 14, height: 14)
                            .cornerRadius(4)
                        
                        Text(zoneShortLabels[i])
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Helper Donut Chart Components

private struct DonutSliceView: View {
    var startAngle: Angle
    var endAngle: Angle
    var color: Color
    var percentage: Double
    var time: TimeInterval
    
    private let thickness: CGFloat = 55

    var body: some View {
        ZStack {
            DonutSliceShape(startAngle: startAngle, endAngle: endAngle, thickness: thickness)
                .fill(color.opacity(0.2))
            DonutSliceShape(startAngle: startAngle, endAngle: endAngle, thickness: thickness)
                .stroke(color, lineWidth: 2)

            GeometryReader { geometry in
                let midAngle = startAngle + (endAngle - startAngle) / 2
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let labelRadius = radius - (thickness / 2)

                if percentage > 0.04 { // Only show label for significant slices
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f%%", percentage * 100))
                            .font(.caption).bold()
                        Text(Int(time).toHoursMinutesSeconds())
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .foregroundColor(color)
                    .position(x: geometry.size.width / 2 + labelRadius * cos(CGFloat(midAngle.radians)),
                              y: geometry.size.height / 2 + labelRadius * sin(CGFloat(midAngle.radians)))
                }
            }
        }
    }
}

private struct DonutSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius - thickness

        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}