import SwiftUI

/// The primary view for the first tab.
/// It conditionally shows a connection view or the list of activities based on auth state.
struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    @State private var showOptionsMenu = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isAuthenticated {
                    activityList
                } else {
                    authenticationPrompt
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showOptionsMenu = true }) {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                    }
                    .confirmationDialog(Text(NSLocalizedString("Options", comment: "")), isPresented: $showOptionsMenu, titleVisibility: .visible) {
                        Button(NSLocalizedString("Clear cache and reload", comment: ""), role: .none) {
                            viewModel.clearCachesAndReload()
                        }
                        Button(NSLocalizedString("Logout and clear cache", comment: ""), role: .destructive) {
                            viewModel.logout()
                        }
                        Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
                    }
                }
            }
            .sheet(isPresented: $isShowingAdvancedSearch) {
                AdvancedSearchView(viewModel: AdvancedSearchViewModel(onSearch: { name, date, distance, elevation, duration, trainingTag in
                    viewModel.applyAdvancedSearch(name: name, date: date, distance: distance, elevation: elevation, duration: duration, trainingTag: trainingTag)
                }))
            }
        }
    }
    
    @State private var isShowingAdvancedSearch = false
    @State private var isShowingHealthSetup = false
    @State private var showTitle = true

    private var activityList: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if showTitle {
                        VStack(alignment: .leading) {
                            HStack(spacing: 0) {
                                Text(NSLocalizedString("Welcome", comment: "") + " ")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text(viewModel.athleteName ?? "")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.accentColor)
                            }
                            Text(NSLocalizedString("Activities", comment: ""))
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom)
                    }

                    LazyVStack {
                        ForEach(viewModel.filteredActivities) { activity in
                            NavigationLink(destination: ActivityDetailView(activity: activity, onAppearAction: {
                                viewModel.markActivityAsCached(activityId: activity.id)
                            }, onDisappearAction: {
                                viewModel.reloadDataFromCache()
                            })) {
                                ActivityRowView(activity: activity, isCached: viewModel.isActivityCached(activityId: activity.id))
                            }
                            .onAppear {
                                if viewModel.shouldLoadMoreActivities(activity: activity) {
                                    viewModel.fetchActivities()
                                }
                            }
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color.white.opacity(0.5))
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.horizontal, 12)

                    if viewModel.isLoading && viewModel.searchText.isEmpty && viewModel.advancedSearchName.isEmpty && viewModel.advancedSearchDate == nil && viewModel.advancedSearchDistance == nil && viewModel.advancedSearchElevation == nil && viewModel.advancedSearchDuration == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Spacer()
                        .frame(height: 80)
                }
                .padding(.horizontal, 12)
                .background(GeometryReader {
                    Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                })
                .onPreferenceChange(ViewOffsetKey.self) { offset in
                    withAnimation {
                        showTitle = offset < 40
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.8))
                    TextField(NSLocalizedString("Search activities", comment: ""), text: $viewModel.searchText)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .opacity(0.85)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 2)

                Button(action: {
                    isShowingAdvancedSearch = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.thinMaterial)
                                .opacity(0.82)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.refreshActivities()
        }
        .onAppear(perform: viewModel.refreshCacheStatus)
        .navigationTitle(showTitle ? "" : NSLocalizedString("Activities", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private var authenticationPrompt: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text(NSLocalizedString("Welcome to trailStats", comment: ""))
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(NSLocalizedString("Connect to Strava to automatically sync your trail and mountain runs.", comment: ""))
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: { isShowingHealthSetup = true }) {
                    Image("boton3")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                }

                Button(action: viewModel.connectToStrava) {
                    Text(NSLocalizedString("Import_from_Strava", comment: "Connect to STRAVA"))
                        .font(.footnote)
                        .foregroundColor(Color("StravaOrange"))
                }
            }
        }
        .padding()
        .sheet(isPresented: $isShowingHealthSetup) {
            UserInfoView(viewModel: UserInfoViewModel(onComplete: {
                viewModel.completeHealthKitOnboarding()
            }))
        }
    }
}

#Preview {
    HomeView()
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
