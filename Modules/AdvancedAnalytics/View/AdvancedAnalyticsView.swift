import SwiftUI
import Charts

struct AdvancedAnalyticsView: View {
    @StateObject private var viewModel = ProgressAnalyticsViewModel()
    @State private var selectedKpiInfo: KPIInfo? = nil
    @State private var showTitle = true

    enum TimePeriod: String, CaseIterable, Identifiable {
        case last7 = "7 Days"
        case last15 = "15 Days"
        case last30 = "30 Days"
        case last60 = "60 Days"
        case last90 = "90 Days"
        
        var id: String { rawValue }
        
        var localizedName: String {
            NSLocalizedString(self.rawValue, comment: "Time period for analytics")
        }
        
        var dayCount: Int {
            switch self {
            case .last7: return 7
            case .last15: return 15
            case .last30: return 30
            case .last60: return 60
            case .last90: return 90
            }
        }
    }
    
    @State private var selectedPeriod: TimePeriod = .last30
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        if showTitle {
                            VStack(alignment: .leading) {
                                HStack(spacing: 0) {
                                    Text(NSLocalizedString("Progress Analysis Part 1", comment: ""))
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                    Text(NSLocalizedString("Progress Analysis Part 2", comment: ""))
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("StravaOrange"))
                                }
                                .padding(.top, 45)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }

