
import SwiftUI

struct RunningDynamicsView: View {
    let verticalOscillationKPI: KPIInfo?
    let groundContactTimeKPI: KPIInfo?
    let strideLengthKPI: KPIInfo?
    let verticalRatioKPI: KPIInfo?
    let onKpiTapped: (KPIInfo) -> Void

    var body: some View {
        if hasAnyMetric {
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString("running_dynamics_title", comment: "Running Dynamics title"))
                    .font(.title2).bold()
                    .foregroundColor(.primary)

                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        if let kpi = verticalOscillationKPI {
                            KPICardView(kpi: kpi, unit: Formatters.isMetric ? "cm" : "in", icon: "arrow.up.and.down.circle.fill", color: .purple)
                                .onTapGesture { onKpiTapped(kpi) }
                        }
                        if let kpi = groundContactTimeKPI {
                            KPICardView(kpi: kpi, unit: "ms", icon: "timer", color: .indigo)
                                .onTapGesture { onKpiTapped(kpi) }
                        }
                    }
                    HStack(spacing: 16) {
                        if let kpi = strideLengthKPI {
                            KPICardView(kpi: kpi, unit: Formatters.isMetric ? "m" : "ft", icon: "ruler.fill", color: .orange)
                                .onTapGesture { onKpiTapped(kpi) }
                        }
                        if let kpi = verticalRatioKPI {
                            KPICardView(kpi: kpi, unit: "%", icon: "percent", color: .teal)
                                .onTapGesture { onKpiTapped(kpi) }
                        }
                    }
                }
            }
        }
    }
    
    private var hasAnyMetric: Bool {
        verticalOscillationKPI != nil ||
        groundContactTimeKPI != nil ||
        strideLengthKPI != nil ||
        verticalRatioKPI != nil
    }
}
