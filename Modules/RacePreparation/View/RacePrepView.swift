import SwiftUI

struct RacePrepView: View {
    @StateObject private var viewModel = RacePrepViewModel()

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
                            NavigationLink(destination: ActivityDetailView(activity: activity)) {
                                ActivityRowView(activity: activity, isCached: true)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Carreras")
            .onAppear {
                viewModel.loadRaceActivities()
            }
        }
    }
}
