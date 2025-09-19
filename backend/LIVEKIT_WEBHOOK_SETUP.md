# LiveKit Egress Webhook Configuration

## 🎯 Webhook URL Configuration

Configure your LiveKit Cloud project with the following webhook settings:

### **Webhook URL:**
```
https://izzocam.web.app/api/egress/snapshot?secret=izzocam-webhook-secret-2025
```

### **Webhook Secret:**
The secret is included in the URL as a query parameter since LiveKit doesn't support custom headers.

### **Alternative Authentication Methods:**
The webhook accepts the secret in multiple ways:
- **Query Parameter**: `?secret=izzocam-webhook-secret-2025` (recommended for LiveKit)
- **Request Header**: `x-webhook-secret: izzocam-webhook-secret-2025`
- **Request Body**: `{"secret": "izzocam-webhook-secret-2025", ...}`

## 🔧 LiveKit Cloud Setup

1. **Go to LiveKit Cloud Console**: https://cloud.livekit.io/
2. **Navigate to your project**: `izzocam-5u8a05zv`
3. **Go to Settings → Webhooks**
4. **Add New Webhook** with:
   - **URL**: `https://izzocam.web.app/api/egress/snapshot?secret=izzocam-webhook-secret-2025`
   - **Signing API Key**: `(anonymous)`
   - **Events**: Select "Egress" events

## 🛡️ Security Features

✅ **Webhook Secret Verification** - All requests must include the correct secret header
✅ **HTTPS Only** - Secure transmission via Firebase Hosting + Cloud Run
✅ **Input Validation** - Payload validation before processing
✅ **Error Handling** - Comprehensive error responses and logging

## 📊 Webhook Payload

The webhook expects snapshot payloads in this format:

```typescript
interface SnapshotPayload {
  burstId: string;           // Unique identifier for the snapshot burst
  capturedAt: string;        // ISO timestamp when captured
  frames: Array<{            // Array of frame data
    frameId?: string;        // Optional frame identifier
    data: string;            // Base64 encoded frame data
    mimeType: string;        // Frame MIME type (e.g., 'image/jpeg')
  }>;
  roomName?: string;         // LiveKit room name (defaults to 'izzocam')
  egressId?: string;         // LiveKit egress ID
}
```

## 🔍 Testing

Test the webhook endpoint:

```bash
# Test webhook authentication with query parameter
curl -X POST "https://izzocam.web.app/api/egress/snapshot?secret=izzocam-webhook-secret-2025" \
  -H "Content-Type: application/json" \
  -d '{"burstId":"test","capturedAt":"2025-09-18T20:00:00Z","frames":[]}'
```

## 📝 Monitoring

- **Logs**: Available in Google Cloud Console → Cloud Run → izzocam-backend
- **Metrics**: Monitor webhook success/failure rates
- **Storage**: Snapshots saved to `gs://izzocam-snapshots/`
- **Database**: Metadata stored in Firestore

## 🚨 Troubleshooting

- **401 Unauthorized**: Check webhook secret header
- **400 Bad Request**: Verify payload format matches interface
- **500 Internal Error**: Check Cloud Run logs for detailed errors

The webhook is now ready to receive LiveKit egress events! 🎉