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
                    
                    // KPI Summary Grids
                    kpiSummaryGrid
                    trailPerformanceSection
                    if viewModel.hasRunningDynamics {
                        runningDynamicsSection
                    }
                    
                    // Charts
                    if !viewModel.weeklyDistanceData.isEmpty {
                        WeeklyDistanceChartView(weeklyData: viewModel.weeklyDistanceData)
                    }

                    if !viewModel.efficiencyData.isEmpty {
                        EfficiencyChartView(data: viewModel.efficiencyData)
                    }
                    
                    if !viewModel.weeklyDecouplingData.isEmpty {
                        WeeklyDecouplingChartView(weeklyData: viewModel.weeklyDecouplingData)
                    }

                    if !viewModel.weeklyZoneDistribution.isEmpty {
                        IntensityChartView(weeklyData: viewModel.weeklyZoneDistribution)
                    }
                    
                    if !viewModel.performanceByGradeData.isEmpty {
                        PerformanceByGradeView(performanceData: viewModel.performanceByGradeData)
                    }
                    
                    // Show empty state only if all charts are empty
                    if viewModel.totalActivities == 0 {
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
    
    private var trailPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Análitica de Trail (Promedios)")
                .font(.title3).bold()
                .padding(.horizontal)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                KPISummaryCard(title: "Vel. Ascenso Prom.", value: "\(String(format: "%.0f", viewModel.averageVAM)) m/h", systemImage: "arrow.up.right.circle.fill", color: .cyan)
                KPISummaryCard(title: "GAP Promedio", value: viewModel.averageGAP.toPaceFormat(), systemImage: "speedometer", color: .purple)
                KPISummaryCard(title: "Vel. Descenso Prom.", value: "\(String(format: "%.0f", viewModel.averageDescentVAM)) m/h", systemImage: "arrow.down.right.circle.fill", color: .blue)
                KPISummaryCard(title: "Potencia Norm. Prom.", value: "\(String(format: "%.0f", viewModel.averageNormalizedPower)) W", systemImage: "bolt.circle.fill", color: .green)
                KPISummaryCard(title: "Índice Eficiencia Prom.", value: String(format: "%.3f", viewModel.averageEfficiencyIndex), systemImage: "leaf.arrow.triangle.circlepath", color: .mint)
                KPISummaryCard(title: "Desacople Prom.", value: "\(String(format: "%.1f", viewModel.averageDecoupling))%", systemImage: "heart.slash.circle.fill", color: .pink)
            }
            .padding(.horizontal)
        }
    }
    
    private var runningDynamicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dinámica de Carrera (Promedios)")
                .font(.title3).bold()
                .padding(.horizontal)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                KPISummaryCard(title: "Oscilación Vertical", value: "\(String(format: "%.1f", viewModel.averageVerticalOscillation)) cm", systemImage: "arrow.up.and.down.circle.fill", color: .pink)
                KPISummaryCard(title: "Tiempo de Contacto", value: "\(String(format: "%.0f", viewModel.averageGroundContactTime)) ms", systemImage: "timer", color: .indigo)
                KPISummaryCard(title: "Longitud de Zancada", value: "\(String(format: "%.2f", viewModel.averageStrideLength)) m", systemImage: "ruler.fill", color: .brown)
                KPISummaryCard(title: "Ratio Vertical", value: "\(String(format: "%.1f", viewModel.averageVerticalRatio)) %", systemImage: "percent", color: .teal)
            }
            .padding(.horizontal)
        }
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