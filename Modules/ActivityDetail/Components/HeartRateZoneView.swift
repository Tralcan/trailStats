import SwiftUI

/// A view that displays the distribution of time spent in different heart rate zones.
struct HeartRateZoneView: View {
    let distribution: HeartRateZoneDistribution

    private let zoneColors: [Color] = [
        .gray.opacity(0.7),
        .blue.opacity(0.8),
        .green.opacity(0.8),
        .orange.opacity(0.8),
        .red.opacity(0.8)
    ]
    
    private let zoneLabels = ["Z1 (Recuperación)", "Z2 (Aeróbico)", "Z3 (Tempo)", "Z4 (Umbral)", "Z5 (Anaeróbico)"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Análisis por Zonas de FC")
                .font(.title2).bold()
                .foregroundColor(.primary)

            if distribution.totalTime > 0 {
                VStack(spacing: 12) {
                    ForEach(0..<5) { i in
                        zoneBarView(zoneIndex: i)
                    }
                }
            } else {
                Text("No hay datos de frecuencia cardíaca para analizar las zonas.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func zoneBarView(zoneIndex: Int) -> some View {
        let timeInZone = getTime(for: zoneIndex)
        let percentage = distribution.totalTime > 0 ? (timeInZone / distribution.totalTime) : 0
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(zoneLabels[zoneIndex])
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Text(Int(timeInZone).toHoursMinutesSeconds())
                    .font(.footnote)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                    
                    Capsule()
                        .fill(zoneColors[zoneIndex])
                        .frame(width: geometry.size.width * percentage)
                    
                    if percentage > 0.1 {
                        Text(String(format: "%.0f%%", percentage * 100))
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.leading, 6)
                    }
                }
            }
            .frame(height: 22)
        }
    }

    private func getTime(for zone: Int) -> TimeInterval {
        switch zone {
        case 0: return distribution.timeInZone1
        case 1: return distribution.timeInZone2
        case 2: return distribution.timeInZone3
        case 3: return distribution.timeInZone4
        case 4: return distribution.timeInZone5
        default: return 0
        }
    }
}
