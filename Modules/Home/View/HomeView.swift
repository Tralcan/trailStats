import SwiftUI

/// The primary view for the first tab.
/// It conditionally shows a connection view or the list of activities based on auth state.
struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    @State private var showOptionsMenu = false
    @State private var selectedActivity: Activity? // New: State to control sheet presentation
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
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showOptionsMenu = true }) {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                    }
                    .confirmationDialog("Options", isPresented: $showOptionsMenu, titleVisibility: .visible) {
                        Button("Clear cache and reload", role: .none) {
                            viewModel.clearCachesAndReload()
                        }
                        Button("Logout and clear cache", role: .destructive) {
                            viewModel.logout()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
            .sheet(isPresented: $isShowingAdvancedSearch) {
                AdvancedSearchView(viewModel: AdvancedSearchViewModel(onSearch: { name, date, distance, elevation, duration in
                    viewModel.applyAdvancedSearch(name: name, date: date, distance: distance, elevation: elevation, duration: duration)
                }))
            }
        }
    }
    
    @State private var isShowingAdvancedSearch = false
    
    private var activityList: some View {
        VStack {
            HStack {
                Spacer()
                Button("Advanced Search") {
                    isShowingAdvancedSearch = true
                }
                .padding(.horizontal)
            }
            List {
                ForEach(viewModel.filteredActivities) { activity in
                    ActivityRowView(activity: activity, isCached: viewModel.isActivityCached(activityId: activity.id))
                        .onTapGesture {
                            viewModel.markActivityAsCached(activityId: activity.id)
                            selectedActivity = activity
                        }
                        .onAppear {
                            if viewModel.shouldLoadMoreActivities(activity: activity) {
                                viewModel.fetchActivities()
                            }
                        }
                }
                if viewModel.isLoading && viewModel.searchText.isEmpty && viewModel.advancedSearchName.isEmpty && viewModel.advancedSearchDate == nil && viewModel.advancedSearchDistance == nil && viewModel.advancedSearchElevation == nil && viewModel.advancedSearchDuration == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listStyle(.plain)
            .refreshable {
                viewModel.refreshActivities()
            }
            .onAppear(perform: viewModel.refreshCacheStatus)
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
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
                Image("boton")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
    }
}

#Preview {
    HomeView()
}