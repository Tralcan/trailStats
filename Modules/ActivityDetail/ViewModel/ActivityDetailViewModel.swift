import SwiftUI

// NUEVO: Estructura para representar segmentos clave de la actividad (subidas, bajadas).
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
    let verticalSpeed: Double? // m/h, solo para subidas

    enum SegmentType: String, Codable {
        case climb = "Subida"
        case descent = "Bajada"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ActivitySegment, rhs: ActivitySegment) -> Bool {
        lhs.id == rhs.id
    }
}

// La estructura para los gráficos ahora se llama ChartDataPoint para evitar conflictos.
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let time: Int
    let value: Double
}


@MainActor
class ActivityDetailViewModel: ObservableObject {
    @Published var activity: Activity
    @Published var heartRateData: [ChartDataPoint] = []
    @Published var cadenceData: [ChartDataPoint] = []
    @Published var powerData: [ChartDataPoint] = []
    @Published var altitudeData: [ChartDataPoint] = []
    @Published var cvertData: [ChartDataPoint] = []
    @Published var verticalSpeedData: [ChartDataPoint] = []
    @Published var strideLengthData: [ChartDataPoint] = []
    @Published var paceData: [ChartDataPoint] = []
    @Published var distanceData: [ChartDataPoint] = []
    @Published var isLoading = false
    @Published var isLoadingGraphData = false
    @Published var errorMessage: String? = nil
    @Published var isGeneratingGPX = false
    @Published var gpxDataToShare: Data? = nil

    // Persistencia de AI Coach
    @Published var aiCoachObservation: String? = nil
    @Published var aiCoachLoading: Bool = false
    @Published var aiCoachError: String? = nil
    
    // Propiedades para los KPIs de Trail Running
    @Published var verticalSpeedVAM: Double?
    @Published var cardiacDecoupling: Double?
    @Published var climbSegments: [ActivitySegment] = []
    @Published var descentVerticalSpeed: Double?
    @Published var normalizedPower: Double?
    @Published var gradeAdjustedPace: Double?
    @Published var heartRateZoneDistribution: HeartRateZoneDistribution?
    @Published var performanceByGrade: [PerformanceByGrade] = []
    @Published var efficiencyIndex: Double?

    private let stravaService = StravaService()
    private let healthKitService = HealthKitService()
    private let cacheManager = CacheManager()
    
    init(activity: Activity) {
        self.activity = activity
    }
    
    func loadActivityDetails() {
        print("[DEBUG] 1. loadActivityDetails() called for activity \(activity.id).")

        // First, try to load the fully enriched activity from the detail cache
        if let cachedActivity = cacheManager.loadActivityDetail(activityId: self.activity.id), cachedActivity.verticalOscillation != nil {
            self.activity = cachedActivity
            print("[DEBUG] 2. Found fully enriched activity in cache. No need to fetch from HealthKit.")
        } else {
            // If not found or incomplete, fetch HealthKit data to enrich the basic activity
            print("[DEBUG] 2. Enriched activity not in cache or incomplete. Fetching HealthKit data.")
            fetchAndEnrichWithHealthKit()
        }

        // Load other data like AI coach and processed metrics from their respective caches
        loadCachedSummaries()
        
        // Asynchronously load graph data (streams) from cache or network
        loadAndProcessStreams()
    }
    
    private func fetchAndEnrichWithHealthKit() {
        print("[DEBUG] 3. fetchAndEnrichWithHealthKit() called.")
        healthKitService.requestAuthorization { [weak self] (authorized, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("[DEBUG] 4. HealthKit authorization error: \(error.localizedDescription)")
                return
            }
            
            if authorized {
                print("[DEBUG] 4. HealthKit authorization successful.")
                self.healthKitService.fetchRunningDynamics(for: self.activity) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let dynamics):
                            print("[DEBUG] 5. Successfully fetched running dynamics from HealthKit.")
                            self.activity.verticalOscillation = dynamics.verticalOscillation
                            self.activity.groundContactTime = dynamics.groundContactTime
                            self.activity.strideLength = dynamics.strideLength
                            self.activity.verticalRatio = dynamics.verticalRatio
                            
                            print("[DEBUG] 6. Saving enriched activity to cache.")
                            self.cacheManager.saveActivityDetail(activity: self.activity)
                            
                        case .failure(let error):
                            print("[DEBUG] 5. Failed to fetch running dynamics: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                print("[DEBUG] 4. HealthKit authorization was denied by the user.")
            }
        }
    }
    
