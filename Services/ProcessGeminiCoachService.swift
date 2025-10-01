import Foundation

class ProcessGeminiCoachService {
    private let cacheManager = CacheManager()

    func getProcessRaceEstimation(for process: TrainingProcess, with activities: [Activity], completion: @escaping (Result<RaceProjection, Error>) -> Void) {
        if let cachedResponse = cacheManager.loadProcessGeminiCoachResponse(processId: process.id) {
            print("Loading RaceProjection from cache for process \(process.id.uuidString)")
            completion(.success(cachedResponse))
            return
        }

        guard !activities.isEmpty, let raceDistance = process.raceDistance, let raceElevation = process.raceElevation else {
            completion(.failure(ProcessGeminiCoachServiceError.noActivityData))
            return
        }

        var activitiesDataString = ""
        for activity in activities {
            var activityDetails: [String] = []
            activityDetails.append("Actividad ID: \(activity.id)")
            activityDetails.append("Nombre: \(activity.name)")
            activityDetails.append("Tipo: \(activity.sportType)")
            activityDetails.append("Distancia: \(Formatters.formatDistance(activity.distance))")
            activityDetails.append("Duración: \(Formatters.formatTime(Int(activity.duration)))")
            activityDetails.append("Elevación: \(Formatters.formatElevation(activity.elevationGain))")

            if let summary = cacheManager.loadSummary(activityId: activity.id) {
                activityDetails.append("Ritmo Promedio: \(summary.averagePace?.toPaceFormat()) " )
            }

            if let processedMetrics = cacheManager.loadProcessedMetrics(activityId: activity.id) {
                activityDetails.append("GAP: \(processedMetrics.gradeAdjustedPace?.toPaceFormat()) " )
                
                activityDetails.append("Desacoplamiento Cardíaco: \(Formatters.formatDecoupling(processedMetrics.cardiacDecoupling ?? 0))%")
                activityDetails.append("Velocidad Vertical Ascenso (VAM): \(Formatters.formatVerticalSpeed(processedMetrics.verticalSpeedVAM ?? 0))")
                activityDetails.append("Velocidad Vertical Descenso: \(Formatters.formatVerticalSpeed(processedMetrics.descentVerticalSpeed ?? 0))")
                activityDetails.append("Potencia Normalizada: \(Formatters.formatPower(processedMetrics.normalizedPower ?? 0))")
                activityDetails.append("Índice de Eficiencia: \(Formatters.formatEfficiencyIndex(processedMetrics.efficiencyIndex ?? 0))")


                if let hrZones = processedMetrics.heartRateZoneDistribution {
                    let zonesSummary = "Z1: \(Int(hrZones.timeInZone1).toHoursMinutesSeconds()), Z2: \(Int(hrZones.timeInZone2).toHoursMinutesSeconds()), Z3: \(Int(hrZones.timeInZone3).toHoursMinutesSeconds()), Z4: \(Int(hrZones.timeInZone4).toHoursMinutesSeconds()), Z5: \(Int(hrZones.timeInZone5).toHoursMinutesSeconds())"
                    activityDetails.append("Distribución Zonas FC: \(zonesSummary)")
                }
            }
            activitiesDataString += activityDetails.joined(separator: ", ") + "\n"
        }

        let systemPrompt = NSLocalizedString("ProcessRaceEstimationSystemPrompt", tableName: "Prompts", comment: "")
        let userPrompt = String(format: NSLocalizedString("ProcessRaceEstimationUserPrompt", tableName: "Prompts", comment: ""), activitiesDataString, process.goal, Formatters.formatDistance(raceDistance), Formatters.formatElevation(raceElevation))

        let kpis = [
            "system_prompt": systemPrompt,
            "user_prompt": userPrompt
        ]
        
        GeminiCoachService.fetchObservation(kpis: kpis) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    let jsonString: String
                    if cleanedText.hasPrefix("```json") && cleanedText.hasSuffix("```") {
                        let startIndex = cleanedText.index(cleanedText.startIndex, offsetBy: 7)
                        let endIndex = cleanedText.index(cleanedText.endIndex, offsetBy: -3)
                        jsonString = String(cleanedText[startIndex..<endIndex])
                    } else {
                        jsonString = cleanedText
                    }

                    guard let jsonData = jsonString.data(using: .utf8) else {
                        completion(.failure(ProcessGeminiCoachServiceError.invalidResponse))
                        return
                    }
                    do {
                        let decodedResponse = try JSONDecoder().decode(RaceProjection.self, from: jsonData)
                        self.cacheManager.saveProcessGeminiCoachResponse(processId: process.id, response: decodedResponse)
                        completion(.success(decodedResponse))
                    } catch {
                        completion(.failure(ProcessGeminiCoachServiceError.invalidResponse))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func getTrainingRecommendations(for process: TrainingProcess, completion: @escaping (Result<String, Error>) -> Void) {
        // If the process is completed, do not fetch new recommendations and return an empty string.
        // The UI should hide the section based on this.
        if process.isCompleted {
            print("Process \(process.id.uuidString) is completed. Not fetching new training recommendations.")
            completion(.success("")) // Return empty string or a specific message for UI to handle
            return
        }

        // 1. Check for cached recommendation
        if let cachedRecommendation = cacheManager.loadProcessTrainingRecommendation(processId: process.id) {
            print("Loading training recommendation from cache for process \(process.id.uuidString)")
            completion(.success(cachedRecommendation))
            return
        }

        let raceInfo: String
        if let distance = process.raceDistance, let elevation = process.raceElevation {
            raceInfo = "una carrera de \(Formatters.formatDistance(distance)) con \(Formatters.formatElevation(elevation)) de desnivel positivo, que se realizará el \(process.endDate.formatted(date: .long, time: .omitted))"
        } else {
            raceInfo = "una carrera futura con fecha objetivo el \(process.endDate.formatted(date: .long, time: .omitted))"
        }

        let systemPrompt = String(format: NSLocalizedString("TrainingRecommendationsSystemPrompt", tableName: "Prompts", comment: ""), raceInfo, process.goal)
        let userPrompt = NSLocalizedString("TrainingRecommendationsUserPrompt", tableName: "Prompts", comment: "")

        let kpis = [
            "system_prompt": systemPrompt,
            "user_prompt": userPrompt
        ]

        GeminiCoachService.fetchObservation(kpis: kpis) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    // 2. Save the recommendation to cache on success
                    self.cacheManager.saveProcessTrainingRecommendation(processId: process.id, recommendation: text)
                    completion(.success(text))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}

enum ProcessGeminiCoachServiceError: Error {
    case noActivityData
    case invalidResponse
}

struct ProcessGeminiCoachResponse: Codable {
    let tiempo: String
    let razon: String
    let importante: String
    let nutricion: String
}