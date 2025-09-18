# IzzoCam 📱🎥

A modern, full-stack video streaming application with real-time LiveKit integration.

## 🏗️ Project Structure

This is a monorepo containing both the iOS app and backend services:

```
izzocam/
├── ios/                         # iOS SwiftUI App
│   ├── izzocam/                 # Main app source
│   ├── izzocam.xcodeproj/       # Xcode project
│   └── README.md                # iOS-specific docs
├── backend/                     # Node.js Backend
│   ├── src/                     # Backend source code
│   ├── package.json             # Dependencies
│   └── README.md                # Backend-specific docs
└── README.md                    # This file
```

## ✨ Features

- **📱 Native iOS App**: Beautiful SwiftUI interface with custom animations
- **🔐 Authentication**: Google Sign-In and Apple Sign-In integration
- **📹 Real-time Streaming**: LiveKit-powered video streaming
- **☁️ Backend API**: Node.js with Firebase integration
- **🎨 Modern Design**: Custom design system with gradients and animations

## 🚀 Quick Start

### Prerequisites

- **iOS Development**: Xcode 15.0+, iOS 15.0+
- **Backend**: Node.js 18+, npm/yarn
- **Services**: Firebase project, LiveKit Cloud account
- **Apple**: Developer account for iOS distribution

### 1. Clone & Setup

```bash
git clone https://github.com/Nas4146/izzocam.git
cd izzocam
```

### 2. Backend Setup

```bash
cd backend
npm install

# Copy environment template
cp .env.example .env
# Edit .env with your credentials
```

Required environment variables:
```env
PORT=8082
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
LIVEKIT_API_KEY=your-livekit-api-key
LIVEKIT_API_SECRET=your-livekit-secret
LIVEKIT_URL=wss://your-project.livekit.cloud
```

Start the backend:
```bash
npm run dev
```

### 3. iOS App Setup

```bash
cd ios
open izzocam.xcodeproj
```

1. **Add Firebase Config**: Download `GoogleService-Info.plist` from Firebase Console and add to Xcode project
2. **Set Development Team**: Configure signing in Xcode
3. **Update Bundle ID**: Ensure it matches your Firebase iOS app
4. **Build & Run**: Select device/simulator and press ⌘R

## 🛠️ Development

### Backend Development

```bash
cd backend
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm test             # Run tests
```

### iOS Development

- Open `ios/izzocam.xcodeproj` in Xcode
- Use iOS Simulator or physical device for testing
- Archive for TestFlight/App Store distribution

## 📦 Tech Stack

### iOS App
- **SwiftUI**: Native iOS UI framework
- **Firebase Auth**: Authentication service
- **LiveKit**: Real-time video streaming
- **Google Sign-In**: OAuth integration

### Backend
- **Node.js**: Runtime environment
- **TypeScript**: Type-safe JavaScript
- **Express**: Web framework
- **Firebase Admin**: Backend Firebase integration
- **LiveKit Server**: Video streaming backend

## 🚀 Deployment

### Backend Deployment

**Heroku:**
```bash
cd backend
git subtree push --prefix=backend heroku main
```

**Vercel:**
```bash
cd backend
vercel --prod
```

**AWS/GCP/Azure:**
- Build: `npm run build`
- Deploy `dist/` folder

### iOS App Deployment

1. **TestFlight**:
   - Archive in Xcode (Product → Archive)
   - Upload to App Store Connect
   - Configure TestFlight testing

2. **App Store**:
   - Complete app metadata in App Store Connect
   - Submit for review
   - Release to App Store

## 🔒 Security

### Environment Variables
- ✅ All sensitive data in `.env` files
- ✅ `.env` files in `.gitignore`
- ✅ Use `.env.example` templates
- ❌ **NEVER** commit API keys or secrets

### Firebase Security
- ✅ Proper Firebase security rules
- ✅ Service account keys protected
- ✅ Client-side and server-side validation

### API Security
- ✅ JWT token validation
- ✅ Rate limiting
- ✅ CORS configuration
- ✅ HTTPS only in production

## 📱 App Store Information

- **Name**: IzzoCam
- **Bundle ID**: com.nick.izzocam
- **Version**: 1.0
- **Platform**: iOS 15.0+

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm test              # Unit tests
npm run test:e2e       # End-to-end tests
npm run test:watch     # Watch mode
```

### iOS Tests
- Unit tests: ⌘U in Xcode
- UI tests: Select UI test target
- Device testing: Use multiple simulators

## 📊 Project Status

- ✅ **iOS App**: Complete with modern UI
- ✅ **Authentication**: Google + Apple Sign-In
- ✅ **Video Streaming**: LiveKit integration
- ✅ **Backend API**: Node.js + Firebase
- ✅ **App Store**: Ready for TestFlight
- 🔄 **CI/CD**: In progress

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Swift style guide for iOS
- Use TypeScript for backend
- Write tests for new features
- Update documentation
- Never commit sensitive data

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Nas4146/izzocam/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Nas4146/izzocam/discussions)
- **Email**: support@izzocam.com

## 👨‍💻 Author

Built with ❤️ by [Nas4146](https://github.com/Nas4146)

---

**IzzoCam** - Modern full-stack video streaming 📱🎥✨