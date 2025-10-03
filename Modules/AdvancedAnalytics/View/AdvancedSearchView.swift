import SwiftUI

struct AdvancedSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: AdvancedSearchViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Search Criteria", comment: ""))) {
                    TextField(NSLocalizedString("Name contains", comment: ""), text: $viewModel.name)
                    
                    Toggle(isOn: Binding<Bool>(
                        get: { viewModel.date != nil },
                        set: { isOn in
                            if isOn { viewModel.date = Date() } else { viewModel.date = nil }
                        }
                    )) {
                        Text(NSLocalizedString("Filter by Date", comment: ""))
                    }
                    
                    if viewModel.date != nil {
                        DatePicker(
                            NSLocalizedString("Date", comment: ""),
                            selection: Binding<Date>(
                                get: { viewModel.date ?? Date() },
                                set: { viewModel.date = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                    }
                    
                    Picker(selection: $viewModel.distance) {
                        Text(NSLocalizedString("None", comment: "")).tag(nil as Double?)
                        ForEach(1..<101) { km in
                            Text(Formatters.formatDistance(Double(km * 1000))).tag(Double(km * 1000) as Double?)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "figure.walk")
                                .foregroundColor(.red)
                            Text(NSLocalizedString("Minimum Distance (km)", comment: ""))
                        }
                    }
                    
                    Picker(selection: $viewModel.elevation) {
                        Text(NSLocalizedString("None", comment: "")).tag(nil as Double?)
                        ForEach(0..<51) { i in
                            let elevation = i * 100
                            Text(Formatters.formatElevation(Double(elevation))).tag(Double(elevation) as Double?)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "mountain.2")
                                .foregroundColor(.green)
                            Text(NSLocalizedString("Minimum Elevation (m)", comment: ""))
                        }
                    }
                    
                    Picker(selection: $viewModel.duration) {
                        Text(NSLocalizedString("None", comment: "")).tag(nil as TimeInterval?)
                        ForEach(durationOptions, id: \.self) { duration in
                            Text(format(duration: duration)).tag(duration as TimeInterval?)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text(NSLocalizedString("Minimum Duration", comment: ""))
                        }
                    }

                    Picker(selection: $viewModel.trainingTag) {
                        Text(NSLocalizedString("None", comment: "")).tag(nil as ActivityTag?)
                        ForEach(ActivityTag.allCases) { tag in
                            Text(tag.localizedName).tag(tag as ActivityTag?)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.purple)
                            Text(NSLocalizedString("Training Type", comment: ""))
                        }
                    }
                }
                
                }
            .navigationTitle(NSLocalizedString("Advanced Search", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        dismiss()
                    }
                    .foregroundColor(Color("StravaOrange"))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(NSLocalizedString("Search", comment: "")) {
                        viewModel.performSearch()
                        dismiss()
                    }
                    .foregroundColor(Color("StravaOrange"))
                }
            }
        }
    }
    
    private var durationOptions: [TimeInterval] {
        var options: [TimeInterval] = []
        // From 30 minutes to 24 hours in 30-minute increments
        for i in 1...48 {
            options.append(TimeInterval(i * 30 * 60))
        }
        return options
    }

    private func format(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

#Preview {
    AdvancedSearchView(viewModel: AdvancedSearchViewModel())
}