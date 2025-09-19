import { FieldValue } from 'firebase-admin/firestore';
import type { DocumentData } from 'firebase-admin/firestore';
import { firestore } from './firebaseAdmin';

export interface SnapshotMetadata {
  burstId: string;
  roomName: string;
  egressId?: string;
  capturedAt: Date;
  frames: Array<{
    frameId: string;
    gcsUri: string;
    storagePath: string;
    mimeType: string;
  }>;
  receivedAt: Date;
}

export async function saveSnapshotMetadata(metadata: SnapshotMetadata): Promise<void> {
  const docRef = firestore.collection('snapshots').doc(metadata.burstId);
  await docRef.set(
    {
      burstId: metadata.burstId,
      roomName: metadata.roomName,
      egressId: metadata.egressId ?? null,
      capturedAt: metadata.capturedAt,
      frames: metadata.frames,
      frameCount: metadata.frames.length,
      receivedAt: metadata.receivedAt,
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

export interface SnapshotRecord {
  burstId: string;
  roomName: string;
  egressId?: string;
  capturedAt: Date;
  frames: Array<{
    frameId: string;
    gcsUri: string;
    storagePath: string;
    mimeType: string;
  }>;
  receivedAt: Date;
}

function fromFirestore(data: DocumentData, docId: string): SnapshotRecord | null {
  if (!data) return null;
  return {
    burstId: data.burstId ?? docId,
    roomName: data.roomName ?? 'izzocam',
    egressId: data.egressId ?? undefined,
    capturedAt: data.capturedAt?.toDate?.() ?? new Date(0),
    frames: Array.isArray(data.frames)
      ? data.frames.map((frame: any) => ({
          frameId: frame?.frameId ?? 'frame',
          gcsUri: frame?.gcsUri ?? '',
          storagePath: frame?.storagePath ?? '',
          mimeType: frame?.mimeType ?? 'image/jpeg',
        }))
      : [],
    receivedAt: data.receivedAt?.toDate?.() ?? new Date(0),
  };
}

export async function fetchSnapshotsSince(start: Date, limit = 100): Promise<SnapshotRecord[]> {
  const snapshot = await firestore
    .collection('snapshots')
    .where('capturedAt', '>=', start)
    .orderBy('capturedAt', 'asc')
    .limit(limit)
    .get();

  return snapshot.docs
    .map((doc) => fromFirestore(doc.data(), doc.id))
    .filter((record): record is SnapshotRecord => Boolean(record));
}

export async function fetchSnapshotsBetween(start: Date, end: Date, limit = 200): Promise<SnapshotRecord[]> {
  const snapshot = await firestore
    .collection('snapshots')
    .where('capturedAt', '>=', start)
    .where('capturedAt', '<=', end)
    .orderBy('capturedAt', 'asc')
    .limit(limit)
    .get();

  return snapshot.docs
    .map((doc) => fromFirestore(doc.data(), doc.id))
    .filter((record): record is SnapshotRecord => Boolean(record));
}
