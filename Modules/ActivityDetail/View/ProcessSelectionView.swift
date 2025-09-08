import SwiftUI

struct ProcessSelectionView: View {
    @Binding var isPresented: Bool
    let processes: [TrainingProcess]
    let onSelectProcess: (TrainingProcess) -> Void

    var body: some View {
        NavigationView {
            List(processes) { process in
                Button(action: {
                    onSelectProcess(process)
                    isPresented = false
                }) {
                    VStack(alignment: .leading) {
                        Text(process.name)
                            .font(.headline)
                        Text("\(process.startDate, style: .date) - \(process.endDate, style: .date)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Seleccionar Proceso")
            .navigationBarItems(trailing: Button("Cancelar") {
                isPresented = false
            })
        }
    }
}
