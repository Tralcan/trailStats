import SwiftUI
import Combine

// MARK: - Data Structures

struct ActivitySegment: Identifiable, Hashable, Codable {
    let id = UUID()
    let type: SegmentType
    let startDistance: Double
    let endDistance: Double
    let distance: Double
    let elevationChange: Double
    let averageGrade: Double
    let time: Int
    let averagePace: Double
    let averageHeartRate: Double?
    let verticalSpeed: Double?

    enum SegmentType: String, Codable {
        case climb = "Climb"
        case descent = "Descent"

        var localizedName: String {
            return NSLocalizedString(self.rawValue, comment: "Segment type")
        }
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ActivitySegment, rhs: ActivitySegment) -> Bool { lhs.id == rhs.id }
}



// MARK: - Activity Detail ViewModel

@MainActor
class ActivityDetailViewModel: ObservableObject {
    // MARK: Published Properties
    @Published var activity: Activity
    
    // Graph Data
    @Published var heartRateData: [ChartDataPoint] = []
    @Published var cadenceData: [ChartDataPoint] = []
    @Published var powerData: [ChartDataPoint] = []
    @Published var altitudeData: [ChartDataPoint] = []
    @Published var paceData: [ChartDataPoint] = []
    @Published var distanceData: [ChartDataPoint] = []
    @Published var strideLengthData: [ChartDataPoint] = []

    // KPIs
    @Published var vamKPI: KPIInfo?
    @Published var decouplingKPI: KPIInfo?
    @Published var descentVamKPI: KPIInfo?
    @Published var normalizedPowerKPI: KPIInfo?
    @Published var gapKPI: KPIInfo?
    @Published var efficiencyIndexKPI: KPIInfo?
    @Published var verticalOscillationKPI: KPIInfo?
    @Published var groundContactTimeKPI: KPIInfo?
    @Published var strideLengthKPI: KPIInfo?
    @Published var verticalRatioKPI: KPIInfo?
    @Published var radarChartDataPoints: [RadarChartDataPoint] = []

    // Complex data
    @Published var climbSegments: [ActivitySegment] = []
    @Published var heartRateZoneDistribution: HeartRateZoneDistribution?
    @Published var performanceByGrade: [PerformanceByGrade] = []

    // Historical data for trend calculation
    private var recentActivities: [Activity] = []

    // RPE & Notes
    @Published var rpe: Double = 5.0
    @Published var notes: String = ""
    @Published var tag: ActivityTag? = nil
    @Published var showAssociateToProcessDialog = false

    // UI State
    @Published var errorMessage: String? = nil
    @Published var isGeneratingGPX = false
    @Published var gpxDataToShare: Data? = nil
    @Published var aiCoachObservation: String? = nil
    @Published var aiCoachLoading: Bool = false
    @Published var aiCoachError: String? = nil
    @Published var showProcessSelection = false
    @Published var activeProcesses: [TrainingProcess] = []
    @Published var isAlreadyRaceOfProcess = false

