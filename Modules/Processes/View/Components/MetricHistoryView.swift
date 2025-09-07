import SwiftUI

struct MetricHistoryView: View {
    let metricEntries: [ProcessMetricEntry]
    var onDelete: ((IndexSet) -> Void)?

    // MARK: - State
    @State private var entryToDelete: ProcessMetricEntry? = nil

    // MARK: - Computed Properties
    private var sortedEntries: [ProcessMetricEntry] {
        metricEntries.sorted(by: { $0.date > $1.date })
    }

    private var groupedEntries: [Date: [ProcessMetricEntry]] {
        Dictionary(grouping: sortedEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
    }

    private var sortedDates: [Date] {
        groupedEntries.keys.sorted(by: >)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historial de Registros")
                .font(.title3).bold()
                .padding(.horizontal, 8)

            if metricEntries.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 15) {
                    ForEach(sortedDates, id: \.self) { date in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(date, style: .date)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.leading)

                            let dateEntries = groupedEntries[date] ?? []
                            ForEach(dateEntries) { entry in
                                entryRow(for: entry)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .confirmationDialog(
            "¿Seguro que quieres borrar este registro?",
            isPresented: .constant(entryToDelete != nil),
            titleVisibility: .visible
        ) {
            Button("Borrar", role: .destructive) {
                if let entry = entryToDelete {
                    delete(entry: entry)
                }
            }
            Button("Cancelar", role: .cancel) {
                entryToDelete = nil
            }
        } message: {
            if let entry = entryToDelete, let notes = entry.notes, !notes.isEmpty {
                Text(notes)
            }
        }
    }
    
    private func entryRow(for entry: ProcessMetricEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.icon.name)
                .font(.headline)
                .foregroundColor(entry.icon.color)
                .frame(width: 25)

            VStack(alignment: .leading, spacing: 3) {
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.callout)
                        .fontWeight(.medium)
                }

                if entry.entryType == .metric {
                    metricDetailView(for: entry)
                }
            }
            Spacer()
            
            Button(action: { self.entryToDelete = entry }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        .background(.thinMaterial)
        .cornerRadius(10)
    }
    
    private func delete(entry: ProcessMetricEntry) {
        if let index = sortedEntries.firstIndex(where: { $0.id == entry.id }) {
            onDelete?(IndexSet(integer: index))
        }
        entryToDelete = nil // Limpiar el estado
    }

    @ViewBuilder
    private func metricDetailView(for entry: ProcessMetricEntry) -> some View {
        HStack(spacing: 10) {
            if let weight = entry.weight {
                Label(String(format: "%.1f kg", weight), systemImage: "scalemass.fill")
            }
            if let bodyFat = entry.bodyFatPercentage {
                Label(String(format: "%.1f%%", bodyFat), systemImage: "percent")
            }
            if let leanMass = entry.leanBodyMass {
                Label(String(format: "%.1f kg", leanMass), systemImage: "figure.stand")
            }
        }
        .font(.caption)
        .foregroundColor(.primary)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer(minLength: 20)
            Text("No hay registros todavía.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
        .padding(.horizontal, 8)
    }
}