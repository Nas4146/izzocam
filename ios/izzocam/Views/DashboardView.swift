import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var session: AppSession
    @State private var showWelcome = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.izzoBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header section
                        headerSection
                        
                        // Live stream card
                        streamCard
                        
                        // Commentary feed
                        commentarySection
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    StatusBadge(state: session.streamState)
                        .scaleEffect(showWelcome ? 1.0 : 0.5)
                        .opacity(showWelcome ? 1 : 0)
                        .animation(.izzoSpring.delay(0.3), value: showWelcome)
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("AppIcon")  // Use app icon instead of video icon
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text("IzzoCam")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.izzoOrange)  // Use orange instead of gradient
                    }
                    .scaleEffect(showWelcome ? 1.0 : 0.5)
                    .opacity(showWelcome ? 1 : 0)
                    .animation(.izzoSpring.delay(0.2), value: showWelcome)
                }
            }
        }
        .onAppear {
            withAnimation(.izzoSpring) {
                showWelcome = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.izzoTextPrimary)
                }
                
                Spacer()
                
                Button(action: {
                    Task { 
                        await session.refreshStream()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(LinearGradient.izzoPrimaryGradient)
                                .shadow(color: Color.izzoPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
            }
        }
        .offset(y: showWelcome ? 0 : 30)
        .opacity(showWelcome ? 1 : 0)
        .animation(.izzoSpring.delay(0.5), value: showWelcome)
    }

    private var streamCard: some View {
        VStack(spacing: 0) {
            // Stream player
            StreamPlayerView()
                .frame(height: 280)
                .background(Color.black)
                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
                )
            
            // Stream info
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live Stream")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.izzoTextPrimary)
                        
                        Text(streamStatusText)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.izzoTextSecondary)
                    }
                    
                    Spacer()
                    
                    StreamStatusIndicator(state: session.streamState)
                }
                
                if session.streamState == .live {
                    LiveStreamStats()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
            )
        }
        .izzoCard()
        .offset(y: showWelcome ? 0 : 50)
        .opacity(showWelcome ? 1 : 0)
        .animation(.izzoSpring.delay(0.7), value: showWelcome)
    }
    
    private var metricsGrid: some View {
        HStack(spacing: 16) {
            MetricCard(
                title: "Viewers",
                value: "\(session.viewerMetrics.currentViewers)",
                icon: "eye.fill",
                color: .izzoSuccess,
                delay: 0.9
            )
            
            MetricCard(
                title: "Views",
                value: "\(session.viewerMetrics.totalSessions)",
                icon: "chart.bar.fill",
                color: .izzoPrimary,
                delay: 1.0
            )
        }
    }
    
    private var commentarySection: some View {
        VStack(spacing: 0) {
            CommentaryFeedView()
                .frame(height: 400) // Fixed height to keep layout consistent
        }
        .izzoCard()
        .offset(y: showWelcome ? 0 : 50)
        .opacity(showWelcome ? 1 : 0)
        .animation(.izzoSpring.delay(0.8), value: showWelcome)
    }
    
    private var streamStatusText: String {
        switch session.streamState {
        case .offline:
            return "Izzo is taking a break. Check back soon!"
        case .connecting:
            return "Connecting to the stream..."
        case .live:
            return "Izzo is live!"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

struct StreamStatusIndicator: View {
    let state: StreamState
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                if state == .live {
                    Circle()
                        .fill(statusColor.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .scaleEffect(pulse ? 1.5 : 1.0)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
                }
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
            }
            
            Text(statusLabel)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
        .onAppear {
            if state == .live {
                pulse = true
            }
        }
        .onChange(of: state) { newState in
            pulse = newState == .live
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .offline: return .izzoError
        case .connecting: return .izzoWarning
        case .live: return .izzoSuccess
        case .error: return .izzoError
        }
    }
    
    private var statusLabel: String {
        switch state {
        case .offline: return "Offline"
        case .connecting: return "Connecting"
        case .live: return "Live"
        case .error: return "Error"
        }
    }
}

struct LiveStreamStats: View {
    @EnvironmentObject private var session: AppSession
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(icon: "wifi", label: "HD")
            StatItem(icon: "video.fill", label: "30 FPS")
            
            Spacer()
            
            // Combined with stream stats
            StatItem(icon: "eye.fill", label: "\(session.viewerMetrics.currentViewers) Viewers")
            StatItem(icon: "chart.bar.fill", label: "\(session.viewerMetrics.totalSessions) Views")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)  // Reduced padding
        .background(
            RoundedRectangle(cornerRadius: 8)  // Smaller corner radius
                .fill(Color.izzoBackground)
        )
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.izzoAccent)
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.izzoTextSecondary)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let delay: Double
    
    @State private var showCard = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.izzoTextPrimary)
            }
            
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.izzoTextSecondary)
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(showCard ? 1.0 : 0.8)
        .opacity(showCard ? 1 : 0)
        .animation(.izzoSpring.delay(delay), value: showCard)
        .onAppear {
            showCard = true
        }
    }
}

struct StatusBadge: View {
    let state: StreamState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }

    private var color: Color {
        switch state {
        case .offline: return .izzoError
        case .connecting: return .izzoWarning
        case .live: return .izzoSuccess
        case .error: return .izzoError
        }
    }

    private var label: String {
        switch state {
        case .offline: return "Offline"
        case .connecting: return "Connecting"
        case .live: return "Live"
        case .error: return "Error"
        }
    }
}
