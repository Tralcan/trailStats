import SwiftUI

// NUEVO: Estructura para representar segmentos clave de la actividad (subidas, bajadas).
struct ActivitySegment: Identifiable, Hashable {
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

    enum SegmentType: String {
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

    private let stravaService = StravaService()
    
    init(activity: Activity) {
        self.activity = activity
        let cacheManager = CacheManager()
        if let cachedText = cacheManager.loadAICoachText(activityId: activity.id) {
            self.aiCoachObservation = cachedText
            self.aiCoachLoading = false
        }
    }
    
    func fetchActivityStreams() {
        isLoading = true
        
        stravaService.getActivityStreams(activityId: activity.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let streamsDictionary):
                    self?.process(streamsDictionary: streamsDictionary)
                case .failure(let error):
                    if let stravaAuthError = error as? StravaAuthError, case .apiError(let message) = stravaAuthError {
                        self?.errorMessage = message
                    } else {
                        self?.errorMessage = "Failed to fetch activity streams: \(error.localizedDescription)"
                    }
                    print("Failed to fetch activity streams: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func process(streamsDictionary: [String: Stream]) {
        guard let timeStream = streamsDictionary["time"]?.data.compactMap({ $0 as? Double }) else { return }

        if let hrStream = streamsDictionary["heartrate"]?.data.compactMap({ $0 as? Double }) {
            let rawHR = zip(timeStream, hrStream).map { ChartDataPoint(time: Int($0), value: $1) }
            self.heartRateData = movingMedian(data: rawHR, windowSize: 31)
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

        self.calculateTrailKPIs()
    }

    // MARK: - Métodos de Cálculo para Trail Running
    
    private func calculateTrailKPIs() {
        calculateVerticalSpeedVAM()
        calculateDescentVerticalSpeed()
        calculateNormalizedPower()
        calculateCardiacDecoupling()
        analyzeAndSetSegments()
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
}
