Phase 1 – InfPhase 3 – iOS App Experience ✅ COMPLETE

SwiftUI CommentaryFeedView under the LiveKit player: Firestore listener + REST fallback, card UI for entries, "What has Izzo been up to?" button with loading states. ✅
Handle empty/loading/error states gracefully. ✅
Connect to backend endpoints and ensure Firebase auth attached. ✅

Phase 4 – Validation & Polish ✅ COMPLETE

End-to-end tests with mocked snapshots and OpenAI stub. ✅
Cost/usage monitoring hooks, error logging, rate-limit enforcement. ✅
Documentation: update README/PRODUCT_REQUIREMENTS with setup instructions (env vars, cron jobs, bucket policies). ✅

**Phase 4 Achievements:**
- Jest test suite with 8 passing tests covering all API endpoints
- MonitoringService with real-time cost tracking and Firestore persistence
- Rate limiting middleware (2 commentary requests per 10 min, 60 API requests per min)
- Comprehensive error logging with severity levels
- Cloud Scheduler cost monitoring with automated alerts
- Complete documentation updates in README and PRODUCT_REQUIREMENTSe & Snapshot Pipeline ✅ COMPLETE

LiveKit Cloud: configure track-composite egress + webhook that delivers frame bursts. ✅
Backend (Node/Express): add webhook endpoint to receive bursts, push images to GCS (with 24h lifecycle), and log snapshot metadata to Firestore (snapshots collection). ✅
Cloud scheduler jobs: set up Cloud Run/Functions cron to fire the 5-minute burst captures. ✅

Phase 2 – Commentary Generation Backend ✅ COMPLETE

Firestore schema for commentary entries and settings/commentary config. ✅
Implement hourly recap worker (Cloud Run job) that gathers last 12 snapshots, calls OpenAI GPT-4o mini, and stores structured output. ✅
Build on-demand recap handler triggered by app (rate-limited per UID); uses snapshots since last hourly recap + stored text. ✅
Add REST endpoints: GET /commentary/latest, POST /commentary/request, GET /commentary/config. ✅
Configuration for OpenAI (API key, prompt templates, comedic tone with dog name). ✅
Phase 3 – iOS App Experience

SwiftUI CommentaryFeedView under the LiveKit player: Firestore listener + REST fallback, card UI for entries, “What has Izzo been up to?” button with loading states.
Handle empty/loading/error states gracefully.
Connect to backend endpoints and ensure Firebase auth attached.
Phase 4 – Validation & Polish

End-to-end tests with mocked snapshots and OpenAI stub.
Cost/usage monitoring hooks, error logging, rate-limit enforcement.
Documentation: update README/PRODUCT_REQUIREMENTS with setup instructions (env vars, cron jobs, bucket policies).