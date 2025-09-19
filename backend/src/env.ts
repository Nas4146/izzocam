import { config } from 'dotenv';

config();

function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

export const env = {
  port: Number(process.env.PORT ?? 8080),
  firebase: {
    projectId: requireEnv('FIREBASE_PROJECT_ID'),
    clientEmail: requireEnv('FIREBASE_CLIENT_EMAIL'),
    privateKey: requireEnv('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n'),
  },
  livekit: {
    apiKey: requireEnv('LIVEKIT_API_KEY'),
    apiSecret: requireEnv('LIVEKIT_API_SECRET'),
    host: requireEnv('LIVEKIT_HOST'),
    roomName: process.env.LIVEKIT_ROOM_NAME ?? 'izzocam',
  },
  gcs: {
    snapshotsBucket: requireEnv('GCS_SNAPSHOTS_BUCKET'),
  },
  openai: {
    apiKey: requireEnv('OPENAI_API_KEY'),
    visionModel: process.env.OPENAI_VISION_MODEL ?? 'gpt-4o-mini',
    requestTimeoutMs: process.env.OPENAI_TIMEOUT_MS ? Number(process.env.OPENAI_TIMEOUT_MS) : 60_000,
  },
  corsOrigins: (process.env.CORS_ALLOWED_ORIGINS ?? '').split(',').map((origin) => origin.trim()).filter(Boolean),
};
