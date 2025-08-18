
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
                
                if viewModel.isLoading {
                    ProgressView("Loading chart data...")
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                } else {
                    // Elevation Chart
                    TimeSeriesChartView(
                        data: viewModel.altitudeData,
                        title: "Elevation",
                        yAxisLabel: "Meters",
                        color: .purple,
                        showAverage: false
                    )

                    // Vertical Energy Cost Chart
                    TimeSeriesChartView(
                        data: viewModel.cvertData,
                        title: "Vertical Energy Cost",
                        yAxisLabel: "W/m",
                        color: .brown
                    )

                    // Vertical Speed Chart
                    TimeSeriesChartView(
                        data: viewModel.verticalSpeedData,
                        title: "Vertical Speed",
                        yAxisLabel: "km/h",
                        color: .cyan
                    )

                    // Heart Rate Chart
                    TimeSeriesChartView(
                        data: viewModel.heartRateData,
                        title: "Heart Rate",
                        yAxisLabel: "BPM",
                        color: .red
                    )

                    // Power Chart
                    TimeSeriesChartView(
                        data: viewModel.powerData,
                        title: "Power",
                        yAxisLabel: "Watts",
                        color: .green
                    )

                    // Pace Chart
                    TimeSeriesChartView(
                        data: viewModel.paceData,
                        title: "Pace",
                        yAxisLabel: "minutos",
                        color: .purple
                    )

                    // Stride Length Chart
                    TimeSeriesChartView(
                        data: viewModel.strideLengthData,
                        title: "Stride Length",
                        yAxisLabel: "m",
                        color: .orange
                    )

                    // Cadence Chart
                    TimeSeriesChartView(
                        data: viewModel.cadenceData,
                        title: "Cadence",
                        yAxisLabel: "SPM",
                        color: .blue
                    )
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
                    .font(.title2).fontWeight(.bold)
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
                    .font(.title2).fontWeight(.bold)
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
                    .font(.title2).fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}


