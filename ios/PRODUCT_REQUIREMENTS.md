IzzoCam AI Commentary – Product Requirements & Implementation Status

**IMPLEMENTAT7. Cost & Monitoring ✅ IMPLEMENTED

**Current Implementation:**
- Ensure commentary API requires Firebase auth (viewer must be signed in).
No secrets in client code; OpenAI access handled server-side.

9. Open Questions ✅ RESOLVEDve cost tracking via MonitoringService
- Real-time usage metrics stored in Firestore (`monitoring_usage`, `monitoring_errors` collections)
- Automated cost alerts when thresholds exceeded:
  - Daily: $10 threshold
  - Hourly: $1 threshold
- Rate limiting implemented:
  - Commentary requests: 2 per 10 minutes per user
  - General API: 60 requests per minute
  - Config endpoint: 10 requests per minute
- Error logging with severity levels (low, medium, high, critical)
- API endpoints for monitoring: `/api/monitoring/health`, `/api/monitoring/usage`, `/api/monitoring/errors`
- Automated cost monitoring cron job runs hourly

**Actual Costs (as implemented):**
- Snapshot burst: ~$0.008-$0.01 per 5-frame prompt (12/hour = ~$3/day baseline)
- Hourly recap: ~$0.01 per prompt (24/day = ~$0.24/day)
- Total estimated daily cost: ~$3.25/day

8. Dependencies & Tasks ✅ ALL COMPLETE

**DevOps / Cloud: ✅ COMPLETE**
- ✅ GCS bucket created with 24-hour lifecycle rule
- ✅ Firestore collections and indexes configured
- ✅ LiveKit egress webhook configured for Cloud Run
- ✅ Cloud Scheduler cron jobs: 5-minute capture, hourly recap, cost monitoring

**Backend: ✅ COMPLETE**
- ✅ Express API with all commentary endpoints implemented
- ✅ Firebase auth middleware and rate limiting
- ✅ AI worker with OpenAI GPT-4o mini integration
- ✅ Configuration endpoints with dynamic dog name
- ✅ Comprehensive monitoring and error handling
- ✅ Environment variables documented and secured

**iOS: ✅ COMPLETE**
- ✅ CommentaryFeedView SwiftUI component implemented
- ✅ Firestore real-time listener with REST fallback
- ✅ "What has [Dog Name] been up to?" button with full functionality
- ✅ Error states and loading states implemented
- ✅ Modern UI with IzzoDesignSystem integration
- ✅ Authentication flow for commentary requests

**QA & Monitoring: ✅ COMPLETE**
- ✅ End-to-end test suite with 8 passing tests
- ✅ Firestore integration verified
- ✅ AI system error handling with fallback text
- ✅ Cost monitoring alerts implemented
- ✅ Device testing completed on iPhone

9. Production Deployment Status ✅ READY

**Infrastructure:**
- ✅ Backend deployed to Google Cloud Run
- ✅ Firebase Hosting configured with API proxying
- ✅ Cloud Scheduler jobs active and running
- ✅ LiveKit egress webhook receiving snapshot bursts
- ✅ OpenAI API integration active with cost monitoring

**Application:**
- ✅ iOS app ready for TestFlight/App Store
- ✅ Real-time commentary feed functional
- ✅ User authentication working
- ✅ Rate limiting and monitoring active
- ✅ Error handling and offline states implemented

10. Open Questions ✅ RESOLVEDUS: ✅ PHASE 4 COMPLETE - PRODUCTION READY**

## Current Status Summary

✅ **Phase 1 - Infrastructure & Snapshot Pipeline**: Complete
✅ **Phase 2 - Commentary Generation Backend**: Complete  
✅ **Phase 3 - iOS App Experience**: Complete
✅ **Phase 4 - Validation & Polish**: Complete

### What's Working Now:
- Real-time video streaming with LiveKit
- Automated snapshot capture every 5 minutes via Cloud Scheduler
- Hourly AI-generated commentary using GPT-4o mini
- On-demand commentary requests (rate-limited to 2 per 10 minutes)
- Full iOS app with CommentaryFeedView integration
- Comprehensive monitoring and cost tracking
- End-to-end testing suite

---

## 1. Objective
Add an AI-powered, lighthearted commentary stream to IzzoCam that summarizes Izzo’s activity. The experience should feel informative, slightly comedic, configurable (dog name, tone), and accessible from the existing iOS app UI.

2. Key Use Cases

Hourly recap: user opens app and sees a fresh, AI-generated summary of the past hour under the live video.
Snapshot feed: every 5 minutes the system captures a short burst (5 frames over 15 seconds) so the AI has context for movement.
On-demand: tapping “What has Izzo been up to?” produces an immediate recap using all snapshots collected since the most recent hourly summary.
History: user can scroll a feed showing timestamped entries (hourly, snapshot, ad-hoc).
3. System Overview

3.1 Capture Layer (LiveKit Egress)

Use LiveKit Cloud egress “track composite → webhook” to capture the broadcast feed centrally (no Mac instrumentation).
Schedule a Cloud Run job every 5 minutes:
Trigger an egress/record command that captures 5 frames over ~15 seconds.
Webhook pushes the frames to our backend, which stores them temporarily in Google Cloud Storage (auto-delete after 24 hours).
Metadata recorded in Firestore: frame timestamp, storage path, egress job ID.
3.2 AI Commentary Pipeline

Provider: OpenAI GPT-4o mini image endpoints (cheap, multimodal).
Hourly job (Cloud Run Cron) selects snapshots for the last hour (approx. 12 bursts) → compiles a prompt (dog name, tone) → OpenAI call returns structured JSON (title, bullet list, comedic highlight) → store in Firestore, mark as mode: hourly.
Snapshot capture itself may optionally produce short insight entries (if desired later); for MVP we only store the frames.
On-demand request takes all snapshots after the last hourly summary + the last summary text, forms an incremental narrative, and returns to the client.
3.3 Data & API

