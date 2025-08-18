
import SwiftUI

/// The main container view of the application, featuring a TabView.
struct MainView: View {
    var body: some View {
        TabView {
            // Tab 1: Home / Activities
            HomeView()
                .tabItem {
                    Label("Activities", systemImage: "figure.run")
                }
            
            // Tab 2: Advanced Analytics
            AdvancedAnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }
            
            // Tab 3: Race Preparation
            RacePrepView()
                .tabItem {
                    Label("Races", systemImage: "flag.checkered.2.crossed")
                }
        }
        .accentColor(Color(red: 0.98, green: 0.30, blue: 0.01)) // Strava Orange
    }
}

#Preview {
    MainView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
