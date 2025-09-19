import SwiftUI
import FirebaseAuth
import Foundation

// MARK: - Data Models

struct CommentaryConfig: Codable {
    let dogName: String
    let locationName: String
    let tone: String
    let comedicLevel: String
    let systemStatus: SystemStatus
    
    struct SystemStatus: Codable {
        let commentaryEnabled: Bool
        let lastSuccessfulRecap: String?
    }
}

struct CommentaryDisplayEntry: Identifiable, Hashable {
    let id: String
    let mode: String
    let title: String
    let body: String
    let createdAt: Date
    let isRecap: Bool
    let requesterId: String?
    let dogName: String
    
    var displayTitle: String {
        if let requesterId = requesterId, !requesterId.isEmpty, requesterId != "anonymous" {
            // For user-requested commentary, format as "[User Name] asks 'What's [Dog Name] been up to?'"
            return "User asks \"What's \(dogName) been up to?\""
        }
        return isRecap ? "Recap: \(title)" : title
    }
    
    var displayBody: String {
        if let requesterId = requesterId, !requesterId.isEmpty, requesterId != "anonymous" {
            // For user-requested commentary, prefix with the question and then the AI response
            return body
        }
        return body
    }
    
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - ViewModel

@MainActor
class CommentaryFeedViewModel: ObservableObject {
    @Published var entries: [CommentaryDisplayEntry] = []
    @Published var config: CommentaryConfig?
    @Published var isLoading = false
    @Published var isLoadingRequest = false
    @Published var errorMessage: String?
    
    private let backendClient = BackendClient.shared
    
    var isCommentaryEnabled: Bool {
        config?.systemStatus.commentaryEnabled ?? false
    }
    
    func loadInitialData() async {
        isLoading = true
        
        // Load config first
        await loadConfig()
        
        // For now, load from API only (we'll add Firestore listener later)
        await loadFromAPI()
        
        isLoading = false
    }
    
    func refreshFeed() async {
        await loadFromAPI()
    }
    
    func requestCommentary() async {
        guard !isLoadingRequest else { return }
        
        isLoadingRequest = true
        
        do {
            let response = try await backendClient.requestCommentary()
            // Add new entry to the top of the list
            let newEntry = CommentaryDisplayEntry(
                id: response.id,
                mode: response.mode,
                title: response.summary.title,
                body: response.summary.body,
                createdAt: response.createdAt,
                isRecap: response.mode == "hourly",
                requesterId: response.meta?.requesterId,
                dogName: config?.dogName ?? "Izzo"
            )
            entries.insert(newEntry, at: 0)
        } catch {
            errorMessage = "Failed to generate commentary: \(error.localizedDescription)"
        }
        
        isLoadingRequest = false
    }
    
    private func loadConfig() async {
        do {
            config = try await backendClient.getCommentaryConfig()
        } catch {
            print("Failed to load config: \(error)")
            // Use default config
            config = CommentaryConfig(
                dogName: "Izzo",
                locationName: "home", 
                tone: "playful",
                comedicLevel: "light",
                systemStatus: CommentaryConfig.SystemStatus(
                    commentaryEnabled: false,
                    lastSuccessfulRecap: nil
                )
            )
        }
    }
    
    private func loadFromAPI() async {
        do {
            let apiEntries = try await backendClient.getLatestCommentary()
            entries = apiEntries.map { entry in
                CommentaryDisplayEntry(
                    id: entry.id,
                    mode: entry.mode,
                    title: entry.summary.title,
                    body: entry.summary.body,
                    createdAt: entry.createdAt,
                    isRecap: entry.mode == "hourly",
                    requesterId: entry.meta?.requesterId,
                    dogName: config?.dogName ?? "Izzo"
                )
            }
        } catch {
            print("Failed to load from API: \(error)")
            errorMessage = "Failed to load commentary feed"
        }
    }
}

// MARK: - Backend Client Extensions

extension BackendClient {
    func getCommentaryConfig() async throws -> CommentaryConfig {
        let url = baseURL.appendingPathComponent("/api/commentary/config")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw BackendError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(CommentaryConfig.self, from: data)
    }
    
    func getLatestCommentary() async throws -> [CommentaryAPIEntry] {
        let url = baseURL.appendingPathComponent("/api/commentary/latest")
        
        var request = URLRequest(url: url)
        try await addAuthToken(to: &request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw BackendError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([CommentaryAPIEntry].self, from: data)
    }
    
    func requestCommentary() async throws -> CommentaryAPIEntry {
        let url = baseURL.appendingPathComponent("/api/commentary/request")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try await addAuthToken(to: &request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            throw BackendError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(CommentaryAPIEntry.self, from: data)
    }
}

// MARK: - API Models

struct CommentaryAPIEntry: Codable {
    let id: String
    let mode: String
    let summary: CommentarySummary
    let createdAt: Date
    let timeframeStart: Date
    let timeframeEnd: Date
    let meta: CommentaryMeta?
    
    struct CommentaryMeta: Codable {
        let requesterId: String?
        let reason: String?
    }
    
    struct CommentarySummary: Codable {
        let title: String
        let body: String
        let bulletPoints: [String]
        let confidence: String?
        let tags: [String]?
    }
}

// MARK: - Date Decoding

extension CommentaryAPIEntry {
    private enum CodingKeys: String, CodingKey {
        case id, mode, summary, createdAt, timeframeStart, timeframeEnd, meta
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        mode = try container.decode(String.self, forKey: .mode)
        summary = try container.decode(CommentarySummary.self, forKey: .summary)
        meta = try container.decodeIfPresent(CommentaryMeta.self, forKey: .meta)
        
        let formatter = ISO8601DateFormatter()
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = formatter.date(from: createdAtString) ?? Date()
        
        let timeframeStartString = try container.decode(String.self, forKey: .timeframeStart)
        timeframeStart = formatter.date(from: timeframeStartString) ?? Date()
        
        let timeframeEndString = try container.decode(String.self, forKey: .timeframeEnd)
        timeframeEnd = formatter.date(from: timeframeEndString) ?? Date()
    }
}