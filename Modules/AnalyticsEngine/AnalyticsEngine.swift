import Foundation

class AnalyticsEngine {
    
    private let cacheManager = CacheManager()

    func calculate(for activities: [Activity]) -> AnalyticsResult {
        // Pre-load all necessary metrics to avoid repeated cache access in loops
        let allMetrics = activities.reduce(into: [Int: ActivityProcessedMetrics]()) { dict, activity in
            if let metrics = cacheManager.loadProcessedMetrics(activityId: activity.id) {
                dict[activity.id] = metrics
            }
        }

        // --- Perform all calculations ---
        let totals = calculateTotals(for: activities)
        let mountainPerformance = calculateMountainPerformance(using: allMetrics.values.map { $0 })
        let runningDynamics = calculateRunningDynamics(for: activities)
        
        let efficiencyData = calculateEfficiencyData(for: activities)
        let weeklyZones = calculateIntensityDistribution(for: activities, metricsCache: allMetrics)
        let weeklyDistance = calculateWeeklyDistance(for: activities)
        let weeklyDecoupling = calculateWeeklyDecoupling(for: activities, metricsCache: allMetrics)
        let performanceByGrade = calculatePerformanceByGrade(using: allMetrics.values.map { $0 })
        
        // --- Assemble the result ---
        return AnalyticsResult(
            totalDistance: totals.distance,
            totalElevation: totals.elevation,
            totalDuration: totals.duration,
            totalActivities: totals.count,
            averageVAM: mountainPerformance.vam,
            averageGAP: mountainPerformance.gap,
            averageDescentVAM: mountainPerformance.descentVam,
            averageNormalizedPower: mountainPerformance.np,
            averageEfficiencyIndex: mountainPerformance.ei,
            averageDecoupling: mountainPerformance.decoupling,
            averageVerticalOscillation: runningDynamics.vo,
            averageGroundContactTime: runningDynamics.gct,
            averageStrideLength: runningDynamics.sl,
            averageVerticalRatio: runningDynamics.vr,
            hasRunningDynamics: runningDynamics.hasDynamics,
            efficiencyData: efficiencyData,
            weeklyZoneDistribution: weeklyZones,
            weeklyDistanceData: weeklyDistance,
            weeklyDecouplingData: weeklyDecoupling,
            performanceByGradeData: performanceByGrade
        )
    }
    
    // MARK: - Private Calculation Methods

    private func calculateTotals(for activities: [Activity]) -> (distance: Double, elevation: Double, duration: TimeInterval, count: Int) {
        let distance = activities.reduce(0) { $0 + $1.distance }
        let elevation = activities.reduce(0) { $0 + $1.elevationGain }
        let duration = activities.reduce(0) { $0 + $1.duration }
        return (distance, elevation, duration, activities.count)
    }

    private func calculateMountainPerformance(using metrics: [ActivityProcessedMetrics]) -> (vam: Double, gap: Double, descentVam: Double, np: Double, ei: Double, decoupling: Double) {
        let vamValues = metrics.compactMap { $0.verticalSpeedVAM }
        let averageVAM = vamValues.isEmpty ? 0 : vamValues.reduce(0, +) / Double(vamValues.count)
        
        let gapValues = metrics.compactMap { $0.gradeAdjustedPace }
        let averageGAP = gapValues.isEmpty ? 0 : gapValues.reduce(0, +) / Double(gapValues.count)
        
        let descentVAMValues = metrics.compactMap { $0.descentVerticalSpeed }
        let averageDescentVAM = descentVAMValues.isEmpty ? 0 : descentVAMValues.reduce(0, +) / Double(descentVAMValues.count)

        let npValues = metrics.compactMap { $0.normalizedPower }
        let averageNormalizedPower = npValues.isEmpty ? 0 : npValues.reduce(0, +) / Double(npValues.count)

        let efficiencyValues = metrics.compactMap { $0.efficiencyIndex }
        let averageEfficiencyIndex = efficiencyValues.isEmpty ? 0 : efficiencyValues.reduce(0, +) / Double(efficiencyValues.count)
        
        let decouplingValues = metrics.compactMap { $0.cardiacDecoupling }
        let averageDecoupling = decouplingValues.isEmpty ? 0 : decouplingValues.reduce(0, +) / Double(decouplingValues.count)
        
        return (averageVAM, averageGAP, averageDescentVAM, averageNormalizedPower, averageEfficiencyIndex, averageDecoupling)
    }

    private func calculateRunningDynamics(for activities: [Activity]) -> (vo: Double, gct: Double, sl: Double, vr: Double, hasDynamics: Bool) {
        let voValues = activities.compactMap { $0.verticalOscillation }
        let gctValues = activities.compactMap { $0.groundContactTime }
        let slValues = activities.compactMap { $0.strideLength }
        let vrValues = activities.compactMap { $0.verticalRatio }
        
        let hasRunningDynamics = !voValues.isEmpty
        
        let averageVO = voValues.isEmpty ? 0 : voValues.reduce(0, +) / Double(voValues.count)
        let averageGCT = gctValues.isEmpty ? 0 : gctValues.reduce(0, +) / Double(gctValues.count)
        let averageSL = slValues.isEmpty ? 0 : slValues.reduce(0, +) / Double(slValues.count)
        let averageVR = vrValues.isEmpty ? 0 : vrValues.reduce(0, +) / Double(vrValues.count)
        
        return (averageVO, averageGCT, averageSL, averageVR, hasRunningDynamics)
    }

