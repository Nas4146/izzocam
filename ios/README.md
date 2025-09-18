# IzzoCam 📱

A modern, beautiful iOS app for streaming video content with real-time LiveKit integration.

## ✨ Features

- **🔐 Simplified Authentication**: Google Sign-In and Apple Sign-In only
- **📹 Real-time Video Streaming**: Powered by LiveKit Cloud
- **🎨 Modern UI Design**: Beautiful gradients, animations, and responsive design
- **📱 Native iOS**: Built with SwiftUI for optimal performance
- **☁️ Firebase Integration**: Secure authentication and backend services

## 🛠️ Technology Stack

- **Frontend**: SwiftUI (iOS 15+)
- **Authentication**: Firebase Auth, Google Sign-In, Apple Sign-In
- **Video Streaming**: LiveKit Swift SDK
- **Backend**: Firebase Functions
- **Design System**: Custom IzzoDesignSystem with modern animations

## 🏗️ Architecture

```
izzocam/
├── izzocam/
│   ├── IzzoCamApp.swift              # App entry point
│   ├── Views/
│   │   ├── AuthView.swift            # Authentication interface
│   │   ├── DashboardView.swift       # Main dashboard
│   │   └── StreamPlayerView.swift    # Video streaming player
│   ├── Controllers/
│   │   └── LiveKitController.swift   # LiveKit room management
│   ├── Services/
│   │   ├── AppSession.swift          # App state management
│   │   ├── BackendClient.swift       # API communication
│   │   └── GoogleSignInHandler.swift # Google auth handling
│   ├── Design/
│   │   └── IzzoDesignSystem.swift   # UI components & animations
│   └── Assets.xcassets/             # App icons and assets
├── izzocamTests/                    # Unit tests
└── izzocamUITests/                  # UI tests
```

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 15.0+
- Apple Developer Account
- Firebase Project
- LiveKit Cloud Account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/izzocam.git
   cd izzocam
   ```

2. **Open in Xcode**
   ```bash
   open izzocam.xcodeproj
   ```

3. **Configure Firebase**
   - Add your `GoogleService-Info.plist` to the project
   - Update Firebase configuration in `Config.swift`

4. **Configure LiveKit**
   - Update LiveKit server URL in `Config.swift`
   - Set up WHIP ingress for OBS streaming

5. **Set up signing**
   - Select your development team in Xcode
   - Configure bundle identifier

6. **Build and run**
   - Select your target device or simulator
   - Press `Cmd+R` to build and run

## 📱 Features Overview

### Authentication
- **Google Sign-In**: Seamless OAuth integration
- **Apple Sign-In**: Native iOS authentication
- **Secure Tokens**: JWT-based session management

### Video Streaming
- **LiveKit Integration**: Real-time video/audio streaming
- **OBS Compatible**: WHIP protocol support
- **Reactive UI**: Automatic track subscription and display
- **Modern Player**: Custom controls with animations

### Design System
- **IzzoDesignSystem**: Consistent UI components
- **Custom Colors**: izzoPrimary, izzoSecondary, izzoAccent
- **Smooth Animations**: Custom easing and transitions
- **Responsive Layout**: Adaptive to all screen sizes

## 🔧 Configuration

### Environment Variables
Create a `.env` file (ignored by git):
```
FIREBASE_API_KEY=your_api_key
LIVEKIT_URL=wss://your-project.livekit.cloud
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_secret
```

### LiveKit Setup
1. Create LiveKit Cloud project
2. Set up WHIP ingress for OBS
3. Configure room settings
4. Update tokens in backend

## 📦 Dependencies

- **Firebase/Auth**: Authentication services
- **GoogleSignIn**: Google OAuth integration
- **LiveKit**: Real-time video streaming
- **SwiftUI**: Native iOS UI framework

## 🧪 Testing

### Unit Tests
```bash
# Run unit tests
cmd+u in Xcode
# Or via command line
xcodebuild test -scheme izzocam -destination 'platform=iOS Simulator,name=iPhone 15'
```

### UI Tests
```bash
# Run UI tests
cmd+u in Xcode (select UI tests)
```

## 🚀 Deployment

### TestFlight
1. Archive the app in Xcode (`Product > Archive`)
2. Upload to App Store Connect
3. Configure TestFlight testing
4. Invite internal/external testers

### App Store
1. Complete app metadata in App Store Connect
2. Upload screenshots and descriptions
3. Submit for review
4. Release to App Store

## 🎨 Design Guidelines

### Colors
- **Primary**: `#FF6B35` (Orange gradient)
- **Secondary**: `#004E89` (Deep blue)
- **Accent**: `#FFB627` (Golden yellow)
- **Background**: Dynamic light/dark support

### Typography
- **System fonts** with custom weights
- **Accessibility** compliant sizing
- **Dynamic Type** support

### Animations
- **Custom easing**: `izzoEaseInOut`, `izzoSpring`
- **Micro-interactions**: Button presses, transitions
- **Loading states**: Smooth progress indicators

## 🔒 Security

- **Firebase Rules**: Secure database access
- **Token Validation**: Server-side JWT verification
- **Privacy**: No personal data collection beyond auth
- **Encryption**: HTTPS/WSS for all communications

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

Built with ❤️ by [Your Name]

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support, email support@izzocam.com or create an issue on GitHub.

---

**IzzoCam** - Modern video streaming for iOS 📱✨