    private func loadCachedSummaries() {
        if let cachedText = cacheManager.loadAICoachText(activityId: activity.id) {
            self.aiCoachObservation = cachedText
            self.aiCoachLoading = false
        }

        if let cachedMetrics = cacheManager.loadProcessedMetrics(activityId: activity.id) {
            self.verticalSpeedVAM = cachedMetrics.verticalSpeedVAM
            self.cardiacDecoupling = cachedMetrics.cardiacDecoupling
            self.climbSegments = cachedMetrics.climbSegments
            self.descentVerticalSpeed = cachedMetrics.descentVerticalSpeed
            self.normalizedPower = cachedMetrics.normalizedPower
            self.gradeAdjustedPace = cachedMetrics.gradeAdjustedPace
            self.heartRateZoneDistribution = cachedMetrics.heartRateZoneDistribution
            self.performanceByGrade = cachedMetrics.performanceByGrade
            self.efficiencyIndex = cachedMetrics.efficiencyIndex
        }
    }

    // MARK: - AI Coach Interaction

    func getAICoachObservation() {
        // If already loading, do nothing.
        if aiCoachLoading { return }

        let cacheManager = CacheManager()
        // Check cache again to ensure aiCoachObservation is up-to-date
        if let cachedText = cacheManager.loadAICoachText(activityId: activity.id) {
            self.aiCoachObservation = cachedText // Ensure ViewModel property is set
            self.aiCoachLoading = false // Ensure loading state is off
            self.aiCoachError = nil // Clear any error
            return // Data loaded from cache, no need to fetch
        }

        // If we reach here, it means aiCoachObservation is nil (no cached data or previous fetch failed)
        // Set loading state
        aiCoachLoading = true
        aiCoachError = nil // Clear previous error if retrying

        // 1. Gather all necessary KPIs
        let kpis = gatherActivityKPIs()
        
        // 2. Call the service with the collected KPIs
        GeminiCoachService.fetchObservation(kpis: kpis) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.aiCoachLoading = false
                switch result {
                case .success(let observation):
                    self.aiCoachObservation = observation
                    // Cache the successful observation
                    let cacheManager = CacheManager()
                    cacheManager.saveAICoachText(activityId: self.activity.id, text: observation)
                case .failure(let error):
                    self.aiCoachError = "Análisis del IA Coach no disponible: \(error.localizedDescription)"
                }
            }
        }
    }
    
    
    
    private func processAndCalculateGraphData(streamsDictionary: [String: Stream]) {
        // Guardar streams en caché
        let cacheManager = CacheManager()
        cacheManager.saveActivityStreams(activityId: activity.id, streams: streamsDictionary)

        guard let timeStream = streamsDictionary["time"]?.data.compactMap({ $0 as? Double }) else { return }

        if let hrStream = streamsDictionary["heartrate"]?.data.compactMap({ $0 as? Double }) {
            let rawHR = zip(timeStream, hrStream).map { ChartDataPoint(time: Int($0), value: $1) }
            self.heartRateData = rawHR
        }
        
        if let cadenceStream = streamsDictionary["cadence"]?.data.compactMap({ $0 as? Double }) {
            let rawCadence = zip(timeStream, cadenceStream).map { ChartDataPoint(time: Int($0), value: $1 * 2) }
            self.cadenceData = movingMedian(data: rawCadence, windowSize: 31)
        }
        
        if let powerStream = streamsDictionary["watts"]?.data.compactMap({ $0 as? Double }) {
            let rawPower = zip(timeStream, powerStream).map { ChartDataPoint(time: Int($0), value: $1) }
            self.powerData = movingMedian(data: rawPower, windowSize: 31)
        }
        
        if let altitudeStream = streamsDictionary["altitude"]?.data.compactMap({ $0 as? Double }) {
            let rawAltitude = zip(timeStream, altitudeStream).map { ChartDataPoint(time: Int($0), value: $1) }
            self.altitudeData = rawAltitude.filter { $0.value.isFinite }
        }

        if let distStream = streamsDictionary["distance"]?.data.compactMap({ $0 as? Double }) {
            self.distanceData = zip(timeStream, distStream).map { ChartDataPoint(time: Int($0), value: $1) }
        }

        self.calculateCvert()
        self.calculateVerticalSpeed()
        self.calculateStrideLength()
        self.calculatePace()

        // Solo recalcular KPIs de trail si no se cargaron desde caché
        // o si los streams son nuevos (no de caché).
        // La forma más sencilla es verificar si heartRateZoneDistribution ya tiene un valor.
        // Si ya tiene un valor, significa que se cargó desde caché en el init.
        if self.heartRateZoneDistribution == nil || self.performanceByGrade.isEmpty {
            self.calculateTrailKPIs()
        }

        // Save processed metrics to cache
        let processedMetrics = ActivityProcessedMetrics(
            verticalSpeedVAM: self.verticalSpeedVAM,
            cardiacDecoupling: self.cardiacDecoupling,
            climbSegments: self.climbSegments,
            descentVerticalSpeed: self.descentVerticalSpeed,
            normalizedPower: self.normalizedPower,
            gradeAdjustedPace: self.gradeAdjustedPace,
            heartRateZoneDistribution: self.heartRateZoneDistribution, // Usar el valor actual (cargado o recalculado)
            performanceByGrade: self.performanceByGrade, // Usar el valor actual (cargado o recalculado)
            efficiencyIndex: self.efficiencyIndex
        )
        cacheManager.saveProcessedMetrics(activityId: activity.id, metrics: processedMetrics)
    }

    // MARK: - Métodos de Cálculo para Trail Running
    
    private func calculateTrailKPIs() {
        calculateVerticalSpeedVAM()
        calculateDescentVerticalSpeed()
        calculateNormalizedPower()
        calculateCardiacDecoupling()
        analyzeAndSetSegments()
        calculateGradeAdjustedPace()
        calculateHeartRateZoneDistribution()
        calculatePerformanceByGrade()
        calculateEfficiencyIndex()
    }

    private func calculateEfficiencyIndex() {
        guard !paceData.isEmpty, !heartRateData.isEmpty else {
            self.efficiencyIndex = nil
            return
        }

        let combinedData = paceData.compactMap { pacePoint -> (pace: Double, hr: Double)? in
            guard let hrPoint = heartRateData.first(where: { $0.time == pacePoint.time }) else { return nil }
            // Ensure data is valid for calculation
            guard pacePoint.value > 0, hrPoint.value > 0 else { return nil }
            return (pace: pacePoint.value, hr: hrPoint.value)
        }

        guard !combinedData.isEmpty else {
            self.efficiencyIndex = nil
            return
        }

        let efficiencyRatios = combinedData.map { (pace, hr) -> Double in
            // Convert pace (min/km) to speed (m/s)
            let speedMetersPerSecond = 1000 / (pace * 60)
            return speedMetersPerSecond / hr
        }

        self.efficiencyIndex = efficiencyRatios.averageOrNil()
    }

    private func calculatePerformanceByGrade() {
        guard distanceData.count > 1, distanceData.count == altitudeData.count, !cadenceData.isEmpty else {
            self.performanceByGrade = []
            return
        }

        let bucketLabels = ["<-15%", "-15% to -10%", "-10% to -5%", "-5% to 0%", "0% to 5%", "5% to 10%", "10% to 15%", ">15%"]
        var bucketedData: [String: (distance: Double, time: TimeInterval, elevation: Double, weightedCadenceSum: Double, timeWithCadence: TimeInterval)] = [:]
        for label in bucketLabels {
            bucketedData[label] = (0, 0, 0, 0, 0)
        }

        let cadenceDict = Dictionary(uniqueKeysWithValues: cadenceData.map { ($0.time, $0.value) })

        for i in 1..<distanceData.count {
            let segmentDistance = distanceData[i].value - distanceData[i-1].value
            let segmentAltitude = altitudeData[i].value - altitudeData[i-1].value
            let segmentTime = TimeInterval(distanceData[i].time - distanceData[i-1].time)

            guard segmentDistance > 0.1 else { continue }

            let grade = segmentAltitude / segmentDistance
            
            let bucketLabel: String
            if grade < -0.15 { bucketLabel = bucketLabels[0] }
            else if grade < -0.10 { bucketLabel = bucketLabels[1] }
            else if grade < -0.05 { bucketLabel = bucketLabels[2] }
            else if grade <= 0.0 { bucketLabel = bucketLabels[3] }
            else if grade < 0.05 { bucketLabel = bucketLabels[4] }
            else if grade < 0.10 { bucketLabel = bucketLabels[5] }
            else if grade < 0.15 { bucketLabel = bucketLabels[6] }
            else { bucketLabel = bucketLabels[7] }

            bucketedData[bucketLabel]?.distance += segmentDistance
            bucketedData[bucketLabel]?.time += segmentTime
            bucketedData[bucketLabel]?.elevation += segmentAltitude
            
            if let cadence = cadenceDict[distanceData[i].time] {
                bucketedData[bucketLabel]?.weightedCadenceSum += cadence * segmentTime
                bucketedData[bucketLabel]?.timeWithCadence += segmentTime
            }
        }

        var performanceData: [PerformanceByGrade] = []
        for label in bucketLabels {
            if let data = bucketedData[label], data.time > 1.0 {
                performanceData.append(
                    PerformanceByGrade(
                        id: UUID(), // Add missing ID
                        gradeBucket: label,
                        distance: data.distance,
                        time: data.time,
                        elevation: data.elevation,
                        weightedCadenceSum: data.weightedCadenceSum,
                        timeWithCadence: data.timeWithCadence
                    )
                )
            }
        }
        
        self.performanceByGrade = performanceData
    }

    private func calculateHeartRateZoneDistribution() {
        guard !heartRateData.isEmpty else {
            self.heartRateZoneDistribution = nil
            return
        }

        // TODO: This should be user-configurable in the future.
        let maxHeartRate = 190.0

        let zoneBoundaries = [
            0.0, // Zone 1 start
            maxHeartRate * 0.6, // Zone 2 start
            maxHeartRate * 0.7, // Zone 3 start
            maxHeartRate * 0.8, // Zone 4 start
            maxHeartRate * 0.9, // Zone 5 start
            Double.infinity // Zone 5 end
        ]

        var timeInZones: [TimeInterval] = Array(repeating: 0.0, count: 5)

        for i in 1..<heartRateData.count {
            let previousTime = heartRateData[i-1].time
            let currentTime = heartRateData[i].time
            let segmentTime = TimeInterval(currentTime - previousTime)

            // Use the average HR in the segment to determine the zone
            let avgHeartRateInSegment = (heartRateData[i-1].value + heartRateData[i].value) / 2.0

            if avgHeartRateInSegment < zoneBoundaries[1] {
                timeInZones[0] += segmentTime
            } else if avgHeartRateInSegment < zoneBoundaries[2] {
                timeInZones[1] += segmentTime
            } else if avgHeartRateInSegment < zoneBoundaries[3] {
                timeInZones[2] += segmentTime
            } else if avgHeartRateInSegment < zoneBoundaries[4] {
                timeInZones[3] += segmentTime
            } else {
                timeInZones[4] += segmentTime
            }
        }

        self.heartRateZoneDistribution = HeartRateZoneDistribution(
            timeInZone1: timeInZones[0],
            timeInZone2: timeInZones[1],
            timeInZone3: timeInZones[2],
            timeInZone4: timeInZones[3],
            timeInZone5: timeInZones[4]
        )
    }

    private func calculateGradeAdjustedPace() {
        guard distanceData.count > 1,
              distanceData.count == altitudeData.count else {
            self.gradeAdjustedPace = nil
            return
        }

        var equivalentTime: Double = 0
        
        for i in 1..<distanceData.count {
            let dist_prev = distanceData[i-1].value
            let dist_curr = distanceData[i].value
            let alt_prev = altitudeData[i-1].value
            let alt_curr = altitudeData[i].value
            let time_prev = distanceData[i-1].time
            let time_curr = distanceData[i].time

            let segmentDistance = dist_curr - dist_prev
            let segmentAltitudeChange = alt_curr - alt_prev
            let segmentTime = time_curr - time_prev

            guard segmentDistance > 0, segmentTime > 0 else { continue }

            let grade = segmentAltitudeChange / segmentDistance
            
            var cost: Double
            if grade >= 0 { // Uphill or flat
                cost = 1.0 + 3.5 * grade
            } else { // Downhill
                cost = 1.0 + 1.8 * grade
            }
            
            if cost < 0.3 { cost = 0.3 }

            equivalentTime += Double(segmentTime) * cost
        }

        guard activity.distance > 0 else {
            self.gradeAdjustedPace = nil
            return
        }
        
        let gapInSecondsPerKm = (equivalentTime / activity.distance) * 1000
        
        self.gradeAdjustedPace = gapInSecondsPerKm / 60.0
    }

    private func calculateVerticalSpeedVAM() {
        guard activity.elevationGain > 0 && activity.duration > 0 else {
            self.verticalSpeedVAM = 0
            return
        }
        let movingTimeInHours = activity.duration / 3600.0
        self.verticalSpeedVAM = activity.elevationGain / movingTimeInHours
    }
    
    private func calculateDescentVerticalSpeed() {
        
        guard !altitudeData.isEmpty else {
            self.descentVerticalSpeed = 0
            return
        }
        
        var totalDescent: Double = 0
        var timeInDescent: Int = 0
        
        for i in 1..<altitudeData.count {
            let altitudeChange = altitudeData[i].value - altitudeData[i-1].value
            if altitudeChange < 0 {
                totalDescent += abs(altitudeChange)
                let timeChange = altitudeData[i].time - altitudeData[i-1].time
                timeInDescent += timeChange
            }
        }
        
        guard timeInDescent > 0 else {
            self.descentVerticalSpeed = 0
            return
        }
        
        let timeInDescentInHours = Double(timeInDescent) / 3600.0
        self.descentVerticalSpeed = totalDescent / timeInDescentInHours
    }
    
    private func calculateNormalizedPower() {
        guard !powerData.isEmpty else {
            self.normalizedPower = nil
            return
        }
        
        var rollingAverages: [Double] = []
        for i in 0..<powerData.count {
            let windowStartTime = powerData[i].time - 30
            let window = powerData.filter { $0.time >= windowStartTime && $0.time <= powerData[i].time }
            if let average = window.map({ $0.value }).averageOrNil() {
                rollingAverages.append(average)
            }
        }
        
        guard !rollingAverages.isEmpty else {
            self.normalizedPower = nil
            return
        }
        
        let fourthPowers = rollingAverages.map { pow($0, 4.0) }
        
        guard let averageOfFourthPowers = fourthPowers.averageOrNil() else {
            self.normalizedPower = nil
            return
        }
        
        self.normalizedPower = pow(averageOfFourthPowers, 1.0/4.0)
    }

    private func calculateCardiacDecoupling() {
        guard heartRateData.count > 10 && paceData.count > 10 else {
            self.cardiacDecoupling = nil
            return
        }

        let combinedData = paceData.compactMap { pacePoint -> (pace: Double, hr: Double)? in
            guard let hrPoint = heartRateData.first(where: { $0.time == pacePoint.time }) else { return nil }
            guard pacePoint.value > 0 && hrPoint.value > 0 else { return nil }
            return (pace: pacePoint.value, hr: hrPoint.value)
        }

        guard combinedData.count > 10 else {
            self.cardiacDecoupling = nil
            return
        }

        let halfIndex = combinedData.count / 2
        let firstHalf = combinedData[0..<halfIndex]
        let secondHalf = combinedData[halfIndex..<combinedData.count]

        let firstHalfRatioSum = firstHalf.reduce(0) { $0 + ($1.pace / $1.hr) }
        let firstHalfAverageRatio = firstHalfRatioSum / Double(firstHalf.count)

        let secondHalfRatioSum = secondHalf.reduce(0) { $0 + ($1.pace / $1.hr) }
        let secondHalfAverageRatio = secondHalfRatioSum / Double(secondHalf.count)

        guard firstHalfAverageRatio > 0 else {
            self.cardiacDecoupling = nil
            return
        }

        let decoupling = ((firstHalfAverageRatio - secondHalfAverageRatio) / firstHalfAverageRatio) * 100.0
        self.cardiacDecoupling = decoupling
    }
    
    private func analyzeAndSetSegments() {
        guard distanceData.count > 1, altitudeData.count == distanceData.count else { return }

        var segments: [ActivitySegment] = []
        var currentSegmentPoints: [(dist: Double, alt: Double, time: Int)] = []
        var isClimbing: Bool? = nil

        let minElevationChangeForSegment: Double = 10
        let minDistanceForSegment: Double = 100

        for i in 1..<altitudeData.count {
            let prevPoint = (dist: distanceData[i-1].value, alt: altitudeData[i-1].value, time: altitudeData[i-1].time)
            let currentPoint = (dist: distanceData[i].value, alt: altitudeData[i].value, time: altitudeData[i].time)
            
            let elevationChange = currentPoint.alt - prevPoint.alt
            let currentlyClimbing = elevationChange > 0.1

            if isClimbing == nil {
                isClimbing = currentlyClimbing
            }

            if currentlyClimbing == isClimbing {
                if currentSegmentPoints.isEmpty {
                    currentSegmentPoints.append(prevPoint)
                }
                currentSegmentPoints.append(currentPoint)
            } else {
                if let startPoint = currentSegmentPoints.first, let endPoint = currentSegmentPoints.last {
                    let segmentElevationChange = endPoint.alt - startPoint.alt
                    let segmentDistance = endPoint.dist - startPoint.dist
                    
                    if abs(segmentElevationChange) >= minElevationChangeForSegment && segmentDistance >= minDistanceForSegment {
                        let segment = createSegment(from: currentSegmentPoints, type: isClimbing! ? .climb : .descent)
                        segments.append(segment)
                    }
                }
                
                currentSegmentPoints = [prevPoint, currentPoint]
                isClimbing = currentlyClimbing
            }
        }

        if let startPoint = currentSegmentPoints.first, let endPoint = currentSegmentPoints.last {
            let segmentElevationChange = endPoint.alt - startPoint.alt
            let segmentDistance = endPoint.dist - startPoint.dist
            if abs(segmentElevationChange) >= minElevationChangeForSegment && segmentDistance >= minDistanceForSegment {
                let segment = createSegment(from: currentSegmentPoints, type: isClimbing! ? .climb : .descent)
                segments.append(segment)
            }
        }
        
        self.climbSegments = segments
    }

    private func createSegment(from points: [(dist: Double, alt: Double, time: Int)], type: ActivitySegment.SegmentType) -> ActivitySegment {
        let startPoint = points.first!
        let endPoint = points.last!

        let distance = endPoint.dist - startPoint.dist
        let elevationChange = endPoint.alt - startPoint.alt
        let time = endPoint.time - startPoint.time
        
        let averageGrade = distance > 0 ? (elevationChange / distance) * 100 : 0
        let averagePace = time > 0 && distance > 0 ? (Double(time) / 60.0) / (distance / 1000.0) : 0
        
        var verticalSpeed: Double? = nil
        if type == .climb && time > 0 {
            let timeInHours = Double(time) / 3600.0
            verticalSpeed = elevationChange / timeInHours
        }
        
        let timeRange = startPoint.time...endPoint.time
        let hrInSegment = heartRateData.filter { timeRange.contains($0.time) }.map { $0.value }
        let averageHeartRate = hrInSegment.averageOrNil()

        return ActivitySegment(
            type: type,
            startDistance: startPoint.dist,
            endDistance: endPoint.dist,
            distance: distance,
            elevationChange: elevationChange,
            averageGrade: averageGrade,
            time: time,
            averagePace: averagePace,
            averageHeartRate: averageHeartRate,
            verticalSpeed: verticalSpeed
        )
    }


    // MARK: - Métodos de Ayuda y Cálculos Anteriores
    private func calculatePace() {
        guard !distanceData.isEmpty else {
            paceData = []
            return
        }

        var rawPacePoints: [ChartDataPoint] = []
        for i in 1..<distanceData.count {
            let currentTime = distanceData[i].time
            let previousTime = distanceData[i-1].time
            let currentDistance = distanceData[i].value
            let previousDistance = distanceData[i-1].value

            let distanceChange = currentDistance - previousDistance
            let timeChange = currentTime - previousTime

            var paceValue: Double = 0.0
            if distanceChange > 0 {
                let distanceChangeKm = distanceChange / 1000.0
                let timeChangeMinutes = Double(timeChange) / 60.0
                paceValue = timeChangeMinutes / distanceChangeKm
            }
            rawPacePoints.append(ChartDataPoint(time: currentTime, value: paceValue))
        }

        let validPaces = rawPacePoints.filter { $0.value > 0 }.map { $0.value }
        var averagePace: Double = 0.0
        if !validPaces.isEmpty {
            averagePace = validPaces.reduce(0.0, +) / Double(validPaces.count)
        }

        var filteredPacePoints: [ChartDataPoint] = []
        let outlierThreshold = averagePace * 3.0
        
        for dataPoint in rawPacePoints {
            if dataPoint.value > 0 && dataPoint.value < outlierThreshold {
                filteredPacePoints.append(dataPoint)
            } else {
                filteredPacePoints.append(ChartDataPoint(time: dataPoint.time, value: 0.0))
            }
        }
        self.paceData = movingMedian(data: filteredPacePoints, windowSize: 31)
    }

    private func calculateStrideLength() {
        guard !self.distanceData.isEmpty && !cadenceData.isEmpty else {
            strideLengthData = []
            return
        }

        var strideLengthPoints: [ChartDataPoint] = []
        for i in 1..<self.distanceData.count {
            let currentTime = self.distanceData[i].time
            let previousTime = self.distanceData[i-1].time
            let currentDistance = self.distanceData[i].value
            let previousDistance = self.distanceData[i-1].value

            let distanceChange = currentDistance - previousDistance
            let timeChange = currentTime - previousTime

            var currentSpeed: Double = 0.0
            if timeChange > 0 {
                currentSpeed = distanceChange / Double(timeChange)
            }

            if let currentCadenceDataPoint = cadenceData.first(where: { $0.time == currentTime }) {
                let currentCadence = currentCadenceDataPoint.value

                var strideLengthValue: Double = 0.0
                if currentCadence > 0 {
                    let cadenceInSPS = currentCadence / 60.0
                    strideLengthValue = currentSpeed / cadenceInSPS
                }
                strideLengthPoints.append(ChartDataPoint(time: currentTime, value: strideLengthValue))
            }
        }
        self.strideLengthData = movingMedian(data: strideLengthPoints, windowSize: 31)
    }

    private func calculateVerticalSpeed() {
        guard !altitudeData.isEmpty else {
            verticalSpeedData = []
            return
        }

        var verticalSpeedPoints: [ChartDataPoint] = []
        for i in 1..<altitudeData.count {
            let currentTime = altitudeData[i].time
            let previousTime = altitudeData[i-1].time
            let currentAltitude = altitudeData[i].value
            let previousAltitude = altitudeData[i-1].value

            let altitudeChange = currentAltitude - previousAltitude
            let timeChange = currentTime - previousTime

            var verticalSpeedValue: Double = 0.0
            if timeChange > 0 {
                let metersPerSecond = altitudeChange / Double(timeChange)
                verticalSpeedValue = metersPerSecond * 3600.0 // Convertido a m/h
            }
            verticalSpeedPoints.append(ChartDataPoint(time: currentTime, value: verticalSpeedValue))
        }
        self.verticalSpeedData = verticalSpeedPoints
    }

    private func calculateCvert() {
        guard !altitudeData.isEmpty && !powerData.isEmpty else {
            cvertData = []
            return
        }

        var cvertPoints: [ChartDataPoint] = []
        for i in 1..<altitudeData.count {
            let currentTime = altitudeData[i].time
            let currentAltitude = altitudeData[i].value
            let previousAltitude = altitudeData[i-1].value

            let currentPower = powerData.first(where: { $0.time == currentTime })?.value ?? 0.0

            let altitudeChange = currentAltitude - previousAltitude

            var cvertValue: Double = 0.0
            let minAltitudeChangeThreshold: Double = 0.2
            
            if altitudeChange > minAltitudeChangeThreshold {
                cvertValue = currentPower / altitudeChange
            }
            if cvertValue.isNaN || cvertValue < 0 {
                cvertValue = 0.0
            }
            cvertPoints.append(ChartDataPoint(time: currentTime, value: cvertValue))
        }
        self.cvertData = movingMedian(data: cvertPoints, windowSize: 31)
    }

    private func movingMedian(data: [ChartDataPoint], windowSize: Int) -> [ChartDataPoint] {
        guard windowSize % 2 == 1, data.count >= windowSize else { return data }
        let halfWindow = windowSize / 2
        var result: [ChartDataPoint] = []
        for i in 0..<data.count {
            let start = max(0, i - halfWindow)
            let end = min(data.count - 1, i + halfWindow)
            let windowSlice = data[start...end].map { $0.value }
            let sorted = windowSlice.sorted()
            let median: Double
            let count = sorted.count
            if count % 2 == 1 {
                median = sorted[count / 2]
            } else {
                median = (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
            }
            result.append(ChartDataPoint(time: data[i].time, value: median))
        }
        return result
    }
    
    // MARK: - AI Coach Data Collection

    func generateAnalysisString() -> String {
        var analysis = "*Análisis de la Actividad: \(activity.name)*\n\n"

        let kpis = gatherActivityKPIs()
        
        // Ordenar KPIs para una presentación consistente
        let orderedKeys = [
            "Fecha", "Distancia", "Tiempo en Movimiento", "Desnivel Positivo",
            "Ritmo Ajustado por Pendiente (GAP)", "Frecuencia Cardíaca Promedio",
            "VAM (Velocidad de Ascenso Media)", "Velocidad de Descenso Media",
            "Desacoplamiento Cardíaco (Ritmo:FC)", "Potencia Normalizada (NP)",
            "Potencia Promedio", "Cadencia Promedio", "Índice de Eficiencia (Velocidad/FC)",
            // Nuevas métricas de dinámica de carrera
            "Oscilación Vertical", "Tiempo de Contacto con el Suelo", "Longitud de Zancada", "Ratio Vertical",
            // KPIs complejos al final
            "Distribución de Zonas de FC", "Rendimiento por Pendiente", "Segmentos Clave"
        ]
        
        for key in orderedKeys {
            if let value = kpis[key], !value.isEmpty, value != "--" {
                analysis += "*\(key):* \(value)\n"
            }
        }

        return analysis
    }

    private func gatherActivityKPIs() -> [String: String] {
        var kpis: [String: String] = [: ]

        // Basic Activity Data
        kpis["Nombre de la Actividad"] = activity.name
        kpis["Fecha"] = Formatters.dateFormatter.string(from: activity.date)
        kpis["Distancia"] = Formatters.formatDistance(activity.distance)
        kpis["Tiempo en Movimiento"] = Formatters.formatTime(Int(activity.duration))
        kpis["Desnivel Positivo"] = Formatters.formatElevation(activity.elevationGain)

        // Main KPIs from Activity object
        if let avgHR = activity.averageHeartRate {
            kpis["Frecuencia Cardíaca Promedio"] = Formatters.formatHeartRate(avgHR)
        }
        if let avgCadence = activity.averageCadence {
            kpis["Cadencia Promedio"] = Formatters.formatCadence(avgCadence)
        }
        if let avgPower = activity.averagePower {
            kpis["Potencia Promedio"] = Formatters.formatPower(avgPower)
        }

        // HealthKit Running Dynamics
        if let vo = activity.verticalOscillation {
            kpis["Oscilación Vertical"] = String(format: "%.1f cm", vo)
        }
        if let gct = activity.groundContactTime {
            kpis["Tiempo de Contacto con el Suelo"] = String(format: "%.0f ms", gct)
        }
        if let sl = activity.strideLength {
            kpis["Longitud de Zancada"] = String(format: "%.2f m", sl)
        }
        if let vr = activity.verticalRatio {
            kpis["Ratio Vertical"] = String(format: "%.1f %%", vr)
        }

        // Calculated KPIs from ViewModel
        if let vam = verticalSpeedVAM {
            kpis["VAM (Velocidad de Ascenso Media)"] = Formatters.formatVerticalSpeed(vam)
        }
        if let decoupling = cardiacDecoupling {
            kpis["Desacoplamiento Cardíaco (Ritmo:FC)"] = Formatters.formatDecoupling(decoupling)
        }
        if let descentV = descentVerticalSpeed {
            kpis["Velocidad de Descenso Media"] = Formatters.formatVerticalSpeed(descentV)
        }
        if let np = normalizedPower {
            kpis["Potencia Normalizada (NP)"] = Formatters.formatPower(np)
        }
        if let gap = gradeAdjustedPace {
            kpis["Ritmo Ajustado por Pendiente (GAP)"] = gap.toPaceFormat()
        }
        if let efficiency = efficiencyIndex {
            kpis["Índice de Eficiencia (Velocidad/FC)"] = Formatters.formatEfficiencyIndex(efficiency)
        }

        // Complex KPIs formatting
        if let hrZones = heartRateZoneDistribution {
            let zones = [
                "Z1: \(Int(hrZones.timeInZone1).toHoursMinutesSeconds())",
                "Z2: \(Int(hrZones.timeInZone2).toHoursMinutesSeconds())",
                "Z3: \(Int(hrZones.timeInZone3).toHoursMinutesSeconds())",
                "Z4: \(Int(hrZones.timeInZone4).toHoursMinutesSeconds())",
                "Z5: \(Int(hrZones.timeInZone5).toHoursMinutesSeconds())"
            ]
            kpis["Distribución de Zonas de FC"] = "\n" + zones.joined(separator: "\n")
        }

        if !performanceByGrade.isEmpty {
            let performanceSummary = performanceByGrade.map { performance -> String in
                "\(performance.gradeBucket): \(performance.averagePace.toPaceFormat())"
            }.joined(separator: "\n")
            kpis["Rendimiento por Pendiente"] = "\n" + performanceSummary
        }
        
        if !climbSegments.isEmpty {
            let segmentsSummary = climbSegments.map { segment -> String in
                let type = segment.type == .climb ? "Subida" : "Bajada"
                let distance = Formatters.formatDistance(segment.distance)
                let grade = Formatters.formatGrade(segment.averageGrade)
                let pace = segment.averagePace.toPaceFormat()
                return "- \(type) de \(distance) al \(grade) (Ritmo: \(pace))"
            }.joined(separator: "\n")

            if !segmentsSummary.isEmpty {
                kpis["Segmentos Clave"] = "\n" + segmentsSummary
            }
        }

        return kpis
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
                        self?.errorMessage = "Failed to generate GPX data."
                    }
                case .failure(let error):
                    if let stravaAuthError = error as? StravaAuthError, case .apiError(let message) = stravaAuthError {
                        self?.errorMessage = message
                    } else {
                        self?.errorMessage = "Failed to fetch activity streams for GPX: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func loadAndProcessStreams() {
        isLoadingGraphData = true
        errorMessage = nil

        Task { @MainActor in
            let cacheManager = CacheManager()
            if let cachedStreams = cacheManager.loadActivityStreams(activityId: activity.id) {
                self.processAndCalculateGraphData(streamsDictionary: cachedStreams)
                self.isLoadingGraphData = false // Desactivar si se cargó desde caché
            } else {
                // Si no están en caché, obtener de la red
                stravaService.getActivityStreams(activityId: activity.id) { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        switch result {
                        case .success(let streamsDictionary):
                            self.processAndCalculateGraphData(streamsDictionary: streamsDictionary)
                        case .failure(let error):
                            if let stravaAuthError = error as? StravaAuthError, case .apiError(let message) = stravaAuthError {
                                self.errorMessage = message
                            } else {
                                self.errorMessage = "Failed to fetch activity streams: \(error.localizedDescription)"
                            }
                            print("Failed to fetch activity streams: \(error.localizedDescription)")
                        }
                        self.isLoadingGraphData = false // Desactivar si se cargó de la red
                    }
                }
            }
        }
    }
}