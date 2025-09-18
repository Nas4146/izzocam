import Foundation
import LiveKit

@MainActor
final class LiveKitController: NSObject, ObservableObject {
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published var tracksUpdated = false // Trigger for video view updates
    let room = Room()
    private var isConnecting = false

    override init() {
        super.init()
        room.add(delegate: self)
    }

    func connect(url: String, token: String) async throws {
        // Prevent multiple simultaneous connections
        guard !isConnecting else {
            print("[LiveKitController] Already connecting, skipping duplicate request")
            return
        }
        
        // Disconnect first if already connected
        if connectionState == .connected || connectionState == .connecting {
            print("[LiveKitController] Disconnecting existing connection...")
            await room.disconnect()
        }
        
        isConnecting = true
        connectionState = .connecting
        
        print("[LiveKitController] Attempting to connect to: \(url)")
        print("[LiveKitController] Token (first 50 chars): \(String(token.prefix(50)))...")
        
        do {
            // Configure connect options to enable auto-subscription
            let connectOptions = ConnectOptions(
                autoSubscribe: true
            )
            
            try await room.connect(url: url, token: token, connectOptions: connectOptions)
            connectionState = room.connectionState
            
            print("[LiveKitController] Successfully connected to room: \(room.name ?? "unknown")")
            print("[LiveKitController] Room SID: \(room.sid?.description ?? "unknown")")
            print("[LiveKitController] Remote participants: \(room.remoteParticipants.count)")
            
            // Manually subscribe to existing tracks since delegate might not fire immediately
            await subscribeToExistingTracks()
            
            isConnecting = false
        } catch {
            isConnecting = false
            throw error
        }
    }

    func disconnect() {
        Task {
            isConnecting = false
            await room.disconnect()
            await MainActor.run {
                self.connectionState = .disconnected
            }
        }
    }
    
    private func subscribeToExistingTracks() async {
        print("[LiveKitController] Manually subscribing to existing tracks...")
        
        // Subscribe to existing tracks from participants already in the room
        for participant in room.remoteParticipants.values {
            let participantName = participant.identity?.stringValue ?? "unknown"
            print("[LiveKitController] Processing existing participant: \(participantName)")
            
            for publication in participant.trackPublications.values {
                if let remotePublication = publication as? RemoteTrackPublication {
                    print("[LiveKitController] Found existing track: \(publication.kind), subscribed: \(remotePublication.isSubscribed)")
                    
                    if !remotePublication.isSubscribed {
                        print("[LiveKitController] Subscribing to existing \(publication.kind) track...")
                        do {
                            try await remotePublication.set(subscribed: true)
                            print("[LiveKitController] Successfully subscribed to existing \(publication.kind) track")
                            
                            // Trigger video view update
                            await MainActor.run {
                                self.tracksUpdated.toggle()
                            }
                        } catch {
                            print("[LiveKitController] Failed to subscribe to existing \(publication.kind) track: \(error)")
                        }
                    }
                }
            }
        }
    }
}

extension LiveKitController: RoomDelegate {
    nonisolated func room(_ room: Room,
                          didUpdateConnectionState state: ConnectionState,
                          from oldState: ConnectionState) {
        Task { @MainActor in
            print("[LiveKitController] Connection state changed: \(oldState) -> \(state)")
            self.connectionState = state
        }
    }
    
    nonisolated func room(_ room: Room, didConnectToRoom: Bool) {
        Task { @MainActor in
            print("[LiveKitController] Connected to room: \(room.name ?? "unknown"), participants: \(room.remoteParticipants.count)")
            
            // Subscribe to existing tracks from participants already in the room
            for participant in room.remoteParticipants.values {
                let participantName = participant.identity?.stringValue ?? "unknown"
                print("[LiveKitController] Found existing participant: \(participantName)")
                for publication in participant.trackPublications.values {
                    if let remotePublication = publication as? RemoteTrackPublication {
                        print("[LiveKitController] Found existing track: \(publication.kind), subscribed: \(remotePublication.isSubscribed)")
                        
                        if !remotePublication.isSubscribed {
                            print("[LiveKitController] Subscribing to existing \(publication.kind) track...")
                            Task {
                                do {
                                    try await remotePublication.set(subscribed: true)
                                    print("[LiveKitController] Successfully subscribed to existing \(publication.kind) track")
                                } catch {
                                    print("[LiveKitController] Failed to subscribe to existing \(publication.kind) track: \(error)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    nonisolated func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        Task { @MainActor in
            let participantName = participant.identity?.stringValue ?? "unknown"
            print("[LiveKitController] Participant connected: \(participantName), total participants: \(room.remoteParticipants.count)")
        }
    }
    
    nonisolated func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        Task { @MainActor in
            let participantName = participant.identity?.stringValue ?? "unknown"
            print("[LiveKitController] Participant disconnected: \(participantName), total participants: \(room.remoteParticipants.count)")
        }
    }
    
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didPublishTrack publication: RemoteTrackPublication) {
        Task { @MainActor in
            let participantName = participant.identity?.stringValue ?? "unknown"
            print("[LiveKitController] Track published: \(publication.kind) by \(participantName)")
            
            // Auto-subscribe to video tracks
            if publication.kind == .video {
                print("[LiveKitController] Auto-subscribing to video track...")
                Task {
                    do {
                        try await publication.set(subscribed: true)
                        print("[LiveKitController] Successfully subscribed to video track")
                    } catch {
                        print("[LiveKitController] Failed to subscribe to video track: \(error)")
                    }
                }
            }
            
            // Also subscribe to audio tracks
            if publication.kind == .audio {
                print("[LiveKitController] Auto-subscribing to audio track...")
                Task {
                    do {
                        try await publication.set(subscribed: true)
                        print("[LiveKitController] Successfully subscribed to audio track")
                    } catch {
                        print("[LiveKitController] Failed to subscribe to audio track: \(error)")
                    }
                }
            }
        }
    }
    
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didSubscribeToTrack publication: RemoteTrackPublication, track: Track) {
        Task { @MainActor in
            let participantName = participant.identity?.stringValue ?? "unknown"
            print("[LiveKitController] Successfully subscribed to \(publication.kind) track from \(participantName)")
        }
    }
    
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeFromTrack publication: RemoteTrackPublication, track: Track) {
        Task { @MainActor in
            let participantName = participant.identity?.stringValue ?? "unknown"
            print("[LiveKitController] Unsubscribed from \(publication.kind) track from \(participantName)")
        }
    }
}
