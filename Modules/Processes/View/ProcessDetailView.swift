import SwiftUI
import Charts

struct ProcessDetailView: View {
    @StateObject private var viewModel: ProcessDetailViewModel
    @State private var selectedKpiInfo: KPIInfo? = nil
    @State private var isShowingAddMetricSheet = false
    @State private var isShowingAddCommentSheet = false
    @State private var showingAddOptions = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    init(process: TrainingProcess) {
        _viewModel = StateObject(wrappedValue: ProcessDetailViewModel(process: process))
    }

    var body: some View {
        ZStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Calculando analíticas del proceso...").padding()
                } else if let result = viewModel.result {
                    VStack(alignment: .leading, spacing: 24) {
                        processSummarySection
                        ProcessProgressView(process: viewModel.process).padding(.horizontal)
                        kpiSummarySection(result: result)
                        trailPerformanceSection(result: result)
                        if result.hasRunningDynamics { runningDynamicsSection(result: result) }
                        
                        if !result.weeklyDistanceData.isEmpty { WeeklyDistanceChartView(weeklyData: result.weeklyDistanceData) }
                        if !result.efficiencyData.isEmpty { EfficiencyChartView(data: result.efficiencyData) }
                        if !result.weeklyDecouplingData.isEmpty { WeeklyDecouplingChartView(weeklyData: result.weeklyDecouplingData) }
                        if !result.weeklyZoneDistribution.isEmpty { IntensityChartView(weeklyData: result.weeklyZoneDistribution) }
                        if !result.performanceByGradeData.isEmpty { PerformanceByGradeView(performanceData: result.performanceByGradeData) }
                        if result.totalActivities == 0 { emptyStateView }

                        MetricHistoryView(
                            metricEntries: viewModel.process.metricEntries,
                            onDelete: viewModel.process.isCompleted ? nil : { indexSet in viewModel.deleteMetricEntry(at: indexSet) }
                        )
                        .padding(.top)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(viewModel.process.name)
            .navigationBarItems(trailing: Button(action: { showingAddOptions = true }) {
                Image(systemName: "plus.circle.fill").font(.title2)
            }.disabled(viewModel.process.isCompleted))
            .confirmationDialog("Añadir Registro", isPresented: $showingAddOptions, titleVisibility: .visible) {
                Button("Métrica Corporal") { isShowingAddMetricSheet = true }
                Button("Visita al Kinesiologo") { viewModel.addSimpleEntry(type: .kinesiologo) }
                Button("Visita al Medico") { viewModel.addSimpleEntry(type: .medico) }
                Button("Sesión de Masajes") { viewModel.addSimpleEntry(type: .masajes) }
                Button("Comentario") { isShowingAddCommentSheet = true } // Reordenado
                Button("Cancelar", role: .cancel) { }
            }

            if selectedKpiInfo != nil {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all).onTapGesture { selectedKpiInfo = nil }.zIndex(1)
            }
            if let info = selectedKpiInfo {
                KpiInfoPopoverView(info: info).zIndex(2).transition(.scale.combined(with: .opacity)).onTapGesture { selectedKpiInfo = nil }
            }
        }
        .animation(.easeInOut, value: selectedKpiInfo)
        .onAppear { viewModel.loadAnalytics() }
        .sheet(isPresented: $isShowingAddMetricSheet, onDismiss: { viewModel.loadProcess() }) {
            AddMetricEntryView(process: viewModel.process)
        }
        .sheet(isPresented: $isShowingAddCommentSheet) {
            AddCommentView { comment in
                viewModel.addCommentEntry(notes: comment)
            }
        }
    }

    private var processSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resumen del Proceso")
                .font(.title3).bold()
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "calendar")
                    Text("\(viewModel.process.startDate, style: .date) - \(viewModel.process.endDate, style: .date)")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private func kpiSummarySection(result: AnalyticsResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Totales del Período")
                .font(.title3).bold()
                .padding(.horizontal)

            LazyVGrid(columns: gridColumns, spacing: 16) {
                KPISummaryCard(title: "Actividades", value: "\(result.totalActivities)", systemImage: "figure.run", color: .orange)
                KPISummaryCard(title: "Tiempo Total", value: Formatters.formatTime(Int(result.totalDuration)), systemImage: "hourglass", color: .blue)
                KPISummaryCard(title: "Distancia Total", value: Formatters.formatDistance(result.totalDistance), systemImage: "location.fill", color: .red)
                KPISummaryCard(title: "Desnivel Total", value: Formatters.formatElevation(result.totalElevation), systemImage: "mountain.2.fill", color: .green)
            }
            .padding(.horizontal)
        }
    }

    private func trailPerformanceSection(result: AnalyticsResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Análitica de Trail")
                .font(.title3).bold()
                .padding(.horizontal)

            LazyVGrid(columns: gridColumns, spacing: 16) {
                KPISummaryCard(title: "Vel. Ascenso", value: "\(String(format: "%.0f", result.averageVAM)) m/h", systemImage: "arrow.up.right.circle.fill", color: .orange)
                    .onTapGesture { selectedKpiInfo = .vam }
                KPISummaryCard(title: "GAP", value: result.averageGAP.toPaceFormat(), systemImage: "speedometer", color: .cyan)
                    .onTapGesture { selectedKpiInfo = .gap }
                KPISummaryCard(title: "Vel. Descenso", value: "\(String(format: "%.0f", result.averageDescentVAM)) m/h", systemImage: "arrow.down.right.circle.fill", color: .blue)
                    .onTapGesture { selectedKpiInfo = .descentVam }
                KPISummaryCard(title: "Potencia Norm.", value: "\(String(format: "%.0f", result.averageNormalizedPower)) W", systemImage: "bolt.circle.fill", color: .green)
                    .onTapGesture { selectedKpiInfo = .normalizedPower }
                KPISummaryCard(title: "Índice Eficiencia", value: String(format: "%.3f", result.averageEfficiencyIndex), systemImage: "leaf.arrow.triangle.circlepath", color: .mint)
                    .onTapGesture { selectedKpiInfo = .efficiencyIndex }
                KPISummaryCard(title: "Desacople", value: "\(String(format: "%.1f", result.averageDecoupling))%", systemImage: "heart.slash.circle.fill", color: .pink)
                    .onTapGesture { selectedKpiInfo = .decoupling }
            }
            .padding(.horizontal)
        }
    }

    private func runningDynamicsSection(result: AnalyticsResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dinámica de Carrera")
                .font(.title3).bold()
                .padding(.horizontal)

            LazyVGrid(columns: gridColumns, spacing: 16) {
                KPISummaryCard(title: "Oscilación Vertical", value: "\(String(format: "%.1f", result.averageVerticalOscillation)) cm", systemImage: "arrow.up.and.down.circle.fill", color: .purple)
                    .onTapGesture { selectedKpiInfo = .verticalOscillation }
                KPISummaryCard(title: "Tiempo de Contacto", value: "\(String(format: "%.0f", result.averageGroundContactTime)) ms", systemImage: "timer", color: .indigo)
                    .onTapGesture { selectedKpiInfo = .groundContactTime }
                KPISummaryCard(title: "Longitud de Zancada", value: "\(String(format: "%.2f", result.averageStrideLength)) m", systemImage: "ruler.fill", color: .orange)
                    .onTapGesture { selectedKpiInfo = .strideLength }
                KPISummaryCard(title: "Ratio Vertical", value: "\(String(format: "%.1f", result.averageVerticalRatio)) %", systemImage: "percent", color: .teal)
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
            Text("No hay actividades en este proceso")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            Text("Registra nuevas actividades para ver las analíticas de este período.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer(minLength: 50)
        }
        .frame(maxWidth: .infinity)
    }
}