import Foundation

struct GeminiCoachService {
    // WARNING: Do not hardcode API keys in production code.
    static let apiKey = "AIzaSyAivQS0y_J_Z87mktDabiVbPQo9z0T-HGM"
    static let endpoint = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=\(apiKey)"

    static func fetchObservation(
        activityId: String,
        kpis: [String: String],
        cacheManager: CacheManager,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // 1. Get device language
        let languageCode = Locale.current.languageCode ?? "en"
        let languageName = Locale(identifier: languageCode).localizedString(forLanguageCode: languageCode) ?? "English"

        // 2. Get localized system prompt
        let promptTemplate = NSLocalizedString("SystemPrompt", tableName: "Prompts", comment: "System prompt for Gemini")
        var systemPrompt = String(format: promptTemplate, languageName)

        // 3. Load and format coaching history
        let history = cacheManager.loadCoachingHistory()
        if history.isEmpty {
            print("[GeminiCoachService] Coaching History is empty. No previous recommendations to consider.")
        } else {
            print("[GeminiCoachService] Loaded Coaching History: \(history)") // Log history content
        }
        let historyPrompt = formatHistoryForPrompt(history)
        
        // 4. Format the KPIs into a string
        let kpiString = kpis.map { "\($0.key): \($0.value)" }.joined(separator: "\n")

        // 5. Combine system prompt, history, and data
        let activityDataLabel = NSLocalizedString("ActivityData", tableName: "Prompts", comment: "Label for activity data")
        let localizedPositiveFeedbackHeader = NSLocalizedString("PositiveFeedbackHeader", tableName: "Prompts", comment: "Header for positive feedback section in Gemini's response")
        let localizedRecommendationsHeader = NSLocalizedString("RecommendationsToImproveHeader", tableName: "Prompts", comment: "Header for recommendations section in Gemini's response")
        let recoveryInstruction = kpis["max_rpe"] != nil ? "\n\nGiven the considerable effort (RPE \(kpis["max_rpe"]!) or higher), please add one or two paragraphs at the end of your analysis focusing on recovery strategies." : ""

        print("[GeminiCoachService] KPIs sent to Gemini: \(kpis)") // Log kpis

        let finalPrompt = """
        \(systemPrompt)

        Here is the coaching history for context. Do not repeat this information in your response:
        \(historyPrompt)

        Analyze the current activity in the context of the provided coaching history. Evaluate progress or changes in performance over time. Explicitly refer to past recommendations where relevant, and explain how they relate to the current performance and your new advice.
        Your response should include two sections: "\(localizedPositiveFeedbackHeader)" and "\(localizedRecommendationsHeader)", each followed by a bulleted list of points.
        \(NSLocalizedString("ConcisenessInstruction", tableName: "Prompts", comment: "Instruction for Gemini to keep its response concise"))

        \(activityDataLabel)
        \(kpiString)
        """
        
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

                // Parse and save the history
                let parsedInsights = parseInsights(from: observation)
                let activityIDForHistory = activityId
                let newHistoryEntry = CoachingHistory(
                    activityId: activityIDForHistory,
                    date: Date(),
                    recommendationsToImprove: parsedInsights.recommendations,
                    positives: parsedInsights.positives
                )
                cacheManager.saveCoachingHistory(newHistoryEntry)
                
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

    private static func formatHistoryForPrompt(_ history: [CoachingHistory]) -> String {
        guard !history.isEmpty else { return "" }

        let historyHeader = NSLocalizedString("CoachingHistoryPromptSection", tableName: "Prompts", comment: "Header for coaching history")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let entries = history.map { entry in
            let date = dateFormatter.string(from: entry.date)
            let recommendations = entry.recommendationsToImprove.joined(separator: ", ")
            return "- On \(date): Key recommendations were: \(recommendations)"
        }.joined(separator: "\n")

        return "\(historyHeader)\n\(entries)"
    }

    private static func parseInsights(from text: String) -> (positives: [String], recommendations: [String]) {
        let localizedPositiveFeedbackHeader = NSLocalizedString("PositiveFeedbackHeader", tableName: "Prompts", comment: "Header for positive feedback section in Gemini's response")
        let localizedRecommendationsHeader = NSLocalizedString("RecommendationsToImproveHeader", tableName: "Prompts", comment: "Header for recommendations section in Gemini's response")

        let positives = extractListItems(from: text, between: localizedPositiveFeedbackHeader, and: localizedRecommendationsHeader)
        let recommendations = extractListItems(from: text, between: localizedRecommendationsHeader, and: nil)

        return (positives, recommendations)
    }

    private static func extractListItems(from text: String, between startHeader: String, and endHeader: String?) -> [String] {
        guard let startRange = text.range(of: startHeader) else { return [] }

        let searchRange: Range<String.Index>
        if let endHeader = endHeader, let endRange = text.range(of: endHeader, range: startRange.upperBound..<text.endIndex) {
            searchRange = startRange.upperBound..<endRange.lowerBound
        } else {
            searchRange = startRange.upperBound..<text.endIndex
        }

        let content = text[searchRange]
        
        // Find all lines starting with "-" or "*"
        let lines = content.components(separatedBy: .newlines)
        let listItems = lines.map { $0.trimmingCharacters(in: .whitespaces) }
                             .filter { $0.starts(with: "-") || $0.starts(with: "*") }
                             .map { $0.dropFirst().trimmingCharacters(in: .whitespaces) }
                             .map { String($0) }
        
        return listItems
    }
}

