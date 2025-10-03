import SwiftUI

struct RacePrepView: View {
    @StateObject private var viewModel = RacePrepViewModel()
    @State private var selectedActivity: Activity? = nil

    var body: some View {
        NavigationView {
            VStack {
                HStack(spacing: 0) {
                    Text(NSLocalizedString("Completed Races Part 1", comment: "Primera parte del título principal de carreras completadas"))
                        .foregroundColor(.primary)
                    Text(NSLocalizedString("Completed Races Part 2", comment: "Segunda parte del título principal de carreras completadas"))
                        .foregroundColor(Color("StravaOrange"))
                }
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 60)
                .padding(.bottom, 0)
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView(NSLocalizedString("Loading races...", comment: "Estado: cargando lista de carreras"))
                } else if viewModel.raceActivities.isEmpty {
                    Text(NSLocalizedString("No races found", comment: "Mensaje de lista vacía de carreras"))
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
                                                .foregroundColor(Color("StravaOrange"))
                                            Text(Int(activity.duration).toHoursMinutesSeconds())
                                                .font(.caption)
                                                .foregroundColor(Color("StravaOrange"))
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
            .toolbar {
                // Removed the ToolbarItem with placement: .principal
            }
            .task {
                await viewModel.loadRaceActivities()
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity, isReadOnly: true, onAppearAction: {}, onDisappearAction: {})
            }
        }
    }
}
