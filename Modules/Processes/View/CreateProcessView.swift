import SwiftUI

struct CreateProcessView: View {
    @StateObject private var viewModel: CreateProcessViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(processToEdit: TrainingProcess? = nil) {
        _viewModel = StateObject(wrappedValue: CreateProcessViewModel(processToEdit: processToEdit))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información del Proceso")) {
                    TextField("Nombre (Ej: Preparación UTMB)", text: $viewModel.name)
                    DatePicker("Fecha de Inicio", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker("Fecha de la Carrera", selection: $viewModel.endDate, displayedComponents: .date)
                }

                Section(header: Text("Objetivo")) {
                    TextField("Describe tu objetivo para este proceso", text: $viewModel.goal)
                }
                
                Section(header: Text("Carrera Objetivo")) {
                    HStack {
                        Text("Distancia")
                        Spacer()
                        TextField("km", text: $viewModel.raceDistance)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Desnivel")
                        Spacer()
                        TextField("m", text: $viewModel.raceElevation)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Only show initial metrics for new processes
                if viewModel.navigationTitle == "Nuevo Proceso" {
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
                            TextField("%%", text: $viewModel.bodyFatPercentage)
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
                }
            }
            .navigationTitle(viewModel.navigationTitle)
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
    CreateProcessView(processToEdit: nil)
}