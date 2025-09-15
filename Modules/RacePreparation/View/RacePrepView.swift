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
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "medal.fill")
                                            .foregroundColor(.yellow)
                                        Text(activity.name)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text(activity.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    HStack(spacing: 15) {
                                        // Distance
                                        HStack(spacing: 4) {
                                            Image(systemName: "location.fill")
                                                .foregroundColor(.red)
                                            Text(String(format: "%.2f km", activity.distance / 1000))
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                        
                                        // Elevation
                                        HStack(spacing: 4) {
                                            Image(systemName: "mountain.2.fill")
                                                .foregroundColor(.green)
                                            Text(String(format: "%.0f m", activity.elevationGain))
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                        
                                        // Duration
                                        HStack(spacing: 4) {
                                            Image(systemName: "hourglass")
                                                .foregroundColor(.blue)
                                            Text(Int(activity.duration).toHoursMinutesSeconds())
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.selectedActivity = activity
                            }
                        }
                    }
                }
            }
            .navigationTitle("Carreras")
            .task {
                await viewModel.loadRaceActivities()
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
            }
        }
    }
}
