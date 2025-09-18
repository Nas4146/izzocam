import Foundation
import SwiftUI
import FirebaseAuth
import LiveKit

@MainActor
final class AppSession: ObservableObject {
    @Published var user: User?
    @Published var viewerMetrics: ViewerMetrics = .placeholder
    @Published var streamState: StreamState = .offline
    @Published var isLoadingStream = false
    @Published var errorMessage: String?

    private let backend = BackendClient()
    let liveKitController = LiveKitController()

    private var metricsTask: Task<Void, Never>?
    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        user = Auth.auth().currentUser
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                await self.handleAuthChange(user: user)
            }
        }

        Task { @MainActor in
            await handleAuthChange(user: Auth.auth().currentUser)
        }
    }

    deinit {
        metricsTask?.cancel()
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            metricsTask?.cancel()
            metricsTask = nil
            streamState = .offline
            liveKitController.disconnect()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }

    private func handleAuthChange(user: User?) async {
        self.user = user
        metricsTask?.cancel()
        metricsTask = nil
        liveKitController.disconnect()

        guard user != nil else {
            streamState = .offline
            return
        }

        await establishStream()
    }

    func refreshStream() async {
        await establishStream(forceRefreshToken: true)
    }

    private func establishStream(forceRefreshToken: Bool = false) async {
        guard let user else { return }
        isLoadingStream = true
        streamState = .connecting

        do {
            let idToken = try await user.idToken(forceRefresh: forceRefreshToken)
            let credentials = try await backend.fetchViewerCredentials(idToken: idToken)
            
            print("[AppSession] Received credentials from backend:")
            print("[AppSession] LiveKit URL: \(credentials.liveKitUrl)")
            print("[AppSession] Token (first 50 chars): \(String(credentials.token.prefix(50)))...")
            
            try await liveKitController.connect(url: credentials.liveKitUrl, token: credentials.token)
            streamState = .live
            metricsTask = Task { [weak self] in
                await self?.pollMetrics()
            }
        } catch {
            print("[AppSession] Failed to establish stream: \(error)")
            streamState = .offline
            errorMessage = "Could not connect to IzzoCam: \(error.localizedDescription)"
        }

        isLoadingStream = false
    }

    private func pollMetrics() async {
        while !Task.isCancelled {
            do {
                guard let user else { return }
                let metricsResponse = try await backend.fetchMetrics(idToken: try await user.idToken(forceRefresh: false))
                
                // Ensure UI updates happen on MainActor
                Task { @MainActor in
                    self.viewerMetrics = metricsResponse
                    switch metricsResponse.streamStatus.lowercased() {
                    case "online", "live":
                        self.streamState = .live
                    case "degraded", "connecting":
                        self.streamState = .connecting
                    default:
                        self.streamState = .offline
                    }
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = "Failed to refresh metrics: \(error.localizedDescription)"
                }
            }
            try? await Task.sleep(for: .seconds(30))
        }
    }
}

enum StreamState {
    case offline
    case connecting
    case live
}

extension User {
    func idToken(forceRefresh: Bool) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            getIDTokenForcingRefresh(forceRefresh) { token, error in
                if let token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "firebase", code: -1))
                }
            }
        }
    }
}
