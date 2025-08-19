import SwiftUI

@MainActor
class ActivityDetailViewModel: ObservableObject {
    @Published var activity: Activity
    @Published var heartRateData: [DataPoint] = []
    @Published var cadenceData: [DataPoint] = []
    @Published var powerData: [DataPoint] = []
    @Published var altitudeData: [DataPoint] = []
    @Published var cvertData: [DataPoint] = []
    @Published var verticalSpeedData: [DataPoint] = []
    @Published var strideLengthData: [DataPoint] = []
    @Published var paceData: [DataPoint] = []
    @Published var distanceData: [DataPoint] = [] // New: Add distanceData as a published property
    @Published var isLoading = false
    @Published var errorMessage: String? = nil // New: Add errorMessage property
    @Published var isGeneratingGPX = false // New: Indicate if GPX generation is in progress
    @Published var gpxDataToShare: Data? = nil // New: Hold generated GPX data for sharing
    
    private let stravaService = StravaService()
    
    init(activity: Activity) {
        self.activity = activity
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
        guard let timeStream = streamsDictionary["time"]?.data.compactMap({ $0 }) else { return }

        if let hrStream = streamsDictionary["heartrate"]?.data.compactMap({ $0 }) {
            self.heartRateData = zip(timeStream, hrStream).map { DataPoint(time: $0, value: $1) }
        }
        
        if let cadenceStream = streamsDictionary["cadence"]?.data.compactMap({ $0 }) {
            self.cadenceData = zip(timeStream, cadenceStream).map { DataPoint(time: $0, value: $1 * 2) } // Cadence is often per leg
        }
        
        if let powerStream = streamsDictionary["watts"]?.data.compactMap({ $0 }) {
            self.powerData = zip(timeStream, powerStream).map { DataPoint(time: $0, value: $1) }
        }
        
        if let altitudeStream = streamsDictionary["altitude"]?.data.compactMap({ $0 }) {
            self.altitudeData = zip(timeStream, altitudeStream).map { DataPoint(time: $0, value: $1) }
        }

        var distanceData: [DataPoint] = []
        // Assign processed distance stream to the published property
        if let distStream = streamsDictionary["distance"]?.data.compactMap({ $0 }) {
            self.distanceData = zip(timeStream, distStream).map { DataPoint(time: $0, value: $1) }
        }

        self.calculateCvert()
        self.calculateVerticalSpeed()
        self.calculateStrideLength() // No longer takes distanceData as parameter
        self.calculatePace() // No longer takes distanceData as parameter
    }

    private func calculatePace() {
        guard !distanceData.isEmpty else {
            paceData = []
            return
        }

        var rawPacePoints: [DataPoint] = []
        for i in 1..<distanceData.count {
            let currentTime = distanceData[i].time
            let previousTime = distanceData[i-1].time
            let currentDistance = distanceData[i].value
            let previousDistance = distanceData[i-1].value

            let distanceChange = currentDistance - previousDistance // meters
            let timeChange = currentTime - previousTime // seconds

            var paceValue: Double = 0.0 // minutes per kilometer
            if distanceChange > 0 { // Only calculate pace if moving forward
                let distanceChangeKm = distanceChange / 1000.0 // kilometers
                let timeChangeMinutes = timeChange / 60.0 // minutes
                paceValue = timeChangeMinutes / distanceChangeKm
            }
            rawPacePoints.append(DataPoint(time: currentTime, value: paceValue))
        }

        // Calculate initial average pace from valid (non-zero) pace points
        let validPaces = rawPacePoints.filter { $0.value > 0 }.map { $0.value }
        var averagePace: Double = 0.0
        if !validPaces.isEmpty {
            averagePace = validPaces.reduce(0.0, +) / Double(validPaces.count)
        }

        // Filter out outliers
        var filteredPacePoints: [DataPoint] = []
        let outlierThreshold = averagePace * 3.0 // 3 times the average
        
        for dataPoint in rawPacePoints {
            if dataPoint.value > 0 && dataPoint.value < outlierThreshold {
                filteredPacePoints.append(dataPoint)
            } else {
                // Discard or set to 0. Setting to 0 for now to keep the time alignment.
                filteredPacePoints.append(DataPoint(time: dataPoint.time, value: 0.0))
            }
        }
        self.paceData = filteredPacePoints
    }

