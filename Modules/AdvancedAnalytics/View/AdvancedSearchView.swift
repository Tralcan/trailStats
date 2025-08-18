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
                        Label("Minimum Distance (km)", systemImage: "figure.walk")
                            .foregroundColor(.red)
                    }
                    
                    Picker(selection: $viewModel.elevation) {
                        Text("None").tag(nil as Double?)
                        ForEach(0..<51) { i in
                            let elevation = i * 100
                            Text("\(elevation) m").tag(Double(elevation) as Double?)
                        }
                    } label: {
                        Label("Minimum Elevation (m)", systemImage: "mountain.2")
                            .foregroundColor(.green)
                    }
                }
                
                VStack {
                    Button("Search") {
                        viewModel.performSearch()
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Advanced Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AdvancedSearchView(viewModel: AdvancedSearchViewModel())
}