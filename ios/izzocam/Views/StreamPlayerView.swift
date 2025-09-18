import SwiftUI
import LiveKit

struct StreamPlayerView: View {
    @EnvironmentObject private var session: AppSession
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Video player
            LiveKitVideoView(room: session.liveKitController.room, liveKitController: session.liveKitController)
                .background(
                    LinearGradient(
                        colors: [Color.black, Color.izzoTextPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .onTapGesture {
                    withAnimation(.izzoEaseInOut) {
                        showControls.toggle()
                    }
                    scheduleHideControls()
                }
            
            // Loading/Status overlay
            if session.streamState != .live {
                StreamStatusOverlay(state: session.streamState)
            }
            
            // Controls overlay
            if showControls && session.streamState == .live {
                StreamControlsOverlay()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                        removal: .opacity
                    ))
            }
        }
        .onAppear {
            scheduleHideControls()
        }
        .onDisappear {
            hideControlsTask?.cancel()
        }
        .onReceive(session.liveKitController.$tracksUpdated) { _ in
            // Video view will automatically update when tracksUpdated changes
            print("[StreamPlayerView] Tracks updated notification received")
        }
    }
    
    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.izzoEaseInOut) {
                        showControls = false
                    }
                }
            }
        }
    }
}

struct StreamStatusOverlay: View {
    let state: StreamState
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
            
            VStack(spacing: 24) {
                // Status icon with animation
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Circle()
                        .fill(iconColor.opacity(0.3))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 12) {
                    Text(statusTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(statusSubtitle)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                if state == .connecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private var iconColor: Color {
        switch state {
        case .offline: return .izzoError
        case .connecting: return .izzoWarning
        case .live: return .izzoSuccess
        }
    }
    
    private var iconName: String {
        switch state {
        case .offline: return "moon.zzz.fill"
        case .connecting: return "wifi"
        case .live: return "play.circle.fill"
        }
    }
    
    private var statusTitle: String {
        switch state {
        case .offline: return "Izzo is Sleeping"
        case .connecting: return "Connecting..."
        case .live: return "Live!"
        }
    }
    
    private var statusSubtitle: String {
        switch state {
        case .offline: return "Check back soon for more adorable moments"
        case .connecting: return "Getting the stream ready for you"
        case .live: return "Enjoy watching Izzo!"
        }
    }
}

struct StreamControlsOverlay: View {
    @State private var showFullscreen = false
    
    var body: some View {
        VStack {
            // Top controls
            HStack {
                Button(action: {}) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    showFullscreen.toggle()
                }) {
                    Image(systemName: showFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Spacer()
            
            // Bottom controls
            VStack(spacing: 16) {
                // Live indicator
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text("LIVE")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                    
                    Spacer()
                    
                    Text("HD")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.6))
                        )
                }
                
                // Control buttons
                HStack(spacing: 32) {
                    ControlButton(icon: "heart.fill", action: {})
                    ControlButton(icon: "message.fill", action: {})
                    ControlButton(icon: "square.and.arrow.up.fill", action: {})
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.3),
                    Color.clear,
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct ControlButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.izzoSpring) {
                isPressed = true
            }
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.izzoSpring) {
                    isPressed = false
                }
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
    }
}

struct LiveKitVideoView: UIViewRepresentable {
    let room: Room
    @State private var videoTrack: RemoteVideoTrack?
    @ObservedObject var liveKitController: LiveKitController

    func makeUIView(context: Context) -> VideoView {
        let view = VideoView()
        view.layoutMode = .fit
        view.backgroundColor = .black
        
        // Set up room delegate to listen for track changes
        room.add(delegate: context.coordinator)
        
        // Initial track setup
        DispatchQueue.main.async {
            context.coordinator.parent.updateVideoTrack()
        }
        
        return view
    }

    func updateUIView(_ uiView: VideoView, context: Context) {
        // Check for track updates when tracksUpdated changes
        DispatchQueue.main.async {
            self.updateVideoTrack()
        }
        
        // Always update the track, even if nil
        uiView.track = videoTrack
        
        if videoTrack != nil {
            print("[LiveKitVideoView] VideoView updated with track: \(videoTrack != nil ? "YES" : "NO")")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, RoomDelegate {
        let parent: LiveKitVideoView
        
        init(_ parent: LiveKitVideoView) {
            self.parent = parent
        }
        
        func room(_ room: Room, participant: RemoteParticipant, didPublishTrack publication: RemoteTrackPublication) {
            DispatchQueue.main.async {
                self.parent.updateVideoTrack()
            }
        }
        
        func room(_ room: Room, participant: RemoteParticipant, didUnpublishTrack publication: RemoteTrackPublication) {
            DispatchQueue.main.async {
                self.parent.updateVideoTrack()
            }
        }
        
        func room(_ room: Room, didUpdateConnectionState state: ConnectionState, from oldState: ConnectionState) {
            DispatchQueue.main.async {
                self.parent.updateVideoTrack()
            }
        }
    }
    
    func updateVideoTrack() {
        DispatchQueue.main.async {
            let newTrack = self.firstRemoteVideoTrack()
            print("[StreamPlayerView] Updating video track: \(newTrack != nil ? "Found track" : "No track")")
            self.videoTrack = newTrack
        }
    }

    private func firstRemoteVideoTrack() -> RemoteVideoTrack? {
        print("[StreamPlayerView] Searching for video tracks in \(room.remoteParticipants.count) participants")
        for participant in room.remoteParticipants.values {
            let participantIdentity: String = participant.identity?.stringValue ?? "unknown"
            print("[StreamPlayerView] Participant \(participantIdentity) has \(participant.trackPublications.count) publications")
            for publication in participant.trackPublications.values {
                if let remotePublication = publication as? RemoteTrackPublication {
                    print("[StreamPlayerView] Track: kind=\(publication.kind), rawValue=\(publication.kind.rawValue), isSubscribed=\(remotePublication.isSubscribed)")
                    // Kind.video has rawValue of 1, Kind.audio has rawValue of 0
                    guard publication.kind.rawValue == 1, // video
                          remotePublication.isSubscribed,
                          let track = remotePublication.track as? RemoteVideoTrack else {
                        continue
                    }
                    print("[StreamPlayerView] Found subscribed video track!")
                    return track
                } else {
                    print("[StreamPlayerView] Track: kind=\(publication.kind), rawValue=\(publication.kind.rawValue)")
                    guard publication.kind.rawValue == 1, // video
                          let remotePublication = publication as? RemoteTrackPublication,
                          let track = remotePublication.track as? RemoteVideoTrack else {
                        continue
                    }
                    print("[StreamPlayerView] Found video track!")
                    return track
                }
            }
        }
        print("[StreamPlayerView] No subscribed video track found")
        return nil
    }
}
