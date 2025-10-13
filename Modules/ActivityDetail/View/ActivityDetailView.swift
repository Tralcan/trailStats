import SwiftUI
import UIKit

/// Displays the detailed metrics and charts for a single activity.
struct ActivityDetailView: View {
    @StateObject var viewModel: ActivityDetailViewModel
    @State private var showGpxShareSheet = false

    // Estado para controlar el KPI seleccionado y mostrar el popover.
    @State private var selectedKpiInfo: KPIInfo?
    @FocusState private var notesFieldIsFocused: Bool

    @Environment(\.presentationMode) var presentationMode

    var onAppearAction: () -> Void
    var onDisappearAction: () -> Void

    // Nuevo: flag de solo lectura
    let isReadOnly: Bool

    init(activity: Activity,
         isReadOnly: Bool = false,
         onAppearAction: @escaping () -> Void,
         onDisappearAction: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ActivityDetailViewModel(activity: activity))
        self.isReadOnly = isReadOnly
        self.onAppearAction = onAppearAction
        self.onDisappearAction = onDisappearAction
    }
    
    // Header principal de la vista de actividad
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color("StravaOrange"))
                    Text(NSLocalizedString("Distance", comment: "Distance"))
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Text(Formatters.formatDistance(viewModel.activity.distance))
                    .font(.title3).fontWeight(.bold)
                    .foregroundColor(Color("StravaOrange"))
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(.green)
                    Text(NSLocalizedString("Elevation", comment: "Elevation"))
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Text(Formatters.formatElevation(viewModel.activity.elevationGain))
                    .font(.title3).fontWeight(.bold)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text(NSLocalizedString("Time", comment: "Time"))
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
                Text(NSLocalizedString("kpi.rpe.title", comment: "RPE title"))
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f", viewModel.rpe))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            .onTapGesture {
                selectedKpiInfo = KPIInfo(title: NSLocalizedString("kpi.rpe.title", comment: "RPE title"), description: NSLocalizedString("kpi.rpe.description", comment: "RPE description"), higherIsBetter: false)
            }
            Slider(value: $viewModel.rpe, in: 1...10, step: 1)
                .disabled(isReadOnly)
                .tint(Color("StravaOrange"))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Activity Type", comment: "Activity Type"))
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ActivityTag.allCases) { tag in
                        Button(action: {
                            if !isReadOnly { viewModel.tag = tag }
                        }) {
                            VStack {
                                Image(systemName: tag.icon)
                                    .font(.title2)
                                Text(tag.localizedName)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(width: 100, height: 90)
                            .background(viewModel.tag == tag ? Color("StravaOrange") : Color(.secondarySystemBackground))
                            .foregroundColor(viewModel.tag == tag ? .white : .primary)
                            .cornerRadius(12)
                        }
                        .disabled(isReadOnly)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(NSLocalizedString("My Notes", comment: "My Notes"), systemImage: "note.text")
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
                .disabled(isReadOnly)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    

    // Sección de KPIs rediseñada y robusta
    private var trailKPIsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Trail Analysis", comment: "Trail Analysis"))
                .font(.title2).bold()
                .foregroundColor(.primary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                if let gapKPI = viewModel.gapKPI {
                    KPICardView(kpi: gapKPI, unit: Formatters.isMetric ? "/km" : "/mi", icon: "speedometer", color: .cyan)
                        .onTapGesture { selectedKpiInfo = gapKPI }
                }
                
                if let decouplingKPI = viewModel.decouplingKPI {
                    KPICardView(kpi: decouplingKPI, unit: "%", icon: "heart.slash.circle.fill", color: (decouplingKPI.value ?? 0) > 10 ? .red : ((decouplingKPI.value ?? 0) > 5 ? .yellow : .green))
                        .onTapGesture { selectedKpiInfo = decouplingKPI }
                }
                
                if let vamKPI = viewModel.vamKPI {
                    KPICardView(kpi: vamKPI, unit: Formatters.isMetric ? "m/h" : "ft/h", icon: "arrow.up.right.circle.fill", color: .orange)
                        .onTapGesture { selectedKpiInfo = vamKPI }
                }
                
                if let descentVamKPI = viewModel.descentVamKPI {
                    KPICardView(kpi: descentVamKPI, unit: Formatters.isMetric ? "m/h" : "ft/h", icon: "arrow.down.right.circle.fill", color: .blue)
                        .onTapGesture { selectedKpiInfo = descentVamKPI }
                }
                
                if let normalizedPowerKPI = viewModel.normalizedPowerKPI {
                    KPICardView(kpi: normalizedPowerKPI, unit: "W", icon: "bolt.circle.fill", color: .green)
                        .onTapGesture { selectedKpiInfo = normalizedPowerKPI }
                }
                
                if let efficiencyIndexKPI = viewModel.efficiencyIndexKPI {
                    KPICardView(kpi: efficiencyIndexKPI, unit: "", icon: "leaf.arrow.triangle.circlepath", color: .mint)
                        .onTapGesture { selectedKpiInfo = efficiencyIndexKPI }
                }
            }
        }
    }

    @ViewBuilder
    private var radarChartSection: some View {
        if !viewModel.radarChartDataPoints.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString("Comparative Radar Analysis", comment: "Comparative Radar Analysis"))
                    .font(.title2).bold()
                    .foregroundColor(.primary)
                    .padding(.horizontal)

                RadarChartView(data: viewModel.radarChartDataPoints, maxValue: 100)
                    .frame(height: 300)
            }
            .padding(.vertical)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private var segmentsSection: some View {
        if !viewModel.climbSegments.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString("Key Segments", comment: "Key Segments"))
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
                Text(NSLocalizedString("Calculating advanced analysis...", comment: "Calculating advanced analysis..."))
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
                Text(NSLocalizedString("Interactive Analysis", comment: "Interactive Analysis"))
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                ProgressView()
                Text(NSLocalizedString("Loading chart data...", comment: "Loading chart data..."))
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
                    NSLocalizedString("Pace", comment: "Pace"): viewModel.paceData,
                    NSLocalizedString("Heart Rate", comment: "Heart Rate"): viewModel.heartRateData,
                    NSLocalizedString("Cadence", comment: "Cadence"): viewModel.cadenceData,
                    NSLocalizedString("Power", comment: "Power"): viewModel.powerData,
                    NSLocalizedString("Stride", comment: "Stride"): viewModel.strideLengthData
                ],
                overlayColors: [
                    NSLocalizedString("Pace", comment: "Pace"): .purple,
                    NSLocalizedString("Heart Rate", comment: "Heart Rate"): .red,
                    NSLocalizedString("Cadence", comment: "Cadence"): .blue,
                    NSLocalizedString("Power", comment: "Power"): .green,
                    NSLocalizedString("Stride", comment: "Stride"): .orange
                ],
                overlayUnits: [
                    NSLocalizedString("Pace", comment: "Pace"): Formatters.isMetric ? "min/km" : "min/mi",
                    NSLocalizedString("Heart Rate", comment: "Heart Rate"): NSLocalizedString("bpm", comment: "beats per minute"),
                    NSLocalizedString("Cadence", comment: "Cadence"): NSLocalizedString("spm", comment: "steps per minute"),
                    NSLocalizedString("Power", comment: "Power"): "W",
                    NSLocalizedString("Stride", comment: "Stride"): Formatters.isMetric ? "m" : "ft"
                ]
            )
        }
    }
    
    var body: some View {
        ZStack {
            if isReadOnly {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "flag.checkered.2.crossed")
                                .font(.system(size: 40))
                                .foregroundColor(.yellow)
                            Text(viewModel.activity.name)
                                .font(.title2).bold()
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top)

                        headerView
                            .padding(.horizontal)
                        rpeSection
                            .padding(.horizontal)
                        tagSection
                        trailKPIsSection
                            .padding(.horizontal)
                        RunningDynamicsView(
                            verticalOscillationKPI: viewModel.verticalOscillationKPI,
                            groundContactTimeKPI: viewModel.groundContactTimeKPI,
                            strideLengthKPI: viewModel.strideLengthKPI,
                            verticalRatioKPI: viewModel.verticalRatioKPI
                        ) { kpiInfo in
                            withAnimation {
                                selectedKpiInfo = kpiInfo
                            }
                        }
                        .padding(.horizontal)
                        
                        radarChartSection
                        
                        advancedAnalysisSection
                            .padding(.horizontal)
                        segmentsSection
                            .padding(.horizontal)
                        interactiveChartSection
                            .padding(.horizontal)
                        notesSection
                            .padding(.horizontal)
                        aiCoachSection
                            .padding(.horizontal)
                        
                        // Botón para convertir en carrera
//                        if !viewModel.isAlreadyRaceOfProcess && viewModel.tag != .race {
//                            Button(action: {
//                                viewModel.prepareToAssociateRace()
//                            }) {
//                                Label("Convertir en Carrera", systemImage: "flag.checkered.2.crossed")
//                                    .font(.headline)
//                                    .foregroundColor(.white)
//                                    .padding()
//                                    .frame(maxWidth: .infinity)
//                                    .background(Color.green)
//                                    .cornerRadius(12)
//                            }
//                            .padding(.top)
//                            .padding(.horizontal)
//                        }

                        // Botón para compartir análisis
                        Button(action: {
                            let analysisText = viewModel.generateAnalysisString()
                            share(items: [analysisText])
                        }) {
                            Label(NSLocalizedString("Share Analysis", comment: "Share Analysis"), systemImage: "text.quote")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color("StravaOrange"))
                                .cornerRadius(12)
                        }
                        .padding(.top)
                        .padding(.horizontal)

                        if let deviceName = viewModel.activity.deviceName {
                            HStack {
                                Text(NSLocalizedString("Device", comment: "Device"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(deviceName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }

                    }
                    .padding(.vertical)
                }
                .onTapGesture {
                    notesFieldIsFocused = false
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        VStack(spacing: 1) {
                            
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top)

                        headerView
                            .padding(.horizontal)
                        rpeSection
                            .padding(.horizontal)
                        tagSection
                        trailKPIsSection
                            .padding(.horizontal)
                        RunningDynamicsView(
                            verticalOscillationKPI: viewModel.verticalOscillationKPI,
                            groundContactTimeKPI: viewModel.groundContactTimeKPI,
                            strideLengthKPI: viewModel.strideLengthKPI,
                            verticalRatioKPI: viewModel.verticalRatioKPI
                        ) { kpiInfo in
                            withAnimation {
                                selectedKpiInfo = kpiInfo
                            }
                        }
                        .padding(.horizontal)
                        
                        radarChartSection
                        
                        advancedAnalysisSection
                            .padding(.horizontal)
                        segmentsSection
                            .padding(.horizontal)
                        interactiveChartSection
                            .padding(.horizontal)
                        notesSection
                            .padding(.horizontal)
                        aiCoachSection
                            .padding(.horizontal)
                        
                        // Botón para convertir en carrera
//                        if !viewModel.isAlreadyRaceOfProcess && viewModel.tag != .race {
//                            Button(action: {
//                                viewModel.prepareToAssociateRace()
//                            }) {
//                                Label("Convertir en Carrera", systemImage: "flag.checkered.2.crossed")
//                                    .font(.headline)
//                                    .foregroundColor(.white)
//                                    .padding()
//                                    .frame(maxWidth: .infinity)
//                                    .background(Color.green)
//                                    .cornerRadius(12)
//                            }
//                            .padding(.top)
//                            .padding(.horizontal)
//                        }

                        // Botón para compartir análisis
                        Button(action: {
                            let analysisText = viewModel.generateAnalysisString()
                            share(items: [analysisText])
                        }) {
                            Label(NSLocalizedString("Share Analysis", comment: "Share Analysis"), systemImage: "text.quote")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color("StravaOrange"))
                                .cornerRadius(12)
                        }
                        .padding(.top)
                        .padding(.horizontal)

                        if let deviceName = viewModel.activity.deviceName {
                            HStack {
                                Text("Device:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(deviceName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }

                    }
                    .padding(.vertical)
                }
                .refreshable { await viewModel.forceRefreshActivity() }
                .onTapGesture {
                    notesFieldIsFocused = false
                }
            }
        }
        .navigationTitle(viewModel.activity.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text(NSLocalizedString("Back", comment: "Back button"))
                    }
                    .foregroundColor(Color("StravaOrange"))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.shareGPX() }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color("StravaOrange"))
                }
                .disabled(viewModel.isGeneratingGPX)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: onAppearAction)
        .onDisappear(perform: onDisappearAction)
        .task {
            await viewModel.loadActivityDetails()
        }
        .onChange(of: viewModel.gpxDataToShare) { gpxData in
            if gpxData != nil {
                showGpxShareSheet = true
            }
        }
        .sheet(isPresented: $viewModel.showProcessSelection) {
            ProcessSelectionView(
                isPresented: $viewModel.showProcessSelection,
                processes: viewModel.activeProcesses
            ) { selectedProcess in
                viewModel.associateActivityTo(process: selectedProcess)
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
        .confirmationDialog(NSLocalizedString("Do you want to associate this race to a process?", comment: "Association confirmation"), isPresented: $viewModel.showAssociateToProcessDialog, titleVisibility: .visible) {
            Button(NSLocalizedString("Associate to Process", comment: "Associate to Process")) {
                viewModel.prepareToAssociateRace()
            }
            Button("No") {}
            Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
        }
        .tint(Color("StravaOrange"))
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
            Text(NSLocalizedString("AI Analysis", comment: "AI Analysis"))
                .font(.title2).bold()
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.aiCoachLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(NSLocalizedString("Generating analysis...", comment: "Generating analysis..."))
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
                        Button(NSLocalizedString("Retry Analysis", comment: "Retry Analysis")) {
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
        
    }
}

private struct SegmentRowView: View {
        let segment: ActivitySegment
     
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: segment.type == .climb ? "arrow.up.forward.circle.fill" : "arrow.down.forward.circle.fill")
                        .foregroundColor(segment.type == .climb ? .green : .blue)
                    Text(segment.type.localizedName)
                        .font(.headline).bold()
                    Spacer()
                    Text(String(format: "%@ @ %.1f%%", Formatters.formatDistance(segment.distance), segment.averageGrade))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("Pace", comment: "Pace")).font(.caption).foregroundColor(.secondary)
                        Text(segment.averagePace.toPaceFormat())
                    }
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("Elevation", comment: "Elevation")).font(.caption).foregroundColor(.secondary)
                        Text(String(format: "%@%@", segment.elevationChange > 0 ? "+" : "", Formatters.formatElevation(segment.elevationChange)))
                    }
                    if let vam = segment.verticalSpeed {
                        VStack(alignment: .leading) {
                            Text("VAM").font(.caption).foregroundColor(.secondary)
                            Text(Formatters.formatVerticalSpeed(vam))
                        }
                    }
                    if let hr = segment.averageHeartRate {
                        VStack(alignment: .leading) {
                            Text(NSLocalizedString("Avg HR", comment: "Average Heart Rate")).font(.caption).foregroundColor(.secondary)
                            Text(Formatters.formatHeartRate(hr))
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
    
        func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) ->
    Any {
            return ""
        }
    
        func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType
         activityType: UIActivity.ActivityType?) -> Any? {
            return url
      }
    
        func activityViewController(_ activityViewController: UIActivityViewController,
    subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
            return filename
        }
    
        func activityViewController(_ uiViewController: UIViewController,
    dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
            return "com.topografix.gpx"
        }
    }
    
    private struct ShareSheet: UIViewControllerRepresentable {
        var activityItems: [Any]
        var applicationActivities: [UIActivity]? = nil
    
        func makeUIViewController(context: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(activityItems: activityItems, applicationActivities:
    applicationActivities)
            return controller
        }
    
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }

