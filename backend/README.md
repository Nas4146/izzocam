# IzzoCam Backend

Express + TypeScript service that brokers Firebase authentication, LiveKit viewer tokens, and metrics for the IzzoCam frontend.

## Development

1. Copy `.env.example` to `.env` and fill in secrets.
2. Install dependencies: `npm install`
3. Start the development server: `npm run dev`
4. Once running, the API listens on `http://localhost:8080` by default.

### Required environment variables

| Name | Description |
| --- | --- |
| `PORT` | HTTP port (defaults to `8080`). |
| `FIREBASE_PROJECT_ID` | Firebase project ID. |
| `FIREBASE_CLIENT_EMAIL` | Service account client email. |
| `FIREBASE_PRIVATE_KEY` | Service account private key (use `\n` for newline escapes). |
| `LIVEKIT_API_KEY` | LiveKit API key. |
| `LIVEKIT_API_SECRET` | LiveKit API secret. |
| `LIVEKIT_HOST` | Websocket URL for LiveKit (e.g. `wss://example.livekit.cloud`). |
| `LIVEKIT_ROOM_NAME` | Room name for IzzoCam (defaults to `izzocam`). |
| `GCS_SNAPSHOTS_BUCKET` | Google Cloud Storage bucket for temporary snapshot frames. |
| `OPENAI_API_KEY` | OpenAI API key used for commentary generation. |
| `OPENAI_VISION_MODEL` | (Optional) OpenAI vision model name (default `gpt-4o-mini`). |
| `CORS_ALLOWED_ORIGINS` | Comma-delimited list of allowed origins (e.g. `https://izzo.cam,http://localhost:5173`). |

## Endpoints

- `POST /api/viewer-token` – Requires Firebase ID token. Returns LiveKit viewer token + server URL.
- `GET /api/metrics/viewers` – Requires Firebase ID token. Returns placeholder viewer metrics data; replace with LiveKit analytics pipeline later.
- `POST /api/egress/snapshot` – Internal webhook for LiveKit egress snapshots; persists frame metadata to Firestore and uploads frames to GCS.
- `GET /api/commentary/latest` – Returns latest commentary entries (hourly + ad-hoc) for authenticated viewers.
- `POST /api/commentary/request` – Authenticated viewers trigger an on-demand commentary recap.
- `POST /api/commentary/generate` – Authenticated manual trigger for hourly/adhoc generation (testing/admin).
- `GET /api/commentary/config` – Fetch configurable commentary settings (dog name, tone).
- `GET /healthz` – Liveness probe.

## Next steps

- Back `metrics` endpoint with real datastore/live telemetry.
- Add admin-only routes for stream controls (start/stop, health signals).
- Wire LiveKit webhooks to persist viewer counts and stream status.
