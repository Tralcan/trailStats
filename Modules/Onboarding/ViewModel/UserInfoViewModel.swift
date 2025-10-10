import Foundation
import Combine

class UserInfoViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var selectedActivity: String = "Running"
    let activityTypes = ["Running", "Hike"]

    private var onComplete: () -> Void
    private let healthKitService = HealthKitService()

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    func savePreferences() {
        // Save to UserDefaults
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(selectedActivity, forKey: "preferredActivity")

        // Request HealthKit authorization
        healthKitService.requestAuthorization { [weak self] (success, error) in
            if success {
                // Notify the coordinator/view that the process is complete
                self?.onComplete()
            } else {
                // Handle the error or failure case if needed
                print("HealthKit Authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                // Even if it fails, we might want to complete the onboarding
                // and let the user see the app, though without data.
                self?.onComplete()
            }
        }
    }
}
