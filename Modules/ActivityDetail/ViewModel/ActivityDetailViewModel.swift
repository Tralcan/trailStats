import SwiftUI

@MainActor
class ActivityDetailViewModel: ObservableObject {
    @Published var activity: Activity
    @Published var heartRateData: [DataPoint] = []
    @Published var cadenceData: [DataPoint] = []
    @Published var powerData: [DataPoint] = []
    @Published var altitudeData: [DataPoint] = []
    @Published var strideLengthData: [DataPoint] = []
    @Published var groundContactTimeData: [DataPoint] = []
    @Published var isLoading = false
    
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

        // New: Stride Length Stream
        if let strideLengthStream = streamsDictionary["stride_length"]?.data.compactMap({ $0 }) {
            self.strideLengthData = zip(timeStream, strideLengthStream).map { DataPoint(time: $0, value: $1) }
        }

        // New: Ground Contact Time Stream
        if let groundContactTimeStream = streamsDictionary["ground_contact_time"]?.data.compactMap({ $0 }) {
            self.groundContactTimeData = zip(timeStream, groundContactTimeStream).map { DataPoint(time: $0, value: $1) }
        }
    }
}
