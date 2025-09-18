import Foundation

struct AppConfig {
    let apiBaseURL: URL
    let liveKitURL: URL

    static let shared: AppConfig = {
        guard let url = Bundle.main.url(forResource: "AppConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            fatalError("Missing AppConfig.plist in application bundle")
        }

        guard let api = dict["API_BASE_URL"] as? String, let apiURL = URL(string: api) else {
            fatalError("API_BASE_URL missing or invalid in AppConfig.plist")
        }

        guard let liveKit = dict["LIVEKIT_URL"] as? String, let liveKitURL = URL(string: liveKit) else {
            fatalError("LIVEKIT_URL missing or invalid in AppConfig.plist")
        }

        return AppConfig(apiBaseURL: apiURL, liveKitURL: liveKitURL)
    }()

    private init(apiBaseURL: URL, liveKitURL: URL) {
        self.apiBaseURL = apiBaseURL
        self.liveKitURL = liveKitURL
    }
}
