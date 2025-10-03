import SwiftUI

// Data structure for a single data point on the radar chart
struct RadarChartDataPoint {
    let label: String
    let currentValue: Double
    let averageValue: Double
    let color: Color
}

// The main Radar Chart View
struct RadarChartView: View {
    let data: [RadarChartDataPoint]
    let maxValue: Double // The outer edge of the chart

    // Configuration for colors and style
    private let gridColor = Color.gray.opacity(0.5)
    private let averageColor = Color.orange
    private let currentColor = Color.blue
    private let labelFont: Font = .caption

    var body: some View {
        VStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 * 0.8 // Leave space for labels

                drawGrid(context: &context, center: center, radius: radius)
                drawAxes(context: &context, center: center, radius: radius)
                drawLabels(context: &context, center: center, radius: radius)

                // Draw average values polygon
                drawDataPolygon(
                    context: &context,
                    center: center,
                    radius: radius,
                    values: data.map { $0.averageValue },
                    color: averageColor
                )

                // Draw current values polygon
                drawDataPolygon(
                    context: &context,
                    center: center,
                    radius: radius,
                    values: data.map { $0.currentValue },
                    color: currentColor
                )

            }
            
            legendView
                .padding(.top, 8)
        }
    }

    // Draws the concentric grid lines
    private func drawGrid(context: inout GraphicsContext, center: CGPoint, radius: Double) {
        let steps = 4 // e.g., 25%, 50%, 75%, 100%
        for i in 1...steps {
            let r = radius * (Double(i) / Double(steps))
            let path = Path { p in
                let angleStep = 2 * .pi / Double(data.count)
                for j in 0..<data.count {
                    let angle = angleStep * Double(j) - .pi / 2
                    let point = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                    if j == 0 {
                        p.move(to: point)
                    } else {
                        p.addLine(to: point)
                    }
                }
                p.closeSubpath()
            }
            context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
        }
    }

    // Draws the lines from the center to the outer edge
    private func drawAxes(context: inout GraphicsContext, center: CGPoint, radius: Double) {
        let angleStep = 2 * .pi / Double(data.count)
        for i in 0..<data.count {
            let angle = angleStep * Double(i) - .pi / 2
            let endPoint = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            let path = Path { p in
                p.move(to: center)
                p.addLine(to: endPoint)
            }
            context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
        }
    }

    // Draws the KPI labels
    private func drawLabels(context: inout GraphicsContext, center: CGPoint, radius: Double) {
        let angleStep = 2 * .pi / Double(data.count)
        let labelRadius = radius * 1.1

        for i in 0..<data.count {
            let angle = angleStep * Double(i) - .pi / 2
            let labelPoint = CGPoint(x: center.x + labelRadius * cos(angle), y: center.y + labelRadius * sin(angle))
            
            let angleDegrees = (angle * 180 / .pi) + 90
            var anchor: UnitPoint
            
            if angleDegrees > 350 || angleDegrees < 10 { anchor = .bottom }
            else if angleDegrees > 170 && angleDegrees < 190 { anchor = .top }
            else if angleDegrees >= 190 && angleDegrees <= 350 { anchor = .trailing }
            else { anchor = .leading }
            
            let labelText = Text(data[i].label).font(labelFont).foregroundColor(data[i].color)
            context.draw(labelText, at: labelPoint, anchor: anchor)
        }
    }

    // Generic function to draw a data polygon (fill and stroke)
    private func drawDataPolygon(context: inout GraphicsContext, center: CGPoint, radius: Double, values: [Double], color: Color) {
        let path = Path { p in
            let angleStep = 2 * .pi / Double(data.count)
            for i in 0..<values.count {
                let value = values[i]
                let r = radius * (min(value, maxValue) / maxValue)
                let angle = angleStep * Double(i) - .pi / 2
                let point = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                
                if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
            }
            p.closeSubpath()
        }
        context.fill(path, with: .color(color.opacity(0.2)))
        context.stroke(path, with: .color(color), lineWidth: 2)
    }
    
    // Legend view with filled rectangles and a border
    private var legendView: some View {
        HStack(spacing: 20) {
            HStack {
                Rectangle()
                    .fill(currentColor.opacity(0.2))
                    .stroke(currentColor, lineWidth: 2)
                    .frame(width: 15, height: 15)
                Text(NSLocalizedString("Current Activity", comment: "Current Activity")).font(.caption)
            }
            HStack {
                Rectangle()
                    .fill(averageColor.opacity(0.2))
                    .stroke(averageColor, lineWidth: 2)
                    .frame(width: 15, height: 15)
                Text(NSLocalizedString("Average", comment: "Average")).font(.caption)
            }
        }
    }
}

#if DEBUG
struct RadarChartView_Previews: PreviewProvider {
    static var sampleData: [RadarChartDataPoint] = [
        .init(label: "Potencia", currentValue: 85, averageValue: 75, color: .green),
        .init(label: "FC", currentValue: 60, averageValue: 70, color: .red),
        .init(label: "Cadencia", currentValue: 90, averageValue: 80, color: .blue),
        .init(label: "T. Contacto", currentValue: 50, averageValue: 65, color: .purple),
        .init(label: "Osc. Vertical", currentValue: 40, averageValue: 55, color: .yellow),
        .init(label: "Ratio Vert.", currentValue: 75, averageValue: 60, color: .mint)
    ]

    static var previews: some View {
        RadarChartView(data: sampleData, maxValue: 100)
            .padding()
            .background(Color.gray.opacity(0.1))
    }
}
#endif
