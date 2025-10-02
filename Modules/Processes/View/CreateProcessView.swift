import SwiftUI

struct CreateProcessView: View {
    @StateObject private var viewModel: CreateProcessViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(processToEdit: TrainingProcess? = nil) {
        _viewModel = StateObject(wrappedValue: CreateProcessViewModel(processToEdit: processToEdit))
    }
    
    private var distanceUnit: String {
        return Formatters.isMetric ? "km" : "mi"
    }
    
    private var elevationUnit: String {
        return Formatters.isMetric ? "m" : "ft"
    }
    
    private var weightUnit: String {
        return Formatters.isMetric ? "kg" : "lbs"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Process Information", comment: "Process Information section header"))) {
                    TextField(NSLocalizedString("Name (e.g. UTMB Preparation)", comment: "Process name textfield placeholder"), text: $viewModel.name)
                    DatePicker(NSLocalizedString("Start Date", comment: "Start Date date picker"), selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker(NSLocalizedString("Race Date", comment: "Race Date date picker"), selection: $viewModel.endDate, displayedComponents: .date)
                }

                Section(header: Text(NSLocalizedString("Goal", comment: "Goal section header"))) {
                    TextField(NSLocalizedString("Describe your goal for this process", comment: "Goal textfield placeholder"), text: $viewModel.goal)
                }
                
                Section(header: Text(NSLocalizedString("Target Race", comment: "Target Race section header"))) {
                    HStack {
                        Text(NSLocalizedString("Distance", comment: "Distance label"))
                        Spacer()
                        TextField(distanceUnit, text: $viewModel.raceDistance)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text(NSLocalizedString("Elevation", comment: "Elevation label"))
                        Spacer()
                        TextField(elevationUnit, text: $viewModel.raceElevation)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Only show initial metrics for new processes
                if !viewModel.isEditing {
                    Section(header: Text(NSLocalizedString("Initial Metrics", comment: "Initial Metrics section header"))) {
                        HStack {
                            Text(NSLocalizedString("Weight", comment: "Weight label"))
                            Spacer()
                            TextField(weightUnit, text: $viewModel.startWeight)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text(NSLocalizedString("Body Fat %%", comment: "Body Fat %% label"))
                            Spacer()
                            TextField(NSLocalizedString("%%", comment: "Percentage symbol"), text: $viewModel.bodyFatPercentage)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text(NSLocalizedString("Lean Body Mass", comment: "Lean Body Mass label"))
                            Spacer()
                            TextField(weightUnit, text: $viewModel.leanBodyMass)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarItems(
                leading: Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(NSLocalizedString("Save", comment: "Save button")) {
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
