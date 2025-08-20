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
            print("Saved AI Coach text for activity \(activityId)")
        } catch {
            print("Error saving AI Coach text: \(error.localizedDescription)")
        }
    }

    // Carga el texto de AI Coach para una actividad
    func loadAICoachText(activityId: Int) -> String? {
        guard let folder = summaryFolderURL(for: activityId) else { return nil }
        let fileURL = folder.appendingPathComponent("ai_coach.txt")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try? String(contentsOf: fileURL, encoding: .utf8)
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
            print("Error loading summary: \(error.localizedDescription)")
            return nil
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

    /// Deletes all local caches, including activities and activity streams.
    func clearAllCaches() {
        clearCache() // Clear activities cache

        guard let streamsURL = streamsDirectoryURL, FileManager.default.fileExists(atPath: streamsURL.path) else {
            print("Activity streams cache directory does not exist.")
            return
        }

        do {
            try FileManager.default.removeItem(at: streamsURL)
            print("Successfully cleared all activity streams cache.")
        } catch {
            print("Error clearing activity streams cache: \(error.localizedDescription)")
        }
    }
}

