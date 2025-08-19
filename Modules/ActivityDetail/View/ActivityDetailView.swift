import SwiftUI

/// Displays the detailed metrics and charts for a single activity.
struct ActivityDetailView: View {
    
    @StateObject var viewModel: ActivityDetailViewModel
    @State private var showShareSheet = false // New: State to control share sheet presentation
    
    init(activity: Activity) {
        _viewModel = StateObject(wrappedValue: ActivityDetailViewModel(activity: activity))
    }
    
    // Header principal de la vista de actividad
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
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerView
                    ChartSaverView(viewModel: viewModel)
                }
                .padding()
            }
            if viewModel.isLoading {
                Color.clear.ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                        .scaleEffect(2)
                    Text("Loading data...")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                }
            }
        }
        .navigationTitle(viewModel.activity.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.shareGPX()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.isGeneratingGPX)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            let startTime = Date()
            print("[PERF] onAppear ActivityDetailView: \(startTime)")
            // Solo cargar streams si falta alguna imagen de gráfico
            let chartNames = ["HeartRate", "Power", "Pace", "Cadence", "StrideLength", "Elevation", "VerticalEnergyCost", "VerticalSpeed"]
            var missingImages: [String] = []
            let allImagesExist = chartNames.allSatisfy { name in
                let exists = CacheManager().loadChartImage(activityId: viewModel.activity.id, chartName: name) != nil
                if !exists { missingImages.append(name) }
                return exists
            }
            print("[PERF] allImagesExist: \(allImagesExist) - \(Date().timeIntervalSince(startTime))s")
            if !allImagesExist {
                print("[PERF] Faltan imágenes de gráficos en caché: \(missingImages)")
                print("[PERF] fetchActivityStreams llamado")
                viewModel.fetchActivityStreams()
            }
        }
        .onChange(of: viewModel.gpxDataToShare) { gpxData in
            if gpxData != nil {
                showShareSheet = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let gpxData = viewModel.gpxDataToShare {
                let sanitizedName = viewModel.activity.name
                    .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let filename = sanitizedName.isEmpty ? "activity.gpx" : "\(sanitizedName).gpx"
                ShareSheet(activityItems: [GPXFile(data: gpxData, filename: filename)])
            }
        }
    }
    
    // Vista auxiliar para renderizar y guardar los gráficos y el resumen automáticamente
    struct ChartSaverView: View {
        @ObservedObject var viewModel: ActivityDetailViewModel
        @State private var didSave = false
    // El estado de AI Coach ahora vive en el ViewModel

        var body: some View {
            VStack(spacing: 52) {
                // Solo mostrar AI Coach si no está cargando
                if !viewModel.isLoading {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Coach")
                            .font(.title3).bold()
                            .foregroundColor(.accentColor)
                        if viewModel.aiCoachLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Analizando actividad...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else if let obs = viewModel.aiCoachObservation {
                            Text(obs)
                                .font(.body)
                                .foregroundColor(.primary)
                        } else if let err = viewModel.aiCoachError {
                            Text("Error: \(err)")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                ChartSnapshotter(title: "Elevation", data: viewModel.altitudeData, color: .purple, viewModel: viewModel, displayTitle: "Elevation", showAverage: false)
                ChartSnapshotter(title: "VerticalEnergyCost", data: viewModel.cvertData, color: .brown, viewModel: viewModel, displayTitle: "Vertical Energy Cost")
                ChartSnapshotter(title: "VerticalSpeed", data: viewModel.verticalSpeedData, color: .cyan, viewModel: viewModel, displayTitle: "Vertical Speed")
                ChartSnapshotter(title: "Power", data: viewModel.powerData, color: .green, viewModel: viewModel, displayTitle: "Power")
                ChartSnapshotter(title: "Pace", data: viewModel.paceData, color: .purple, viewModel: viewModel, displayTitle: "Pace")
                ChartSnapshotter(title: "HeartRate", data: viewModel.heartRateData, color: .red, viewModel: viewModel, displayTitle: "Heart Rate")
                ChartSnapshotter(title: "StrideLength", data: viewModel.strideLengthData, color: .orange, viewModel: viewModel, displayTitle: "Stride Length")
                ChartSnapshotter(title: "Cadence", data: viewModel.cadenceData, color: .blue, viewModel: viewModel, displayTitle: "Cadence")
            }
            .onAppear {
                if !didSave {
                    saveSummary()
                    didSave = true
                }
                // 1. Si ya hay texto de AI Coach en el ViewModel, no hacer nada
                if viewModel.aiCoachObservation != nil {
                    viewModel.aiCoachLoading = false
                    return
                }
                // 2. Si hay texto en caché, cargarlo y no mostrar spinner
                let cacheManager = CacheManager()
                if let cachedText = cacheManager.loadAICoachText(activityId: viewModel.activity.id) {
                    print("[AI Coach] Texto AI Coach cargado del caché:", cachedText)
                    viewModel.aiCoachObservation = cachedText
                    viewModel.aiCoachLoading = false
                    return
                }
                // 3. Solo si no hay texto en caché ni en memoria, mostrar spinner y generar
                if !viewModel.aiCoachLoading {
                    viewModel.aiCoachLoading = true
                    var summary = cacheManager.loadSummary(activityId: viewModel.activity.id)
                    print("[AI Coach] Resumen cargado del caché:", summary as Any)
                    // Si el resumen existe pero no tiene promedios válidos, forzar recarga de streams y recalcular
                    if let s = summary, !Self.tienePromediosValidos(summary: s) {
                        print("[AI Coach] Resumen sin promedios válidos. Forzando recarga de streams...")
                        viewModel.isLoading = true
                        viewModel.fetchActivityStreams()
                        // Esperar a que los datos se procesen antes de continuar
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            let recalculated = ActivitySummary(
                                activityId: viewModel.activity.id,
                                date: viewModel.activity.date,
                                distance: viewModel.activity.distance,
                                elevation: viewModel.activity.elevationGain,
                                duration: viewModel.activity.duration,
                                averageHeartRate: viewModel.heartRateData.map { $0.value }.averageOrNil(),
                                averagePower: viewModel.powerData.map { $0.value }.averageOrNil(),
                                averagePace: viewModel.paceData.map { $0.value }.averageOrNil(),
                                averageCadence: viewModel.cadenceData.map { $0.value }.averageOrNil(),
                                averageStrideLength: viewModel.strideLengthData.map { $0.value }.averageOrNil()
                            )
                            print("[AI Coach] Resumen recalculado tras recarga:", recalculated)
                            cacheManager.saveSummary(activityId: viewModel.activity.id, summary: recalculated)
                            if Self.tienePromediosValidos(summary: recalculated) {
                                print("[AI Coach] Enviando resumen a Gemini:", recalculated)
                                GeminiCoachService.fetchObservation(summary: recalculated) { obs in
                                    DispatchQueue.main.async {
                                        viewModel.aiCoachObservation = obs ?? "No se pudo obtener observación de la IA."
                                        if let obs = obs {
                                            cacheManager.saveAICoachText(activityId: viewModel.activity.id, text: obs)
                                        }
                                        viewModel.aiCoachLoading = false
                                        viewModel.isLoading = false
                                    }
                                }
                            } else {
                                print("[AI Coach] No hay resumen de la actividad con datos válidos tras recarga. No se llama a Gemini.")
                                viewModel.aiCoachError = "No hay resumen de la actividad con datos válidos."
                                viewModel.aiCoachLoading = false
                                viewModel.isLoading = false
                            }
                        }
                        return
                    }
                    // Si ahora hay promedios válidos, llamar a Gemini
                    if let s = summary, Self.tienePromediosValidos(summary: s) {
                        print("[AI Coach] Enviando resumen a Gemini:", s)
                        GeminiCoachService.fetchObservation(summary: s) { obs in
                            DispatchQueue.main.async {
                                viewModel.aiCoachObservation = obs ?? "No se pudo obtener observación de la IA."
                                if let obs = obs {
                                    cacheManager.saveAICoachText(activityId: viewModel.activity.id, text: obs)
                                }
                                viewModel.aiCoachLoading = false
                            }
                        }
                    } else {
                        print("[AI Coach] No hay resumen de la actividad con datos válidos. No se llama a Gemini.")
                        viewModel.aiCoachError = "No hay resumen de la actividad con datos válidos."
                        viewModel.aiCoachLoading = false
                    }
                }
            }
        }

        // Helper para validar que el resumen tiene promedios válidos
        private static func tienePromediosValidos(summary: ActivitySummary) -> Bool {
            return summary.averageHeartRate != nil || summary.averagePower != nil || summary.averagePace != nil || summary.averageCadence != nil || summary.averageStrideLength != nil
        }
        
        // Calcula y guarda el resumen de la actividad
        private func saveSummary() {
            let summary = ActivitySummary(
                activityId: viewModel.activity.id,
                date: viewModel.activity.date,
                distance: viewModel.activity.distance,
                elevation: viewModel.activity.elevationGain,
                duration: viewModel.activity.duration,
                averageHeartRate: viewModel.heartRateData.map { $0.value }.averageOrNil(),
                averagePower: viewModel.powerData.map { $0.value }.averageOrNil(),
                averagePace: viewModel.paceData.map { $0.value }.averageOrNil(),
                averageCadence: viewModel.cadenceData.map { $0.value }.averageOrNil(),
                averageStrideLength: viewModel.strideLengthData.map { $0.value }.averageOrNil()
            )
            CacheManager().saveSummary(activityId: viewModel.activity.id, summary: summary)

            // Guardar métricas avanzadas
            // Prints de depuración para ver los datos antes de guardar
            print("[DEBUG] altitudeData count: \(viewModel.altitudeData.count), values: \(viewModel.altitudeData.map { $0.value })")
            print("[DEBUG] cvertData count: \(viewModel.cvertData.count), values: \(viewModel.cvertData.map { $0.value })")
            print("[DEBUG] verticalSpeedData count: \(viewModel.verticalSpeedData.count), values: \(viewModel.verticalSpeedData.map { $0.value })")
            print("[DEBUG] heartRateData count: \(viewModel.heartRateData.count), values: \(viewModel.heartRateData.map { $0.value })")
            print("[DEBUG] powerData count: \(viewModel.powerData.count), values: \(viewModel.powerData.map { $0.value })")
            print("[DEBUG] paceData count: \(viewModel.paceData.count), values: \(viewModel.paceData.map { $0.value })")
            print("[DEBUG] strideLengthData count: \(viewModel.strideLengthData.count), values: \(viewModel.strideLengthData.map { $0.value })")
            print("[DEBUG] cadenceData count: \(viewModel.cadenceData.count), values: \(viewModel.cadenceData.map { $0.value })")

            let metrics = ActivitySummaryMetrics(
                activityId: viewModel.activity.id,
                distance: viewModel.activity.distance,
                elevation: viewModel.activity.elevationGain,
                elevationAverage: viewModel.altitudeData.map { $0.value }.averageOrNil() ?? 0,
                verticalEnergyCostAverage: viewModel.cvertData.map { $0.value }.averageOrNil() ?? 0,
                verticalSpeedAverage: viewModel.verticalSpeedData.map { $0.value }.averageOrNil() ?? 0,
                heartRateAverage: viewModel.heartRateData.map { $0.value }.averageOrNil() ?? 0,
                powerAverage: viewModel.powerData.map { $0.value }.averageOrNil() ?? 0,
                paceAverage: viewModel.paceData.map { $0.value }.averageOrNil() ?? 0,
                strideLengthAverage: viewModel.strideLengthData.map { $0.value }.averageOrNil() ?? 0,
                cadenceAverage: viewModel.cadenceData.map { $0.value }.averageOrNil() ?? 0
            )
            CacheManager().saveMetrics(activityId: viewModel.activity.id, metrics: metrics)
        }
    }
    
    // Vista auxiliar para capturar y guardar la imagen de cada gráfico
    struct ChartSnapshotter: View {
        let title: String
        let data: [DataPoint]
        let color: Color
        let viewModel: ActivityDetailViewModel
    // Eliminado didSave global, cada gráfico guarda su imagen independientemente
    var displayTitle: String? = nil
    var showAverage: Bool = true

        var body: some View {
            let chartTitle = displayTitle ?? title
            if let imageData = CacheManager().loadChartImage(activityId: viewModel.activity.id, chartName: title),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else if !data.isEmpty {
                let chartContent = VStack(spacing: 0) {
                    TimeSeriesChartView(
                        data: data,
                        title: chartTitle,
                        yAxisLabel: "",
                        color: color,
                        showAverage: showAverage
                    )
                    Spacer().frame(height: 70) // Espacio extra para el eje X
                }
                .frame(height: 210) // 200 + 32
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
                .background(Color(.secondarySystemBackground))
                chartContent
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    // Guardar la imagen siempre que no exista en caché
                                    if CacheManager().loadChartImage(activityId: viewModel.activity.id, chartName: title) == nil {
                                        if let imageData = ViewSnapshotter.snapshot(of: chartContent, size: geo.size) {
                                            CacheManager().saveChartImage(activityId: viewModel.activity.id, chartName: title, imageData: imageData)
                                        }
                                    }
                                }
                        }
                    )
            }
        }
    }
    
    
    
    // Helper class to represent a GPX file for sharing
    class GPXFile: NSObject, UIActivityItemSource {
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
                print("Error writing GPX data to temporary file: \(error.localizedDescription)")
                return nil
            }
        }
        
        @objc func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
            return ""
        }
        
        @objc func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
            return url
        }
        
        @objc func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
            return filename
        }
        
        @objc func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
            return "com.topografix.gpx" // GPX UTI
        }
    }
    
    // UIViewControllerRepresentable for UIActivityViewController
    struct ShareSheet: UIViewControllerRepresentable {
        var activityItems: [Any]
        var applicationActivities: [UIActivity]? = nil
        
        func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
            let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
            return controller
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {}
    }
    
}
