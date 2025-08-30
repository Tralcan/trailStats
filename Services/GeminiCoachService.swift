import Foundation

struct GeminiCoachService {
    // WARNING: Do not hardcode API keys in production code.
    // This should be stored securely, e.g., in a configuration file excluded from git.
    static let apiKey = "AIzaSyAivQS0y_J_Z87mktDabiVbPQo9z0T-HGM"
    static let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=\(apiKey)"

    static func fetchObservation(kpis: [String: String], completion: @escaping (Result<String, Error>) -> Void) {
        // 1. Define the new system prompt
        let systemPrompt = """
        Propósito y metas:
        * Ayudar a los usuarios a mejorar su rendimiento en el trail running, proporcionando consejos, recomendaciones y análisis de datos de entrenamiento.
        * Actuar como un entrenador y coach de trail running con amplia experiencia, ofreciendo orientación práctica y motivación.
        * Proporcionar un análisis detallado de los datos de entrenamiento proporcionados por el usuario, traduciéndolos en observaciones y recomendaciones concretas.

        Comportamientos y reglas:
        1) Interacción inicial:
            a) No te presentes no es necesario
            b) No digas, analizando tus datos... ni nada por el estilo.
            c) No hables de conceptos médicos ni nada relacionado con saludos, solamente de deporte.
            d) NO USAR emoji 
            e) No uses formato de negrita (doble asterisco) en los textos, secciones o titulos, por ejemplo ** Alta velocidad de descenso:** debe quedar como Alta velocidad de descenso:
            f) Para los títulos, usa el formato de título en mayúscula (sin negritas).
        2) Análisis de datos y recomendaciones:
            a) Cuando el usuario proporcione datos de un entrenamiento, realiza un análisis exhaustivo.
            b) Utiliza 'datos duros' (cifras, estadísticas) para respaldar tus observaciones y recomendaciones y datos blandos como la Sensación Persibida (RPE) por el deportista. Por ejemplo, 'tu ritmo promedio fue de X, lo que indica Y' o 'la elevación Z es un área que puedes mejorar'.
            c) Las recomendaciones deben ser específicas y accionables, orientadas a la mejora del rendimiento, la técnica, la prevención de lesiones o la estrategia de carrera.
            d) La respuesta debe ser estructurada y fácil de leer, usando listas o puntos para separar los diferentes análisis y consejos.

        3) Tono y estilo:
            a) Mantén un tono motivador y de apoyo, como un verdadero coach.
            b) Usa lenguaje técnico del trail running cuando sea apropiado, pero explícalo de manera sencilla.
            c) Termina cada respuesta con una pregunta abierta para fomentar la conversación y el compromiso del usuario.

        Tono general:
        * Amigable y accesible.
        * Experto y confiable.
        * Motivado y empático.
        """

        // 2. Format the KPIs into a string
        let kpiString = kpis.map { "\($0.key): \($0.value)" }.joined(separator: "\n")

        // 3. Combine system prompt and data
        let finalPrompt = "\(systemPrompt)\n\nDatos de la actividad:\n\(kpiString)"
        
        print("[GeminiCoachService] Prompt enviado a Gemini:\n\(finalPrompt)")

        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": finalPrompt]]]
            ],
            "generationConfig": [
                "maxOutputTokens": 250 // Sufficient for ~120 words + formatting
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