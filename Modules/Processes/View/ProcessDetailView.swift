import SwiftUI
import Charts

struct ProcessDetailView: View {
    @StateObject private var viewModel: ProcessDetailViewModel
    @State private var selectedKpiInfo: KPIInfo? = nil
    @State private var isShowingAddMetricSheet = false
    @State private var isShowingAddCommentSheet = false
    @State private var showingAddOptions = false
    @State private var selectedRace: Activity? = nil

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    init(process: TrainingProcess) {
        _viewModel = StateObject(wrappedValue: ProcessDetailViewModel(process: process))
    }

    private var attributedTrainingRecommendation: AttributedString? {
        guard let recommendation = viewModel.trainingRecommendation else { return nil }
        do {
            return try AttributedString(markdown: recommendation, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString(recommendation)
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Calculando analíticas del proceso...").padding()
                } else if let result = viewModel.result {
                    VStack(alignment: .leading, spacing: 24) {
                        processSummarySection
                        if viewModel.process.raceDistance != nil {
                            raceGoalSection
                        }
                        if !viewModel.process.goal.isEmpty {
                            goalSection
                        }
                        ProcessProgressView(process: viewModel.process).padding(.horizontal)
                        kpiSummarySection(result: result)
                        trailPerformanceSection(result: result)
                        if result.hasRunningDynamics { runningDynamicsSection(result: result) }
                        
                        if !result.weeklyDistanceData.isEmpty { WeeklyDistanceChartView(weeklyData: result.weeklyDistanceData) }
                        if !result.efficiencyData.isEmpty { EfficiencyChartView(data: result.efficiencyData) }
                        if !result.weeklyDecouplingData.isEmpty { WeeklyDecouplingChartView(weeklyData: result.weeklyDecouplingData) }
                        if !result.weeklyZoneDistribution.isEmpty { IntensityChartView(weeklyData: result.weeklyZoneDistribution) }
                        if !result.performanceByGradeData.isEmpty { PerformanceByGradeView(performanceData: result.performanceByGradeData) }
                        TrainingTypeDistributionChartView(process: viewModel.process)
                        if result.totalActivities == 0 { emptyStateView }

                        MetricHistoryView(
                            metricEntries: viewModel.process.metricEntries,
                            onDelete: viewModel.process.isCompleted ? nil : { indexSet in viewModel.deleteMetricEntry(at: indexSet) }
                        )
                        .padding(.top)

                        if !viewModel.process.isCompleted { trainingRecommendationSection }
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
        .sheet(item: $selectedRace) { race in
            ActivityDetailView(activity: race, onAppearAction: {}, onDisappearAction: {})
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
    
    @ViewBuilder
    private var raceGoalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Carrera Objetivo")
                .font(.title3).bold()
                .padding(.horizontal)

            VStack(alignment: .center, spacing: 10) {
                // Si ya hay una actividad de carrera real, mostrar sus resultados
                if let race = viewModel.goalActivity {
                    HStack(spacing: 12) {
                        Image(systemName: "flag.checkered.2.crossed")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                        
                        VStack(alignment: .leading) {
                            Text(Int(race.duration).toHoursMinutesSeconds())
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            Text("Tiempo Oficial")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onTapGesture {
                        if viewModel.process.isCompleted {
                            self.selectedRace = race
                        }
                    }
                    .padding(.bottom, 8)
                    
                    HStack(spacing: 24) {
                        Label(Formatters.formatDistance(race.distance), systemImage: "location.fill")
                            .foregroundColor(.red)
                        
                        Label(Formatters.formatElevation(race.elevationGain), systemImage: "mountain.2.fill")
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(.top, 8)

                } else if viewModel.isEstimatingTime {
                    ProgressView("Consultando al coach Gemini...")
                } else if let projection = viewModel.raceProjection {
                    HStack(spacing: 12) {
                        Image(systemName: "medal.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                        
                        VStack(alignment: .leading) {
                            Text(projection.tiempo)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            Text("Tiempo Estimado")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                    .onTapGesture {
                        self.selectedKpiInfo = KPIInfo(
                            title: "Razón de la Estimación",
                            description: projection.razon,
                            higherIsBetter: false
                        )
                    }
                    
                    if let distance = viewModel.process.raceDistance, let elevation = viewModel.process.raceElevation {
                        HStack(spacing: 24) {
                            Label(Formatters.formatDistance(distance), systemImage: "location.fill")
                                .foregroundColor(.red)
                            
                            Label(Formatters.formatElevation(elevation), systemImage: "mountain.2.fill")
                                .foregroundColor(.green)
                            
                            Button(action: {
                                self.selectedKpiInfo = KPIInfo(
                                    title: "Recomendaciones IA",
                                    description: "**Importante:**\n" + projection.importante.joined(separator: "\n") + "\n\n**Nutrición:**\n" + projection.nutricion.joined(separator: "\n"),
                                    higherIsBetter: false
                                )
                            }) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.cyan)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.top, 8)
                    }
                    
                } else if let error = viewModel.estimationError {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    Text(viewModel.process.goal)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var goalSection: some View {
        HStack {
            (Text("Objetivo: ") + Text(viewModel.process.goal))
                .font(.body)
                .italic()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if viewModel.goalActivity != nil {
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.updateGoalStatus(to: .met)
                    }) {
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundColor(viewModel.process.goalStatus == .met ? .green : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        viewModel.updateGoalStatus(to: .notMet)
                    }) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .foregroundColor(viewModel.process.goalStatus == .notMet ? .red : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal)
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

    private var trainingRecommendationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recomendación de entrenamientos IA")
                .font(.title3).bold()
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                if viewModel.isFetchingRecommendation {
                    HStack {
                        ProgressView()
                        Text("Consultando al coach Gemini...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let recommendation = attributedTrainingRecommendation {
                    Text(recommendation)
                        .font(.body)
                } else if let error = viewModel.recommendationError {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .cornerRadius(12)
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
