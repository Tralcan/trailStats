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
                Section(header: 
                    HStack(spacing: 0) {
                        Text(NSLocalizedString("Training Cycle Part 1", comment: ""))
                            .foregroundColor(.primary)
                        Text(NSLocalizedString("Training Cycle Part 2", comment: ""))
                            .foregroundColor(Color("StravaOrange"))
                    }
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                    .textCase(nil) // Prevents the header from being uppercased
                ) {
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
                                    Text(NSLocalizedString("ACTIVE", comment: "Active process label"))
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
                                Label(NSLocalizedString("Edit", comment: "Edit button"), systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.deleteProcess(at: indexSet)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingCreateSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
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