import SwiftUI

struct CreateProcessView: View {
    @StateObject private var viewModel = CreateProcessViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información del Proceso")) {
                    TextField("Nombre (Ej: Preparación UTMB)", text: $viewModel.name)
                    DatePicker("Fecha de Inicio", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker("Fecha de la Carrera", selection: $viewModel.endDate, displayedComponents: .date)
                }
                
                Section(header: Text("Métricas Iniciales")) {
                    HStack {
                        Text("Peso")
                        Spacer()
                        TextField("kg", text: $viewModel.startWeight)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("% Grasa Corporal")
                        Spacer()
                        TextField("%", text: $viewModel.bodyFatPercentage)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Masa Magra")
                        Spacer()
                        TextField("kg", text: $viewModel.leanBodyMass)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Notas")) {
                    TextEditor(text: $viewModel.notes)
                        .frame(height: 150)
                }
            }
            .navigationTitle("Nuevo Proceso")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Guardar") {
                    viewModel.save()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(!viewModel.isFormValid)
            )
            .onAppear {
                viewModel.fetchInitialMetrics()
            }
        }
    }
}

#Preview {
    CreateProcessView()
}
