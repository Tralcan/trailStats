
import SwiftUI

struct RunningDynamicsView: View {
    let activity: Activity
    let onKpiTapped: (KpiInfo) -> Void

    private let kpiInfoData: [String: String] = [
        "Oscilación Vertical": "Mide cuánto te desplazas verticalmente con cada paso. Menos es generalmente más eficiente.",
        "Tiempo de Contacto": "El tiempo que tu pie pasa en el suelo en cada paso. Tiempos más cortos suelen indicar mayor reactividad y eficiencia.",
        "Longitud de Zancada": "La distancia que cubres con cada zancada, de un pie al otro. Varía con la velocidad y el terreno.",
        "Ratio Vertical": "La eficiencia de tu movimiento (Oscilación Vertical dividida por Longitud de Zancada). Un ratio más bajo indica que estás usando más energía para avanzar y menos para rebotar."
    ]

    var body: some View {
        if hasAnyMetric {
            VStack(alignment: .leading, spacing: 16) {
                Text("Dinámica de Carrera")
                    .font(.title2).bold()
                    .foregroundColor(.primary)

                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        if let vo = activity.verticalOscillation {
                            KPICardView(title: "Oscilación Vertical", value: String(format: "%.1f", vo), unit: "cm", icon: "arrow.up.and.down.circle.fill", color: .purple)
                                .onTapGesture {
                                    onKpiTapped(KpiInfo(title: "Oscilación Vertical", description: kpiInfoData["Oscilación Vertical"]!))
                                }
                        }
                        if let gct = activity.groundContactTime {
                            KPICardView(title: "Tiempo de Contacto", value: String(format: "%.0f", gct), unit: "ms", icon: "timer", color: .indigo)
                                .onTapGesture {
                                    onKpiTapped(KpiInfo(title: "Tiempo de Contacto", description: kpiInfoData["Tiempo de Contacto"]!))
                                }
                        }
                    }
                    HStack(spacing: 16) {
                        if let sl = activity.strideLength {
                            KPICardView(title: "Longitud de Zancada", value: String(format: "%.2f", sl), unit: "m", icon: "ruler.fill", color: .orange)
                                .onTapGesture {
                                    onKpiTapped(KpiInfo(title: "Longitud de Zancada", description: kpiInfoData["Longitud de Zancada"]!))
                                }
                        }
                        if let vr = activity.verticalRatio {
                            KPICardView(title: "Ratio Vertical", value: String(format: "%.1f", vr), unit: "%", icon: "percent", color: .teal)
                                .onTapGesture {
                                    onKpiTapped(KpiInfo(title: "Ratio Vertical", description: kpiInfoData["Ratio Vertical"]!))
                                }
                        }
                    }
                }
            }
        }
    }
    
    private var hasAnyMetric: Bool {
        activity.verticalOscillation != nil ||
        activity.groundContactTime != nil ||
        activity.strideLength != nil ||
        activity.verticalRatio != nil
    }
}
