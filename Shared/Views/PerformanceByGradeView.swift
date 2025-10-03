import SwiftUI

/// A view that displays performance metrics broken down by grade buckets.
struct PerformanceByGradeView: View {
    let performanceData: [PerformanceByGrade]
    var onKpiTapped: ((KPIInfo) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Performance by Grade", comment: "Performance by Grade section title"))
                .font(.title2).bold()
                .foregroundColor(.primary)

            // Header Row
            HStack {
                Text(NSLocalizedString("Grade", comment: "Grade column header"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(NSLocalizedString("Pace", comment: "Pace column header"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(NSLocalizedString("VAM", comment: "VAM column header"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .onTapGesture {
                        onKpiTapped?(KPIInfo(title: NSLocalizedString("kpi.vamGrade.title", comment: "VAM Grade KPI title"), description: NSLocalizedString("kpi.vamGrade.description", comment: "VAM Grade KPI description"), higherIsBetter: true))
                    }
                Text(NSLocalizedString("Cadence", comment: "Cadence column header"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(NSLocalizedString("Time", comment: "Time column header"))
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
                        
                        let verticalSpeed = data.verticalSpeed.map { Formatters.isMetric ? $0 : $0 * 3.28084 }
                        Text(verticalSpeed != nil ? String(format: "%.0f", verticalSpeed!) : "--")
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