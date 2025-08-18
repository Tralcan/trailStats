
import Foundation

/// ViewModel for the Home screen.
/// Manages both the authentication state and the list of activities.
@MainActor
class HomeViewModel: ObservableObject {
    
    @Published var isAuthenticated: Bool
    @Published var activities: [Activity] = []
    @Published var isLoading: Bool = false
    
    private let stravaService = StravaService()
    private var currentPage = 1
    private var canLoadMoreActivities = true
    
    init() {
        _isAuthenticated = Published(initialValue: stravaService.isAuthenticated())
        if isAuthenticated {
            fetchActivities()
        }
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
        guard !isLoading, canLoadMoreActivities else { return }
        
        isLoading = true
        stravaService.getActivities(page: currentPage, perPage: 10) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                switch result {
                case .success(let newActivities):
                    if newActivities.isEmpty {
                        self.canLoadMoreActivities = false
                    } else {
                        self.activities.append(contentsOf: newActivities.filter { $0.sportType == "TrailRun" })
                        self.currentPage += 1
                    }
                case .failure(let error):
                    print("Failed to fetch activities: \(error.localizedDescription)")
                }
            }
        }
    }
}
