
import Foundation

import Foundation

class AdvancedAnalyticsViewModel: ObservableObject {
    @Published var filteredActivities: [Activity] = []
    private var allActivities: [Activity] = []

    init() {
        // Cargar actividades desde el caché (igual que HomeViewModel)
        if let cached = CacheManager().loadActivities() {
            allActivities = cached.sorted { $0.date > $1.date }
        }
        filteredActivities = allActivities
    }

    func filterByDateRange(days: Int) {
        let now = Date()
        let fromDate = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        filteredActivities = allActivities.filter { $0.date >= fromDate && $0.date <= now }
            .sorted { $0.date < $1.date }
    }
}
