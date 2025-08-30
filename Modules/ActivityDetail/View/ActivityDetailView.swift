import SwiftUI
import UIKit

/// Displays the detailed metrics and charts for a single activity.
struct ActivityDetailView: View {
    
    @StateObject var viewModel: ActivityDetailViewModel
    @State private var showGpxShareSheet = false
    
    // Estado para controlar el KPI seleccionado y mostrar el popover.
    @State private var selectedKpiInfo: KpiInfo?
    @FocusState private var notesFieldIsFocused: Bool
    
    // Diccionario con las descripciones para cada KPI.
    private let kpiInfoData: [String: String] = [
        "Esfuerzo Percibido (RPE)": "1 - 3 (Fácil): Podrías mantener una conversación completa sin problema. Sería un trote regenerativo.\n\n4 - 6 (Moderado): Te sientes cómodo y puedes hablar, pero con frases cortas. Es tu ritmo de resistencia.\n\n7 - 8 (Duro): Te cuesta mucho hablar. Estás en tu umbral o ritmo de carrera.\n\n9 - 10 (Máximo): Estás al límite, jadeando. Solo puedes mantenerlo por periodos muy cortos.",
        "Ritmo Ajustado (GAP)": "Calcula tu ritmo equivalente en terreno llano, ajustando el esfuerzo realizado en subidas y bajadas. Ayuda a comparar esfuerzos en terrenos variados.",
        "Desacoplamiento Cardíaco": "Mide cómo tu frecuencia cardíaca aumenta con respecto a tu ritmo a lo largo del tiempo. Un valor bajo (idealmente < 5%) indica una excelente resistencia aeróbica.",
        "Vel. Vertical (Ascenso)": "Mide los metros que asciendes por hora (m/h). Es un indicador clave de tu capacidad y eficiencia como escalador. También conocido como VAM.",
        "Vel. Vertical (Descenso)": "Mide los metros que desciendes por hora (m/h). Un valor alto puede indicar una buena técnica y confianza en las bajadas.",
        "Potencia Normalizada": "Estimación de la potencia que podrías haber mantenido con un esfuerzo constante. Es más precisa que la potencia media para esfuerzos variables como los del trail.",
        "Índice Eficiencia": "Relaciona tu velocidad con tu frecuencia cardíaca. Un valor más alto sugiere que eres más eficiente, cubriendo más distancia por cada latido del corazón.",
        "VAM (Velocidad de Ascenso Media)": "Mide los metros que asciendes por hora (m/h) específicamente en este rango de pendiente. Es un indicador clave de tu eficiencia como escalador en diferentes inclinaciones."
    ]
    
    init(activity: Activity) {
        _viewModel = StateObject(wrappedValue: ActivityDetailViewModel(activity: activity))
    }
    
