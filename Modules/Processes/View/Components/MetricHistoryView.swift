import SwiftUI

struct MetricHistoryView: View {
    let metricEntries: [ProcessMetricEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historial de Métricas y Notas")
                .font(.title3).bold()
                .padding(.horizontal)

            if metricEntries.isEmpty {
                Text("No hay registros de métricas o notas para este proceso.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(metricEntries.sorted(by: { $0.date > $1.date })) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let weight = entry.weight {
                            Text("Peso: \(String(format: "%.1f", weight)) kg")
                        }
                        if let bodyFat = entry.bodyFatPercentage {
                            Text("Grasa Corporal: \(String(format: "%.1f", bodyFat))%")
                        }
                        if let leanMass = entry.leanBodyMass {
                            Text("Masa Magra: \(String(format: "%.1f", leanMass)) kg")
                        }
                        if let notes = entry.notes, !notes.isEmpty {
                            Text("Notas: \(notes)")
                                .font(.body)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .cornerRadius(8)
                }
            }
        }
    }
}