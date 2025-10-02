import SwiftUI

struct KPICardView: View {
    let kpi: KPIInfo
    let unit: String
    let icon: String
    let color: Color

    private func formattedValue() -> String {
        guard let value = kpi.value else { return "--" }

        switch kpi.title {
        case KPIInfo.gap.title:
            return value.toPaceFormat(withUnit: false)
        case KPIInfo.decoupling.title:
            return String(format: "%.1f", value)
        case KPIInfo.vam.title, KPIInfo.descentVam.title:
            return String(format: "%.0f", value)
        case KPIInfo.normalizedPower.title:
            return String(format: "%.0f", value)
        case KPIInfo.efficiencyIndex.title:
            return String(format: "%.3f", value)
        case KPIInfo.verticalOscillation.title:
            return String(format: "%.1f", value)
        case KPIInfo.groundContactTime.title:
            return String(format: "%.0f", value)
        case KPIInfo.strideLength.title:
            return String(format: "%.2f", value)
        case KPIInfo.verticalRatio.title:
            return String(format: "%.1f", value)
        default:
            return String(describing: value)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(kpi.title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formattedValue())
                        .font(.title2).bold()
                        .foregroundColor(color)
                    
                    if kpi.value != nil {
                        Text(unit)
                            .font(.title2).bold()
                            .foregroundColor(color)
                    }
                }

                Spacer()

                if let trend = kpi.trend {
                    trendIcon(for: trend)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func trendIcon(for trend: KPITrend) -> some View {
        switch trend {
        case .up:
            Image(systemName: "arrow.up.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        case .down:
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.red)
                .font(.title3)
        case .equal:
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.gray)
                .font(.title3)
        }
    }
}