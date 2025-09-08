import SwiftUI

struct ActivitySelectionView: View {
    @StateObject private var viewModel = ActivitySelectionViewModel()
    
    var onActivitySelected: (Activity) -> Void
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Cargando actividades...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(viewModel.activities) { activity in
                        Button(action: {
                            onActivitySelected(activity)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            ActivityRowView(activity: activity, isCached: false)
                        }
                    }
                }
            }
            .navigationTitle("Asociar Carrera")
            .navigationBarItems(leading: Button("Cancelar") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                viewModel.fetchActivities()
            }
        }
    }
}