import SwiftUI

/// A view that displays performance metrics broken down by grade buckets.
struct PerformanceByGradeView: View {
    let performanceData: [PerformanceByGrade]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rendimiento por Pendiente")
                .font(.title2).bold()
                .foregroundColor(.primary)

            // Header Row
            HStack {
                Text("Pendiente")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Ritmo")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("VAM")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("Cadencia")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("Tiempo")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.footnote.weight(.semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)

            Divider()

            // Data Rows
            VStack(spacing: 12) {
                ForEach(performanceData) { data in
                    HStack {
                        Text(data.gradeBucket)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(data.averagePace.toPaceFormat())
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        Text(data.verticalSpeed != nil ? String(format: "%.0f", data.verticalSpeed!) : "--")
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        Text(data.averageCadence != nil ? String(format: "%.0f", data.averageCadence!) : "--")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        Text(Int(data.time).toHoursMinutesSeconds())
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.system(.footnote, design: .monospaced))
                    .padding(.horizontal, 8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