    // Header principal de la vista de actividad
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.red)
                    Text("Distance")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Text(String(format: "%.2f km", viewModel.activity.distance / 1000))
                    .font(.title3).fontWeight(.bold)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(.green)
                    Text("Elevation")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Text(String(format: "%.0f m", viewModel.activity.elevationGain))
                    .font(.title3).fontWeight(.bold)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Time")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Text(Int(viewModel.activity.duration).toHoursMinutesSeconds())
                    .font(.title3).fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Esfuerzo Percibido (RPE)")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f / 10", viewModel.rpe))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(colorForRPE(value: viewModel.rpe))
            }
            .onTapGesture {
                selectedKpiInfo = KpiInfo(title: "Esfuerzo Percibido (RPE)", description: kpiInfoData["Esfuerzo Percibido (RPE)"]!)
            }
            Slider(value: $viewModel.rpe, in: 1...10, step: 0.5)
                .tint(colorForRPE(value: viewModel.rpe))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Mis Notas", systemImage: "note.text")
                .font(.headline)
            
            TextEditor(text: $viewModel.notes)
                .frame(height: 100)
                .padding(4)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .focused($notesFieldIsFocused)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func colorForRPE(value: Double) -> Color {
        let normalizedValue = (value - 1) / 9 // Normalize RPE from 1-10 to 0-1
        
        // As value goes from 0 to 1, red goes from 0 to 1, and blue goes from 1 to 0.
        let redComponent = normalizedValue
        let blueComponent = 1 - normalizedValue
        
        return Color(red: redComponent, green: 0.2, blue: blueComponent)
    }

    // Sección de KPIs rediseñada y robusta
    private var trailKPIsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Análisis de Trail")
                .font(.title2).bold()
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    KPICardView(title: "Ritmo Ajustado (GAP)", value: viewModel.gradeAdjustedPace?.toPaceFormat(), unit: "", icon: "speedometer", color: .cyan)
                        .onTapGesture {
                            selectedKpiInfo = KpiInfo(title: "Ritmo Ajustado (GAP)", description: kpiInfoData["Ritmo Ajustado (GAP)"]!)
                        }
                    
                    KPICardView(title: "Desacoplamiento Cardíaco", value: viewModel.cardiacDecoupling.map { String(format: "%.1f", $0) }, unit: "%", icon: "heart.slash.circle.fill", color: (viewModel.cardiacDecoupling ?? 0) > 10 ? .red : ((viewModel.cardiacDecoupling ?? 0) > 5 ? .yellow : .green))
                        .onTapGesture {
                            selectedKpiInfo = KpiInfo(title: "Desacoplamiento Cardíaco", description: kpiInfoData["Desacoplamiento Cardíaco"]!)
                        }
                }
                
                HStack(spacing: 16) {
                    KPICardView(title: "Vel. Vertical (Ascenso)", value: viewModel.verticalSpeedVAM.map { String(format: "%.0f", $0) }, unit: "m/h", icon: "arrow.up.right.circle.fill", color: .orange)
                        .onTapGesture {
                            selectedKpiInfo = KpiInfo(title: "Vel. Vertical (Ascenso)", description: kpiInfoData["Vel. Vertical (Ascenso)"]!)
                        }

                    KPICardView(title: "Vel. Vertical (Descenso)", value: viewModel.descentVerticalSpeed.map { String(format: "%.0f", $0) }, unit: "m/h", icon: "arrow.down.right.circle.fill", color: .blue)
                        .onTapGesture {
                            selectedKpiInfo = KpiInfo(title: "Vel. Vertical (Descenso)", description: kpiInfoData["Vel. Vertical (Descenso)"]!)
                        }
                }
                
                HStack(spacing: 16) {
                    KPICardView(title: "Potencia Normalizada", value: viewModel.normalizedPower.map { String(format: "%.0f", $0) }, unit: "W", icon: "bolt.circle.fill", color: .green)
                        .onTapGesture {
                            selectedKpiInfo = KpiInfo(title: "Potencia Normalizada", description: kpiInfoData["Potencia Normalizada"]!)
                        }

                    KPICardView(title: "Índice Eficiencia", value: viewModel.efficiencyIndex.map { String(format: "%.3f", $0) }, unit: "", icon: "leaf.arrow.triangle.circlepath", color: .mint)
                        .onTapGesture {
                            selectedKpiInfo = KpiInfo(title: "Índice Eficiencia", description: kpiInfoData["Índice Eficiencia"]!)
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var segmentsSection: some View {
        if !viewModel.climbSegments.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Segmentos Clave")
                    .font(.title2).bold()
                    .foregroundColor(.primary)

                ForEach(viewModel.climbSegments) { segment in
                    SegmentRowView(segment: segment)
                }
            }
        }
    }
    
    @ViewBuilder
    private var advancedAnalysisSection: some View {
        // Si no hay datos de zonas de FC o de rendimiento por pendiente, mostramos un placeholder
        if viewModel.heartRateZoneDistribution == nil && viewModel.performanceByGrade.isEmpty {
            VStack(spacing: 10) {
                ProgressView()
                Text("Calculando análisis avanzado...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        } else {
            // Si hay datos, mostramos las vistas correspondientes
            if let distribution = viewModel.heartRateZoneDistribution {
                HeartRateZoneView(distribution: distribution)
            }

            if !viewModel.performanceByGrade.isEmpty {
                PerformanceByGradeView(performanceData: viewModel.performanceByGrade, onKpiTapped: { kpiInfo in
                    withAnimation {
                        selectedKpiInfo = kpiInfo
                    }
                })
            }
        }
    }

    @ViewBuilder
    private var interactiveChartSection: some View {
        if viewModel.altitudeData.isEmpty {
            VStack {
                Text("Análisis Interactivo")
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                ProgressView()
                Text("Cargando datos del gráfico...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .frame(height: 300)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        } else {
            InteractiveChartView(
                altitudeData: viewModel.altitudeData,
                overlayData: [
                    "Ritmo": viewModel.paceData,
                    "Frec. Cardíaca": viewModel.heartRateData,
                    "Cadencia": viewModel.cadenceData,
                    "Potencia": viewModel.powerData,
                    "Zancada": viewModel.strideLengthData
                ],
                overlayColors: [
                    "Ritmo": .purple,
                    "Frec. Cardíaca": .red,
                    "Cadencia": .blue,
                    "Potencia": .green,
                    "Zancada": .orange
                ],
                overlayUnits: [
                    "Ritmo": "min/km",
                    "Frec. Cardíaca": "BPM",
                    "Cadencia": "spm",
                    "Potencia": "W",
                    "Zancada": "m"
                ]
            )
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(viewModel.activity.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { viewModel.shareGPX() }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        .disabled(viewModel.isGeneratingGPX)
                    }
                    
                    headerView
                    rpeSection
                    trailKPIsSection
                    RunningDynamicsView(activity: viewModel.activity) { kpiInfo in
                        withAnimation {
                            selectedKpiInfo = kpiInfo
                        }
                    }

                    advancedAnalysisSection
                    segmentsSection
                    interactiveChartSection
                    notesSection
                    aiCoachSection
                    
                    // Botón para compartir análisis
                    Button(action: {
                        let analysisText = viewModel.generateAnalysisString()
                        share(items: [analysisText])
                    }) {
                        Label("Compartir Análisis", systemImage: "text.quote")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    .padding(.top)

                }
                .padding()
            }
            .onTapGesture {
                notesFieldIsFocused = false
            }
        }
        .navigationTitle(viewModel.activity.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.loadActivityDetails()
        }
        .onChange(of: viewModel.gpxDataToShare) { gpxData in
            if gpxData != nil {
                showGpxShareSheet = true
            }
        }
        .sheet(isPresented: $showGpxShareSheet) {
            if let gpxData = viewModel.gpxDataToShare {
                let sanitizedName = viewModel.activity.name
                    .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let filename = sanitizedName.isEmpty ? "activity.gpx" : "\(sanitizedName).gpx"
                ShareSheet(activityItems: [GPXFile(data: gpxData, filename: filename)])
            }
        }
        .overlay(
            ZStack {
                if let kpiInfo = selectedKpiInfo {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                selectedKpiInfo = nil
                            }
                        }
                    
                    KpiInfoPopoverView(info: kpiInfo)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .animation(.easeInOut, value: selectedKpiInfo != nil)
        )
    }
    
    private func share(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              var topViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }

        // Traverse up the view controller hierarchy to find the topmost one
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = topViewController.view
            popoverController.sourceRect = CGRect(x: topViewController.view.bounds.midX,
                                                  y: topViewController.view.bounds.midY,
                                                  width: 0,
                                                  height: 0)
            popoverController.permittedArrowDirections = []
        }

        topViewController.present(activityViewController, animated: true)
    }
    
    private var aiCoachSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Análisis IA")
                .font(.title2).bold()
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.aiCoachLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Generando análisis...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let obs = viewModel.aiCoachObservation {
                    Text(obs)
                        .font(.body)
                        .foregroundColor(.primary)
                } else if let err = viewModel.aiCoachError {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(err)
                            .font(.body)
                            .foregroundColor(.red)
                        Button("Reintentar Análisis") {
                            viewModel.getAICoachObservation()
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .onAppear {
            // Only fetch AI Coach observation if it's not already loaded or being loaded
            if viewModel.aiCoachObservation == nil && !viewModel.aiCoachLoading && viewModel.aiCoachError == nil {
                viewModel.getAICoachObservation()
            }
        }
    }
}

private struct SegmentRowView: View {
    let segment: ActivitySegment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: segment.type == .climb ? "arrow.up.forward.circle.fill" : "arrow.down.forward.circle.fill")
                    .foregroundColor(segment.type == .climb ? .green : .blue)
                Text(segment.type.rawValue)
                    .font(.headline).bold()
                Spacer()
                Text(String(format: "%.2f km @ %.1f%%", segment.distance / 1000, segment.averageGrade))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Ritmo").font(.caption).foregroundColor(.secondary)
                    Text(segment.averagePace.toPaceFormat())
                }
                VStack(alignment: .leading) {
                    Text("Desnivel").font(.caption).foregroundColor(.secondary)
                    Text(String(format: "%@%.0f m", segment.elevationChange > 0 ? "+" : "", segment.elevationChange))
                }
                if let vam = segment.verticalSpeed {
                    VStack(alignment: .leading) {
                        Text("VAM").font(.caption).foregroundColor(.secondary)
                        Text(String(format: "%.0f m/h", vam))
                    }
                }
                if let hr = segment.averageHeartRate {
                    VStack(alignment: .leading) {
                        Text("FC Media").font(.caption).foregroundColor(.secondary)
                        Text(String(format: "%.0f", hr))
                    }
                }
            }
            .font(.footnote)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private class GPXFile: NSObject, UIActivityItemSource {
    let data: Data
    let filename: String
    
    init(data: Data, filename: String) {
        self.data = data
        self.filename = filename
    }
    
    var url: URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return url
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return filename
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "com.topografix.gpx"
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
