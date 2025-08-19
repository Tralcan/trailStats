import Foundation

struct GeminiCoachService {
    static let apiKey = "AIzaSyAivQS0y_J_Z87mktDabiVbPQo9z0T-HGM"
    static let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=\(apiKey)"

    static func fetchObservation(summary: ActivitySummary, completion: @escaping (String?) -> Void) {
        let prompt = "Eres un coach experto en trail running. Analiza la siguiente actividad y entrega una observación útil y concreta en máximo 500 caracteres para el atleta: Distancia: \(String(format: "%.1f", summary.distance/1000)) km, Desnivel: \(Int(summary.elevation)) m, Tiempo: \(formatDuration(summary.duration)), FC Prom: \(summary.averageHeartRate != nil ? String(Int(summary.averageHeartRate!)) : "-") bpm, Potencia Prom: \(summary.averagePower != nil ? String(Int(summary.averagePower!)) : "-") W, Ritmo Prom: \(summary.averagePace != nil ? String(format: "%.2f", summary.averagePace!) : "-") min/km, Cadencia Prom: \(summary.averageCadence != nil ? String(Int(summary.averageCadence!)) : "-") spm, Zancada Prom: \(summary.averageStrideLength != nil ? String(format: "%.2f", summary.averageStrideLength!) : "-") m."
        print("[GeminiCoachService] Prompt enviado a Gemini:\n\(prompt)")
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        guard let url = URL(string: endpoint),
              let body = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                print("[GeminiCoachService] Error o respuesta inesperada de Gemini: \(String(data: data ?? Data(), encoding: .utf8) ?? "Sin datos")")
                completion(nil)
                return
            }
            print("[GeminiCoachService] Respuesta de Gemini:\n\(text)")
            completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        task.resume()
    }

    private static func formatDuration(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%02dh %02dm %02ds", h, m, s)
        } else {
            return String(format: "%02dm %02ds", m, s)
        }
    }
}
