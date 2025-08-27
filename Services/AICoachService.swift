import Foundation

class AICoachService {
    func fetchObservation(kpis: [String: String], completion: @escaping (Result<String, Error>) -> Void) {
        // TODO: Implement actual Gemini API call for AI Coach observation
        // For now, simulate a response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let simulatedObservation = "Based on your activity, you showed strong performance in uphill segments. Focus on maintaining a consistent pace on flats."
            completion(.success(simulatedObservation))
        }
    }
}

enum AICoachServiceError: Error {
    case apiError(String)
    case invalidResponse
}