
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
                
                // Cadence Chart
                TimeSeriesChartView(
                    data: viewModel.activity.cadenceData,
                    title: "Cadence",
                    yAxisLabel: "SPM",
                    color: .blue
                )
                
                // Power Chart
                TimeSeriesChartView(
                    data: viewModel.activity.powerData,
                    title: "Power",
                    yAxisLabel: "Watts",
                    color: .green
                )
                
                // Heart Rate Chart
                TimeSeriesChartView(
                    data: viewModel.activity.heartRateData,
                    title: "Heart Rate",
                    yAxisLabel: "BPM",
                    color: .red
                )
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(viewModel.activity.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Distance")
                    .font(.subheadline).foregroundColor(.secondary)
                Text(viewModel.activity.formattedDistance)
                    .font(.title2).fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Elevation")
                    .font(.subheadline).foregroundColor(.secondary)
                Text(viewModel.activity.formattedElevation)
                    .font(.title2).fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Time")
                    .font(.subheadline).foregroundColor(.secondary)
                Text(viewModel.activity.formattedDuration)
                    .font(.title2).fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}


