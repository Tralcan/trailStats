import Foundation

/// Manages caching of activities to the device's local storage.
class CacheManager {
    // Devuelve la ruta del archivo de métricas para una actividad
    func metricsFileURL(for activityId: Int) -> URL? {
        guard let folder = summaryFolderURL(for: activityId) else { return nil }
        return folder.appendingPathComponent("metrics.json")
    }
    // Guarda las métricas avanzadas de una actividad (metrics.json)
    func saveMetrics(activityId: Int, metrics: ActivitySummaryMetrics) {
        guard let folder = summaryFolderURL(for: activityId) else { return }
        let fileURL = folder.appendingPathComponent("metrics.json")
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(metrics)
            try data.write(to: fileURL, options: .atomic)
            // print("Saved metrics for activity \(activityId)")
        } catch {
            // print("Error saving metrics for activity \(activityId): \(error.localizedDescription)")
        }
    }

    // Carga las métricas avanzadas de una actividad (metrics.json)
    func loadMetrics(activityId: Int) -> ActivitySummaryMetrics? {
        guard let folder = summaryFolderURL(for: activityId) else { return nil }
        let fileURL = folder.appendingPathComponent("metrics.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(ActivitySummaryMetrics.self, from: data)
        } catch {
            print("Error loading metrics for activity \(activityId): \(error.localizedDescription)")
            return nil
        }
    }
    // Guarda el texto de AI Coach para una actividad
    func saveAICoachText(activityId: Int, text: String) {
        guard let folder = summaryFolderURL(for: activityId) else { return }
        let fileURL = folder.appendingPathComponent("ai_coach.txt")
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            print("[CacheManager] Saved AI Coach text for activity \(activityId) at \(fileURL.path)")
        } catch {
            print("[CacheManager] Error saving AI Coach text for activity \(activityId): \(error.localizedDescription)")
        }
    }

    // Carga el texto de AI Coach para una actividad
    func loadAICoachText(activityId: Int) -> String? {
        guard let folder = summaryFolderURL(for: activityId) else { return nil }
        let fileURL = folder.appendingPathComponent("ai_coach.txt")
        print("[CacheManager] Attempting to load AI Coach text for activity \(activityId) from \(fileURL.lastPathComponent). File exists: \(FileManager.default.fileExists(atPath: fileURL.path))")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let text = try String(contentsOf: fileURL, encoding: .utf8)
            print("[CacheManager] Successfully loaded AI Coach text for activity \(activityId).")
            return text
        } catch {
            print("[CacheManager] Error loading AI Coach text for activity \(activityId): \(error.localizedDescription)")
            return nil
        }
    }

    // Guarda las métricas procesadas de una actividad
    func saveProcessedMetrics(activityId: Int, metrics: ActivityProcessedMetrics) {
        guard let folder = summaryFolderURL(for: activityId) else { return }
        let fileURL = folder.appendingPathComponent("processed_metrics.json")
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(metrics)
            try data.write(to: fileURL, options: .atomic)
            print("Saved processed metrics for activity \(activityId)")
        } catch {
            print("Error saving processed metrics for activity \(activityId): \(error.localizedDescription)")
        }
    }

    // Carga las métricas procesadas de una actividad
    func loadProcessedMetrics(activityId: Int) -> ActivityProcessedMetrics? {
        guard let folder = summaryFolderURL(for: activityId) else { return nil }
        let fileURL = folder.appendingPathComponent("processed_metrics.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(ActivityProcessedMetrics.self, from: data)
        } catch {
            print("Error loading processed metrics for activity \(activityId): \(error.localizedDescription)")
            return nil
        }
    }

    /// Checks a list of activity IDs and returns a Set containing the IDs that have cached processed metrics.
    func getExistingMetricIds(for activityIds: [Int]) -> Set<Int> {
        var existingIds = Set<Int>()
        for id in activityIds {
            if let folder = summaryFolderURL(for: id) {
                let fileURL = folder.appendingPathComponent("processed_metrics.json")
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    existingIds.insert(id)
                }
            }
        }
        return existingIds
    }

    // MARK: - Activity Detail Cache

    func saveActivityDetail(activity: Activity) {
        guard let folder = summaryFolderURL(for: activity.id) else { return }
        let fileURL = folder.appendingPathComponent("activity_detail.json")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(activity)
            try data.write(to: fileURL, options: .atomic)
            print("Saved activity detail for activity \(activity.id)")
        } catch {
            print("Error saving activity detail for activity \(activity.id): \(error.localizedDescription)")
        }
    }

    func updateActivityInSummaryCache(activity: Activity) {
        guard var activities = loadActivities() else { return }
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index] = activity
            saveActivities(activities)
            print("Updated activity \(activity.id) in summary cache.")
        }
    }

    func loadActivityDetail(activityId: Int) -> Activity? {
        guard let folder = summaryFolderURL(for: activityId) else { return nil }
        let fileURL = folder.appendingPathComponent("activity_detail.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Activity.self, from: data)
        } catch {
            print("Error loading activity detail for activity \(activityId): \(error.localizedDescription)")
            return nil
        }
    }

    func loadAllActivityDetails() -> [Activity] {
        guard let summariesURL = summariesDirectoryURL else {
            print("Summaries directory not found.")
            return []
        }

        var activities: [Activity] = []
        let fileManager = FileManager.default
        
        do {
            let activityIDFolders = try fileManager.contentsOfDirectory(at: summariesURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            for folderURL in activityIDFolders {
                let detailFileURL = folderURL.appendingPathComponent("activity_detail.json")
                
                if fileManager.fileExists(atPath: detailFileURL.path) {
                    do {
                        let data = try Data(contentsOf: detailFileURL)
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let activity = try decoder.decode(Activity.self, from: data)
                        activities.append(activity)
                    } catch {
                        // Silently ignore decoding errors for individual files
                    }
                }
            }
        } catch {
            print("Error reading contents of summaries directory: \(error.localizedDescription)")
        }
        
        print("Loaded \(activities.count) total activity details from cache.")
        return activities
    }


    // MARK: - Summaries & Chart Images

    private var summariesDirectoryURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not find documents directory.")
            return nil
        }
        let summariesDir = documentsDirectory.appendingPathComponent("activitySummaries")
        if !FileManager.default.fileExists(atPath: summariesDir.path) {
            do {
                try FileManager.default.createDirectory(at: summariesDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating summaries directory: \(error.localizedDescription)")
                return nil
            }
        }
        return summariesDir
    }

    private func summaryFolderURL(for activityId: Int) -> URL? {
        guard let base = summariesDirectoryURL else { return nil }
        let folder = base.appendingPathComponent("\(activityId)")
        if !FileManager.default.fileExists(atPath: folder.path) {
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating summary folder: \(error.localizedDescription)")
                return nil
            }
        }
        return folder
    }

    // Guarda una imagen PNG de un gráfico para una actividad
    func saveChartImage(activityId: Int, chartName: String, imageData: Data) {
        guard let folder = summaryFolderURL(for: activityId) else { return }
        let fileURL = folder.appendingPathComponent("\(chartName).jpg")
        do {
            try imageData.write(to: fileURL, options: .atomic)
            print("Saved chart image \(chartName) for activity \(activityId)")
        } catch {
            print("Error saving chart image: \(error.localizedDescription)")
        }
    }

    // Carga una imagen PNG de un gráfico para una actividad
    func loadChartImage(activityId: Int, chartName: String) -> Data? {
    guard let folder = summaryFolderURL(for: activityId) else { return nil }
    let fileURL = folder.appendingPathComponent("\(chartName).jpg")
    return try? Data(contentsOf: fileURL)
    }

    // Guarda un resumen JSON de la actividad (distancia, elevación, tiempo, promedios, etc)
    func saveSummary(activityId: Int, summary: ActivitySummary) {
        guard let folder = summaryFolderURL(for: activityId) else { return }
        let fileURL = folder.appendingPathComponent("summary.json")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(summary)
            try data.write(to: fileURL, options: .atomic)
            print("Saved summary for activity \(activityId)")
            self.saveActivityForWidget(summary)
        } catch {
            print("Error saving summary: \(error.localizedDescription)")
        }
    }

    // Carga el resumen JSON de la actividad
    func loadSummary(activityId: Int) -> ActivitySummary? {
        guard let folder = summaryFolderURL(for: activityId) else { return nil }
        let fileURL = folder.appendingPathComponent("summary.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ActivitySummary.self, from: data)
        } catch {
            print("Error loading summary: \(activityId): \(error.localizedDescription)")
            return nil
        }
    }
    
    // Elimina el texto de AI Coach para una actividad
    func deleteAICoachText(activityId: Int) {
        guard let folder = summaryFolderURL(for: activityId) else { return }
        let fileURL = folder.appendingPathComponent("ai_coach.txt")
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("Deleted AI Coach text for activity \(activityId)")
            }
        } catch {
            print("Error deleting AI Coach text: \(error.localizedDescription)")
        }
    }
    
    private var fileURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not find documents directory.")
            return nil
        }
        return documentsDirectory.appendingPathComponent("activities.json")
    }

    private var streamsDirectoryURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not find documents directory.")
            return nil
        }
        let streamsDir = documentsDirectory.appendingPathComponent("activityStreams")
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: streamsDir.path) {
            do {
                try FileManager.default.createDirectory(at: streamsDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating streams directory: \(error.localizedDescription)")
                return nil
            }
        }
        return streamsDir
    }

    private func streamFileURL(for activityId: Int) -> URL? {
        return streamsDirectoryURL?.appendingPathComponent("\(activityId)_streams.json")
    }
    
    /// Saves a list of activities to a local JSON file.
    /// - Parameter activities: The array of `Activity` objects to save.
    func saveActivities(_ activities: [Activity]) {
        guard let url = fileURL else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(activities)
            try data.write(to: url, options: .atomic)
            print("Successfully saved \(activities.count) activities to cache.")
        } catch {
            print("Error saving activities to cache: \(error.localizedDescription)")
        }
    }
    
    /// Loads a list of activities from the local JSON file.
    /// - Returns: An array of `Activity` objects, or `nil` if no cache exists or an error occurs.
    func loadActivities() -> [Activity]? {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else {
            print("Cache file does not exist.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let activities = try decoder.decode([Activity].self, from: data)
            print("Successfully loaded \(activities.count) activities from cache.")
            return activities
        } catch {
            print("Error loading activities from cache: \(error.localizedDescription)")
            return nil
        }
    }

    /// Saves activity streams to a local JSON file.
    /// - Parameters:
    ///   - activityId: The ID of the activity.
    ///   - streams: The dictionary of `Stream` objects to save.
    func saveActivityStreams(activityId: Int, streams: [String: Stream]) {
        guard let url = streamFileURL(for: activityId) else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(streams)
            try data.write(to: url, options: .atomic)
            print("Successfully saved streams for activity \(activityId) to cache.")
        } catch {
            print("Error saving streams for activity \(activityId) to cache: \(error.localizedDescription)")
        }
    }

    /// Loads activity streams from a local JSON file.
    /// - Parameter activityId: The ID of the activity.
    /// - Returns: A dictionary of `Stream` objects, or `nil` if no cache exists or an error occurs.
    func loadActivityStreams(activityId: Int) -> [String: Stream]? {
        guard let url = streamFileURL(for: activityId), FileManager.default.fileExists(atPath: url.path) else {
            print("Cache file for activity \(activityId) streams does not exist.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let streams = try decoder.decode([String: Stream].self, from: data)
            print("Successfully loaded streams for activity \(activityId) from cache.")
            return streams
        } catch {
            print("Error loading streams for activity \(activityId) from cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Deletes the local activities cache file.
    func clearCache() {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else {
            print("Cache file does not exist.")
            return
        }
        
        do {
            try FileManager.default.removeItem(at: url)
            print("Successfully cleared the activity cache.")
        } catch {
            print("Error clearing activity cache: \(error.localizedDescription)")
        }
    }

    /// Deletes all local caches, including activities, activity streams, and summaries.
    func clearAllCaches() {
        clearCache() // Clear activities cache

        // Clear activity streams cache
        if let streamsURL = streamsDirectoryURL, FileManager.default.fileExists(atPath: streamsURL.path) {
            do {
                try FileManager.default.removeItem(at: streamsURL)
                print("Successfully cleared all activity streams cache.")
            } catch {
                print("Error clearing activity streams cache: \(error.localizedDescription)")
            }
        }

        // Clear activity summaries cache (metrics, AI coach, charts, summaries)
        if let summariesURL = summariesDirectoryURL, FileManager.default.fileExists(atPath: summariesURL.path) {
            do {
                try FileManager.default.removeItem(at: summariesURL)
                print("Successfully cleared all activity summaries cache.")
            } catch {
                print("Error clearing activity summaries cache: \(error.localizedDescription)")
            }
        }
    }

    /// Deletes all cached data for a single activity.
    func clearCache(for activityId: Int) {
        guard let folderURL = summaryFolderURL(for: activityId) else {
            print("Cache folder for activity \(activityId) not found.")
            return
        }
        
        if FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.removeItem(at: folderURL)
                print("Successfully cleared cache for activity \(activityId).")
            } catch {
                print("Error clearing cache for activity \(activityId): \(error.localizedDescription)")
            }
        }
    }

    private var raceCoachingDirectoryURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not find documents directory.")
            return nil
        }
        let raceCoachingDir = documentsDirectory.appendingPathComponent("raceCoaching")
        if !FileManager.default.fileExists(atPath: raceCoachingDir.path) {
            do {
                try FileManager.default.createDirectory(at: raceCoachingDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating raceCoaching directory: \(error.localizedDescription)")
                return nil
            }
        }
        return raceCoachingDir
    }

    private func raceCoachingFileURL(for raceId: UUID) -> URL? {
        return raceCoachingDirectoryURL?.appendingPathComponent("\(raceId.uuidString).json")
    }

    func saveRaceGeminiCoachResponse(raceId: UUID, response: RaceGeminiCoachResponse) {
        guard let url = raceCoachingFileURL(for: raceId) else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(response)
            try data.write(to: url, options: .atomic)
            print("Successfully saved RaceGeminiCoachResponse for race \(raceId.uuidString) to cache.")
        } catch {
            print("Error saving RaceGeminiCoachResponse for race \(raceId.uuidString) to cache: \(error.localizedDescription)")
        }
    }

    func loadRaceGeminiCoachResponse(raceId: UUID) -> RaceGeminiCoachResponse? {
        guard let url = raceCoachingFileURL(for: raceId), FileManager.default.fileExists(atPath: url.path) else {
            print("Cache file for race \(raceId.uuidString) does not exist.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(RaceGeminiCoachResponse.self, from: data)
            print("Successfully loaded RaceGeminiCoachResponse for race \(raceId.uuidString) from cache.")
            return response
        } catch {
            print("Error loading RaceGeminiCoachResponse for race \(raceId.uuidString) from cache: \(error.localizedDescription)")
            return nil
        }
    }

    func deleteRaceGeminiCoachResponse(raceId: UUID) {
        guard let url = raceCoachingFileURL(for: raceId), FileManager.default.fileExists(atPath: url.path) else {
            print("Cache file for race \(raceId.uuidString) does not exist.")
            return
        }
        
        do {
            try FileManager.default.removeItem(at: url)
            print("Successfully deleted RaceGeminiCoachResponse for race \(raceId.uuidString) from cache.")
        } catch {
            print("Error deleting RaceGeminiCoachResponse for race \(raceId.uuidString) from cache: \(error.localizedDescription)")
        }
    }

    // MARK: - Process Gemini Coach Cache

    private var processCoachingDirectoryURL: URL? {
        let appGroupId = "group.com.danguita.trailStats"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("[CacheManager] ERROR: No se pudo obtener URL del App Group (\(appGroupId)) para processCoachingDirectoryURL")
            return nil
        }
        let processCoachingDir = groupURL.appendingPathComponent("processCoaching")
        if !FileManager.default.fileExists(atPath: processCoachingDir.path) {
            do {
                try FileManager.default.createDirectory(at: processCoachingDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating processCoaching directory: \(error.localizedDescription)")
                return nil
            }
        }
        return processCoachingDir
    }

    private func processCoachingFileURL(for processId: UUID, withSuffix suffix: String = ".json") -> URL? {
        return processCoachingDirectoryURL?.appendingPathComponent("\(processId.uuidString)\(suffix)")
    }

    func saveProcessGeminiCoachResponse(processId: UUID, response: RaceProjection) {
        guard let url = processCoachingFileURL(for: processId) else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(response)
            try data.write(to: url, options: .atomic)
            print("Successfully saved RaceProjection for process \(processId.uuidString) to cache.")
        } catch {
            print("Error saving RaceProjection for process \(processId.uuidString) to cache: \(error.localizedDescription)")
        }
    }

    func loadProcessGeminiCoachResponse(processId: UUID) -> RaceProjection? {
        guard let url = processCoachingFileURL(for: processId), FileManager.default.fileExists(atPath: url.path) else {
            print("Cache file for process \(processId.uuidString) does not exist.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(RaceProjection.self, from: data)
            print("Successfully loaded RaceProjection for process \(processId.uuidString) from cache.")
            return response
        } catch {
            print("Error loading RaceProjection for process \(processId.uuidString) from cache: \(error.localizedDescription)")
            return nil
        }
    }

    func deleteProcessGeminiCoachResponse(processId: UUID) {
        guard let url = processCoachingFileURL(for: processId), FileManager.default.fileExists(atPath: url.path) else {
            print("Cache file for process \(processId.uuidString) does not exist.")
            return
        }
        
        do {
            try FileManager.default.removeItem(at: url)
            print("Successfully deleted ProcessGeminiCoachResponse for process \(processId.uuidString) from cache.")
        } catch {
            print("Error deleting ProcessGeminiCoachResponse for process \(processId.uuidString) from cache: \(error.localizedDescription)")
        }
    }

    func saveProcessTrainingRecommendation(processId: UUID, recommendation: String) {
        guard let url = processCoachingFileURL(for: processId, withSuffix: "_recommendation.txt") else { return }
        do {
            try recommendation.write(to: url, atomically: true, encoding: .utf8)
            print("Successfully saved training recommendation for process \(processId.uuidString) to cache.")
        } catch {
            print("Error saving training recommendation for process \(processId.uuidString) to cache: \(error.localizedDescription)")
        }
    }

    func loadProcessTrainingRecommendation(processId: UUID) -> String? {
        guard let url = processCoachingFileURL(for: processId, withSuffix: "_recommendation.txt"), FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let recommendation = try String(contentsOf: url, encoding: .utf8)
            print("Successfully loaded training recommendation for process \(processId.uuidString) from cache.")
            return recommendation
        } catch {
            print("Error loading training recommendation for process \(processId.uuidString) from cache: \(error.localizedDescription)")
            return nil
        }
    }

    func deleteProcessTrainingRecommendation(processId: UUID) {
        guard let url = processCoachingFileURL(for: processId, withSuffix: "_recommendation.txt"), FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(at: url)
            print("Successfully deleted training recommendation for process \(processId.uuidString) from cache.")
        } catch {
            print("Error deleting training recommendation for process \(processId.uuidString) from cache: \(error.localizedDescription)")
        }
    }

    // MARK: - Widget Process Cache

    private var processWidgetFileURL: URL? {
        let appGroupId = "group.com.danguita.trailStats"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("[CacheManager] ERROR: No se pudo obtener URL del App Group (\(appGroupId)) para processWidgetFileURL")
            return nil
        }
        return groupURL.appendingPathComponent("active_process_widget.json")
    }

    func saveProcessForWidget(_ data: ProcessWidgetData) {
        guard let url = processWidgetFileURL else { return }
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(data)
            try data.write(to: url, options: .atomic)
            print("[CacheManager] Guardado active_process_widget.json en: \(url.path)")
        } catch {
            print("Error saving active process widget data: \(error.localizedDescription)")
        }
    }

    func deleteProcessWidgetData() {
        guard let url = processWidgetFileURL, FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(at: url)
            print("[CacheManager] Borrado active_process_widget.json.")
        } catch {
            print("Error deleting active process widget data: \(error.localizedDescription)")
        }
    }

    // MARK: - Training Process Cache

    private var trainingProcessesURL: URL? {
        let appGroupId = "group.com.danguita.trailStats"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("[CacheManager] ERROR: No se pudo obtener URL del App Group (\(appGroupId)) para trainingProcessesURL")
            return nil
        }
        return groupURL.appendingPathComponent("training_processes.json")
    }

    func saveTrainingProcesses(_ processes: [TrainingProcess]) {
        guard let url = trainingProcessesURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(processes)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Error saving training processes: \(error)")
        }
    }

    func loadTrainingProcesses() -> [TrainingProcess] {
        guard let url = trainingProcessesURL, FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([TrainingProcess].self, from: data)
        } catch {
            print("Error loading training processes: \(error)")
            return []
        }
    }

    func deleteTrainingProcess(_ process: TrainingProcess) {
        var currentProcesses = loadTrainingProcesses()
        currentProcesses.removeAll { $0.id == process.id }
        saveTrainingProcesses(currentProcesses)
    }
    
    // MARK: - Widget Activity Cache

    private var widgetActivityFileURL: URL? {
        let appGroupId = "group.com.danguita.trailStats" // Usa tu App Group real aquí
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("[CacheManager] ERROR: No se pudo obtener URL del App Group (\(appGroupId))")
            return nil
        }
        let fileURL = groupURL.appendingPathComponent("latest_widget_activity.json")
        print("[CacheManager] Usando App Group para widgetActivityFileURL: \(fileURL.path)")
        return fileURL
    }

    /// Guarda la última actividad para el widget (ActivitySummary)
    func saveActivityForWidget(_ summary: ActivitySummary) {
        print("[CacheManager] Intentando guardar última actividad para widget: \(summary)")
        guard let url = widgetActivityFileURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(summary)
            try data.write(to: url, options: .atomic)
            print("[CacheManager] Guardado latest_widget_activity.json en: \(url.path)")
            if let jsonString = String(data: data, encoding: .utf8) { print("[CacheManager] Contenido guardado: \(jsonString)") }
        } catch {
            print("Error saving latest widget activity: \(error.localizedDescription)")
        }
    }

    /// Carga la última actividad guardada para el widget
    func loadActivityForWidget() -> ActivitySummary? {
        print("[CacheManager] Intentando cargar última actividad del widget...")
        guard let url = widgetActivityFileURL, FileManager.default.fileExists(atPath: url.path) else {
            print("No cached latest widget activity found.")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            print("[CacheManager] Archivo encontrado en: \(url.path)")
            if let jsonString = String(data: data, encoding: .utf8) { print("[CacheManager] Contenido cargado: \(jsonString)") }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ActivitySummary.self, from: data)
        } catch {
            print("[CacheManager] Error cargando y decodificando latest_widget_activity.json: \(error.localizedDescription)")
            return nil
        }
    }
}
