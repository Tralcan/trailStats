
import CoreData

// MARK: - PersistenceController
/// Manages the Core Data stack for the application.
/// This is a standard setup for a SwiftUI application using Core Data.
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "trailStats")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // This is a critical error. In a real app, you would handle this appropriately.
                // For now, we'll just crash.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func delete<T: NSManagedObject>(_ object: T) {
        container.viewContext.delete(object)
        saveContext()
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

/*
 * =====================================================================================
 * 🔴 ACTION REQUIRED: Define the Core Data Model in Xcode
 * =====================================================================================
 *
 * 1. Open the project in Xcode.
 * 2. Find the file `trailStats.xcdatamodeld` in the Project Navigator.
 * 3. Click 'Add Entity' and name it `ActivityEntity`.
 * 4. In the Data Model Inspector on the right, under 'Class', set the 'Codegen' 
 *    to 'Class Definition' and the 'Name' to `ActivityEntity`.
 * 5. Add the following attributes to the `ActivityEntity` entity:
 *
 *    ATTRIBUTE NAME         TYPE
 *    --------------------   ------------------
 *    id                     UUID
 *    name                   String
 *    date                   Date
 *    distance               Double
 *    duration               Double
 *    elevationGain          Double
 *    averageHeartRate       Integer 16
 *    averageCadence         Integer 16
 *    averagePower           Integer 16
 *    polyline               String
 *    timestamp              Date (use this for sorting, e.g., when fetching)
 *
 *    NOTE: We are not storing complex data like chart points directly in Core Data.
 *    We will fetch the basic activity data and, if needed, re-fetch details 
 *    from Strava or HealthKit. This keeps the local database lean.
 * =====================================================================================
 */
