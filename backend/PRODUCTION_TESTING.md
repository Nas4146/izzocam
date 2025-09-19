# 🧪 IzzoCam Production Testing Guide

## 🏁 **Quick Health Check**
```bash
# Test basic connectivity and health
curl https://izzocam.web.app/api/healthz
```
Expected: `{"status":"ok","uptime":<seconds>}`

---

## 🔐 **Authentication & LiveKit Integration**

### 1. Test Viewer Token Generation
```bash
# This requires Firebase authentication, so test from your iOS app or web client
# The endpoint is: POST /api/viewer-token
# Expected: Returns LiveKit access token for joining rooms
```

### 2. Test LiveKit Configuration
```bash
# Verify LiveKit connection details
echo "LiveKit URL: wss://izzocam-5u8a05zv.livekit.cloud"
echo "Room Name: izzocam"
```

---

## 📸 **Egress Webhook Testing**

### 1. Test Webhook Authentication
```bash
# Should be REJECTED (no secret)
curl -X POST "https://izzocam.web.app/api/egress/snapshot" \
  -H "Content-Type: application/json" \
  -d '{"test": "payload"}'
```
Expected: `{"message":"Unauthorized"}`

```bash
# Should be ACCEPTED (with secret)
curl -X POST "https://izzocam.web.app/api/egress/snapshot?secret=izzocam-webhook-secret-2025" \
  -H "Content-Type: application/json" \
  -d '{"burstId":"test","capturedAt":"2025-09-19T15:00:00Z","frames":[]}'
```
Expected: `{"message":"frames array is required"}` (authentication passed, validation failed as expected)

### 2. Test Full Webhook Payload
```bash
curl -X POST "https://izzocam.web.app/api/egress/snapshot?secret=izzocam-webhook-secret-2025" \
  -H "Content-Type: application/json" \
  -d '{
    "burstId": "test-burst-$(date +%s)",
    "capturedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "roomName": "izzocam",
    "frames": [{
      "frameId": "test-frame-1",
      "data": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/wAA/9k=",
      "mimeType": "image/jpeg"
    }]
  }'
```

### 3. Verify Cloud Storage Upload
```bash
# Check if snapshots are being stored
gsutil ls gs://izzocam-snapshots/
```

---

## 🤖 **Commentary & AI Integration**

### 1. Test Commentary Generation (Requires Authentication)
```bash
# This requires Firebase auth token - test from your iOS app
# POST /api/commentary/generate
# Expected: Generates AI commentary using OpenAI
```

### 2. Test Commentary Retrieval (Requires Authentication)
```bash
# This requires Firebase auth token - test from your iOS app  
# GET /api/commentary/latest
# Expected: Returns recent commentary entries
```

---

## 🔄 **LiveKit Egress Integration Test**

### **Manual LiveKit Test:**
1. **Start a stream** in your iOS app
2. **Trigger egress recording** in LiveKit Console
3. **Check webhook receives data:**
   - Monitor Cloud Run logs: `gcloud logs read --resource=cloud_run_revision --log-filter="severity>=INFO"`
   - Verify frames uploaded to GCS: `gsutil ls gs://izzocam-snapshots/`
   - Check Firestore for metadata

### **LiveKit Webhook Configuration:**
- **URL**: `https://izzocam.web.app/api/egress/snapshot?secret=izzocam-webhook-secret-2025`
- **Events**: Egress events enabled
- **Signing**: (anonymous)

---

## 📊 **Infrastructure Verification**

### 1. Firebase Hosting
```bash
# Test routing to Cloud Run
curl https://izzocam.web.app/api/healthz
```

### 2. Cloud Run Status
```bash
# Check service status
gcloud run services describe izzocam-backend --region=us-central1
```

### 3. Cloud Storage Access
```bash
# Verify bucket permissions
gsutil ls gs://izzocam-snapshots/
```

### 4. Firestore Access
```bash
# Check from Cloud Console or app - stores commentary and snapshot metadata
```

---

## 🎯 **iOS App Integration Tests**

### Update your iOS app to test:

1. **Backend URL**: Should now use `https://izzocam.web.app/api`
2. **Authentication**: Test Firebase auth → viewer token flow  
3. **Live Streaming**: Connect to LiveKit and verify video works
4. **Commentary**: Test AI commentary generation and retrieval

---

## ⚠️ **Troubleshooting**

### Check Logs:
```bash
# Cloud Run logs
gcloud logs read --resource=cloud_run_revision --log-filter="resource.labels.service_name=izzocam-backend"

# Firebase Hosting logs (in Firebase Console)
```

### Common Issues:
- **401 Unauthorized**: Check Firebase auth tokens
- **CORS errors**: Verify CORS_ALLOWED_ORIGINS includes your domain
- **Webhook failures**: Verify secret in URL query parameter
- **Storage errors**: Check IAM permissions for Cloud Run service account

---

## ✅ **Success Criteria**

- [ ] Health check returns OK
- [ ] Webhook rejects unauthorized requests
- [ ] Webhook accepts requests with correct secret
- [ ] Frames can be uploaded to Cloud Storage
- [ ] LiveKit integration works end-to-end
- [ ] iOS app connects successfully to production backend
- [ ] Commentary generation works with OpenAI
- [ ] All logs show no critical errors

🎉 **Your IzzoCam platform is production-ready!**