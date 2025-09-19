import SwiftUI
import LiveKit

struct StreamPlayerView: View {
    @EnvironmentObject private var session: AppSession
    @State private var showControls = false
    @State private var controlsTimer: Timer?
    @State private var isFullscreen = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Live stream video
            if session.liveKitController.connectionState == .connected {
                LiveKitVideoView()
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showControls.toggle()
                        }
                        resetControlsTimer()
                    }
            } else {
                // Placeholder when not connected
                VStack(spacing: 20) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("Stream Offline")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    if session.isLoadingStream {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                }
            }
            
            // Overlay controls
            if showControls {
                VStack {
                    // Top controls
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isFullscreen.toggle()
                            }
                        }) {
                            Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Live indicator with design system integration
                        if session.streamState == .live {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.izzoError)
                                    .frame(width: 12, height: 12)
                                    .scaleEffect(showControls ? 1.0 : 0.8)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showControls)
                                
                                Text("LIVE")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom controls with design system styling
                    HStack(spacing: 20) {
                        // Mute button
                        Button(action: {
                            session.liveKitController.toggleMicrophone()
                        }) {
                            Image(systemName: session.liveKitController.isMicrophoneEnabled ? "mic" : "mic.slash")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    LinearGradient.izzoPrimaryGradient
                                        .opacity(0.8)
                                )
                                .clipShape(Circle())
                        }
                        
                        // Camera toggle
                        Button(action: {
                            session.liveKitController.toggleCamera()
                        }) {
                            Image(systemName: session.liveKitController.isCameraEnabled ? "video" : "video.slash")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    LinearGradient.izzoPrimaryGradient
                                        .opacity(0.8)
                                )
                                .clipShape(Circle())
                        }
                        
                        // Volume control
                        Button(action: {
                            // Toggle speaker/headphones
                        }) {
                            Image(systemName: "speaker.wave.2")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
                .transition(.opacity)
            }
            
            // Connection status overlay with design system
            if session.streamState == .connecting {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color.izzoOrange)
                    
                    Text("Connecting to stream...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.izzoOrange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Error state
            if case .error(let message) = session.streamState {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(Color.izzoError)
                    
                    Text("Connection Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        Task {
                            await session.refreshStream()
                        }
                    }) {
                        Text("Retry")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.izzoOrange)
                            .clipShape(Capsule())
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.izzoError.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .navigationBarHidden(isFullscreen)
        .statusBarHidden(isFullscreen)
        .onAppear {
            showControls = true
            resetControlsTimer()
        }
        .onDisappear {
            controlsTimer?.invalidate()
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation(Animation.izzoEaseInOut) {
                showControls = false
            }
        }
    }
}

// MARK: - LiveKit Video View Integration
struct LiveKitVideoView: UIViewRepresentable {
    @EnvironmentObject private var session: AppSession
    
    func makeUIView(context: Context) -> VideoView {
        let videoView = VideoView()
        videoView.layoutMode = .fill
        videoView.isDebugMode = false
        videoView.backgroundColor = UIColor.black
        return videoView
    }
    
    func updateUIView(_ uiView: VideoView, context: Context) {
        // Get the remote video track from LiveKit room using working pattern from git
        let room = session.liveKitController.room
        
        // Find the first remote participant with a video track
        for participant in room.remoteParticipants.values {
            for publication in participant.trackPublications.values {
                if let remotePublication = publication as? RemoteTrackPublication {
                    // Use rawValue comparison like the working git version
                    guard publication.kind.rawValue == 1, // video
                          remotePublication.isSubscribed,
                          let track = remotePublication.track as? RemoteVideoTrack else {
                        continue
                    }
                    print("🎥 Connecting video track from participant: \(participant.identity?.stringValue ?? "unknown")")
                    uiView.track = track
                    return
                }
            }
        }
        
        // Clear track if no video found
        uiView.track = nil
    }
}

#Preview {
    StreamPlayerView()
        .environmentObject(AppSession())
}
