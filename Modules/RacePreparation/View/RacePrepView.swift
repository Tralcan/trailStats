import SwiftUI

struct RacePrepView: View {
    @StateObject private var viewModel = RacePrepViewModel()
    @State private var selectedActivity: Activity? = nil

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Cargando carreras...")
                } else if viewModel.raceActivities.isEmpty {
                    Text("No se encontraron carreras.")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(viewModel.raceActivities) { activity in
                            ActivityRowView(activity: activity, isCached: true)
                                .onTapGesture {
                                    self.selectedActivity = activity
                                }
                        }
                    }
                }
            }
            .navigationTitle("Carreras")
            .onAppear {
                viewModel.loadRaceActivities()
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
            }
        }
    }
}
