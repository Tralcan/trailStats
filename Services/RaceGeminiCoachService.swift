import Foundation

struct RaceGeminiCoachResponse: Decodable, Encodable {
    let tiempo: String
    let razon: String
    let importante: String
    let nutricion: String
}

class RaceGeminiCoachService {
    private let cacheManager = CacheManager()

    func getRaceEstimationAndRecommendations(for race: Race, completion: @escaping (Result<RaceGeminiCoachResponse, Error>) -> Void) {
        // Try to load from cache first
        if let cachedResponse = cacheManager.loadRaceGeminiCoachResponse(raceId: race.id) {
            print("Loading RaceGeminiCoachResponse from cache for race \(race.id.uuidString)")
            completion(.success(cachedResponse))
            return
        }
        guard let allActivities = cacheManager.loadActivities() else {
            completion(.failure(RaceGeminiCoachServiceError.noActivityData))
            return
        }

        let recentActivities = Array(allActivities.suffix(30))

        var activitiesDataString = ""
        for activity in recentActivities {
            var activityDetails: [String] = []
            activityDetails.append("Actividad ID: \(activity.id)")
            activityDetails.append("Nombre: \(activity.name)")
            activityDetails.append("Tipo: \(activity.sportType)")
            activityDetails.append("Distancia: \(Formatters.formatDistance(activity.distance))")
            activityDetails.append("Duración: \(Formatters.formatTime(Int(activity.duration)))")
            activityDetails.append("Elevación: \(Formatters.formatElevation(activity.elevationGain))")

            if let summary = cacheManager.loadSummary(activityId: activity.id) {
                activityDetails.append("Ritmo Promedio: \(summary.averagePace?.toPaceFormat() ?? "N/A")")
            }

            if let processedMetrics = cacheManager.loadProcessedMetrics(activityId: activity.id) {
                activityDetails.append("GAP: \(processedMetrics.gradeAdjustedPace?.toPaceFormat() ?? "N/A")")
                activityDetails.append("Desacoplamiento Cardíaco: \(Formatters.formatDecoupling(processedMetrics.cardiacDecoupling ?? 0))%")
                activityDetails.append("Velocidad Vertical Ascenso (VAM): \(Formatters.formatVerticalSpeed(processedMetrics.verticalSpeedVAM ?? 0))")
                activityDetails.append("Velocidad Vertical Descenso: \(Formatters.formatVerticalSpeed(processedMetrics.descentVerticalSpeed ?? 0))")
                activityDetails.append("Potencia Normalizada: \(Formatters.formatPower(processedMetrics.normalizedPower ?? 0))")
                activityDetails.append("Índice de Eficiencia: \(Formatters.formatEfficiencyIndex(processedMetrics.efficiencyIndex ?? 0))")

                if let hrZones = processedMetrics.heartRateZoneDistribution {
                    let zonesSummary = "Z1: \(Int(hrZones.timeInZone1).toHoursMinutesSeconds()), Z2: \(Int(hrZones.timeInZone2).toHoursMinutesSeconds()), Z3: \(Int(hrZones.timeInZone3).toHoursMinutesSeconds()), Z4: \(Int(hrZones.timeInZone4).toHoursMinutesSeconds()), Z5: \(Int(hrZones.timeInZone5).toHoursMinutesSeconds())"
                    activityDetails.append("Distribución Zonas FC: \(zonesSummary)")
                }

                if !processedMetrics.performanceByGrade.isEmpty {
                    let performanceSummary = processedMetrics.performanceByGrade.map { performance -> String in
                        "\(performance.gradeBucket): \(performance.averagePace.toPaceFormat())"
                    }.joined(separator: ", ")
                    activityDetails.append("Rendimiento por Pendiente: \(performanceSummary)")
                }
            }
            activitiesDataString += activityDetails.joined(separator: ", ") + "\n"
        }

        let systemPrompt = """
        Eres un experto entrenador de trail. Tu misión es calcular el tiempo estimado de una carrera futura, basándote en los datos de carreras anteriores.
        Para el cálculo del tiempo, considera que los datos de entrenamiento representan un 55% del esfuerzo y rendimiento real que se puede alcanzar en una competencia. Por lo tanto, tu estimación debe proyectar un tiempo optimista y agresivo, reflejando tu máximo potencial de carrera.
        Aplica la siguiente lógica:
        1.  **Ajusta el ritmo base:** Proyecta un ritmo base (GAP) de carrera que sea significativamente más rápido que el de los entrenamientos más largos (que están al 55% del esfuerzo), asumiendo que el día de la carrera correrás a un nivel de intensidad del 100%.
        2.  **Aplica la fatiga:** Considera la fatiga como un factor que afectará el ritmo proyectado, no el ritmo de entrenamiento (que están al 55% del esfuerzo). Modera la proyección de ritmo en los tramos finales para reflejar un nivel de fatiga realista para una competencia. No bases este cálculo en el desacoplamiento de entrenamientos.
        3.  **Usa los mejores datos:** Prioriza la información de tus mejores Ritmos Ajustados (GAP) y Velocidades de Ascenso y Descenso (VAM) para la proyección, ajustándolos para reflejar un rendimiento óptimo.
        La carrera futura tiene una distancia y un desnivel específicos.
        Además de la estimación de tiempo, debes recomendar temas importantes a considerar durante la carrera y una recomendación de nutrición.

        Responde únicamente con un JSON en el siguiente formato, asegurándote de que la estimación de tiempo sea solo un número (ej. "4:30:00"). La explicación en 'razon' no debe exceder los 500 caracteres, el resto puede ser más largo y debe referirse a las carreras por su nombre, no por su ID.
        { \"tiempo\":\"tiempo calculado\", \"razon\":\"razon del tiempo calculado\", \"importante\":\"temas importantes a considerar durante la carrera\", \"nutricion\":\"recomendación de nutricion durante la carrera\" }
        """

        let userPrompt = """
        Datos de carreras anteriores (últimas 30):
        \(activitiesDataString)

        Para una carrera futura con Distancia: \(Formatters.formatDistance(race.distance)) y Desnivel: \(Formatters.formatElevation(race.elevationGain)), ¿cuánto tiempo estimado, consideraciones importantes a considerar en la carrera misma y recomendaciones de nutrición durante la carrera? Nada genérico, que sea muy orientado a la persona que correrá.
        """

        let finalPrompt = "\(systemPrompt)\n\n\(userPrompt)"
        //print("[DEBUG] \(finalPrompt)");
        let requestBody: [String: Any] = [
            "contents": [ ["parts": [ ["text": finalPrompt] ]] ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 2048 // Ajustado para una respuesta más detallada
            ]
        ]

        guard let url = URL(string: GeminiCoachService.endpoint),
              let body = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(RaceGeminiCoachServiceError.apiError("Error creando cuerpo de la solicitud")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("Raw Data (if available): \(String(data: data ?? Data(), encoding: .utf8) ?? "N/A")")
                print("JSON Parsing Error: Could not parse data into [String: Any]")
                completion(.failure(RaceGeminiCoachServiceError.invalidResponse))
                return
            }

            print("Received JSON: \(json)")

            if let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                // Extract JSON from Markdown code block
                let jsonString: String
                if cleanedText.hasPrefix("```json") && cleanedText.hasSuffix("```") {
                    let startIndex = cleanedText.index(cleanedText.startIndex, offsetBy: "```json\n".count)
                    let endIndex = cleanedText.index(cleanedText.endIndex, offsetBy: -"\n```".count)
                    jsonString = String(cleanedText[startIndex..<endIndex])
                } else {
                    jsonString = cleanedText
                }

                guard let jsonData = jsonString.data(using: .utf8) else {
                    print("JSON Data Conversion Error: Could not convert cleaned text to Data.")
                    completion(.failure(RaceGeminiCoachServiceError.invalidResponse))
                    return
                }
                do {
                    let decodedResponse = try JSONDecoder().decode(RaceGeminiCoachResponse.self, from: jsonData)
                    self.cacheManager.saveRaceGeminiCoachResponse(raceId: race.id, response: decodedResponse)
                    completion(.success(decodedResponse))
                } catch {
                    print("JSON Decoding Error: \(error.localizedDescription)")
                    completion(.failure(RaceGeminiCoachServiceError.invalidResponse))
                }
            } else if let errorPayload = json["error"] as? [String: Any] {
                let errorMessage = errorPayload["message"] as? String ?? "Unknown Gemini API error"
                print("Gemini API Error Payload: \(errorPayload)")
                completion(.failure(RaceGeminiCoachServiceError.apiError(errorMessage)))
            } else {
                print("Unexpected JSON structure, no 'candidates' or 'error' found.")
                completion(.failure(RaceGeminiCoachServiceError.invalidResponse))
            }
        }
        task.resume()
    }
}

enum RaceGeminiCoachServiceError: Error {
    case noActivityData
    case invalidResponse
    case apiError(String)
}
