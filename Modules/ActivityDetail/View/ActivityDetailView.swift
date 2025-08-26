import SwiftUI
import UIKit

/// Displays the detailed metrics and charts for a single activity.
struct ActivityDetailView: View {
    
    @StateObject var viewModel: ActivityDetailViewModel
    @State private var showShareSheet = false
    
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
    
    // Sección para los KPIs de Trail Running
    private var trailKPIsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Análisis de Trail")
                .font(.title2).bold()
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                if let vam = viewModel.verticalSpeedVAM {
                    VStack(alignment: .leading) {
                        Label("Velocidad Vertical", systemImage: "arrow.up.right.circle.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f m/h", vam))
                            .font(.title).bold()
                            .foregroundColor(.orange)
                    }
                }
                Spacer()
                if let decoupling = viewModel.cardiacDecoupling {
                    VStack(alignment: .leading) {
                        Label("Desacoplamiento", systemImage: "heart.slash.circle.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f %%", decoupling))
                            .font(.title).bold()
                            .foregroundColor(decoupling > 10 ? .red : (decoupling > 5 ? .yellow : .green))
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
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
    private var interactiveChartSection: some View {
        if !viewModel.isLoading && !viewModel.altitudeData.isEmpty {
            InteractiveChartView(
                altitudeData: viewModel.altitudeData,
                overlayData: [
                    "Ritmo": viewModel.paceData,
                    "Frec. Cardíaca": viewModel.heartRateData,
                    "Cadencia": viewModel.cadenceData
                ],
                overlayColors: [
                    "Ritmo": .purple,
                    "Frec. Cardíaca": .red,
                    "Cadencia": .blue
                ],
                overlayUnits: [
                    "Ritmo": "min/km",
                    "Frec. Cardíaca": "BPM",
                    "Cadencia": "spm"
                ]
            )
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerView
                    trailKPIsSection
                    segmentsSection
                    interactiveChartSection
                    aiCoachSection
                }
                .padding()
            }
            if viewModel.isLoading {
                loadingView
            }
        }
        .navigationTitle(viewModel.activity.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.shareGPX() }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.isGeneratingGPX)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if viewModel.heartRateData.isEmpty {
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
    
    private var loadingView: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .scaleEffect(2)
                Text("Analizando actividad...")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
            .padding(32)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    private var aiCoachSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Coach")
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
                    Text("Error: \(err)")
                        .font(.body)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// Vista para una fila de segmento
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

// Las vistas auxiliares para compartir GPX permanecen aquí debajo.
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
