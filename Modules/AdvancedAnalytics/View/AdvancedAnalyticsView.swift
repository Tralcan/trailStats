import SwiftUI
import Charts

struct AdvancedAnalyticsView: View {
    @StateObject private var viewModel = ProgressAnalyticsViewModel()
    @State private var selectedKpiInfo: KPIInfo? = nil
    
    enum TimePeriod: String, CaseIterable, Identifiable {
        case last7 = "7 Días"
        case last15 = "15 Días"
        case last30 = "30 Días"
        case last60 = "60 Días"
        case last90 = "90 Días"
        
        var id: String { rawValue }
        
        var dayCount: Int {
            switch self {
            case .last7: return 7
            case .last15: return 15
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
        ZStack {
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
                        kpiSummarySection
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
                .onAppear {
                    viewModel.recalculateAnalyticsIfNeeded()
                }
            }
            
            if selectedKpiInfo != nil {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { selectedKpiInfo = nil }
                    .zIndex(1)
            }
            
            if let info = selectedKpiInfo {
                KpiInfoPopoverView(info: info)
                    .zIndex(2)
                    .transition(.scale.combined(with: .opacity))
                    .onTapGesture { selectedKpiInfo = nil }
            }
        }
        .animation(.easeInOut, value: selectedKpiInfo)
    }
    
    private var kpiSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Totales del Período")
                .font(.title3).bold()
                .padding(.horizontal)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                KPISummaryCard(title: "Actividades", value: "\(viewModel.totalActivities)", systemImage: "figure.run", color: .orange)
                KPISummaryCard(title: "Tiempo Total", value: Formatters.formatTime(Int(viewModel.totalDuration)), systemImage: "hourglass", color: .blue)
                KPISummaryCard(title: "Distancia Total", value: Formatters.formatDistance(viewModel.totalDistance), systemImage: "location.fill", color: .red)
                KPISummaryCard(title: "Desnivel Total", value: Formatters.formatElevation(viewModel.totalElevation), systemImage: "mountain.2.fill", color: .green)
            }
            .padding(.horizontal)
        }
    }
    
    private var trailPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Análitica de Trail")
                .font(.title3).bold()
                .padding(.horizontal)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                KPISummaryCard(title: "Vel. Ascenso", value: "\(String(format: "%.0f", viewModel.averageVAM)) m/h", systemImage: "arrow.up.right.circle.fill", color: .orange)
                    .onTapGesture { selectedKpiInfo = .vam }
                KPISummaryCard(title: "GAP", value: viewModel.averageGAP.toPaceFormat(), systemImage: "speedometer", color: .cyan)
                    .onTapGesture { selectedKpiInfo = .gap }
                KPISummaryCard(title: "Vel. Descenso", value: "\(String(format: "%.0f", viewModel.averageDescentVAM)) m/h", systemImage: "arrow.down.right.circle.fill", color: .blue)
                    .onTapGesture { selectedKpiInfo = .descentVam }
                KPISummaryCard(title: "Potencia Norm.", value: "\(String(format: "%.0f", viewModel.averageNormalizedPower)) W", systemImage: "bolt.circle.fill", color: .green)
                    .onTapGesture { selectedKpiInfo = .normalizedPower }
                KPISummaryCard(title: "Índice Eficiencia", value: String(format: "%.3f", viewModel.averageEfficiencyIndex), systemImage: "leaf.arrow.triangle.circlepath", color: .mint)
                    .onTapGesture { selectedKpiInfo = .efficiencyIndex }
                KPISummaryCard(title: "Desacople", value: "\(String(format: "%.1f", viewModel.averageDecoupling))%", systemImage: "heart.slash.circle.fill", color: .pink)
                    .onTapGesture { selectedKpiInfo = .decoupling }
            }
            .padding(.horizontal)
        }
    }
    
    private var runningDynamicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dinámica de Carrera")
                .font(.title3).bold()
                .padding(.horizontal)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                KPISummaryCard(title: "Oscilación Vertical", value: "\(String(format: "%.1f", viewModel.averageVerticalOscillation)) cm", systemImage: "arrow.up.and.down.circle.fill", color: .purple)
                    .onTapGesture { selectedKpiInfo = .verticalOscillation }
                KPISummaryCard(title: "Tiempo de Contacto", value: "\(String(format: "%.0f", viewModel.averageGroundContactTime)) ms", systemImage: "timer", color: .indigo)
                    .onTapGesture { selectedKpiInfo = .groundContactTime }
                KPISummaryCard(title: "Longitud de Zancada", value: "\(String(format: "%.2f", viewModel.averageStrideLength)) m", systemImage: "ruler.fill", color: .orange)
                    .onTapGesture { selectedKpiInfo = .strideLength }
                KPISummaryCard(title: "Ratio Vertical", value: "\(String(format: "%.1f", viewModel.averageVerticalRatio)) %", systemImage: "percent", color: .teal)
                    .onTapGesture { selectedKpiInfo = .verticalRatio }
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
