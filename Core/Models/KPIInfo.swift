import Foundation

enum KPITrend {
    case up, down, equal
}

/// Data model for a Key Performance Indicator (KPI).
struct KPIInfo: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let value: Double?
    let trend: KPITrend?
    let higherIsBetter: Bool

    init(title: String, description: String, value: Double? = nil, trend: KPITrend? = nil, higherIsBetter: Bool) {
        self.title = title
        self.description = description
        self.value = value
        self.trend = trend
        self.higherIsBetter = higherIsBetter
    }

    static func == (lhs: KPIInfo, rhs: KPIInfo) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Analytics KPIs
    static let aerobicEfficiency = KPIInfo(
        title: NSLocalizedString("kpi.aerobicEfficiency.title", comment: "Aerobic Efficiency KPI title"),
        description: NSLocalizedString("kpi.aerobicEfficiency.description", comment: "Aerobic Efficiency KPI description"),
        higherIsBetter: true
    )

    static let trainingLoadCTL = KPIInfo(
        title: NSLocalizedString("kpi.trainingLoadCTL.title", comment: "CTL KPI title"),
        description: NSLocalizedString("kpi.trainingLoadCTL.description", comment: "CTL KPI description"),
        higherIsBetter: true
    )

    static let fatigueATL = KPIInfo(
        title: NSLocalizedString("kpi.fatigueATL.title", comment: "ATL KPI title"),
        description: NSLocalizedString("kpi.fatigueATL.description", comment: "ATL KPI description"),
        higherIsBetter: false // Higher fatigue is generally not "better"
    )

    // MARK: - Trail Performance KPIs
    static let vam = KPIInfo(
        title: NSLocalizedString("kpi.vam.title", comment: "VAM KPI title"),
        description: NSLocalizedString("kpi.vam.description", comment: "VAM KPI description"),
        higherIsBetter: true
    )

    static let gap = KPIInfo(
        title: NSLocalizedString("kpi.gap.title", comment: "GAP KPI title"),
        description: NSLocalizedString("kpi.gap.description", comment: "GAP KPI description"),
        higherIsBetter: false // Lower pace (time) is better
    )

    static let descentVam = KPIInfo(
        title: NSLocalizedString("kpi.descentVam.title", comment: "Descent VAM KPI title"),
        description: NSLocalizedString("kpi.descentVam.description", comment: "Descent VAM KPI description"),
        higherIsBetter: true
    )

    static let normalizedPower = KPIInfo(
        title: NSLocalizedString("kpi.normalizedPower.title", comment: "NP KPI title"),
        description: NSLocalizedString("kpi.normalizedPower.description", comment: "NP KPI description"),
        higherIsBetter: true
    )

    static let efficiencyIndex = KPIInfo(
        title: NSLocalizedString("kpi.efficiencyIndex.title", comment: "EI KPI title"),
        description: NSLocalizedString("kpi.efficiencyIndex.description", comment: "EI KPI description"),
        higherIsBetter: true
    )

    static let decoupling = KPIInfo(
        title: NSLocalizedString("kpi.decoupling.title", comment: "Decoupling KPI title"),
        description: NSLocalizedString("kpi.decoupling.description", comment: "Decoupling KPI description"),
        higherIsBetter: false // Lower decoupling is better
    )

    // MARK: - Running Dynamics KPIs
    static let verticalOscillation = KPIInfo(
        title: NSLocalizedString("kpi.verticalOscillation.title", comment: "VO KPI title"),
        description: NSLocalizedString("kpi.verticalOscillation.description", comment: "VO KPI description"),
        higherIsBetter: false // Lower oscillation is better
    )

    static let groundContactTime = KPIInfo(
        title: NSLocalizedString("kpi.groundContactTime.title", comment: "GCT KPI title"),
        description: NSLocalizedString("kpi.groundContactTime.description", comment: "GCT KPI description"),
        higherIsBetter: false // Lower GCT is better
    )

    static let strideLength = KPIInfo(
        title: NSLocalizedString("kpi.strideLength.title", comment: "Stride Length KPI title"),
        description: NSLocalizedString("kpi.strideLength.description", comment: "Stride Length KPI description"),
        higherIsBetter: true // Generally, for a given pace, longer stride is more efficient, but it's complex.
    )

    static let verticalRatio = KPIInfo(
        title: NSLocalizedString("kpi.verticalRatio.title", comment: "Vertical Ratio KPI title"),
        description: NSLocalizedString("kpi.verticalRatio.description", comment: "Vertical Ratio KPI description"),
        higherIsBetter: false // Lower ratio is better
    )
}