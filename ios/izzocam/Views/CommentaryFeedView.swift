import SwiftUI
import FirebaseAuth

struct CommentaryFeedView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel = CommentaryFeedViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Feed content
            feedContent
        }
        .background(Color.izzoBackground)
        .onAppear {
            Task {
                await viewModel.loadInitialData()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.config?.dogName ?? "Izzo") Commentary")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.izzoTextPrimary)
                    
                    Text("Hourly and requested AI recaps")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.izzoTextSecondary)
                }
                
                Spacer()
                
                // Status indicator
                commentaryStatusIndicator
            }
            
            // "What's [Dog Name] been up to?" button
            commentaryRequestButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }
    
    private var commentaryStatusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.isCommentaryEnabled ? Color.izzoSuccess : Color.izzoError)
                .frame(width: 8, height: 8)
            
            Text(viewModel.isCommentaryEnabled ? "Active" : "Offline")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(viewModel.isCommentaryEnabled ? Color.izzoSuccess : Color.izzoError)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill((viewModel.isCommentaryEnabled ? Color.izzoSuccess : Color.izzoError).opacity(0.15))
        )
    }
    
    private var commentaryRequestButton: some View {
        Button(action: {
            Task {
                await viewModel.requestCommentary()
            }
        }) {
            HStack(spacing: 12) {
                if viewModel.isLoadingRequest {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                Text("What's \(viewModel.config?.dogName ?? "Izzo") been up to?")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Color.izzoOrange  // Use orange instead of gradient
                    .opacity(canRequestCommentary ? 1.0 : 0.5)
            )
            .cornerRadius(16)
        }
        .disabled(!canRequestCommentary)
        .animation(.easeInOut(duration: 0.2), value: canRequestCommentary)
    }
    
    private var canRequestCommentary: Bool {
        viewModel.isCommentaryEnabled && 
        !viewModel.isLoadingRequest && 
        session.isAuthenticated
    }
    
    private var feedContent: some View {
        Group {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                loadingState
            } else if !viewModel.isCommentaryEnabled {
                errorState
            } else if viewModel.entries.isEmpty {
                emptyState
            } else {
                feedList
            }
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .izzoPrimary))
            
            Text("Loading commentary...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.izzoTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(LinearGradient.izzoPrimaryGradient)
            
            VStack(spacing: 8) {
                Text("IzzoCam AI is warming up")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.izzoTextPrimary)
                
                Text("Check back soon for AI-generated updates!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.izzoTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }
    
    private var errorState: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.izzoError)
            
            VStack(spacing: 8) {
                Text("\(viewModel.config?.dogName ?? "Izzo") Commentary is off right now")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.izzoTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Please come back a little later")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.izzoTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }
    
    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.entries) { entry in
                    CommentaryEntryCard(entry: entry)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .refreshable {
            await viewModel.refreshFeed()
        }
    }
}

struct CommentaryEntryCard: View {
    let entry: CommentaryDisplayEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with type and timestamp
            HStack {
                entryTypeIndicator
                
                Spacer()
                
                Text(entry.relativeTime)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.izzoTextSecondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.displayTitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.izzoTextPrimary)
                    .lineLimit(nil)
                
                Text(entry.displayBody)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.izzoTextSecondary)
                    .lineLimit(nil)
            }
        }
        .padding(16)
        .background(Color.white)
        .izzoCard()
    }
    
    private var entryTypeIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.isRecap ? "clock.fill" : "person.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(entry.isRecap ? .izzoAccent : .izzoPrimary)
            
            Text(entry.isRecap ? "Recap" : "User Request")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(entry.isRecap ? .izzoAccent : .izzoPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((entry.isRecap ? Color.izzoAccent : Color.izzoPrimary).opacity(0.15))
        )
    }
}

#Preview {
    CommentaryFeedView()
        .environmentObject(AppSession())
}