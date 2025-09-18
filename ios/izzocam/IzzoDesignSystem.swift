import SwiftUI

// MARK: - Color Palette
extension Color {
    static let izzoPrimary = Color(red: 0.3, green: 0.4, blue: 0.9)      // Vibrant blue
    static let izzoSecondary = Color(red: 0.9, green: 0.3, blue: 0.5)    // Pink accent
    static let izzoAccent = Color(red: 0.2, green: 0.8, blue: 0.6)       // Teal
    static let izzoBackground = Color(red: 0.97, green: 0.98, blue: 1.0)  // Light blue-white
    static let izzoCardBg = Color.white
    static let izzoTextPrimary = Color(red: 0.1, green: 0.1, blue: 0.2)
    static let izzoTextSecondary = Color(red: 0.4, green: 0.4, blue: 0.6)
    static let izzoSuccess = Color(red: 0.2, green: 0.7, blue: 0.3)
    static let izzoWarning = Color(red: 0.9, green: 0.6, blue: 0.1)
    static let izzoError = Color(red: 0.9, green: 0.2, blue: 0.3)
}

// MARK: - Gradients
extension LinearGradient {
    static let izzoPrimaryGradient = LinearGradient(
        colors: [Color.izzoPrimary, Color.izzoSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let izzoBackgroundGradient = LinearGradient(
        colors: [Color.izzoBackground, Color.white],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let izzoCardGradient = LinearGradient(
        colors: [Color.white, Color.izzoBackground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Custom Button Styles
struct IzzoPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                LinearGradient.izzoPrimaryGradient
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .cornerRadius(25)
            .shadow(color: Color.izzoPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IzzoSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.izzoPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Color.izzoCardBg
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.izzoPrimary.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Text Field Style
struct IzzoTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.izzoCardBg)
                    .shadow(color: Color.izzoPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.izzoPrimary.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Custom Card Style
struct IzzoCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient.izzoCardGradient)
                    .shadow(color: Color.izzoPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
            )
    }
}

extension View {
    func izzoCard() -> some View {
        modifier(IzzoCardStyle())
    }
}

// MARK: - Animation Extensions
extension Animation {
    static let izzoSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let izzoEaseInOut = Animation.easeInOut(duration: 0.4)
}