                        Picker(NSLocalizedString("Period", comment: "Period picker label"), selection: $selectedPeriod) {
                            ForEach(TimePeriod.allCases) { period in
                                Text(period.localizedName).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: selectedPeriod) { newPeriod in
                            viewModel.timeFrameChanged(newTimeFrame: newPeriod.dayCount)
                        }
                        
                        // KPI Summary Grids
                        kpiSummarySection
                        trailPerformanceSection
                        if viewModel.hasRunningDynamics {
                            runningDynamicsSection
                        }
                        
                        // Charts
                        if !viewModel.weeklyDistanceData.isEmpty {
                            WeeklyDistanceChartView(weeklyData: viewModel.weeklyDistanceData)
                        }

                        if !viewModel.efficiencyData.isEmpty {
                            EfficiencyChartView(data: viewModel.efficiencyData)
                        }
                        
                        if !viewModel.weeklyDecouplingData.isEmpty {
                            WeeklyDecouplingChartView(weeklyData: viewModel.weeklyDecouplingData)
                        }

                        if !viewModel.weeklyZoneDistribution.isEmpty {
                            IntensityChartView(weeklyData: viewModel.weeklyZoneDistribution)
                        }
                        
                        if !viewModel.performanceByGradeData.isEmpty {
                            PerformanceByGradeView(performanceData: viewModel.performanceByGradeData)
                        }
                        
                        TrainingTypeDistributionChartView(dayCount: selectedPeriod.dayCount)
                        
                        // Show empty state only if all charts are empty
                        if viewModel.totalActivities == 0 {
                            emptyStateView
                        }
                    }
                    .padding(.vertical)
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
                .navigationTitle(showTitle ? "" : NSLocalizedString("Progress Analysis", comment: ""))
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    viewModel.recalculateAnalyticsIfNeeded()
                }
            }
            
            if selectedKpiInfo != nil {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { selectedKpiInfo = nil }
                    .zIndex(1)
            }
            
            if let info = selectedKpiInfo {
                KpiInfoPopoverView(info: info)
                    .zIndex(2)
                    .transition(.scale.combined(with: .opacity))
                    .onTapGesture { selectedKpiInfo = nil }
            }
        }
        .animation(.easeInOut, value: selectedKpiInfo)
    }
    
    private var kpiSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Period Totals", comment: "Period Totals section title"))
                .font(.title3).bold()
                .padding(.horizontal)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                KPISummaryCard(title: NSLocalizedString("Activities", comment: "Activities KPI"), value: "\(viewModel.totalActivities)", systemImage: "figure.run", color: .orange)
                KPISummaryCard(title: NSLocalizedString("Total Time", comment: "Total Time KPI"), value: Formatters.formatTime(Int(viewModel.totalDuration)), systemImage: "hourglass", color: .blue)
                KPISummaryCard(title: NSLocalizedString("Total Distance", comment: "Total Distance KPI"), value: Formatters.formatDistance(viewModel.totalDistance), systemImage: "location.fill", color: .red)
                KPISummaryCard(title: NSLocalizedString("Total Elevation", comment: "Total Elevation KPI"), value: Formatters.formatElevation(viewModel.totalElevation), systemImage: "mountain.2.fill", color: .green)
            }
            .padding(.horizontal)
        }
    }
    
    private var trailPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Trail Analytics", comment: "Trail Analytics section title"))
                .font(.title3).bold()
                .padding(.horizontal)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                KPISummaryCard(title: NSLocalizedString("Ascent Speed", comment: "Ascent Speed KPI"), value: Formatters.formatVerticalSpeed(viewModel.averageVAM), systemImage: "arrow.up.right.circle.fill", color: .orange)
                    .onTapGesture { selectedKpiInfo = .vam }
                KPISummaryCard(title: "GAP", value: viewModel.averageGAP.toPaceFormat(), systemImage: "speedometer", color: .cyan)
                    .onTapGesture { selectedKpiInfo = .gap }
                KPISummaryCard(title: NSLocalizedString("Descent Speed", comment: "Descent Speed KPI"), value: Formatters.formatVerticalSpeed(viewModel.averageDescentVAM), systemImage: "arrow.down.right.circle.fill", color: .blue)
                    .onTapGesture { selectedKpiInfo = .descentVam }
                KPISummaryCard(title: NSLocalizedString("Norm. Power", comment: "Normalized Power KPI"), value: "\(String(format: "%.0f", viewModel.averageNormalizedPower)) W", systemImage: "bolt.circle.fill", color: .green)
                    .onTapGesture { selectedKpiInfo = .normalizedPower }
                KPISummaryCard(title: NSLocalizedString("Efficiency Index", comment: "Efficiency Index KPI"), value: String(format: "%.3f", viewModel.averageEfficiencyIndex), systemImage: "leaf.arrow.triangle.circlepath", color: .mint)
                    .onTapGesture { selectedKpiInfo = .efficiencyIndex }
                KPISummaryCard(title: NSLocalizedString("Decoupling", comment: "Decoupling KPI"), value: "\(String(format: "%.1f", viewModel.averageDecoupling))%", systemImage: "heart.slash.circle.fill", color: .pink)
                    .onTapGesture { selectedKpiInfo = .decoupling }
            }
            .padding(.horizontal)
        }
    }
    
    private var runningDynamicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Running Dynamics", comment: "Running Dynamics section title"))
                .font(.title3).bold()
                .padding(.horizontal)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                KPISummaryCard(title: NSLocalizedString("Vertical Oscillation", comment: "Vertical Oscillation KPI"), value: "\(String(format: "%.1f", viewModel.averageVerticalOscillation)) cm", systemImage: "arrow.up.and.down.circle.fill", color: .purple)
                    .onTapGesture { selectedKpiInfo = .verticalOscillation }
                KPISummaryCard(title: NSLocalizedString("Contact Time", comment: "Contact Time KPI"), value: "\(String(format: "%.0f", viewModel.averageGroundContactTime)) ms", systemImage: "timer", color: .indigo)
                    .onTapGesture { selectedKpiInfo = .groundContactTime }
                KPISummaryCard(title: NSLocalizedString("Stride Length", comment: "Stride Length KPI"), value: "\(String(format: "%.2f", viewModel.averageStrideLength)) m", systemImage: "ruler.fill", color: .orange)
                    .onTapGesture { selectedKpiInfo = .strideLength }
                KPISummaryCard(title: NSLocalizedString("Vertical Ratio", comment: "Vertical Ratio KPI"), value: "\(String(format: "%.1f", viewModel.averageVerticalRatio)) %", systemImage: "percent", color: .teal)
                    .onTapGesture { selectedKpiInfo = .verticalRatio }
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer(minLength: 50)
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(NSLocalizedString("Not enough data", comment: "Empty state title"))
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            Text(NSLocalizedString("Log more activities to see your progress over time.", comment: "Empty state message"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer(minLength: 50)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AdvancedAnalyticsView()
}
