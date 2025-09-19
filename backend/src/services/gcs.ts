import { Storage } from '@google-cloud/storage';
import { env } from '../env';

const storage = new Storage({
  projectId: env.firebase.projectId,
  credentials: {
    client_email: env.firebase.clientEmail,
    private_key: env.firebase.privateKey,
  },
});

const snapshotsBucket = storage.bucket(env.gcs.snapshotsBucket);

export interface SnapshotFrameUpload {
  burstId: string;
  frameId: string;
  buffer: Buffer;
  mimeType: string;
  capturedAt: Date;
}

export interface SnapshotUploadResult {
  gcsUri: string;
  publicPath: string;
}

function sanitize(segment: string): string {
  return segment.replace(/[^a-zA-Z0-9-_]/g, '_');
}

export async function uploadSnapshotFrame({
  burstId,
  frameId,
  buffer,
  mimeType,
  capturedAt,
}: SnapshotFrameUpload): Promise<SnapshotUploadResult> {
  const datePrefix = capturedAt.toISOString().split('T')[0];
  const safeBurst = sanitize(burstId);
  const safeFrame = sanitize(frameId);

  const extension = mimeType.split('/')[1] ?? 'jpg';
  const objectPath = `snapshots/${datePrefix}/${safeBurst}/${safeFrame}.${extension}`;
  const file = snapshotsBucket.file(objectPath);

  await file.save(buffer, {
    metadata: {
      contentType: mimeType,
    },
  });

  return {
    gcsUri: `gs://${env.gcs.snapshotsBucket}/${objectPath}`,
    publicPath: objectPath,
  };
}

export async function generateSignedUrl(objectPath: string, expiresSeconds = 300): Promise<string> {
  const expirationDate = Date.now() + expiresSeconds * 1000;
  const [url] = await snapshotsBucket.file(objectPath).getSignedUrl({
    action: 'read',
    expires: expirationDate,
  });
  return url;
}
