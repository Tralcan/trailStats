
import Foundation

/// ViewModel for the Home screen.
/// Manages both the authentication state and the list of activities.
@MainActor
class HomeViewModel: ObservableObject {
    // Deletes all app caches (activities, streams, summaries, metrics, images, AI coach, etc) and reloads from Strava
    func clearCachesAndReload() {
        cacheManager.clearAllCaches() // Borra actividades y streams
        // Borra summaries y archivos relacionados
        if let summariesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("activitySummaries"),
           FileManager.default.fileExists(atPath: summariesURL.path) {
            do {
                try FileManager.default.removeItem(at: summariesURL)
                print("Successfully cleared all activity summaries cache.")
            } catch {
                print("Error clearing activity summaries cache: \(error.localizedDescription)")
            }
        }
        activities = []
        currentPage = 1
        canLoadMoreActivities = true
        fetchActivities()
    }
    
    @Published var isAuthenticated: Bool
    @Published var activities: [Activity] = []
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var advancedSearchName: String = ""
    @Published var advancedSearchDate: Date? = nil
    @Published var advancedSearchDistance: Double? = nil
    @Published var advancedSearchElevation: Double? = nil
    @Published var advancedSearchDuration: TimeInterval? = nil
    @Published private(set) var cachedActivityIds = Set<Int>()

    private let stravaService = StravaService()
    private let cacheManager = CacheManager()
    private var currentPage = 1
    @Published var canLoadMoreActivities = true

    func refreshCacheStatus() {
        for activity in activities {
            if cacheManager.loadMetrics(activityId: activity.id) != nil {
                cachedActivityIds.insert(activity.id)
            }
        }
    }

    func isActivityCached(activityId: Int) -> Bool {
        return cachedActivityIds.contains(activityId)
    }

    func markActivityAsCached(activityId: Int) {
        cachedActivityIds.insert(activityId)
    }
    
    var filteredActivities: [Activity] {
        var filtered = activities
        // Apply basic name search if advanced search is not active
        if advancedSearchName.isEmpty && advancedSearchDate == nil && advancedSearchDistance == nil && advancedSearchElevation == nil && advancedSearchDuration == nil {
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
            if let searchDuration = advancedSearchDuration {
                filtered = filtered.filter { $0.duration >= searchDuration }
            }
        }
        // Siempre ordenar por fecha descendente
        return filtered.sorted { $0.date > $1.date }
    }
    
    func applyAdvancedSearch(name: String, date: Date?, distance: Double?, elevation: Double?, duration: TimeInterval?) {
        self.advancedSearchName = name
        self.advancedSearchDate = date
        self.advancedSearchDistance = distance
        self.advancedSearchElevation = elevation
        self.advancedSearchDuration = duration
        // Clear basic search text when advanced search is applied
        self.searchText = ""
    }
    
    init() {
        _isAuthenticated = Published(initialValue: stravaService.isAuthenticated())
        if isAuthenticated {
            if let cachedActivities = cacheManager.loadActivities(), !cachedActivities.isEmpty {
                // Mostrar instantáneamente el caché, pero siempre empezar el paginado en 1
                self.activities = cachedActivities.sorted { $0.date > $1.date }
                self.currentPage = 1
            } else {
                fetchActivities()
            }
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
    cacheManager.clearAllCaches()
    isAuthenticated = false
    activities = [] // Clear activities on logout
    }
    
    func shouldLoadMoreActivities(activity: Activity) -> Bool {
        let isLastActivity = activity.id == filteredActivities.last?.id
        let isSearchActive = !searchText.isEmpty || !advancedSearchName.isEmpty || advancedSearchDate != nil || advancedSearchDistance != nil || advancedSearchElevation != nil || advancedSearchDuration != nil
        return isLastActivity && !isSearchActive && canLoadMoreActivities
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
                        return
                    }
                    let trailRuns = newActivities.filter { $0.sportType == "TrailRun" }
                    // Evitar duplicados por id
                    let existingIds = Set(self.activities.map { $0.id })
                    let uniqueNew = trailRuns.filter { !existingIds.contains($0.id) }
                    self.activities.append(contentsOf: uniqueNew)
                    // Ordenar siempre por fecha descendente
                    self.activities.sort { $0.date > $1.date }
                    self.cacheManager.saveActivities(self.activities)
                    // Siempre avanzar de página si la respuesta no está vacía
                    self.currentPage += 1
                case .failure(let error):
                    print("Failed to fetch activities: \(error.localizedDescription)")
                }
            }
        }
    }
}
