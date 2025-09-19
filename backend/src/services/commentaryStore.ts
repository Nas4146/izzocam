import { FieldValue } from 'firebase-admin/firestore';
import type { QueryDocumentSnapshot } from 'firebase-admin/firestore';
import { firestore } from './firebaseAdmin';

export type CommentaryMode = 'hourly' | 'adhoc';

export interface CommentaryEntryInput {
  mode: CommentaryMode;
  timeframeStart: Date;
  timeframeEnd: Date;
  summary: CommentarySummary;
  bursts: Array<{ burstId: string; capturedAt: Date; frameCount: number }>;
  provider: {
    name: string;
    model: string;
    latencyMs?: number;
  };
  meta?: Record<string, unknown>;
}

export interface CommentarySummary {
  title: string;
  body: string;
  bulletPoints: string[];
  confidence?: 'low' | 'medium' | 'high';
  tags?: string[];
}

export interface CommentaryEntry extends CommentaryEntryInput {
  id: string;
  createdAt: Date;
}

const COLLECTION = 'commentaryEntries';

export async function addCommentaryEntry(input: CommentaryEntryInput): Promise<CommentaryEntry> {
  const docRef = firestore.collection(COLLECTION).doc();
  const createdAt = new Date();

  await docRef.set({
    ...input,
    createdAt,
    timeframeStart: input.timeframeStart,
    timeframeEnd: input.timeframeEnd,
    summary: {
      ...input.summary,
      bulletPoints: input.summary.bulletPoints ?? [],
    },
    bursts: input.bursts,
    provider: input.provider,
    meta: input.meta ?? {},
    createdAtTimestamp: FieldValue.serverTimestamp(),
  });

  return {
    id: docRef.id,
    createdAt,
    ...input,
  };
}

export async function getLatestCommentary(limit = 20): Promise<CommentaryEntry[]> {
  const snapshot = await firestore
    .collection(COLLECTION)
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => mapDoc(doc));
}

export async function getLatestEntryByMode(mode: CommentaryMode): Promise<CommentaryEntry | null> {
  const snapshot = await firestore
    .collection(COLLECTION)
    .where('mode', '==', mode)
    .orderBy('createdAt', 'desc')
    .limit(1)
    .get();

  if (snapshot.empty) {
    return null;
  }

  return mapDoc(snapshot.docs[0]);
}

function mapDoc(doc: QueryDocumentSnapshot): CommentaryEntry {
  const data = doc.data();
  return {
    id: doc.id,
    mode: data.mode,
    timeframeStart: data.timeframeStart?.toDate?.() ?? new Date(0),
    timeframeEnd: data.timeframeEnd?.toDate?.() ?? new Date(0),
    summary: {
      title: data.summary?.title ?? 'Summary unavailable',
      body: data.summary?.body ?? '',
      bulletPoints: data.summary?.bulletPoints ?? [],
      confidence: data.summary?.confidence,
      tags: data.summary?.tags ?? [],
    },
    bursts: Array.isArray(data.bursts)
      ? data.bursts.map((burst: any) => ({
          burstId: burst?.burstId ?? 'unknown',
          capturedAt: burst?.capturedAt?.toDate?.() ?? new Date(0),
          frameCount: burst?.frameCount ?? 0,
        }))
      : [],
    provider: data.provider ?? { name: 'unknown', model: 'unknown' },
    meta: data.meta ?? {},
    createdAt: data.createdAt?.toDate?.() ?? new Date(0),
  };
}
