
import SwiftUI

/// The primary view for the first tab.
/// It conditionally shows a connection view or the list of activities based on auth state.
struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isAuthenticated {
                    activityList
                } else {
                    authenticationPrompt
                }
            }
            .navigationTitle(viewModel.isAuthenticated ? "Activities" : "Welcome")
        }
    }
    
    private var activityList: some View {
        List {
            ForEach(viewModel.activities) { activity in
                NavigationLink(destination: ActivityDetailView(activity: activity)) {
                    ActivityRowView(activity: activity)
                        .onAppear {
                            if activity.id == viewModel.activities.last?.id {
                                viewModel.fetchActivities()
                            }
                        }
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Logout") {
                    viewModel.logout()
                }
            }
        }
    }
    
    private var authenticationPrompt: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "figure.trail.running")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Welcome to trailStats")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Connect to Strava to automatically sync your trail and mountain runs.")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: viewModel.connectToStrava) {
                HStack {
                    Image(systemName: "link")
                    Text("Connect with Strava")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
