import SwiftUI

@main
struct trailStatsApp: App {
    // Persistence controller for Core Data
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}