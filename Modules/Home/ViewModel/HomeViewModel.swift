import Foundation

/// ViewModel for the Home screen.
/// Manages both the authentication state and the list of activities.
@MainActor
class HomeViewModel: ObservableObject {
    func clearCachesAndReload() {
        cacheManager.clearAllCaches()
        activities = [] // Immediately clear UI
        refreshActivities() // Reloads from the correct source (Strava or HealthKit)
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
    @Published var advancedSearchTrainingTag: ActivityTag? = nil
    @Published private(set) var cachedActivityIds = Set<Int>()
    @Published var athleteName: String?
    
    private let stravaService = StravaService()
    private let healthKitService = HealthKitService()
    private let cacheManager = CacheManager()
    private let userDefaults = UserDefaults.standard
    private var currentPage = 1
    @Published var canLoadMoreActivities = true
    
    func refreshCacheStatus() {
        let allActivityIds = activities.map { $0.id }
        cachedActivityIds = cacheManager.getExistingMetricIds(for: allActivityIds)
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
        if advancedSearchName.isEmpty && advancedSearchDate == nil && advancedSearchDistance == nil && advancedSearchElevation == nil && advancedSearchDuration == nil && advancedSearchTrainingTag == nil {
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
            if let searchTag = advancedSearchTrainingTag {
                filtered = filtered.filter { $0.tag == searchTag }
            }
        }
        // Siempre ordenar por fecha descendente
        return filtered.sorted { $0.date > $1.date }
    }
    
    func applyAdvancedSearch(name: String, date: Date?, distance: Double?, elevation: Double?, duration: TimeInterval?, trainingTag: ActivityTag?) {
        self.advancedSearchName = name
        self.advancedSearchDate = date
        self.advancedSearchDistance = distance
        self.advancedSearchElevation = elevation
        self.advancedSearchDuration = duration
        self.advancedSearchTrainingTag = trainingTag
        // Clear basic search text when advanced search is applied
        self.searchText = ""
    }
    
    init() {
        let isStravaAuthenticated = stravaService.isAuthenticated()
        let isHealthKitUser = userDefaults.string(forKey: "userName") != nil
        
        _isAuthenticated = Published(initialValue: isStravaAuthenticated || isHealthKitUser)
        
        if isAuthenticated {
            fetchAthleteName()
            if isStravaAuthenticated {
                if let cachedActivities = cacheManager.loadActivities(), !cachedActivities.isEmpty {
                    self.activities = cachedActivities.sorted { $0.date > $1.date }
                    self.currentPage = 1
                    refreshCacheStatus()
                } else {
                    fetchActivities()
                }
            } else if isHealthKitUser {
                fetchHealthKitActivities()
            }
        }
    }
    
    private func fetchHealthKitActivities() {
        guard let activityType = userDefaults.string(forKey: "preferredActivity") else { return }
        isLoading = true
        healthKitService.fetchWorkouts(activityType: activityType) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let activities):
                    self?.activities = activities
                    // Caching for HealthKit activities can be added here if needed
                case .failure(let error):
                    print("Failed to fetch HealthKit workouts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func reloadDataFromCache() {
        if let cachedActivities = cacheManager.loadActivities() {
            self.activities = cachedActivities.sorted { $0.date > $1.date }
            refreshCacheStatus()
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
                    self?.fetchAthleteName()
                case .failure(let error):
                    print("Strava authentication failed: \(error.localizedDescription)")
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    func completeHealthKitOnboarding() {
        self.isAuthenticated = true
        self.fetchAthleteName()
        fetchHealthKitActivities()
    }
    
    func logout() {
        stravaService.logout()
        cacheManager.clearAllCaches()
        isAuthenticated = false
        activities = [] // Clear activities on logout
        athleteName = nil
        userDefaults.removeObject(forKey: "athleteFirstName")
        userDefaults.removeObject(forKey: "userName") // Also remove HealthKit name
        userDefaults.removeObject(forKey: "preferredActivity")
    }

    func fetchAthleteName() {
        if let storedName = userDefaults.string(forKey: "userName") { // Check for HealthKit name
            self.athleteName = storedName
            return
        }
        if let storedName = userDefaults.string(forKey: "athleteFirstName") { // Check for Strava name
            self.athleteName = storedName
            return
        }

        stravaService.getAthlete { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let athlete):
                    self?.athleteName = athlete.firstname
                    self?.userDefaults.set(athlete.firstname, forKey: "athleteFirstName")
                case .failure(let error):
                    print("Failed to fetch athlete name: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func shouldLoadMoreActivities(activity: Activity) -> Bool {
        let isLastActivity = activity.id == filteredActivities.last?.id
        let isSearchActive = !searchText.isEmpty || !advancedSearchName.isEmpty || advancedSearchDate != nil || advancedSearchDistance != nil || advancedSearchElevation != nil || advancedSearchDuration != nil || advancedSearchTrainingTag != nil
        // Disable pagination for HealthKit for now
        let isStravaAuthenticated = stravaService.isAuthenticated()
        return isLastActivity && !isSearchActive && canLoadMoreActivities && isStravaAuthenticated
    }
    
    func refreshActivities() {
        if stravaService.isAuthenticated() {
            currentPage = 1
            canLoadMoreActivities = true
            fetchActivities() // Solo busca la primera página para nuevas actividades
        } else {
            fetchHealthKitActivities()
        }
    }
    
    func fetchActivities() {
        guard !isLoading, canLoadMoreActivities, stravaService.isAuthenticated() else { return }
        isLoading = true
        stravaService.getActivities(page: currentPage, perPage: 50) { [weak self] result in
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
                    
                    // Si es la primera página, reemplazamos las actividades locales con las de Strava
                    // para asegurar que el orden y los datos son los más recientes.
                    if self.currentPage == 1 {
                        var updatedActivities: [Activity] = []
                        let existingActivitiesById = Dictionary(uniqueKeysWithValues: self.activities.map { ($0.id, $0) })
                        
                        for var newActivity in trailRuns {
                            if let existingActivity = existingActivitiesById[newActivity.id] {
                                // Preserve the tag and other local data
                                newActivity.tag = existingActivity.tag
                                newActivity.rpe = existingActivity.rpe
                                newActivity.notes = existingActivity.notes
                            }
                            updatedActivities.append(newActivity)
                        }
                        
                        let existingIds = Set(updatedActivities.map { $0.id })
                        for activity in self.activities {
                            if !existingIds.contains(activity.id) {
                                updatedActivities.append(activity)
                            }
                        }
                        
                        self.activities = updatedActivities
                    } else {
                        // Para páginas siguientes, solo añadimos las que no tengamos
                        let existingIds = Set(self.activities.map { $0.id })
                        let uniqueNew = trailRuns.filter { !existingIds.contains($0.id) }
                        self.activities.append(contentsOf: uniqueNew)
                    }
                    
                    self.activities.sort { $0.date > $1.date }
                    self.cacheManager.saveActivities(self.activities)
                    self.checkAndInvalidateAffectedProcesses(for: trailRuns)
                    self.refreshCacheStatus() // Actualizar estado de caché después de cada carga
                    
                    self.currentPage += 1
                    
                case .failure(let error):
                    print("Failed to fetch activities: \(error.localizedDescription)")
                    if let stravaError = error as? StravaAuthError, stravaError == .invalidRefreshToken {
                        print("Invalid refresh token detected. Logging out.")
                        self.logout()
                    }
                }
            }
        }
    }
    
    private func checkAndInvalidateAffectedProcesses(for newActivities: [Activity]) {
        let processes = cacheManager.loadTrainingProcesses()
        guard !processes.isEmpty, !newActivities.isEmpty else { return }
        
        for activity in newActivities {
            for process in processes {
                if !process.isCompleted && activity.date >= process.startDate && activity.date <= process.endDate {
                    print("Activity \(activity.id) affects process '\(process.name)'. Invalidating Gemini cache.")
                    cacheManager.deleteProcessGeminiCoachResponse(processId: process.id)
                }
            }
        }
    }
}