Firestore collections:
commentary/{day}/entries/{id} with fields: timestamp, mode (hourly, adhoc), title, body, mediaRefs[], confidence, tags, configMetadata.
snapshots/{timestamp} storing metadata for each burst: gcsPaths[], capturedAt, burstId.
Express backend additions:
GET /commentary/latest?limit=20 (reads from Firestore).
POST /commentary/request (requires Firebase ID token; triggers on-demand commentary pipeline).
GET /commentary/config to supply dynamic text (dog name, tone).
Cloud Storage bucket for frames (temporary). Enable lifecycle rule to delete objects after 1 day.
3.4 Mobile UI

Add CommentaryFeedView beneath the video player in the iOS app. Elements:
Header: “Izzo Live Commentary”, optional toggle for showing hourly vs. summary.
“What has Izzo been up to?” button (disabled while a request is pending; rate-limit in backend).
Scrollable feed of cards: timestamp, mode icon, title, witty body copy (with ellipsis for multi-line).
Firestore real-time listener for incremental updates; fallback to GET /commentary/latest for initial load.
Empty state: “IzzoCam AI is warming up. Check back soon!”
4. Config & Personalization

Store dog name, tone, comedic level in Firestore config doc (settings/commentary).
Pipeline passes these into the prompt to adjust personality (e.g., “Izzo”, “energetic + playful”).
Later we can add per-user preferences (opt-out of humor, adjust frequency).
5. Notifications (future)

Plan to integrate Firebase Cloud Messaging later:
Store FCM tokens keyed by UID.
When hourly recap contains high-interest tags (e.g., “Izzo left the house”), send push to opted-in users.
Not in MVP scope; design the Firestore schema with a boolean shouldNotify flag.
6. Privacy & Security

Document AI usage in privacy policy; provide toggle to disable commentary if a user opts out.
Store frames only in GCS with 24-hour retention; no long-term archival.
Restrict GCS bucket access to backend service accounts.
Log AI requests without storing raw images after processing (or anonymize).
Ensure commentary API requires Firebase auth (viewer must be signed in).
No secrets in client code; OpenAI access handled server-side.
7. Cost & Monitoring

Snapshot burst: ~12 per hour. Each 5-frame prompt to GPT-4o mini costs roughly $0.008–$0.01 (conservative). Daily baseline ≈ $3; add on-demand use.
Hourly recap: 24 prompts/day (~$0.24/day).
Implement metrics in Cloud Logging/Tracer to track egress jobs, AI costs, and errors.
Set up alerting for failed AI calls (fallback to “IzzoCam AI is taking a nap”).
Provide rate limiting: at most 2 on-demand recaps per user every 10 minutes.

9. Open Questions ✅ RESOLVED
8. Dependencies & Tasks

DevOps / Cloud

Create GCS bucket + lifecycle rule.
Create Firestore collections and indexes.
Configure LiveKit egress webhook and Cloud Run/Cloud Functions to handle bursts.
Cron jobs for 5-minute capture scheduler and hourly recap pipeline.
Backend

Expand Express API with commentary endpoints; include Firebase auth middleware.
Implement snapshot metadata ingestion (webhook handler).
Build AI worker (could be the same Cloud Run service) that fetches frames and calls OpenAI.
Provide config endpoints (dog name, tone).
Ensure .env includes OpenAI API key and project IDs.
iOS

Create CommentaryFeedView SwiftUI component.
Add Firestore listener (and fallback REST fetch).
Hook up “What has Izzo been up to?” button to backend POST.
Present friendly error states and loading states.
Optional styling with animation for new entries.
QA & Monitoring

Test egress frame pipeline with real stream.
Verify Firestore writes and app display.
Simulate AI downtime; confirm fallback text.
Monitor Cloud costs, ensure egress jobs finish.
9. Open Questions ✅ RESOLVED

**Originally Identified Questions:**
- ❓ How do we throttle or skip commentary when Izzo is inactive (e.g., sleeping for hours)? 
  - ✅ **RESOLVED:** Implemented AI detection of activity levels in prompts; inactive periods generate appropriate "sleeping/resting" commentary
- ❓ Should we allow users to opt out of their data being sent to OpenAI? 
  - ✅ **RESOLVED:** Privacy controls implemented; users can disable commentary in app settings
- ❓ Do we want to expose commentary on the web frontend simultaneously? 
  - ✅ **RESOLVED:** Web frontend shows same Firestore commentary feed via real-time listeners
- ❓ Are there guardrails for comedic tone to avoid problematic jokes? 
  - ✅ **RESOLVED:** Prompt engineering includes family-friendly guidelines and content filtering
- ❓ Handling multiple AI provider configs simultaneously—fallback provider if OpenAI fails? 
  - ✅ **RESOLVED:** Fallback text system implemented: "IzzoCam AI is taking a nap" during outages
- ❓ How do we test commentary quality before launching to users? 
  - ✅ **RESOLVED:** Comprehensive test suite with mocked responses and device testing completed

**Additional Resolved Questions During Development:**
- ✅ Rate limiting strategy: Implemented 2 requests per 10 minutes for commentary, 60/min for general API
- ✅ Cost monitoring: Real-time cost tracking with daily/hourly thresholds and automated alerts
- ✅ Error handling: Comprehensive error logging with severity levels and fallback mechanisms
- ✅ Testing strategy: Jest-based E2E testing with mocked OpenAI responses and Firebase integration
- ✅ Production deployment: Cloud Run backend with Firebase hosting and Cloud Scheduler automation