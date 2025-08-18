import SwiftUI

struct AdvancedSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: AdvancedSearchViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search Criteria")) {
                    TextField("Name contains", text: $viewModel.name)
                    
                    Toggle(isOn: Binding<Bool>(
                        get: { viewModel.date != nil },
                        set: { isOn in
                            if isOn { viewModel.date = Date() } else { viewModel.date = nil }
                        }
                    )) {
                        Text("Filter by Date")
                    }
                    
                    if viewModel.date != nil {
                        DatePicker(
                            "Date",
                            selection: Binding<Date>(
                                get: { viewModel.date ?? Date() },
                                set: { viewModel.date = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                    }
                    
                    Picker(selection: $viewModel.distance) {
                        Text("None").tag(nil as Double?)
                        ForEach(1..<101) { km in
                            Text("\(km) km").tag(Double(km * 1000) as Double?)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "figure.walk")
                                .foregroundColor(.red)
                            Text("Minimum Distance (km)")
                        }
                    }
                    
                    Picker(selection: $viewModel.elevation) {
                        Text("None").tag(nil as Double?)
                        ForEach(0..<51) { i in
                            let elevation = i * 100
                            Text("\(elevation) m").tag(Double(elevation) as Double?)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "mountain.2")
                                .foregroundColor(.green)
                            Text("Minimum Elevation (m)")
                        }
                    }
                }
                
                }
            .navigationTitle("Advanced Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.0))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Search") {
                        viewModel.performSearch()
                        dismiss()
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.0))
                }
            }
        }
    }
}

#Preview {
    AdvancedSearchView(viewModel: AdvancedSearchViewModel())
}