    private func calculateStrideLength() { // No longer takes distanceData as parameter
        guard !self.distanceData.isEmpty && !cadenceData.isEmpty else { // Use self.distanceData
            strideLengthData = []
            return
        }

        var strideLengthPoints: [DataPoint] = []
        for i in 1..<self.distanceData.count { // Use self.distanceData
            let currentTime = self.distanceData[i].time
            let previousTime = self.distanceData[i-1].time
            let currentDistance = self.distanceData[i].value
            let previousDistance = self.distanceData[i-1].value

            let distanceChange = currentDistance - previousDistance // meters
            let timeChange = currentTime - previousTime // seconds

            var currentSpeed: Double = 0.0 // meters/second
            if timeChange > 0 {
                currentSpeed = distanceChange / timeChange
            }

            // Find corresponding cadence data point
            if let currentCadenceDataPoint = cadenceData.first(where: { $0.time == currentTime }) {
                let currentCadence = currentCadenceDataPoint.value // in SPM (steps per minute)

                var strideLengthValue: Double = 0.0 // meters/stride
                if currentCadence > 0 {
                    // Convert cadence from SPM to steps per second
                    let cadenceInSPS = currentCadence / 60.0
                    // Stride Length (meters/stride) = Speed (meters/second) / Cadence (strides/second)
                    strideLengthValue = currentSpeed / cadenceInSPS
                }
                strideLengthPoints.append(DataPoint(time: currentTime, value: strideLengthValue))
            }
        }
        self.strideLengthData = strideLengthPoints
    }

    private func calculateVerticalSpeed() {
        guard !altitudeData.isEmpty else {
            verticalSpeedData = []
            return
        }

        var verticalSpeedPoints: [DataPoint] = []
        for i in 1..<altitudeData.count {
            let currentTime = altitudeData[i].time
            let previousTime = altitudeData[i-1].time
            let currentAltitude = altitudeData[i].value
            let previousAltitude = altitudeData[i-1].value

            let altitudeChange = currentAltitude - previousAltitude
            let timeChange = currentTime - previousTime

            var verticalSpeedValue: Double = 0.0
            if timeChange > 0 { // Avoid division by zero
                // Calculate vertical speed in meters per second (m/s)
                let metersPerSecond = altitudeChange / timeChange
                // Convert m/s to km/h (1 m/s = 3.6 km/h)
                verticalSpeedValue = metersPerSecond * 3.6
            }
            verticalSpeedPoints.append(DataPoint(time: currentTime, value: verticalSpeedValue))
        }
        self.verticalSpeedData = verticalSpeedPoints
    }

    private func calculateCvert() {
        guard !altitudeData.isEmpty && !powerData.isEmpty else {
            cvertData = []
            return
        }

        var cvertPoints: [DataPoint] = []
        for i in 1..<altitudeData.count {
            let currentTime = altitudeData[i].time
            let currentAltitude = altitudeData[i].value
            let previousAltitude = altitudeData[i-1].value

            let currentPower = powerData.first(where: { $0.time == currentTime })?.value ?? 0.0

            let altitudeChange = currentAltitude - previousAltitude

            var cvertValue: Double = 0.0
            let minAltitudeChangeThreshold: Double = 0.2 // Define a threshold, e.g., 0.2 meters
            
            if altitudeChange > minAltitudeChangeThreshold { // Only consider uphill segments with significant altitude change
                cvertValue = currentPower / altitudeChange
            }
            cvertPoints.append(DataPoint(time: currentTime, value: cvertValue))
        }
        self.cvertData = cvertPoints
    }

    func shareGPX() {
        isGeneratingGPX = true
        gpxDataToShare = nil // Clear previous data

        stravaService.getActivityStreams(activityId: activity.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGeneratingGPX = false
                switch result {
                case .success(let streamsDictionary):
                    if let gpxString = GPXGenerator.generateGPX(from: streamsDictionary, startDate: self?.activity.date ?? Date()) {
                        self?.gpxDataToShare = gpxString.data(using: .utf8)
                    } else {
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