    // MARK: Private Properties
    private let stravaService = StravaService()
    private let healthKitService = HealthKitService()
    private let cacheManager = CacheManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(activity: Activity) {
        self.activity = activity
        self.rpe = activity.rpe ?? 5.0
        self.notes = activity.notes ?? ""
        self.tag = activity.tag

        $rpe
            .dropFirst()
            .sink { [weak self] newRPE in
                guard let self = self else { return }
                let previousRPE = self.activity.rpe
                self.activity.rpe = newRPE
                
                if newRPE != previousRPE {
                    self.cacheManager.deleteAICoachText(activityId: self.activity.id)
                    self.getAICoachObservation()
                    self.saveActivity()
                }
            }
            .store(in: &cancellables)

        $notes
            .dropFirst()
            .sink { [weak self] newNotes in
                self?.activity.notes = newNotes
                self?.saveActivity()
            }
            .store(in: &cancellables)

        $tag
            .dropFirst()
            .sink { [weak self] newTag in
                guard let self = self else { return }
                let previousTag = self.activity.tag
                self.activity.tag = newTag

                if newTag != previousTag {
                    self.cacheManager.deleteAICoachText(activityId: self.activity.id)
                    self.getAICoachObservation(newTag: newTag)
                    self.saveActivity()

                    if newTag == .race && !self.isAlreadyRaceOfProcess {
                        self.showAssociateToProcessDialog = true
                    } else if previousTag == .race && newTag != .race {
                        self.disassociateRaceFromProcess()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadActivityDetails() async {
        checkIfActivityIsRace()
        // Try to load the detailed activity from cache first.
        if let cachedActivity = cacheManager.loadActivityDetail(activityId: self.activity.id) {
            self.activity = cachedActivity
            self.rpe = cachedActivity.rpe ?? 5.0 // Update RPE from cached activity
            self.notes = cachedActivity.notes ?? "" // Update notes from cached activity
            self.tag = cachedActivity.tag
        }

        // If the loaded activity (either from cache or initial) is missing dynamics, fetch them.
        if self.activity.verticalOscillation == nil {
            fetchAndEnrichWithHealthKit()
        }
        
        loadCachedSummaries()
        await loadAndProcessStreams()
    }

    func prepareToAssociateRace() {
        loadActiveProcesses()
        showProcessSelection = true
    }

    func associateActivityTo(process: TrainingProcess) {
        var updatedProcess = process
        updatedProcess.goalActivityID = self.activity.id
        updatedProcess.endDate = self.activity.date

        var allProcesses = cacheManager.loadTrainingProcesses()
        if let index = allProcesses.firstIndex(where: { $0.id == updatedProcess.id }) {
            allProcesses[index] = updatedProcess
            cacheManager.saveTrainingProcesses(allProcesses)
            cacheManager.deleteProcessGeminiCoachResponse(processId: updatedProcess.id)
            print("Process '\(updatedProcess.name)' updated and associated with activity \(self.activity.id).")
            self.isAlreadyRaceOfProcess = true // Update state after association
        }
    }

    func forceRefreshActivity() async {
        // 1. Clear all caches for this specific activity
        cacheManager.clearCache(for: self.activity.id)
        
        // 2. Reset all published properties to give immediate feedback to the user
        self.heartRateData = []
        self.cadenceData = []
        self.powerData = []
        self.altitudeData = []
        self.paceData = []
        self.distanceData = []
        self.strideLengthData = []
        self.vamKPI = nil
        self.decouplingKPI = nil
        self.descentVamKPI = nil
        self.normalizedPowerKPI = nil
        self.gapKPI = nil
        self.efficiencyIndexKPI = nil
        self.verticalOscillationKPI = nil
        self.groundContactTimeKPI = nil
        self.strideLengthKPI = nil
        self.verticalRatioKPI = nil
        self.radarChartDataPoints = []
        self.climbSegments = []
        self.heartRateZoneDistribution = nil
        self.performanceByGrade = []
        self.aiCoachObservation = nil
        
        // 3. Reload all data from the network
        await loadActivityDetails()
    }

    private func disassociateRaceFromProcess() {
        var allProcesses = cacheManager.loadTrainingProcesses()
        if let index = allProcesses.firstIndex(where: { $0.goalActivityID == self.activity.id }) {
            var processToUpdate = allProcesses[index]
            processToUpdate.goalActivityID = nil
            allProcesses[index] = processToUpdate
            cacheManager.saveTrainingProcesses(allProcesses)
            self.isAlreadyRaceOfProcess = false
            print("Process '\(processToUpdate.name)' disassociated from activity \(self.activity.id).")
        }
    }

    private func saveActivity() {
        cacheManager.saveActivityDetail(activity: activity)
        cacheManager.updateActivityInSummaryCache(activity: activity)
    }

    private func loadActiveProcesses() {
        self.activeProcesses = cacheManager.loadTrainingProcesses().filter { !$0.isCompleted }
    }

    private func checkIfActivityIsRace() {
        let allProcesses = cacheManager.loadTrainingProcesses()
        let isRace = allProcesses.contains { $0.goalActivityID == self.activity.id }
        self.isAlreadyRaceOfProcess = isRace
    }
    
    // MARK: - Data Loading and Processing
    private func loadAndProcessStreams() async {
        if let cachedStreams = self.cacheManager.loadActivityStreams(activityId: self.activity.id) {
            await self.processAndCalculateGraphData(streamsDictionary: cachedStreams)
            return
        }
        
        do {
            let streams = try await getStreamsFromNetwork(activityId: activity.id)
            await processAndCalculateGraphData(streamsDictionary: streams)
        } catch {
            await updateError(message: "Failed to fetch activity streams: \(error.localizedDescription)")
        }
    }
    
    private func getStreamsFromNetwork(activityId: Int) async throws -> [String: Stream] {
        return try await withCheckedThrowingContinuation { continuation in
            stravaService.getActivityStreams(activityId: activityId) { result in
                switch result {
                case .success(let streams):
                    continuation.resume(returning: streams)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func processAndCalculateGraphData(streamsDictionary: [String: Stream]) async {
        Task.detached(priority: .userInitiated) {
            let cacheManager = CacheManager()
            await cacheManager.saveActivityStreams(activityId: self.activity.id, streams: streamsDictionary)

            guard let timeStream = streamsDictionary["time"]?.data.compactMap({ $0 as? Double }) else { return }

            let heartRateData = ActivityAnalyticsCalculator.createChartData(timeStream: timeStream, dataStream: streamsDictionary["heartrate"]?.data)
            let rawCadence = ActivityAnalyticsCalculator.createChartData(timeStream: timeStream, dataStream: streamsDictionary["cadence"]?.data, transform: { $0 * 2 })
            let cadenceData = ActivityAnalyticsCalculator.movingMedian(data: rawCadence, windowSize: 31)
            let rawPower = ActivityAnalyticsCalculator.createChartData(timeStream: timeStream, dataStream: streamsDictionary["watts"]?.data)
            let powerData = ActivityAnalyticsCalculator.movingMedian(data: rawPower, windowSize: 31)
            let altitudeData = ActivityAnalyticsCalculator.createChartData(timeStream: timeStream, dataStream: streamsDictionary["altitude"]?.data).filter { $0.value.isFinite }
            let distanceData = ActivityAnalyticsCalculator.createChartData(timeStream: timeStream, dataStream: streamsDictionary["distance"]?.data)
            
            await MainActor.run {
                self.updateGraphData(heartRate: heartRateData, cadence: cadenceData, power: powerData, altitude: altitudeData, distance: distanceData)
            }

            let paceData = ActivityAnalyticsCalculator.calculatePace(distanceData: distanceData)
            let strideLengthData = ActivityAnalyticsCalculator.calculateStrideLength(distanceData: distanceData, cadenceData: cadenceData)

            let shouldCalculateTrailKPIs = await MainActor.run { self.heartRateZoneDistribution == nil || self.performanceByGrade.isEmpty }
            
            var processedMetrics: ActivityProcessedMetrics?
            if shouldCalculateTrailKPIs {
                let activity = await self.activity // Safely access actor-isolated property
                processedMetrics = ActivityAnalyticsCalculator.calculateAllTrailKPIs(activity: activity, powerData: powerData, heartRateData: heartRateData, paceData: paceData, distanceData: distanceData, altitudeData: altitudeData, cadenceData: cadenceData)
                if let metrics = processedMetrics {
                    cacheManager.saveProcessedMetrics(activityId: activity.id, metrics: metrics)
                }
            }

            await MainActor.run {
                self.updateFinalData(pace: paceData, strideLength: strideLengthData, metrics: processedMetrics)
                
                // Si se procesaron nuevas métricas, ahora es el momento de llamar a IA Coach
                // ya que tenemos la garantía de que los datos están completos.
                if processedMetrics != nil {
                    self.getAICoachObservation()
                }
            }
        }
    }
    
    private func loadCachedSummaries() {
        if let cachedText = cacheManager.loadAICoachText(activityId: activity.id) {
            self.aiCoachObservation = cachedText
            self.aiCoachLoading = false
        }
        if let cachedMetrics = cacheManager.loadProcessedMetrics(activityId: activity.id) {
            let vamValue = cachedMetrics.verticalSpeedVAM
            let descentVamValue = cachedMetrics.descentVerticalSpeed
            let isMetric = Formatters.isMetric

            self.vamKPI = KPIInfo(
                title: NSLocalizedString("kpi.vam.title", comment: "VAM title"),
                description: NSLocalizedString("kpi.vam.description", comment: "VAM description"),
                value: isMetric ? vamValue : vamValue.map { $0 * 3.28084 },
                higherIsBetter: true
            )
            self.decouplingKPI = KPIInfo(
                title: NSLocalizedString("kpi.decoupling.title", comment: "Decoupling title"),
                description: NSLocalizedString("kpi.decoupling.description", comment: "Decoupling description"),
                value: cachedMetrics.cardiacDecoupling,
                higherIsBetter: false
            )
            self.descentVamKPI = KPIInfo(
                title: NSLocalizedString("kpi.descentVam.title", comment: "Descent VAM title"),
                description: NSLocalizedString("kpi.descentVam.description", comment: "Descent VAM description"),
                value: isMetric ? descentVamValue : descentVamValue.map { $0 * 3.28084 },
                higherIsBetter: true
            )
            self.normalizedPowerKPI = KPIInfo(
                title: NSLocalizedString("kpi.normalizedPower.title", comment: "Normalized Power title"),
                description: NSLocalizedString("kpi.normalizedPower.description", comment: "Normalized Power description"),
                value: cachedMetrics.normalizedPower,
                higherIsBetter: true
            )
            self.gapKPI = KPIInfo(
                title: NSLocalizedString("kpi.gap.title", comment: "GAP title"),
                description: NSLocalizedString("kpi.gap.description", comment: "GAP description"),
                value: cachedMetrics.gradeAdjustedPace,
                higherIsBetter: false
            )
            self.efficiencyIndexKPI = KPIInfo(
                title: NSLocalizedString("kpi.efficiencyIndex.title", comment: "Efficiency Index title"),
                description: NSLocalizedString("kpi.efficiencyIndex.description", comment: "Efficiency Index description"),
                value: cachedMetrics.efficiencyIndex,
                higherIsBetter: true
            )
            
            self.climbSegments = cachedMetrics.climbSegments
            self.heartRateZoneDistribution = cachedMetrics.heartRateZoneDistribution
            self.performanceByGrade = cachedMetrics.performanceByGrade
        }
        calculateKPITrends()
    }
    
    // MARK: - UI Update Helpers
    private func updateGraphData(heartRate: [ChartDataPoint], cadence: [ChartDataPoint], power: [ChartDataPoint], altitude: [ChartDataPoint], distance: [ChartDataPoint]) {
        self.heartRateData = heartRate
        self.cadenceData = cadence
        self.powerData = power
        self.altitudeData = altitude
        self.distanceData = distance
    }
    
    private func updateFinalData(pace: [ChartDataPoint], strideLength: [ChartDataPoint], metrics: ActivityProcessedMetrics?) {
        self.paceData = pace
        self.strideLengthData = strideLength
        if let metrics = metrics {
            let vamValue = metrics.verticalSpeedVAM
            let descentVamValue = metrics.descentVerticalSpeed
            let isMetric = Formatters.isMetric

            self.vamKPI = KPIInfo(
                title: NSLocalizedString("kpi.vam.title", comment: "VAM title"),
                description: NSLocalizedString("kpi.vam.description", comment: "VAM description"),
                value: isMetric ? vamValue : vamValue.map { $0 * 3.28084 },
                higherIsBetter: true
            )
            self.decouplingKPI = KPIInfo(
                title: NSLocalizedString("kpi.decoupling.title", comment: "Decoupling title"),
                description: NSLocalizedString("kpi.decoupling.description", comment: "Decoupling description"),
                value: metrics.cardiacDecoupling,
                higherIsBetter: false
            )
            self.descentVamKPI = KPIInfo(
                title: NSLocalizedString("kpi.descentVam.title", comment: "Descent VAM title"),
                description: NSLocalizedString("kpi.descentVam.description", comment: "Descent VAM description"),
                value: isMetric ? descentVamValue : descentVamValue.map { $0 * 3.28084 },
                higherIsBetter: true
            )
            self.normalizedPowerKPI = KPIInfo(
                title: NSLocalizedString("kpi.normalizedPower.title", comment: "Normalized Power title"),
                description: NSLocalizedString("kpi.normalizedPower.description", comment: "Normalized Power description"),
                value: metrics.normalizedPower,
                higherIsBetter: true
            )
            self.gapKPI = KPIInfo(
                title: NSLocalizedString("kpi.gap.title", comment: "GAP title"),
                description: NSLocalizedString("kpi.gap.description", comment: "GAP description"),
                value: metrics.gradeAdjustedPace,
                higherIsBetter: false
            )
            self.efficiencyIndexKPI = KPIInfo(
                title: NSLocalizedString("kpi.efficiencyIndex.title", comment: "Efficiency Index title"),
                description: NSLocalizedString("kpi.efficiencyIndex.description", comment: "Efficiency Index description"),
                value: metrics.efficiencyIndex,
                higherIsBetter: true
            )
            
            self.climbSegments = metrics.climbSegments
            self.heartRateZoneDistribution = metrics.heartRateZoneDistribution
            self.performanceByGrade = metrics.performanceByGrade
        }
        calculateKPITrends()
    }
    
    private func updateError(message: String) {
        self.errorMessage = message
    }
    
    // MARK: - User Actions
    func generateAnalysisString() -> String {
        var analysis = String(format: NSLocalizedString("Activity Analysis: %@", comment: "Activity analysis title"), activity.name) + "\n\n"

        let kpis = gatherActivityKPIs()
        
        let orderedKeys = [
            NSLocalizedString("Date", comment: "Date"),
            NSLocalizedString("Distance", comment: "Distance"),
            NSLocalizedString("Moving Time", comment: "Moving Time"),
            NSLocalizedString("Positive Elevation", comment: "Positive Elevation"),
            NSLocalizedString("Perceived Effort (RPE)", comment: "Perceived Effort (RPE)"),
            NSLocalizedString("Race Type", comment: "Race Type"),
            NSLocalizedString("Grade Adjusted Pace (GAP)", comment: "Grade Adjusted Pace (GAP)"),
            NSLocalizedString("Average Heart Rate", comment: "Average Heart Rate"),
            NSLocalizedString("VAM (Average Ascent Speed)", comment: "VAM (Average Ascent Speed)"),
            NSLocalizedString("Average Descent Speed", comment: "Average Descent Speed"),
            NSLocalizedString("Cardiac Decoupling (Pace:HR)", comment: "Cardiac Decoupling (Pace:HR)"),
            NSLocalizedString("Normalized Power (NP)", comment: "Normalized Power (NP)"),
            NSLocalizedString("Average Power", comment: "Average Power"),
            NSLocalizedString("Average Cadence", comment: "Average Cadence"),
            NSLocalizedString("Efficiency Index (Speed/HR)", comment: "Efficiency Index (Speed/HR)"),
            NSLocalizedString("Vertical Oscillation", comment: "Vertical Oscillation"),
            NSLocalizedString("Ground Contact Time", comment: "Ground Contact Time"),
            NSLocalizedString("Stride Length", comment: "Stride Length"),
            NSLocalizedString("Vertical Ratio", comment: "Vertical Ratio"),
            NSLocalizedString("Heart Rate Zone Distribution", comment: "Heart Rate Zone Distribution"),
            NSLocalizedString("Performance by Grade", comment: "Performance by Grade"),
            NSLocalizedString("Key Segments", comment: "Key Segments")
        ]
        
        for key in orderedKeys {
            if let value = kpis[key], !value.isEmpty, value != "--" {
                analysis += "*\(key):* \(value)\n"
            }
        }

        return analysis
    }

    func getAICoachObservation(newTag: ActivityTag? = nil) {
        if aiCoachLoading { return }

        let currentTag = newTag ?? self.tag

        guard currentTag != nil else {
            self.aiCoachObservation = NSLocalizedString("Please select a race type to get AI analysis.", comment: "AI analysis placeholder")
            self.aiCoachError = nil
            self.aiCoachLoading = false
            self.cacheManager.deleteAICoachText(activityId: self.activity.id)
            return
        }

        guard vamKPI != nil else { 
            print("[AICoach] KPI data not yet processed. Skipping request.")
            return
        }

        if let cachedText = cacheManager.loadAICoachText(activityId: activity.id) {
            self.aiCoachObservation = cachedText
            self.aiCoachLoading = false
            self.aiCoachError = nil
            return
        }
        aiCoachLoading = true
        aiCoachError = nil
        let kpis = gatherActivityKPIs(newTag: newTag)
        GeminiCoachService.fetchObservation(kpis: kpis) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.aiCoachLoading = false
                switch result {
                case .success(let observation):
                    self.aiCoachObservation = observation
                    self.cacheManager.saveAICoachText(activityId: self.activity.id, text: observation)
                case .failure(let error):
                    self.aiCoachError = String(format: NSLocalizedString("AI Coach analysis not available: %@", comment: "AI analysis error"), error.localizedDescription)
                }
            }
        }
    }

    func shareGPX() {
        isGeneratingGPX = true
        gpxDataToShare = nil

        stravaService.getActivityStreams(activityId: activity.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGeneratingGPX = false
                switch result {
                case .success(let streamsDictionary):
                    if let gpxString = GPXGenerator.generateGPX(from: streamsDictionary, startDate: self?.activity.date ?? Date()) {
                        self?.gpxDataToShare = gpxString.data(using: .utf8)
                    }
                    else {
                        self?.errorMessage = NSLocalizedString("Failed to generate GPX data.", comment: "GPX generation error")
                    }
                case .failure(let error):
                    self?.errorMessage = String(format: NSLocalizedString("Failed to fetch activity streams for GPX: %@", comment: "GPX fetch error"), error.localizedDescription)
                }
            }
        }
    }
    
    private func gatherActivityKPIs(newTag: ActivityTag? = nil) -> [String: String] {
        var kpis: [String: String] = [: ]

        kpis[NSLocalizedString("Activity Name", comment: "Activity Name")] = activity.name
        kpis[NSLocalizedString("Date", comment: "Date")] = Formatters.dateFormatter.string(from: activity.date)
        kpis[NSLocalizedString("Distance", comment: "Distance")] = Formatters.formatDistance(activity.distance)
        kpis[NSLocalizedString("Moving Time", comment: "Moving Time")] = Formatters.formatTime(Int(activity.duration))
        kpis[NSLocalizedString("Positive Elevation", comment: "Positive Elevation")] = Formatters.formatElevation(activity.elevationGain)

        if let avgHR = activity.averageHeartRate {
            kpis[NSLocalizedString("Average Heart Rate", comment: "Average Heart Rate")] = Formatters.formatHeartRate(avgHR)
        }
        if let avgCadence = activity.averageCadence {
            kpis[NSLocalizedString("Average Cadence", comment: "Average Cadence")] = Formatters.formatCadence(avgCadence)
        }
        if let avgPower = activity.averagePower {
            kpis[NSLocalizedString("Average Power", comment: "Average Power")] = Formatters.formatPower(avgPower)
        }

        if let vo = activity.verticalOscillation {
            kpis[NSLocalizedString("Vertical Oscillation", comment: "Vertical Oscillation")] = String(format: "%.1f cm", vo)
        }
        if let gct = activity.groundContactTime {
            kpis[NSLocalizedString("Ground Contact Time", comment: "Ground Contact Time")] = String(format: "%.0f ms", gct)
        }
        if let sl = activity.strideLength {
            kpis[NSLocalizedString("Stride Length", comment: "Stride Length")] = String(format: "%.2f m", sl)
        }
        if let vr = activity.verticalRatio {
            kpis[NSLocalizedString("Vertical Ratio", comment: "Vertical Ratio")] = String(format: "%.1f %%", vr)
        }

        if let vam = vamKPI?.value {
            kpis[NSLocalizedString("VAM (Average Ascent Speed)", comment: "VAM (Average Ascent Speed)")] = Formatters.formatVerticalSpeed(vam)
        }
        if let decoupling = decouplingKPI?.value {
            kpis[NSLocalizedString("Cardiac Decoupling (Pace:HR)", comment: "Cardiac Decoupling (Pace:HR)")] = Formatters.formatDecoupling(decoupling)
        }
        if let descentV = descentVamKPI?.value {
            kpis[NSLocalizedString("Average Descent Speed", comment: "Average Descent Speed")] = Formatters.formatVerticalSpeed(descentV)
        }
        if let np = normalizedPowerKPI?.value {
            kpis[NSLocalizedString("Normalized Power (NP)", comment: "Normalized Power (NP)")] = Formatters.formatPower(np)
        }
        if let gap = gapKPI?.value {
            kpis[NSLocalizedString("Grade Adjusted Pace (GAP)", comment: "Grade Adjusted Pace (GAP)")] = gap.toPaceFormat()
        }
        if let efficiency = efficiencyIndexKPI?.value {
            kpis[NSLocalizedString("Efficiency Index (Speed/HR)", comment: "Efficiency Index (Speed/HR)")] = Formatters.formatEfficiencyIndex(efficiency)
        }
        if let rpe = activity.rpe {
            kpis[NSLocalizedString("Perceived Effort (RPE)", comment: "Perceived Effort (RPE)")] = String(format: "%.0f/10", rpe)
        }
        
        let currentTag = newTag ?? self.tag
        if let tag = currentTag {
            kpis[NSLocalizedString("Race Type", comment: "Race Type")] = tag.localizedName
        }

        if let hrZones = heartRateZoneDistribution {
            let zones = [
                "Z1: \(Int(hrZones.timeInZone1).toHoursMinutesSeconds())",
                "Z2: \(Int(hrZones.timeInZone2).toHoursMinutesSeconds())",
                "Z3: \(Int(hrZones.timeInZone3).toHoursMinutesSeconds())",
                "Z4: \(Int(hrZones.timeInZone4).toHoursMinutesSeconds())",
                "Z5: \(Int(hrZones.timeInZone5).toHoursMinutesSeconds())"
            ]
            kpis[NSLocalizedString("Heart Rate Zone Distribution", comment: "Heart Rate Zone Distribution")] = "\n" + zones.joined(separator: "\n")
        }

        if !performanceByGrade.isEmpty {
            let performanceSummary = performanceByGrade.map {
                "\($0.gradeBucket): \($0.averagePace.toPaceFormat())"
            }.joined(separator: "\n")
            kpis[NSLocalizedString("Performance by Grade", comment: "Performance by Grade")] = "\n" + performanceSummary
        }
        
        if !climbSegments.isEmpty {
            let segmentsSummary = climbSegments.map {
                let type = $0.type.localizedName
                let distance = Formatters.formatDistance($0.distance)
                let grade = Formatters.formatGrade($0.averageGrade)
                let pace = $0.averagePace.toPaceFormat()
                return "- \(type) " + String(format: NSLocalizedString("of %@ at %@ (Pace: %@)", comment: "segment summary format"), distance, grade, pace)
            }.joined(separator: "\n")

            if !segmentsSummary.isEmpty {
                kpis[NSLocalizedString("Key Segments", comment: "Key Segments")] = "\n" + segmentsSummary
            }
        }

        return kpis
    }
    
    private func fetchAndEnrichWithHealthKit() {
        healthKitService.requestAuthorization { [weak self] (authorized, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("[DEBUG] HealthKit authorization error: \(error.localizedDescription)")
                return
            }
            
            if authorized {
                self.healthKitService.fetchRunningDynamics(for: self.activity) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let dynamics):
                            self.activity.verticalOscillation = dynamics.verticalOscillation
                            self.activity.groundContactTime = dynamics.groundContactTime
                            self.activity.strideLength = dynamics.strideLength
                            self.activity.verticalRatio = dynamics.verticalRatio
                            
                        case .failure(let error):
                            print("[DEBUG] Failed to fetch running dynamics: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                print("[DEBUG] HealthKit authorization was denied by the user.")
            }
        }
    }

    // MARK: - KPI Trend Calculation
    private func calculateKPITrends() {
        let allActivities = cacheManager.loadAllActivityDetails()
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        
        let recentActivities = allActivities.filter { $0.date > thirtyDaysAgo && $0.id != self.activity.id }
        
        let recentMetrics = recentActivities.compactMap { cacheManager.loadProcessedMetrics(activityId: $0.id) }
        
        let isMetric = Formatters.isMetric

        // Update KPIs from Processed Metrics
        vamKPI = vamKPI.map { updateTrend(for: $0, with: recentMetrics.compactMap { $0.verticalSpeedVAM }) }
        decouplingKPI = decouplingKPI.map { updateTrend(for: $0, with: recentMetrics.compactMap { $0.cardiacDecoupling }) }
        descentVamKPI = descentVamKPI.map { updateTrend(for: $0, with: recentMetrics.compactMap { $0.descentVerticalSpeed }) }
        normalizedPowerKPI = normalizedPowerKPI.map { updateTrend(for: $0, with: recentMetrics.compactMap { $0.normalizedPower }) }
        gapKPI = gapKPI.map { updateTrend(for: $0, with: recentMetrics.compactMap { $0.gradeAdjustedPace }) }
        efficiencyIndexKPI = efficiencyIndexKPI.map { updateTrend(for: $0, with: recentMetrics.compactMap { $0.efficiencyIndex }) }
        
        // Update KPIs from Activity object (Running Dynamics)
        verticalOscillationKPI = activity.verticalOscillation.map { KPIInfo(title: KPIInfo.verticalOscillation.title, description: KPIInfo.verticalOscillation.description, value: isMetric ? $0 : $0 * 0.393701, higherIsBetter: KPIInfo.verticalOscillation.higherIsBetter) }
        verticalOscillationKPI = verticalOscillationKPI.map { updateTrend(for: $0, with: recentActivities.compactMap { $0.verticalOscillation }) }

        groundContactTimeKPI = activity.groundContactTime.map { KPIInfo(title: KPIInfo.groundContactTime.title, description: KPIInfo.groundContactTime.description, value: $0, higherIsBetter: KPIInfo.groundContactTime.higherIsBetter) }
        groundContactTimeKPI = groundContactTimeKPI.map { updateTrend(for: $0, with: recentActivities.compactMap { $0.groundContactTime }) }

        strideLengthKPI = activity.strideLength.map { KPIInfo(title: KPIInfo.strideLength.title, description: KPIInfo.strideLength.description, value: isMetric ? $0 : $0 * 3.28084, higherIsBetter: KPIInfo.strideLength.higherIsBetter) }
        strideLengthKPI = strideLengthKPI.map { updateTrend(for: $0, with: recentActivities.compactMap { $0.strideLength }) }

        verticalRatioKPI = activity.verticalRatio.map { KPIInfo(title: KPIInfo.verticalRatio.title, description: KPIInfo.verticalRatio.description, value: $0, higherIsBetter: KPIInfo.verticalRatio.higherIsBetter) }
        verticalRatioKPI = verticalRatioKPI.map { updateTrend(for: $0, with: recentActivities.compactMap { $0.verticalRatio }) }
        
        prepareRadarChartData(recentMetrics: recentMetrics, recentActivities: recentActivities)
    }

    private func updateTrend(for kpi: KPIInfo, with recentValues: [Double]) -> KPIInfo {
        guard let currentValue = kpi.value, !recentValues.isEmpty else { 
            return kpi
        }

        let average = recentValues.reduce(0, +) / Double(recentValues.count)
        let trend = determineTrend(currentValue: currentValue, average: average, higherIsBetter: kpi.higherIsBetter)

        return KPIInfo(
            title: kpi.title,
            description: kpi.description,
            value: kpi.value,
            trend: trend,
            higherIsBetter: kpi.higherIsBetter
        )
    }

    private func determineTrend(currentValue: Double, average: Double, higherIsBetter: Bool) -> KPITrend {
        // Use a 1% tolerance relative to the average to avoid flagging tiny, insignificant changes.
        let tolerance = 0.01 * abs(average)

        if abs(currentValue - average) <= tolerance {
            return .equal
        } else if higherIsBetter {
            return currentValue > average ? .up : .down
        } else {
            return currentValue < average ? .up : .down
        }
    }
    
    private func prepareRadarChartData(recentMetrics: [ActivityProcessedMetrics], recentActivities: [Activity]) {
        var points: [RadarChartDataPoint] = []

        let kpis: [(kpi: KPIInfo?, recentValues: [Double], label: String, color: Color)] = [
            (vamKPI, recentMetrics.compactMap { $0.verticalSpeedVAM }, NSLocalizedString("radar.vam.label", comment: "VAM radar label"), .orange),
            (decouplingKPI, recentMetrics.compactMap { $0.cardiacDecoupling }, NSLocalizedString("radar.decoupling.label", comment: "Decoupling radar label"), .yellow),
            (normalizedPowerKPI, recentMetrics.compactMap { $0.normalizedPower }, NSLocalizedString("radar.np.label", comment: "Normalized Power radar label"), .green),
            (gapKPI, recentMetrics.compactMap { $0.gradeAdjustedPace }, NSLocalizedString("radar.gap.label", comment: "GAP radar label"), .cyan),
            (efficiencyIndexKPI, recentMetrics.compactMap { $0.efficiencyIndex }, NSLocalizedString("radar.efficiency.label", comment: "Efficiency radar label"), .mint),
            (verticalRatioKPI, recentActivities.compactMap { $0.verticalRatio }, NSLocalizedString("radar.verticalRatio.label", comment: "Vertical Ratio radar label"), .purple)
        ]

        for (kpi, recentValues, label, color) in kpis {
            guard let currentValue = kpi?.value, let average = recentValues.averageOrNil() else { continue }

            // Normalization: Use the greater of the two values to set the scale for this axis, with a floor to avoid division by zero.
            let maxVal = max(currentValue, average) * 1.5
            
            let isLowerBetter = !(kpi?.higherIsBetter ?? true)

            var currentScaled: Double
            var averageScaled: Double

            if maxVal > 0 {
                if isLowerBetter {
                    // For 'lower is better', a lower value is 'better' (higher on the chart)
                    currentScaled = 100 - (currentValue / maxVal * 100)
                    averageScaled = 100 - (average / maxVal * 100)
                } else {
                    currentScaled = (currentValue / maxVal) * 100
                    averageScaled = (average / maxVal) * 100
                }
            } else {
                currentScaled = 50
                averageScaled = 50
            }

            points.append(
                .init(
                    label: label,
                    currentValue: min(max(currentScaled, 0), 100), // Clamp between 0 and 100
                    averageValue: min(max(averageScaled, 0), 100),
                    color: color
                )
            )
        }

        self.radarChartDataPoints = points
    }
}

// MARK: - Analytics Calculator
struct ActivityAnalyticsCalculator {
    
    static func createChartData(timeStream: [Double], dataStream: [Any]?, transform: ((Double) -> Double)? = nil) -> [ChartDataPoint] {
        guard let dataStream = dataStream?.compactMap({ $0 as? Double }) else { return [] }
        let transformedData = transform != nil ? dataStream.map(transform!) : dataStream
        return zip(timeStream, transformedData).map { ChartDataPoint(time: Int($0), value: $1) }
    }

    static func movingMedian(data: [ChartDataPoint], windowSize: Int) -> [ChartDataPoint] {
        guard windowSize % 2 == 1, data.count >= windowSize else { return data }
        let halfWindow = windowSize / 2
        var result: [ChartDataPoint] = []
        for i in 0..<data.count {
            let start = max(0, i - halfWindow)
            let end = min(data.count - 1, i + halfWindow)
            let windowSlice = data[start...end].map { $0.value }
            let sorted = windowSlice.sorted()
            let median = sorted.count % 2 == 1 ? sorted[sorted.count / 2] : (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2.0
            result.append(ChartDataPoint(time: data[i].time, value: median))
        }
        return result
    }
    
    static func calculatePace(distanceData: [ChartDataPoint]) -> [ChartDataPoint] {
        guard !distanceData.isEmpty else { return [] }
        var rawPacePoints: [ChartDataPoint] = []
        for i in 1..<distanceData.count {
            let timeChange = distanceData[i].time - distanceData[i-1].time
            let distanceChangeKm = (distanceData[i].value - distanceData[i-1].value) / 1000.0
            let paceValue = (distanceChangeKm > 0 && timeChange > 0) ? (Double(timeChange) / 60.0) / distanceChangeKm : 0.0
            rawPacePoints.append(ChartDataPoint(time: distanceData[i].time, value: paceValue))
        }
        return movingMedian(data: rawPacePoints, windowSize: 31)
    }

    static func calculateStrideLength(distanceData: [ChartDataPoint], cadenceData: [ChartDataPoint]) -> [ChartDataPoint] {
        guard !distanceData.isEmpty, !cadenceData.isEmpty else { return [] }
        let cadenceDict = Dictionary(uniqueKeysWithValues: cadenceData.map { ($0.time, $0.value) })
        var strideLengthPoints: [ChartDataPoint] = []
        for i in 1..<distanceData.count {
            let timeChange = Double(distanceData[i].time - distanceData[i-1].time)
            let distanceChangeMeters = distanceData[i].value - distanceData[i-1].value
            let speed = timeChange > 0 ? distanceChangeMeters / timeChange : 0
            if let cadence = cadenceDict[distanceData[i].time], cadence > 0 {
                let strideLength = speed / (cadence / 60.0) // speed (m/s) / cadence (steps/s)
                strideLengthPoints.append(ChartDataPoint(time: distanceData[i].time, value: strideLength))
            }
        }
        return movingMedian(data: strideLengthPoints, windowSize: 31)
    }
    
    static func calculateAllTrailKPIs(activity: Activity, powerData: [ChartDataPoint], heartRateData: [ChartDataPoint], paceData: [ChartDataPoint], distanceData: [ChartDataPoint], altitudeData: [ChartDataPoint], cadenceData: [ChartDataPoint]) -> ActivityProcessedMetrics {
        
        let vam = calculateVerticalSpeedVAM(elevationGain: activity.elevationGain, duration: activity.duration)
        let descentSpeed = calculateDescentVerticalSpeed(altitudeData: altitudeData)
        let normalizedPower = calculateNormalizedPower(powerData: powerData)
        let cardiacDecoupling = calculateCardiacDecoupling(paceData: paceData, heartRateData: heartRateData)
        let gap = calculateGradeAdjustedPace(distanceData: distanceData, altitudeData: altitudeData, totalDistance: activity.distance)
        let hrDistribution = calculateHeartRateZoneDistribution(heartRateData: heartRateData)
        let performanceByGrade = calculatePerformanceByGrade(distanceData: distanceData, altitudeData: altitudeData, cadenceData: cadenceData)
        let efficiencyIndex = calculateEfficiencyIndex(paceData: paceData, heartRateData: heartRateData)
        let segments = analyzeAndSetSegments(distanceData: distanceData, altitudeData: altitudeData, heartRateData: heartRateData)

        return ActivityProcessedMetrics(
            verticalSpeedVAM: vam,
            cardiacDecoupling: cardiacDecoupling,
            climbSegments: segments,
            descentVerticalSpeed: descentSpeed,
            normalizedPower: normalizedPower,
            gradeAdjustedPace: gap,
            heartRateZoneDistribution: hrDistribution,
            performanceByGrade: performanceByGrade,
            efficiencyIndex: efficiencyIndex
        )
    }
    
    // MARK: - Private Calculation Helpers

    static private func calculateVerticalSpeedVAM(elevationGain: Double, duration: Double) -> Double? {
        guard elevationGain > 0, duration > 0 else { return nil }
        return elevationGain / (duration / 3600.0)
    }

    static private func calculateDescentVerticalSpeed(altitudeData: [ChartDataPoint]) -> Double? {
        guard !altitudeData.isEmpty else { return nil }
        var totalDescent = 0.0
        var timeInDescent = 0
        for i in 1..<altitudeData.count {
            let altitudeChange = altitudeData[i].value - altitudeData[i-1].value
            if altitudeChange < 0 {
                totalDescent += abs(altitudeChange)
                timeInDescent += altitudeData[i].time - altitudeData[i-1].time
            }
        }
        guard timeInDescent > 0 else { return nil }
        return totalDescent / (Double(timeInDescent) / 3600.0)
    }

    static private func calculateNormalizedPower(powerData: [ChartDataPoint]) -> Double? {
        guard !powerData.isEmpty else { return nil }
        let rollingAverages = powerData.indices.compactMap { i -> Double? in
            let windowStartTime = powerData[i].time - 30
            let window = powerData.filter { $0.time >= windowStartTime && $0.time <= powerData[i].time }
            return window.map({ $0.value }).averageOrNil()
        }
        guard !rollingAverages.isEmpty else { return nil }
        let fourthPowers = rollingAverages.map { pow($0, 4.0) }
        guard let avgFourthPowers = fourthPowers.averageOrNil() else { return nil }
        return pow(avgFourthPowers, 1.0/4.0)
    }

    static private func calculateCardiacDecoupling(paceData: [ChartDataPoint], heartRateData: [ChartDataPoint]) -> Double? {
        let combinedData = paceData.compactMap { pacePoint -> (pace: Double, hr: Double)? in
            guard let hrPoint = heartRateData.first(where: { $0.time == pacePoint.time }), pacePoint.value > 0, hrPoint.value > 0 else { return nil }
            return (pace: pacePoint.value, hr: hrPoint.value)
        }
        guard combinedData.count > 10 else { return nil }
        let halfIndex = combinedData.count / 2
        let firstHalf = combinedData[0..<halfIndex]
        let secondHalf = combinedData[halfIndex..<combinedData.count]
        guard let firstHalfAvgRatio = firstHalf.map({ $0.pace / $0.hr }).averageOrNil(), firstHalfAvgRatio > 0, 
              let secondHalfAvgRatio = secondHalf.map({ $0.pace / $0.hr }).averageOrNil() else { return nil }
        return ((firstHalfAvgRatio - secondHalfAvgRatio) / firstHalfAvgRatio) * 100.0
    }

    static private func calculateGradeAdjustedPace(distanceData: [ChartDataPoint], altitudeData: [ChartDataPoint], totalDistance: Double) -> Double? {
        guard distanceData.count > 1, distanceData.count == altitudeData.count else { return nil }
        var equivalentTime: Double = 0
        for i in 1..<distanceData.count {
            let segmentDistance = distanceData[i].value - distanceData[i-1].value
            let segmentAltitudeChange = altitudeData[i].value - altitudeData[i-1].value
            let segmentTime = distanceData[i].time - distanceData[i-1].time
            guard segmentDistance > 0, segmentTime > 0 else { continue }
            let grade = segmentAltitudeChange / segmentDistance
            let cost = 1.0 + (grade >= 0 ? 3.5 * grade : 1.8 * grade)
            equivalentTime += Double(segmentTime) * max(0.3, cost)
        }
        guard totalDistance > 0 else { return nil }
        return (equivalentTime / totalDistance) * 1000 / 60.0
    }

    static private func calculateHeartRateZoneDistribution(heartRateData: [ChartDataPoint], maxHeartRate: Double = 190.0) -> HeartRateZoneDistribution? {
        guard !heartRateData.isEmpty else { return nil }
        let boundaries = [0.6, 0.7, 0.8, 0.9].map { $0 * maxHeartRate }
        var timeInZones: [TimeInterval] = Array(repeating: 0.0, count: 5)
        for i in 1..<heartRateData.count {
            let segmentTime = TimeInterval(heartRateData[i].time - heartRateData[i-1].time)
            let avgHeartRate = (heartRateData[i-1].value + heartRateData[i].value) / 2.0
            let zone = (boundaries.firstIndex(where: { avgHeartRate < $0 }) ?? 4)
            timeInZones[zone] += segmentTime
        }
        return HeartRateZoneDistribution(timeInZone1: timeInZones[0], timeInZone2: timeInZones[1], timeInZone3: timeInZones[2], timeInZone4: timeInZones[3], timeInZone5: timeInZones[4])
    }

    static private func calculatePerformanceByGrade(distanceData: [ChartDataPoint], altitudeData: [ChartDataPoint], cadenceData: [ChartDataPoint]) -> [PerformanceByGrade] {
        guard distanceData.count > 1, distanceData.count == altitudeData.count, !cadenceData.isEmpty else { return [] }
        let bucketLabels = ["<-15%", "-15% to -10%", "-10% to -5%", "-5% to 0%", "0% to 5%", "5% to 10%", "10% to 15%", ">15%"]
        var bucketedData = [String: (distance: Double, time: TimeInterval, elevation: Double, weightedCadenceSum: Double, timeWithCadence: TimeInterval)](uniqueKeysWithValues: bucketLabels.map { ($0, (0,0,0,0,0)) })
        let cadenceDict = Dictionary(uniqueKeysWithValues: cadenceData.map { ($0.time, $0.value) })

        for i in 1..<distanceData.count {
            let segmentDistance = distanceData[i].value - distanceData[i-1].value
            let segmentAltitude = altitudeData[i].value - altitudeData[i-1].value
            let segmentTime = TimeInterval(distanceData[i].time - distanceData[i-1].time)
            guard segmentDistance > 0.1 else { continue }
            let grade = segmentAltitude / segmentDistance
            let bucketLabel: String
            if grade < -0.15 { bucketLabel = bucketLabels[0] } else if grade < -0.10 { bucketLabel = bucketLabels[1] } else if grade < -0.05 { bucketLabel = bucketLabels[2] } else if grade <= 0.0 { bucketLabel = bucketLabels[3] } else if grade < 0.05 { bucketLabel = bucketLabels[4] } else if grade < 0.10 { bucketLabel = bucketLabels[5] } else if grade < 0.15 { bucketLabel = bucketLabels[6] } else { bucketLabel = bucketLabels[7] }
            bucketedData[bucketLabel]?.distance += segmentDistance
            bucketedData[bucketLabel]?.time += segmentTime
            bucketedData[bucketLabel]?.elevation += segmentAltitude
            if let cadence = cadenceDict[distanceData[i].time] {
                bucketedData[bucketLabel]?.weightedCadenceSum += cadence * segmentTime
                bucketedData[bucketLabel]?.timeWithCadence += segmentTime
            }
        }
        return bucketLabels.compactMap { label -> PerformanceByGrade? in
            guard let data = bucketedData[label], data.time > 1.0 else { return nil }
            return PerformanceByGrade(id: UUID(), gradeBucket: label, distance: data.distance, time: data.time, elevation: data.elevation, weightedCadenceSum: data.weightedCadenceSum, timeWithCadence: data.timeWithCadence)
        }
    }

    static private func calculateEfficiencyIndex(paceData: [ChartDataPoint], heartRateData: [ChartDataPoint]) -> Double? {
        let combinedData = paceData.compactMap { pacePoint -> (pace: Double, hr: Double)? in
            guard let hrPoint = heartRateData.first(where: { $0.time == pacePoint.time }), pacePoint.value > 0, hrPoint.value > 0 else { return nil }
            return (pace: pacePoint.value, hr: hrPoint.value)
        }
        guard !combinedData.isEmpty else { return nil }
        let efficiencyRatios = combinedData.map { (1000 / ($0.pace * 60)) / $0.hr }
        return efficiencyRatios.averageOrNil()
    }

    static private func analyzeAndSetSegments(distanceData: [ChartDataPoint], altitudeData: [ChartDataPoint], heartRateData: [ChartDataPoint]) -> [ActivitySegment] {
        guard distanceData.count > 1, altitudeData.count == distanceData.count else { return [] }
        var segments: [ActivitySegment] = []
        var currentSegmentPoints: [(dist: Double, alt: Double, time: Int)] = []
        var isClimbing: Bool? = nil
        for i in 1..<altitudeData.count {
            let prevPoint = (dist: distanceData[i-1].value, alt: altitudeData[i-1].value, time: altitudeData[i-1].time)
            let currentPoint = (dist: distanceData[i].value, alt: altitudeData[i].value, time: altitudeData[i].time)
            let currentlyClimbing = (currentPoint.alt - prevPoint.alt) > 0.1
            if isClimbing == nil { isClimbing = currentlyClimbing }
            if currentlyClimbing == isClimbing {
                if currentSegmentPoints.isEmpty { currentSegmentPoints.append(prevPoint) }
                currentSegmentPoints.append(currentPoint)
            } else {
                if let segment = createSegment(from: currentSegmentPoints, type: isClimbing! ? .climb : .descent, heartRateData: heartRateData) { segments.append(segment) }
                currentSegmentPoints = [prevPoint, currentPoint]
                isClimbing = currentlyClimbing
            }
        }
        if let segment = createSegment(from: currentSegmentPoints, type: isClimbing! ? .climb : .descent, heartRateData: heartRateData) { segments.append(segment) }
        return segments
    }

    static private func createSegment(from points: [(dist: Double, alt: Double, time: Int)], type: ActivitySegment.SegmentType, heartRateData: [ChartDataPoint]) -> ActivitySegment? {
        guard let startPoint = points.first, let endPoint = points.last else { return nil }
        let distance = endPoint.dist - startPoint.dist
        let elevationChange = endPoint.alt - startPoint.alt
        guard abs(elevationChange) >= 10, distance >= 100 else { return nil }
        let time = endPoint.time - startPoint.time
        let averageGrade = distance > 0 ? (elevationChange / distance) * 100 : 0
        let averagePace = (time > 0 && distance > 0) ? (Double(time) / 60.0) / (distance / 1000.0) : 0
        let verticalSpeed = (type == .climb && time > 0) ? (elevationChange / (Double(time) / 3600.0)) : nil
        let timeRange = startPoint.time...endPoint.time
        let averageHeartRate = heartRateData.filter { timeRange.contains($0.time) }.map { $0.value }.averageOrNil()
        return ActivitySegment(type: type, startDistance: startPoint.dist, endDistance: endPoint.dist, distance: distance, elevationChange: elevationChange, averageGrade: averageGrade, time: time, averagePace: averagePace, averageHeartRate: averageHeartRate, verticalSpeed: verticalSpeed)
    }
}