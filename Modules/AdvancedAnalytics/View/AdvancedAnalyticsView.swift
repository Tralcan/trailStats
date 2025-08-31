import SwiftUI
import Charts

struct AdvancedAnalyticsView: View {
    @StateObject private var viewModel = ProgressAnalyticsViewModel()
    
    enum TimePeriod: String, CaseIterable, Identifiable {
        case last7 = "7 Días"
        case last30 = "30 Días"
        case last60 = "60 Días"
        case last90 = "90 Días"
        
        var id: String { rawValue }
        
        var dayCount: Int {
            switch self {
            case .last7: return 7
            case .last30: return 30
            case .last60: return 60
            case .last90: return 90
            }
        }
    }
    
    @State private var selectedPeriod: TimePeriod = .last30
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    Picker("Período", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedPeriod) { newPeriod in
                        viewModel.timeFrameChanged(newTimeFrame: newPeriod.dayCount)
                    }
                    
                    // KPI Summary Grid
                    kpiSummaryGrid
                    
                    // Weekly Distance Chart
                    if !viewModel.weeklyDistanceData.isEmpty {
                        WeeklyDistanceChartView(weeklyData: viewModel.weeklyDistanceData)
                    }

                    // Efficiency Chart
                    if !viewModel.efficiencyData.isEmpty {
                        EfficiencyChartView(data: viewModel.efficiencyData)
                    }
                    
                    // Decoupling Chart
                    if !viewModel.weeklyDecouplingData.isEmpty {
                        WeeklyDecouplingChartView(weeklyData: viewModel.weeklyDecouplingData)
                    }

                    // Intensity Chart
                    if !viewModel.weeklyZoneDistribution.isEmpty {
                        IntensityChartView(weeklyData: viewModel.weeklyZoneDistribution)
                    }
                    
                    // Show empty state only if all charts are empty
                    if viewModel.efficiencyData.isEmpty && viewModel.weeklyZoneDistribution.isEmpty && viewModel.weeklyDistanceData.isEmpty && viewModel.weeklyDecouplingData.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Análisis de Progreso")
        }
    }
    
    private var kpiSummaryGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            KPISummaryCard(title: "Actividades", value: "\(viewModel.totalActivities)", systemImage: "figure.run", color: .orange)
            KPISummaryCard(title: "Tiempo Total", value: Formatters.formatTime(Int(viewModel.totalDuration)), systemImage: "hourglass", color: .blue)
            KPISummaryCard(title: "Distancia Total", value: Formatters.formatDistance(viewModel.totalDistance), systemImage: "location.fill", color: .red)
            KPISummaryCard(title: "Desnivel Total", value: Formatters.formatElevation(viewModel.totalElevation), systemImage: "mountain.2.fill", color: .green)
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer(minLength: 50)
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No hay suficientes datos")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            Text("Registra más actividades para ver tu progreso a lo largo del tiempo.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer(minLength: 50)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct KPISummaryCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    AdvancedAnalyticsView()
}