import Foundation
import FirebaseAuth

struct StreamCredentials: Decodable {
    let token: String
    let liveKitUrl: String
}

struct ViewerMetrics: Decodable {
    let currentViewers: Int
    let peakToday: Int
    let totalSessions: Int
    let lastUpdated: Date
    let streamStatus: String

    static let placeholder = ViewerMetrics(
        currentViewers: 0,
        peakToday: 0,
        totalSessions: 0,
        lastUpdated: Date(),
        streamStatus: "offline"
    )
}

enum BackendError: Error, LocalizedError {
    case invalidResponse
    case requestFailed(Int)
    case serverError(Int)
    case authenticationRequired

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from backend"
        case .requestFailed(let code):
            return "Backend request failed with status \(code)"
        case .serverError(let code):
            return "Server error with status \(code)"
        case .authenticationRequired:
            return "Authentication required"
        }
    }
}

struct BackendClient {
    static let shared = BackendClient()
    
    private let apiBaseURL: URL = AppConfig.shared.apiBaseURL
    let baseURL: URL = AppConfig.shared.apiBaseURL
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private init() {}

    func fetchViewerCredentials(idToken: String) async throws -> StreamCredentials {
        let url = apiBaseURL.appendingPathComponent("viewer-token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BackendError.requestFailed(httpResponse.statusCode)
        }

        return try decoder.decode(StreamCredentials.self, from: data)
    }

    func fetchMetrics(idToken: String) async throws -> ViewerMetrics {
        let url = apiBaseURL.appendingPathComponent("metrics/viewers")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BackendError.requestFailed(httpResponse.statusCode)
        }

        return try decoder.decode(ViewerMetrics.self, from: data)
    }
    
    func addAuthToken(to request: inout URLRequest) async throws {
        guard let user = Auth.auth().currentUser else {
            throw BackendError.authenticationRequired
        }
        
        let token = try await user.getIDToken()
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}