    private func calculateEfficiencyData(for activities: [Activity]) -> [ChartDataPoint] {
        let dataPoints = activities.compactMap { activity -> ChartDataPoint? in
            guard let avgHR = activity.averageHeartRate, avgHR > 0, activity.duration > 0 else { return nil }
            let distanceInKm = activity.distance / 1000
            let durationInHours = activity.duration / 3600
            guard durationInHours > 0 else { return nil }
            let speed = distanceInKm / durationInHours
            let efficiencyIndex = speed / avgHR
            guard !efficiencyIndex.isNaN && !efficiencyIndex.isInfinite else { return nil }
            return ChartDataPoint(time: Int(activity.date.timeIntervalSince1970), value: efficiencyIndex)
        }
        return dataPoints.sorted(by: { $0.time < $1.time })
    }

    private func calculateIntensityDistribution(for activities: [Activity], metricsCache: [Int: ActivityProcessedMetrics]) -> [WeeklyZoneData] {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: activities) { calendar.startOfWeek(for: $0.date) }
        
        var weeklyData: [WeeklyZoneData] = []
        for (weekStartDate, activitiesInWeek) in groupedByWeek {
            let weekOfYear = calendar.component(.weekOfYear, from: weekStartDate)
            let weekID = "W\(weekOfYear)"
            var weeklyZone = WeeklyZoneData(id: weekID, weekDate: weekStartDate)
            
            for activity in activitiesInWeek {
                if let metrics = metricsCache[activity.id], let distribution = metrics.heartRateZoneDistribution {
                    weeklyZone.timeInZones[0] += distribution.timeInZone1
                    weeklyZone.timeInZones[1] += distribution.timeInZone2
                    weeklyZone.timeInZones[2] += distribution.timeInZone3
                    weeklyZone.timeInZones[3] += distribution.timeInZone4
                    weeklyZone.timeInZones[4] += distribution.timeInZone5
                }
            }
            weeklyData.append(weeklyZone)
        }
        return weeklyData.sorted(by: { $0.weekDate < $1.weekDate })
    }

    private func calculateWeeklyDistance(for activities: [Activity]) -> [WeeklyDistanceData] {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: activities) { calendar.startOfWeek(for: $0.date) }
        
        var weeklyData: [WeeklyDistanceData] = []
        for (weekStartDate, activitiesInWeek) in groupedByWeek {
            let weekOfYear = calendar.component(.weekOfYear, from: weekStartDate)
            let weekID = "W\(weekOfYear)"
            
            let totalDistance = activitiesInWeek.reduce(0) { $0 + $1.distance }
            weeklyData.append(WeeklyDistanceData(id: weekID, distance: totalDistance, weekDate: weekStartDate))
        }
        return weeklyData.sorted(by: { $0.weekDate < $1.weekDate })
    }

    private func calculateWeeklyDecoupling(for activities: [Activity], metricsCache: [Int: ActivityProcessedMetrics]) -> [WeeklyDecouplingData] {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: activities) { calendar.startOfWeek(for: $0.date) }
        
        var weeklyData: [WeeklyDecouplingData] = []
        for (weekStartDate, activitiesInWeek) in groupedByWeek {
            let weekOfYear = calendar.component(.weekOfYear, from: weekStartDate)
            let weekID = "W\(weekOfYear)"
            
            let decouplingValues = activitiesInWeek.compactMap { metricsCache[$0.id]?.cardiacDecoupling }
            
            if !decouplingValues.isEmpty {
                let averageDecoupling = decouplingValues.reduce(0, +) / Double(decouplingValues.count)
                weeklyData.append(WeeklyDecouplingData(id: weekID, averageDecoupling: averageDecoupling, weekDate: weekStartDate))
            }
        }
        return weeklyData.sorted(by: { $0.weekDate < $1.weekDate })
    }

    private func calculatePerformanceByGrade(using metrics: [ActivityProcessedMetrics]) -> [PerformanceByGrade] {
        var aggregatedData: [String: (totalDistance: Double, totalTime: TimeInterval, totalElevation: Double, weightedCadenceSum: Double, timeWithCadence: TimeInterval)] = [:]

        for metricSet in metrics {
            for gradePerformance in metricSet.performanceByGrade {
                var bucket = aggregatedData[gradePerformance.gradeBucket] ?? (0, 0, 0, 0, 0)
                bucket.totalDistance += gradePerformance.distance
                bucket.totalTime += gradePerformance.time
                bucket.totalElevation += gradePerformance.elevation
                bucket.weightedCadenceSum += gradePerformance.weightedCadenceSum
                bucket.timeWithCadence += gradePerformance.timeWithCadence
                aggregatedData[gradePerformance.gradeBucket] = bucket
            }
        }

        let finalData = aggregatedData.map { bucketName, totals -> PerformanceByGrade in
            return PerformanceByGrade(
                id: UUID(),
                gradeBucket: bucketName,
                distance: totals.totalDistance,
                time: totals.totalTime,
                elevation: totals.totalElevation,
                weightedCadenceSum: totals.weightedCadenceSum,
                timeWithCadence: totals.timeWithCadence
            )
        }
        
        let sortOrder = ["<-15%", "-15% to -10%", "-10% to -5%", "-5% to 0%", "0% to 5%", "5% to 10%", "10% to 15%", ">15%"]
        return finalData.sorted { first, second in
            guard let firstIndex = sortOrder.firstIndex(of: first.gradeBucket), let secondIndex = sortOrder.firstIndex(of: second.gradeBucket) else {
                return false
            }
            return firstIndex < secondIndex
        }
    }
}
