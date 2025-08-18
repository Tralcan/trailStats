
import Foundation

/// ViewModel for the Home screen.
/// Manages both the authentication state and the list of activities.
@MainActor
class HomeViewModel: ObservableObject {
    
    @Published var isAuthenticated: Bool
    @Published var activities: [Activity] = []
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var advancedSearchName: String = ""
    @Published var advancedSearchDate: Date? = nil
    @Published var advancedSearchDistance: Double? = nil
    @Published var advancedSearchElevation: Double? = nil
    
    private let stravaService = StravaService()
    private var currentPage = 1
    private var canLoadMoreActivities = true
    
    var filteredActivities: [Activity] {
        var filtered = activities
        
        // Apply basic name search if advanced search is not active
        if advancedSearchName.isEmpty && advancedSearchDate == nil && advancedSearchDistance == nil && advancedSearchElevation == nil {
            if !searchText.isEmpty {
                filtered = filtered.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            }
        } else {
            // Apply advanced search filters
            if !advancedSearchName.isEmpty {
                filtered = filtered.filter { $0.name.lowercased().contains(advancedSearchName.lowercased()) }
            }
            
            if let searchDate = advancedSearchDate {
                let calendar = Calendar.current
                filtered = filtered.filter { calendar.isDate($0.date, inSameDayAs: searchDate) }
            }
            
            if let searchDistance = advancedSearchDistance {
                filtered = filtered.filter { $0.distance >= searchDistance }
            }
            
            if let searchElevation = advancedSearchElevation {
                filtered = filtered.filter { $0.elevationGain >= searchElevation }
            }
        }
        
        return filtered
    }
    
    func applyAdvancedSearch(name: String, date: Date?, distance: Double?, elevation: Double?, duration: TimeInterval?) {
        self.advancedSearchName = name
        self.advancedSearchDate = date
        self.advancedSearchDistance = distance
        self.advancedSearchElevation = elevation
        // Clear basic search text when advanced search is applied
        self.searchText = ""
    }
    
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
