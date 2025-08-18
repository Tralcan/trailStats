import SwiftUI

@MainActor
class ActivityDetailViewModel: ObservableObject {
    @Published var activity: Activity
    @Published var heartRateData: [DataPoint] = []
    @Published var cadenceData: [DataPoint] = []
    @Published var powerData: [DataPoint] = []
    @Published var altitudeData: [DataPoint] = []
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
                case .success(let streams):
                    self?.process(streams: streams)
                case .failure(let error):
                    print("Failed to fetch activity streams: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func process(streams: [Stream]) {
        guard let timeStream = streams.first(where: { $0.type == "time" })?.data.compactMap({ $0 }) else { return }

        if let hrStream = streams.first(where: { $0.type == "heartrate" })?.data.compactMap({ $0 }) {
            self.heartRateData = zip(timeStream, hrStream).map { DataPoint(time: $0, value: $1) }
        }
        
        if let cadenceStream = streams.first(where: { $0.type == "cadence" })?.data.compactMap({ $0 }) {
            self.cadenceData = zip(timeStream, cadenceStream).map { DataPoint(time: $0, value: $1 * 2) } // Cadence is often per leg, so we multiply by 2 for SPM
        }
        
        if let powerStream = streams.first(where: { $0.type == "watts" })?.data.compactMap({ $0 }) {
            self.powerData = zip(timeStream, powerStream).map { DataPoint(time: $0, value: $1) }
        }
        
        if let altitudeStream = streams.first(where: { $0.type == "altitude" })?.data.compactMap({ $0 }) {
            self.altitudeData = zip(timeStream, altitudeStream).map { DataPoint(time: $0, value: $1) }
        }
    }
}