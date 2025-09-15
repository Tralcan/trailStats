import SwiftUI
import trailStats

struct ProcessesView: View {
    @StateObject private var viewModel = ProcessesViewModel()
    @State private var isShowingCreateSheet = false
    @State private var selectedProcess: TrainingProcess? = nil
    @State private var processToEdit: TrainingProcess? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.processes) { processData in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: processData.hasGoalActivity ? "medal.fill" : "sparkles")
                                .foregroundColor(processData.hasGoalActivity ? .yellow : .cyan)
                            Text(processData.name)
                                .font(.headline)
                                .lineLimit(2)
                        }
                        HStack {
                            Text(processData.dates)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            if processData.isActive {
                                Text("ACTIVO")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        }
                        
                        HStack(spacing: 15) {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.red)
                                Text(processData.distance)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "mountain.2.fill")
                                    .foregroundColor(.green)
                                Text(processData.elevation)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "hourglass")
                                    .foregroundColor(.blue)
                                Text(processData.time)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProcess = processData.process
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            processToEdit = processData.process
                        } label: {
                            Label("Editar", systemImage: "pencil")
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
            .task {
                await viewModel.loadProcesses()
            }
            .sheet(isPresented: $isShowingCreateSheet, onDismiss: {
                Task { await viewModel.loadProcesses() }
            }) {
                CreateProcessView()
            }
            .sheet(item: $selectedProcess) { process in
                ProcessDetailView(process: process)
            }
            .sheet(item: $processToEdit, onDismiss: {
                Task { await viewModel.loadProcesses() }
            }) { process in
                CreateProcessView(processToEdit: process)
            }
        }
    }
}