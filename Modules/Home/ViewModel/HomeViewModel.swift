
import Foundation

/// ViewModel for the Home screen.
/// Manages both the authentication state and the list of activities.
@MainActor
class HomeViewModel: ObservableObject {
    
    @Published var isAuthenticated = false
    @Published var activities: [Activity] = []
    
    func connectToStrava() {
        // TODO: Implement Strava OAuth flow.
        print("Initiating Strava connection...")
        // Simulate a successful login and data fetch.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("Successfully authenticated with Strava.")
            self.isAuthenticated = true
            self.fetchActivities()
        }
    }
    
    func fetchActivities() {
        // In the future, this will fetch from a repository.
        // For now, we use the mock service.
        self.activities = MockDataService.generateActivities()
    }
}
