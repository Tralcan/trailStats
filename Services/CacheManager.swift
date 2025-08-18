import Foundation

/// Manages caching of activities to the device's local storage.
class CacheManager {
    
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

