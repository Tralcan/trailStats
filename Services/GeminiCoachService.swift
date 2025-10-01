import Foundation

struct GeminiCoachService {
    // WARNING: Do not hardcode API keys in production code.
    // This should be stored securely, e.g., in a configuration file excluded from git.
    static let apiKey = "AIzaSyAivQS0y_J_Z87mktDabiVbPQo9z0T-HGM"
    static let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"

    static func fetchObservation(kpis: [String: String], completion: @escaping (Result<String, Error>) -> Void) {
        // 1. Get device language
        let languageCode = Locale.current.languageCode ?? "en"
        let languageName = Locale(identifier: languageCode).localizedString(forLanguageCode: languageCode) ?? "English"

        // 2. Get localized system prompt
        let promptTemplate = NSLocalizedString("SystemPrompt", tableName: "Prompts", comment: "System prompt for Gemini")
        let systemPrompt = String(format: promptTemplate, languageName)

        // 3. Format the KPIs into a string
        let kpiString = kpis.map { "\($0.key): \($0.value)" }.joined(separator: "\n")

        // 4. Combine system prompt and data
        let activityDataLabel = NSLocalizedString("ActivityData", tableName: "Prompts", comment: "Label for activity data")
        let finalPrompt = "\(systemPrompt)\n\n\(activityDataLabel)\n\(kpiString)"
        
        print("[GeminiCoachService] Prompt enviado a Gemini:\n\(finalPrompt)")

        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": finalPrompt]]]
            ],
            "generationConfig": [
                "maxOutputTokens": 8192
            ]
        ]

        guard let url = URL(string: endpoint),
              let body = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(NSError(domain: "GeminiCoachService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error creating request body"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(NSError(domain: "GeminiCoachService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Gemini"])))
                return
            }

            if let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                let observation = text.trimmingCharacters(in: .whitespacesAndNewlines)
                print("[GeminiCoachService] Respuesta de Gemini:\n\(observation)")
                completion(.success(observation))
            } else if let errorPayload = json["error"] as? [String: Any] {
                let errorMessage = errorPayload["message"] as? String ?? "Unknown Gemini API error"
                 print("[GeminiCoachService] Error from Gemini API: \(errorMessage)")
                completion(.failure(NSError(domain: "GeminiCoachService.API", code: 3, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "No data"
                print("[GeminiCoachService] Unexpected response structure from Gemini: \(responseString)")
                completion(.failure(NSError(domain: "GeminiCoachService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unexpected response structure from Gemini."])))
            }
        }
        task.resume()
    }
}
