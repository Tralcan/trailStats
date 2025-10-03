import Foundation
import AuthenticationServices
import Combine
import CoreLocation

// MARK: - API Configuration



// MARK: - Strava Error Response
struct StravaErrorResponse: Decodable {
    let message: String
    let errors: [StravaErrorDetail]?
}

struct StravaErrorDetail: Decodable {
    let resource: String?
    let field: String?
    let code: String?
}

enum StravaAPIDefinition {
    case getActivities(page: Int, perPage: Int)
    case getActivityStreams(activityId: Int)
    case refreshToken
    case getAthlete
    
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
        case .getActivityStreams(let activityId):
            components.path = "/api/v3/activities/\(activityId)/streams"
            // Aseguramos que 'latlng' esté incluido explícitamente en los keys
            components.queryItems = [
                URLQueryItem(name: "keys", value: "latlng,time,heartrate,cadence,watts,altitude,distance"),
                URLQueryItem(name: "key_by_type", value: "true")
            ]
        case .refreshToken:
            components.path = "/oauth/token"
        case .getAthlete:
            components.path = "/api/v3/athlete"
        }
        
        return components.url
    }
}

// MARK: - Stream Model

struct Stream: Decodable, Encodable {
    let type: String
    let data: [Double?]
    let latlngData: [[Double]]?

    enum CodingKeys: String, CodingKey {
        case type = "series_type"
        case data
    }

    // Custom decoding to handle both [Double] and [[Double]] for 'latlng'
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = (try? container.decode(String.self, forKey: .type)) ?? ""

        // Try to decode as [[Double]] first (for latlng)
        if let latlngArray = try? container.decode([[Double]].self, forKey: .data) {
            self.latlngData = latlngArray
            self.data = latlngArray.flatMap { $0 }
        } else if let doubleArray = try? container.decode([Double?].self, forKey: .data) {
            self.data = doubleArray
            self.latlngData = nil
        } else {
            self.data = []
            self.latlngData = nil
        }
    }
}

// MARK: - Strava Service

class StravaService: NSObject, ASWebAuthenticationPresentationContextProviding {

    private var authSession: ASWebAuthenticationSession?
    private var completionHandler: ((Result<Void, Error>) -> Void)?
    private let cacheManager = CacheManager() // Instantiate CacheManager

    // MARK: - Public Methods

    func authenticate(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completionHandler = completion

        guard let authURL = buildAuthorizationURL() else {
            completion(.failure(StravaAuthError.invalidURL))
            return
        }

        authSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "trailStats") { [weak self] callbackURL, error in
            guard let self = self else {
                return
            }

            if let error = error {
                if let authError = error as? ASWebAuthenticationSessionError {
                    if authError.code == ASWebAuthenticationSessionError.canceledLogin {
                        completion(.failure(StravaAuthError.userCancelled))
                    } else {
                        completion(.failure(authError))
                    }
                } else {
                    completion(.failure(error))
                }
                return
            }

            guard let callbackURL = callbackURL else {
                completion(.failure(StravaAuthError.noCallbackURL))
                return
            }

            self.handleCallback(callbackURL: callbackURL)
        }

        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = true // Use ephemeral session for privacy

