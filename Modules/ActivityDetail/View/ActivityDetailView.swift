
import SwiftUI

/// Displays the detailed metrics and charts for a single activity.
struct ActivityDetailView: View {
    
    @StateObject var viewModel: ActivityDetailViewModel
    
    init(activity: Activity) {
        _viewModel = StateObject(wrappedValue: ActivityDetailViewModel(activity: activity))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with main stats
                headerView
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                } else if viewModel.isLoading {
                    ProgressView("Loading chart data...")
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                } else {
                    // Elevation Chart
                    if !viewModel.altitudeData.isEmpty {
                        TimeSeriesChartView(
                            data: viewModel.altitudeData,
                            title: "Elevation",
                            yAxisLabel: "Meters",
                            color: .purple,
                            showAverage: false
                        )
                    }

                    // Vertical Energy Cost Chart
                    if !viewModel.cvertData.isEmpty {
                        TimeSeriesChartView(
                            data: viewModel.cvertData,
                            title: "Vertical Energy Cost",
                            yAxisLabel: "W/m",
                            color: .brown
                        )
                    }

                    // Vertical Speed Chart
                    if !viewModel.verticalSpeedData.isEmpty {
                        TimeSeriesChartView(
                            data: viewModel.verticalSpeedData,
                            title: "Vertical Speed",
                            yAxisLabel: "km/h",
                            color: .cyan
                        )
                    }

                    // Heart Rate Chart
                    if !viewModel.heartRateData.isEmpty {
                        TimeSeriesChartView(
                            data: viewModel.heartRateData,
                            title: "Heart Rate",
                            yAxisLabel: "BPM",
                            color: .red
                        )
                    }

                    // Power Chart
                    if !viewModel.powerData.isEmpty {
                        TimeSeriesChartView(
                            data: viewModel.powerData,
                            title: "Power",
                            yAxisLabel: "Watts",
                            color: .green
                        )
                    }

                    // Pace Chart
                    if !viewModel.paceData.isEmpty {
                        TimeSeriesChartView(
                            data: viewModel.paceData,
                            title: "Pace",
                            yAxisLabel: "minutos",
                            color: .purple
                        )
                    }

                    // Stride Length Chart
                    if !viewModel.strideLengthData.isEmpty {
                        TimeSeriesChartView(
                            data: viewModel.strideLengthData,
                            title: "Stride Length",
                            yAxisLabel: "m",
                            color: .orange
                        )
                    }

                    // Cadence Chart
                    if !viewModel.cadenceData.isEmpty {
                        TimeSeriesChartView(
                            data: viewModel.cadenceData,
                            title: "Cadence",
                            yAxisLabel: "SPM",
                            color: .blue
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(viewModel.activity.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.fetchActivityStreams()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "location.fill") // Red icon for distance
                        .foregroundColor(.red)
                    Text("Distance")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Text(viewModel.activity.formattedDistance)
                    .font(.title3).fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mountain.2.fill") // Green icon for elevation
                        .foregroundColor(.green)
                    Text("Elevation")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Text(viewModel.activity.formattedElevation)
                    .font(.title3).fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill") // Blue clock icon for time
                        .foregroundColor(.blue)
                    Text("Time")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Text(viewModel.activity.formattedDuration)
                    .font(.title3).fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}


