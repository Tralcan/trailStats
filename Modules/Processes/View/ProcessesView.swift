import SwiftUI
import trailStats

struct ProcessesView: View {
    @StateObject private var viewModel = ProcessesViewModel()
    @State private var isShowingCreateSheet = false
    @State private var selectedProcess: TrainingProcess? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.processes) { process in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(process.name)
                            .font(.headline)
                        HStack {
                            Text("\(process.startDate, style: .date) - \(process.endDate, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            if process.isActive {
                                Text("ACTIVO")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProcess = process
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            // Acción para editar (por ahora vacía, solo para mostrar el botón)
                            print("Editar proceso: \(process.name)")
                        } label: {
                            Text("Edit")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { indexSet in
                    viewModel.deleteProcess(at: indexSet)
                }
            }
            .navigationTitle("Procesos")
            .navigationBarItems(trailing: Button(action: {
                isShowingCreateSheet = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            })
            .onAppear {
                viewModel.loadProcesses()
            }
            .sheet(isPresented: $isShowingCreateSheet, onDismiss: {
                viewModel.loadProcesses()
            }) {
                CreateProcessView()
            }
            .sheet(item: $selectedProcess) { process in
                ProcessDetailView(process: process)
            }
        }
    }
}