        if authSession?.start() == false {
            completion(.failure(StravaAuthError.failedToStartAuthSession))
        }
    }

    func isAuthenticated() -> Bool {
        return KeychainHelper.read(service: "strava", account: "accessToken") != nil
    }

    func logout() {
        _ = KeychainHelper.delete(service: "strava", account: "accessToken")
        _ = KeychainHelper.delete(service: "strava", account: "refreshToken")
        _ = KeychainHelper.delete(service: "strava", account: "expiresAt")
        cacheManager.clearAllCaches()
    }
    
    func getActivities(page: Int, perPage: Int, completion: @escaping (Result<[Activity], Error>) -> Void) {
        refreshTokenIfNeeded { [weak self] refreshResult in
            guard let self = self else { return }

            switch refreshResult {
            case .success:
                // Token is valid or refreshed, proceed with the original API call
                guard let url = StravaAPIDefinition.getActivities(page: page, perPage: perPage).url else {
                    completion(.failure(StravaAuthError.invalidAPIRequestURL))
                    return
                }

                guard let accessTokenData = KeychainHelper.read(service: "strava", account: "accessToken"), let accessToken = String(data: accessTokenData, encoding: .utf8) else {
                    // This case should ideally not be hit if refreshTokenIfNeeded succeeded, but as a safeguard
                    completion(.failure(StravaAuthError.missingAccessToken))
                    return
                }

                var request = URLRequest(url: url)
                request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    guard let data = data else {
                        completion(.failure(StravaAuthError.noDataInAPIResponse))
                        return
                    }

                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let activities = try decoder.decode([Activity].self, from: data)
                        completion(.success(activities))
                    } catch {
                        print("Decoding error: \(error)")
                        completion(.failure(error))
                    }
                }.resume()

            case .failure(let error):
                // Token refresh failed, propagate the error
                completion(.failure(error))
            }
        }
    }

    func getAthlete(completion: @escaping (Result<StravaAthlete, Error>) -> Void) {
        refreshTokenIfNeeded { [weak self] refreshResult in
            guard let self = self else { return }

            switch refreshResult {
            case .success:
                guard let url = StravaAPIDefinition.getAthlete.url else {
                    completion(.failure(StravaAuthError.invalidAPIRequestURL))
                    return
                }

                guard let accessTokenData = KeychainHelper.read(service: "strava", account: "accessToken"), let accessToken = String(data: accessTokenData, encoding: .utf8) else {
                    completion(.failure(StravaAuthError.missingAccessToken))
                    return
                }

                var request = URLRequest(url: url)
                request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    guard let data = data else {
                        completion(.failure(StravaAuthError.noDataInAPIResponse))
                        return
                    }

                    do {
                        let decoder = JSONDecoder()
                        let athlete = try decoder.decode(StravaAthlete.self, from: data)
                        completion(.success(athlete))
                    } catch {
                        print("Decoding error: \(error)")
                        completion(.failure(error))
                    }
                }.resume()

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getActivityStreams(activityId: Int, completion: @escaping (Result<[String: Stream], Error>) -> Void) {
        // Try to load from cache first
        if let cachedStreams = cacheManager.loadActivityStreams(activityId: activityId) {
            completion(.success(cachedStreams))
            return
        }

        refreshTokenIfNeeded { [weak self] refreshResult in
            guard let self = self else { return }

            switch refreshResult {
            case .success:
                // Token is valid or refreshed, proceed with the original API call
                guard let url = StravaAPIDefinition.getActivityStreams(activityId: activityId).url else {
                    completion(.failure(StravaAuthError.invalidAPIRequestURL))
                    return
                }

                guard let accessTokenData = KeychainHelper.read(service: "strava", account: "accessToken"), let accessToken = String(data: accessTokenData, encoding: .utf8) else {
                    // This case should ideally not be hit if refreshTokenIfNeeded succeeded, but as a safeguard
                    completion(.failure(StravaAuthError.missingAccessToken))
                    return
                }

                var request = URLRequest(url: url)
                request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                    guard let self = self else { return }
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    guard let data = data else {
                        completion(.failure(StravaAuthError.noDataInAPIResponse))
                        return
                    }

                    // Imprimir el JSON recibido de Strava para depuración
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("\n--- RAW STRAVA STREAMS JSON ---\n\(jsonString)\n------------------------------\n")
                    }

                    do {
                        let decoder = JSONDecoder()
                        // Attempt to decode as streams
                        let streams = try decoder.decode([String: Stream].self, from: data)
                        // Imprimir solo el stream latlng si existe
                        if let latlng = streams["latlng"] {
                            print("\n--- DECODED latlng STREAM ---\n\(latlng)\n----------------------------\n")
                        } else {
                            print("\n--- NO latlng STREAM FOUND ---\n")
                        }
                        self.cacheManager.saveActivityStreams(activityId: activityId, streams: streams) // Save to cache
                        completion(.success(streams))
                    } catch let decodingError {
                        // If decoding as streams fails, attempt to decode as an error response
                        if let stravaError = try? JSONDecoder().decode(StravaErrorResponse.self, from: data) {
                            let errorMessage = stravaError.message + (stravaError.errors?.first?.code.map { " (\($0))" } ?? "")
                            completion(.failure(StravaAuthError.apiError(message: errorMessage)))
                        } else {
                            // If it's not a Strava error response, then it's a true decoding error
                            print("Decoding error for streams: \(decodingError)")
                            print("Error details: \(decodingError.localizedDescription)")
                            completion(.failure(decodingError))
                        }
                    }
                }.resume()

            case .failure(let error):
                // Token refresh failed, propagate the error
                completion(.failure(error))
            }
        }
    }

    // MARK: - Private Methods

    private func refreshTokenIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let expiresAtData = KeychainHelper.read(service: "strava", account: "expiresAt"),
              let refreshTokenData = KeychainHelper.read(service: "strava", account: "refreshToken"),
              let storedRefreshToken = String(data: refreshTokenData, encoding: .utf8) else {
            // No hay tokens o fecha de expiración, el usuario no está autenticado o necesita reautenticarse
            completion(.failure(StravaAuthError.missingAccessToken))
            return
        }

        let expiresAt = expiresAtData.withUnsafeBytes { $0.load(as: TimeInterval.self) }
        let currentTime = Date().timeIntervalSince1970
        let refreshBuffer: TimeInterval = 300 // 5 minutos antes de la expiración

        if currentTime + refreshBuffer >= expiresAt {
            // El token está a punto de expirar o ya expiró, necesitamos refrescarlo
            refreshToken(refreshToken: storedRefreshToken) { result in
                completion(result)
            }
        } else {
            // El token sigue siendo válido
            completion(.success(()))
        }
    }

    private func refreshToken(refreshToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = StravaAPIDefinition.refreshToken.url else {
            completion(.failure(StravaAuthError.invalidTokenExchangeURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "client_id": StravaConfig.clientId,
            "client_secret": StravaConfig.clientSecret,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            completion(.failure(StravaAuthError.invalidTokenExchangeURL))
            return
        }
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(StravaAuthError.noDataInTokenExchange))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400 {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let errorDescription = json["error"] as? String,
                   errorDescription == "invalid_grant" {
                    completion(.failure(StravaAuthError.invalidRefreshToken))
                    return
                }
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let newAccessToken = json["access_token"] as? String,
                   let newRefreshToken = json["refresh_token"] as? String,
                   let newExpiresAt = json["expires_at"] as? TimeInterval {

                    let newExpiresAtData = withUnsafeBytes(of: newExpiresAt) { Data($0) }

                    _ = KeychainHelper.save(data: newAccessToken.data(using: .utf8)!, service: "strava", account: "accessToken")
                    _ = KeychainHelper.save(data: newRefreshToken.data(using: .utf8)!, service: "strava", account: "refreshToken")
                    _ = KeychainHelper.save(data: newExpiresAtData, service: "strava", account: "expiresAt")

                    completion(.success(()))
                } else {
                    completion(.failure(StravaAuthError.invalidTokenResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func buildAuthorizationURL() -> URL? {
        var components = URLComponents(string: "https://www.strava.com/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: StravaConfig.clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: StravaConfig.redirectURI),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: "activity:read_all,profile:read_all")
        ]
        return components?.url
    }

    private func handleCallback(callbackURL: URL) {
        guard let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
              let queryItems = urlComponents.queryItems,
              let code = queryItems.first(where: { $0.name == "code" })?.value else {
            self.completionHandler?(.failure(StravaAuthError.missingAuthCode))
            return
        }

        exchangeCodeForToken(code: code)
    }

    private func exchangeCodeForToken(code: String) {
        var components = URLComponents(string: "https://www.strava.com/oauth/token")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: StravaConfig.clientId),
            URLQueryItem(name: "client_secret", value: StravaConfig.clientSecret),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        guard let url = components?.url else {
            self.completionHandler?(.failure(StravaAuthError.invalidTokenExchangeURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                return
            }

            if let error = error {
                self.completionHandler?(.failure(error))
                return
            }

            guard let data = data else {
                self.completionHandler?(.failure(StravaAuthError.noDataInTokenExchange))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let accessToken = json["access_token"] as? String,
                   let refreshToken = json["refresh_token"] as? String,
                   let expiresAt = json["expires_at"] as? TimeInterval {

                    let expiresAtData = withUnsafeBytes(of: expiresAt) { Data($0) }
                    
                    _ = KeychainHelper.save(data: accessToken.data(using: .utf8)!, service: "strava", account: "accessToken")
                    _ = KeychainHelper.save(data: refreshToken.data(using: .utf8)!, service: "strava", account: "refreshToken")
                    _ = KeychainHelper.save(data: expiresAtData, service: "strava", account: "expiresAt")

                    self.completionHandler?(.success(()))
                } else {
                    self.completionHandler?(.failure(StravaAuthError.invalidTokenResponse))
                }
            } catch {
                self.completionHandler?(.failure(error))
            }
        }.resume()
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

// MARK: - StravaAuthError

enum StravaAuthError: Error, LocalizedError, Equatable {
    case invalidURL
    case userCancelled
    case noCallbackURL
    case missingAuthCode
    case invalidTokenExchangeURL
    case noDataInTokenExchange
    case invalidTokenResponse
    case failedToStartAuthSession
    case invalidAPIRequestURL
    case missingAccessToken
    case noDataInAPIResponse
    case apiError(message: String)
    case invalidRefreshToken

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The Strava authorization URL could not be constructed."
        case .userCancelled:
            return "The user cancelled the Strava login process."
        case .noCallbackURL:
            return "No callback URL was received from the authentication session."
        case .missingAuthCode:
            return "The authorization code was missing from the callback URL."
        case .invalidTokenExchangeURL:
            return "The URL for exchanging the authorization code for tokens is invalid."
        case .noDataInTokenExchange:
            return "No data was received when exchanging the authorization code for tokens."
        case .invalidTokenResponse:
            return "The token exchange response was invalid or missing tokens."
        case .failedToStartAuthSession:
            return "Failed to start the web authentication session."
        case .invalidAPIRequestURL:
            return "The Strava API request URL could not be constructed."
        case .missingAccessToken:
            return "The Strava access token is missing from the Keychain."
        case .noDataInAPIResponse:
            return "No data was received from the Strava API."
        case .apiError(let message):
            return "Strava API Error: \(message)"
        case .invalidRefreshToken:
            return "The refresh token is invalid or has expired. Please re-authenticate with Strava."
        }
    }
}
