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
    
    /// Deletes the local activities cache file.
    func clearCache() {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            try FileManager.default.removeItem(at: url)
            print("Successfully cleared the activity cache.")
        } catch {
            print("Error clearing activity cache: \(error.localizedDescription)")
        }
    }
}
