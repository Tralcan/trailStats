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

        let systemPrompt = """
        Eres un experto entrenador de trail. Tu misión es calcular el tiempo estimado de una carrera futura, basándote en los datos de los entrenamientos de un proceso específico.
        Para el cálculo del tiempo, considera que los datos de entrenamiento representan un 55% del esfuerzo y rendimiento real que se puede alcanzar en una competencia. Por lo tanto, tu estimación debe proyectar un tiempo optimista y agresivo, reflejando el máximo potencial de carrera.
        Aplica la siguiente lógica:
        1.  **Ajusta el ritmo base:** Proyecta un ritmo base (GAP) de carrera que sea significativamente más rápido que el de los entrenamientos más largos (que están al 55% del esfuerzo), asumiendo que el día de la carrera correrás a un nivel de intensidad del 100%.
        2.  **Aplica la fatiga:** Considera la fatiga como un factor que afectará el ritmo proyectado, no el ritmo de entrenamiento. Modera la proyección de ritmo en los tramos finales para reflejar un nivel de fatiga realista para una competencia. No bases este cálculo en el desacoplamiento de entrenamientos.
        3.  **Usa los mejores datos:** Prioriza la información de los mejores Ritmos Ajustados (GAP) y Velocidades de Ascenso y Descenso (VAM) para la proyección, ajustándolos para reflejar un rendimiento óptimo.
        La carrera futura tiene una distancia y un desnivel específicos.
        Además de la estimación de tiempo, debes recomendar temas importantes a considerar durante la carrera y una recomendación de nutrición.

        Responde únicamente con un JSON en el siguiente formato, asegurándote de que la estimación de tiempo sea solo un número (ej. "4:30:00"). La explicación en 'razon' no debe exceder los 500 caracteres, el resto puede ser más largo y debe referirse a las carreras por su nombre, no por su ID.
        { "tiempo":"tiempo calculado", "razon":"razon del tiempo calculado", "importante":"temas importantes a considerar durante la carrera, no mencionar la palabra Importante", "nutricion":"recomendación de nutricion durante la carrera" }
        """

        let userPrompt = """
        Datos de los entrenamientos del proceso actual:
        \(activitiesDataString)

        El objetivo del atleta es: \"\(process.goal)\".
        Para su carrera objetivo con Distancia: \(Formatters.formatDistance(raceDistance)) y Desnivel: \(Formatters.formatElevation(raceElevation)), ¿cuál es el tiempo estimado, las consideraciones importantes para el día de la carrera y las recomendaciones de nutrición? La respuesta debe ser muy orientada al atleta y su objetivo, nada genérico.
        """

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
        if let cachedRecommendation = cacheManager.loadTrainingRecommendation(processId: process.id) {
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

        let systemPrompt = """
        Eres un experto entrenador de trail. Tu misión dar consejos (mas bien generales) para preparar \(raceInfo).
        Debes entregar información, por ejemplo, de cantidad de kilómetros que se debe correr y desnivel acumulado, etc. en el proceso para estar bien preparado y cumplir con el objetivo que se fijó: \"\(process.goal)\".
        La respuesta debe ser un texto plano, sin formato JSON, y no debe terminar con una pregunta y un máximo de 300 palabras.
        """

        let kpis = [
            "system_prompt": systemPrompt,
            "user_prompt": "Dame tus recomendaciones."
        ]

        GeminiCoachService.fetchObservation(kpis: kpis) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    // 2. Save the recommendation to cache on success
                    self.cacheManager.saveTrainingRecommendation(processId: process.id, text: text)
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
