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
- **🤖 AI Commentary**: GPT-4o mini powered commentary system with hourly recaps
- **📊 Smart Monitoring**: Automated cost tracking and rate limiting
- **☁️ Backend API**: Node.js with Firebase integration
- **🎨 Modern Design**: Custom design system with gradients and animations

## Production URLs

- **Backend API**: https://izzocam-backend-17482328523.us-central1.run.app/api
- **Monitoring Health**: https://izzocam-backend-17482328523.us-central1.run.app/api/monitoring/health
- **Frontend Web App**: https://izzocam.web.app
- **LiveKit Stream**: wss://izzocam-5u8a05zv.livekit.cloud
- **Firebase Project**: izzocam
- **Cloud Storage**: izzocam-snapshots

## System Status

✅ **Phase 4 Complete**: End-to-end production deployment with comprehensive testing, monitoring, rate limiting, and documentation.

- Backend deployed to Google Cloud Run
- Firestore database with security rules deployed  
- Firebase Authentication integrated
- LiveKit WebRTC streaming active
- AI commentary system operational
- Real-time cost monitoring with Firestore
- Rate limiting for commentary requests (2/10min)
- Complete test suite (8 passing tests)
- Error logging and monitoring active

## Quick Start

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
OPENAI_API_KEY=your-openai-api-key
GCS_BUCKET_NAME=your-gcs-bucket-name
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
- **OpenAI GPT-4o mini**: AI commentary generation
- **Google Cloud Storage**: Snapshot storage with lifecycle management

### Infrastructure
- **Google Cloud Run**: Serverless container deployment
- **Cloud Scheduler**: Automated cron jobs for snapshots and recaps
- **Firebase Hosting**: Web frontend and API proxying
- **Firestore**: Real-time database for commentary and monitoring

## 🚀 Deployment

### Backend Deployment (Cloud Run + Firebase Hosting)

1. **Build & push container**
```bash
cd backend
gcloud builds submit --tag gcr.io/<project-id>/izzocam-backend .
```

2. **Deploy to Cloud Run**
```bash
gcloud run deploy izzocam-backend \
  --image gcr.io/<project-id>/izzocam-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars "FIREBASE_PROJECT_ID=...,..."
```

3. **Firebase Hosting rewrite**
```bash
firebase deploy --only hosting
```

The rewrite in `firebase.json` proxies `/api/**` to the Cloud Run service so LiveKit webhooks and the mobile app can use `https://<project>.web.app/api/...`.

## 🤖 AI Commentary System Setup

### Google Cloud Storage Configuration

1. **Create GCS bucket for snapshots**:
```bash
gsutil mb gs://your-snapshots-bucket
```

2. **Set up lifecycle policy** (auto-delete after 24 hours):
```bash
cat > lifecycle.json << EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"age": 1}
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle.json gs://your-snapshots-bucket
```

3. **Configure bucket permissions**:
```bash
# Grant service account access
gsutil iam ch serviceAccount:your-service-account@project.iam.gserviceaccount.com:objectAdmin gs://your-snapshots-bucket
```

### OpenAI API Setup

1. **Get API key** from [OpenAI Platform](https://platform.openai.com/api-keys)
2. **Add to environment variables**:
```env
OPENAI_API_KEY=sk-...your-key-here
```

### Firestore Collections Setup

The system automatically creates these collections:
- `commentary/{date}/entries/{id}` - Commentary entries
- `snapshots/{timestamp}` - Snapshot metadata  
- `settings/commentary` - Configuration (dog name, tone)
- `monitoring_usage` - Usage and cost tracking
- `monitoring_errors` - Error logging

### Firestore Security Rules

The project includes comprehensive security rules in `firestore.rules`:
- **Commentary entries**: Readable by authenticated users, writable by backend service
- **Configuration**: Readable by authenticated users, writable by admins  
- **Snapshots**: Backend service read/write access only
- **Monitoring data**: Backend service write access, admin read access

Deploy the rules:
```bash
firebase deploy --only firestore:rules
```

### Cloud Scheduler Jobs

1. **Snapshot capture job** (every 5 minutes):
```bash
gcloud scheduler jobs create http snapshot-capture \
  --schedule="*/5 * * * *" \
  --uri="https://your-project.web.app/api/cron/capture-snapshots" \
  --http-method=POST \
  --headers="X-Cloudscheduler=true"
```

2. **Hourly recap generation**:
```bash
gcloud scheduler jobs create http hourly-recap \
  --schedule="0 * * * *" \
  --uri="https://your-project.web.app/api/cron/generate-recap" \
  --http-method=POST \
  --headers="X-Cloudscheduler=true"
```

3. **Cost monitoring** (every hour):
```bash
gcloud scheduler jobs create http cost-monitoring \
  --schedule="0 * * * *" \
  --uri="https://your-project.web.app/api/cron/monitor-costs" \
  --http-method=POST \
  --headers="X-Cloudscheduler=true"
```

### LiveKit Egress Configuration

Set up webhook for snapshot capture:
```bash
# Configure in LiveKit Cloud dashboard
Webhook URL: https://your-project.web.app/api/egress/webhook
Events: egress_ended
```

### Rate Limiting Configuration

The system includes built-in rate limiting:
- **Commentary requests**: 2 per 10 minutes per user
- **General API**: 60 requests per minute
- **Config endpoint**: 10 requests per minute

### Cost Monitoring

Monitor costs via API endpoints:
```bash
# Get usage summary
curl https://your-project.web.app/api/monitoring/usage

# Get error summary  
curl https://your-project.web.app/api/monitoring/errors

# Check current rate limits
curl https://your-project.web.app/api/monitoring/rate-limits
```

Cost alerts are triggered when:
- Daily costs exceed $10
- Hourly costs exceed $1

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

**Test Coverage Includes:**
- API endpoint validation
- Authentication and rate limiting
- OpenAI integration with mocks
- Error handling and monitoring
- Commentary generation pipeline

### iOS Tests
- Unit tests: ⌘U in Xcode
- UI tests: Select UI test target
- Device testing: Use multiple simulators

## 📊 Project Status

- ✅ **iOS App**: Complete with modern UI
- ✅ **Authentication**: Google + Apple Sign-In
- ✅ **Video Streaming**: LiveKit integration
- ✅ **AI Commentary System**: GPT-4o mini integration with hourly recaps
- ✅ **Snapshot Pipeline**: Automated capture and storage
- ✅ **Monitoring & Alerts**: Cost tracking and error logging
- ✅ **Rate Limiting**: User and API protection
- ✅ **Backend API**: Node.js + Firebase
- ✅ **App Store**: Ready for TestFlight
- ✅ **Testing Suite**: Comprehensive E2E tests
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
