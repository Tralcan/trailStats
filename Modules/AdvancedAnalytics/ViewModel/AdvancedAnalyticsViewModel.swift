
import Foundation

import Foundation

import Foundation

class AdvancedAnalyticsViewModel: ObservableObject {
    @Published var filteredActivities: [Activity] = []
    @Published var filteredMetrics: [ActivitySummaryMetrics] = []
    private var allActivities: [Activity] = []
    private var allMetrics: [ActivitySummaryMetrics] = []

    init() {
        // Cargar actividades desde el caché (igual que HomeViewModel)
        if let cached = CacheManager().loadActivities() {
            allActivities = cached.sorted { $0.date > $1.date }
        }
        // Cargar métricas avanzadas desde el caché de cada actividad
        allMetrics = allActivities.compactMap { CacheManager().loadMetrics(activityId: $0.id) }
        filteredActivities = allActivities
        filteredMetrics = allMetrics
    }

    func filterByDateRange(days: Int) {
        let now = Date()
        let fromDate = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        filteredActivities = allActivities.filter { $0.date >= fromDate && $0.date <= now }
            .sorted { $0.date < $1.date }
        let filteredIds = Set(filteredActivities.map { $0.id })
        filteredMetrics = allMetrics.filter { filteredIds.contains($0.activityId) }
    }
}
