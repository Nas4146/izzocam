import SwiftUI
import FirebaseAuth
import GoogleSignInSwift
import AuthenticationServices

struct RootView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        Group {
            if session.user != nil {
                DashboardView()
            } else {
                AuthView()
            }
        }
        .alert(item: Binding(
            get: { session.errorMessage.map(IdentifiableString.init(value:)) },
            set: { session.errorMessage = $0?.value }
        )) { item in
            Alert(
                title: Text("Something went wrong"),
                message: Text(item.value),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct AuthView: View {
    @State private var authError: String?
    @State private var isLoading = false
    @State private var showWelcome = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient.izzoBackgroundGradient
                    .ignoresSafeArea()
                
                // Floating shapes for visual interest
                FloatingShapes()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header section
                        VStack(spacing: 24) {
                            Spacer(minLength: geometry.size.height * 0.15)
                            
                            // Logo with animation
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient.izzoPrimaryGradient)
                                        .frame(width: 100, height: 100)
                                        .shadow(color: Color.izzoPrimary.opacity(0.4), radius: 20, x: 0, y: 10)
                                    
                                    Image(systemName: "video.circle.fill")
                                        .font(.system(size: 44, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .scaleEffect(showWelcome ? 1.0 : 0.5)
                                .animation(.izzoSpring.delay(0.2), value: showWelcome)
                                
                                VStack(spacing: 12) {
                                    Text("IzzoCam")
                                        .font(.system(size: 52, weight: .bold, design: .rounded))
                                        .foregroundStyle(LinearGradient.izzoPrimaryGradient)
                                        .offset(y: showWelcome ? 0 : 20)
                                        .opacity(showWelcome ? 1 : 0)
                                        .animation(.izzoSpring.delay(0.4), value: showWelcome)
                                    
                                    Text("Watch Izzo live, anytime, anywhere")
                                        .font(.system(size: 20, weight: .medium, design: .rounded))
                                        .foregroundColor(.izzoTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .offset(y: showWelcome ? 0 : 20)
                                        .opacity(showWelcome ? 1 : 0)
                                        .animation(.izzoSpring.delay(0.6), value: showWelcome)
                                }
                            }
                        }
                        
                        Spacer(minLength: 60)
                        
                        // Sign-in options
                        VStack(spacing: 32) {
                            VStack(spacing: 20) {
                                Text("Sign in to continue")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.izzoTextPrimary)
                                    .offset(y: showWelcome ? 0 : 30)
                                    .opacity(showWelcome ? 1 : 0)
                                    .animation(.izzoSpring.delay(0.8), value: showWelcome)
                                
                                VStack(spacing: 16) {
                                    // Google Sign In
                                    Button(action: { 
                                        Task { await handleGoogleSignIn() }
                                    }) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "globe")
                                                .font(.system(size: 20, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Text("Continue with Google")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            if isLoading {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.9)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 18)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(LinearGradient.izzoPrimaryGradient)
                                                .shadow(color: Color.izzoPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                                        )
                                    }
                                    .disabled(isLoading)
                                    .offset(y: showWelcome ? 0 : 30)
                                    .opacity(showWelcome ? 1 : 0)
                                    .animation(.izzoSpring.delay(1.0), value: showWelcome)
                                    
                                    // Apple Sign In
                                    Button(action: { 
                                        Task { await handleAppleSignIn() }
                                    }) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "apple.logo")
                                                .font(.system(size: 20, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Text("Continue with Apple")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 18)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.black, Color.izzoTextPrimary],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
                                        )
                                    }
                                    .disabled(isLoading)
                                    .offset(y: showWelcome ? 0 : 30)
                                    .opacity(showWelcome ? 1 : 0)
                                    .animation(.izzoSpring.delay(1.2), value: showWelcome)
                                }
                                .padding(.horizontal, 32)
                            }
                        }
                        
                        // Error message
                        if let authError {
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.izzoError)
                                    
                                    Text(authError)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(.izzoError)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.izzoError.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.izzoError.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal, 32)
                                .padding(.top, 24)
                            }
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .opacity.combined(with: .scale(scale: 0.9))
                            ))
                        }
                        
                        Spacer(minLength: 60)
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text("By signing in, you agree to our")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.izzoTextSecondary)
                            
                            HStack(spacing: 4) {
                                Button("Terms of Service") {}
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.izzoPrimary)
                                
                                Text("and")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.izzoTextSecondary)
                                
                                Button("Privacy Policy") {}
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.izzoPrimary)
                            }
                        }
                        .offset(y: showWelcome ? 0 : 20)
                        .opacity(showWelcome ? 1 : 0)
                        .animation(.izzoSpring.delay(1.4), value: showWelcome)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.izzoSpring) {
                showWelcome = true
            }
        }
    }

    
    @MainActor
    private func handleGoogleSignIn() async {
        isLoading = true
        authError = nil
        
        do {
            try await GoogleSignInHandler.shared.signIn()
        } catch {
            authError = "Failed to sign in with Google: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    private func handleAppleSignIn() async {
        isLoading = true
        authError = nil
        
        // TODO: Implement Apple Sign In
        // For now, show a placeholder message
        authError = "Apple Sign In coming soon!"
        
        isLoading = false
    }
}

// MARK: - Floating Shapes Background
struct FloatingShapes: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Large circle
                Circle()
                    .fill(Color.izzoPrimary.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .position(
                        x: animate ? geometry.size.width * 0.8 : geometry.size.width * 0.2,
                        y: animate ? geometry.size.height * 0.2 : geometry.size.height * 0.8
                    )
                
                // Medium circle
                Circle()
                    .fill(Color.izzoAccent.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .position(
                        x: animate ? geometry.size.width * 0.1 : geometry.size.width * 0.9,
                        y: animate ? geometry.size.height * 0.7 : geometry.size.height * 0.3
                    )
                
                // Small circle
                Circle()
                    .fill(Color.izzoSecondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .position(
                        x: animate ? geometry.size.width * 0.7 : geometry.size.width * 0.3,
                        y: animate ? geometry.size.height * 0.9 : geometry.size.height * 0.1
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}
