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
            // let startTime = Date()
            // print("[PERF] onAppear ActivityDetailView: \(startTime)")
            // Solo cargar streams si falta alguna imagen de gráfico
            let chartNames = ["HeartRate", "Power", "Pace", "Cadence", "StrideLength", "Elevation", "VerticalEnergyCost", "VerticalSpeed"]
            var missingImages: [String] = []
            let allImagesExist = chartNames.allSatisfy { name in
                let exists = CacheManager().loadChartImage(activityId: viewModel.activity.id, chartName: name) != nil
                if !exists { missingImages.append(name) }
                return exists
            }
            // print("[PERF] allImagesExist: \(allImagesExist) - \(Date().timeIntervalSince(startTime))s")
            if !allImagesExist {
                // print("[PERF] Faltan imágenes de gráficos en caché: \(missingImages)")
                // print("[PERF] fetchActivityStreams llamado")
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

        var body: some View {
            VStack(spacing: 52) {
                if !viewModel.isLoading {
                    // AI Coach y spinner
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

                    ChartSnapshotter(title: "Elevation", data: viewModel.altitudeData, color: .purple, viewModel: viewModel, displayTitle: "Elevation", showAverage: false, normalize: false)
                    ChartSnapshotter(title: "VerticalEnergyCost", data: viewModel.cvertData, color: .brown, viewModel: viewModel, displayTitle: "Vertical Energy Cost")
                    ChartSnapshotter(title: "VerticalSpeed", data: viewModel.verticalSpeedData, color: .cyan, viewModel: viewModel, displayTitle: "Vertical Speed", showAverage: true, normalize: false)
                    ChartSnapshotter(title: "Power", data: viewModel.powerData, color: .green, viewModel: viewModel, displayTitle: "Power")
                    ChartSnapshotter(title: "Pace", data: viewModel.paceData, color: .purple, viewModel: viewModel, displayTitle: "Pace")
                    ChartSnapshotter(title: "HeartRate", data: viewModel.heartRateData, color: .red, viewModel: viewModel, displayTitle: "Heart Rate")
                    ChartSnapshotter(title: "StrideLength", data: viewModel.strideLengthData, color: .orange, viewModel: viewModel, displayTitle: "Stride Length")
                    ChartSnapshotter(title: "Cadence", data: viewModel.cadenceData, color: .blue, viewModel: viewModel, displayTitle: "Cadence")
                }
            }
        }
    }
    
    // Vista auxiliar para capturar y guardar la imagen de cada gráfico
    struct ChartSnapshotter: View {
        let title: String
        let data: [DataPoint]
        let color: Color
        let viewModel: ActivityDetailViewModel
        var displayTitle: String? = nil
        var showAverage: Bool = true
        var normalize: Bool = true

        private var chartTitle: String { displayTitle ?? title }
        private var unit: String {
            switch title {
            case "VerticalEnergyCost": return "W/m"
            case "VerticalSpeed": return "km/h"
            case "Power": return "W"
            case "Pace": return "min/km"
            case "HeartRate": return "BPM"
            case "StrideLength": return "m"
            case "Cadence": return "RPM"
            default: return ""
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(chartTitle)
                        .font(.headline)
                    
                    if showAverage {
                        averageView
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 8)

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
                            title: "",
                            yAxisLabel: "",
                            color: color,
                            showAverage: showAverage,
                            normalize: normalize
                        )
                        Spacer().frame(height: 70)
                    }
                    .frame(height: 210)
                    .padding(.horizontal, 0)
                    .padding(.vertical, 0)
                    .background(Color(.secondarySystemBackground))

                    chartContent
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
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

        @ViewBuilder
        private var averageView: some View {
            if title == "VerticalSpeed" {
                let (positiveAvg, negativeAvg) = getVerticalSpeedAverages()
                
                if let pAvg = positiveAvg {
                    Text(String(format: "Avg ↗: %.2f %@", pAvg, unit))
                }
                if let nAvg = negativeAvg {
                    Text(String(format: "Avg ↘: %.2f %@", nAvg, unit))
                }

            } else if title != "Elevation" {
                if let avg = getGenericAverage() {
                    let format = (title == "Pace" || title == "StrideLength") ? "AVG: %.2f %@" : "AVG: %.0f %@"
                    Text(String(format: format, avg, unit))
                }
            }
        }

        private func getVerticalSpeedAverages() -> (Double?, Double?) {
            if !data.isEmpty {
                let positive = data.filter { $0.value > 0 }.map { $0.value }.averageOrNil()
                let negative = data.filter { $0.value < 0 }.map { $0.value }.averageOrNil()
                return (positive, negative)
            } else if let metrics = CacheManager().loadMetrics(activityId: viewModel.activity.id) {
                return (metrics.positiveVerticalSpeedAverage, metrics.negativeVerticalSpeedAverage)
            }
            return (nil, nil)
        }

        private func getGenericAverage() -> Double? {
            if !data.isEmpty {
                return data.map { $0.value }.averageOrNil()
            } else if let metrics = CacheManager().loadMetrics(activityId: viewModel.activity.id) {
                switch title {
                case "VerticalEnergyCost": return metrics.verticalEnergyCostAverage
                case "Power": return metrics.powerAverage
                case "Pace": return metrics.paceAverage
                case "HeartRate": return metrics.heartRateAverage
                case "StrideLength": return metrics.strideLengthAverage
                case "Cadence": return metrics.cadenceAverage
                default: return nil
                }
            }
            return nil
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
                // print("Error writing GPX data to temporary file: \(error.localizedDescription)")
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
