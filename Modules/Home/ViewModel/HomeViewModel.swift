
import Foundation

/// ViewModel for the Home screen.
/// Manages both the authentication state and the list of activities.
@MainActor
class HomeViewModel: ObservableObject {
    
    @Published var isAuthenticated: Bool
    @Published var activities: [Activity] = []
    
    private let stravaService = StravaService()
    
    init() {
        _isAuthenticated = Published(initialValue: stravaService.isAuthenticated())
    }
    
    func connectToStrava() {
        print("Initiating Strava connection...")
        stravaService.authenticate { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Successfully authenticated with Strava.")
                    self?.isAuthenticated = true
                    self?.fetchActivities()
                case .failure(let error):
                    print("Strava authentication failed: \(error.localizedDescription)")
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    func logout() {
        stravaService.logout()
        isAuthenticated = false
        activities = [] // Clear activities on logout
    }
    
    func fetchActivities() {
        // In the future, this will fetch from a repository.
        // For now, we use the mock service.
        self.activities = MockDataService.generateActivities()
    }
}
