
import Foundation

// MARK: - StravaAPI Endpoints
/// Defines the endpoints for the Strava API.
/// This enum provides a structured way to build URLs for API requests.
enum StravaAPI {
    case getActivities(page: Int, perPage: Int)
    
    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.strava.com"
        
        switch self {
        case .getActivities(let page, let perPage):
            components.path = "/api/v3/athlete/activities"
            components.queryItems = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "\(perPage)")
            ]
        }
        
        return components.url
    }
}
