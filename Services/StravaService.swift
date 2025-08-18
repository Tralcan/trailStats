import Foundation
import AuthenticationServices
import Combine
import CoreLocation

class StravaService: NSObject, ASWebAuthenticationPresentationContextProviding {

    private var authSession: ASWebAuthenticationSession?
    private var completionHandler: ((Result<Void, Error>) -> Void)?

    // MARK: - Public Methods

    func authenticate(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completionHandler = completion

        guard let authURL = buildAuthorizationURL() else {
            completion(.failure(StravaAuthError.invalidURL))
            return
        }

        authSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "trailStats") { [weak self] callbackURL, error in
            guard let self = self else { return }

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
        // Check if access token exists in Keychain
        return KeychainHelper.read(service: "strava", account: "accessToken") != nil
    }

    func logout() {
        _ = KeychainHelper.delete(service: "strava", account: "accessToken")
        _ = KeychainHelper.delete(service: "strava", account: "refreshToken")
        // Optionally, revoke token on Strava's side if needed
    }
    
    func getActivities(page: Int, perPage: Int, completion: @escaping (Result<[Activity], Error>) -> Void) {
        guard let url = StravaAPI.getActivities(page: page, perPage: perPage).url else {
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
                decoder.dateDecodingStrategy = .iso8601
                let activities = try decoder.decode([Activity].self, from: data)
                completion(.success(activities))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Private Methods

    private func buildAuthorizationURL() -> URL? {
        var components = URLComponents(string: "https://www.strava.com/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: StravaConfig.clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: StravaConfig.redirectURI),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: "activity:read_all,profile:read_all") // Request necessary scopes
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
            guard let self = self else { return }

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
                   let refreshToken = json["refresh_token"] as? String {

                    _ = KeychainHelper.save(data: accessToken.data(using: .utf8)!, service: "strava", account: "accessToken")
                    _ = KeychainHelper.save(data: refreshToken.data(using: .utf8)!, service: "strava", account: "refreshToken")

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
        return ASPresentationAnchor() // Use default window
    }
}

// MARK: - StravaAuthError

enum StravaAuthError: Error, LocalizedError {
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
        }
    }
}




// MARK: - Activity Codable
