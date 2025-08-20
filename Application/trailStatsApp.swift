import SwiftUI

@main
struct trailStatsApp: App {
    // Persistence controller for Core Data
    let persistenceController = PersistenceController.shared
    
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    self.showSplash = false
                                }
                            }
                        }
                } else {
                    MainView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
            }
        }
    }
}