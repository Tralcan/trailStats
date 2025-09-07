import SwiftUI

struct AddMetricEntryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddMetricEntryViewModel

    init(process: TrainingProcess) {
        _viewModel = StateObject(wrappedValue: AddMetricEntryViewModel(process: process))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Fecha del Registro") {
                    DatePicker("Fecha", selection: $viewModel.date, displayedComponents: .date)
                }

                Section("Métricas Corporales") {
                    HStack {
                        Text("Peso (kg)")
                        Spacer()
                        TextField("Ej. 70.5", text: $viewModel.weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Grasa Corporal (%)")
                        Spacer()
                        TextField("Ej. 15.0", text: $viewModel.bodyFatPercentage)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Masa Magra (kg)")
                        Spacer()
                        TextField("Ej. 55.0", text: $viewModel.leanBodyMass)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Añadir Métrica")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        viewModel.saveMetricEntry()
                        dismiss()
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
            .onAppear {
                viewModel.fetchLatestMetrics()
            }
        }
    }
}