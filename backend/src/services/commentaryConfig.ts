import { firestore } from './firebaseAdmin';

export interface CommentaryConfig {
  dogName: string;
  locationName: string;
  tone: 'playful' | 'calm' | 'formal';
  comedicLevel: 'none' | 'light' | 'medium';
}

const DEFAULT_CONFIG: CommentaryConfig = {
  dogName: 'Izzo',
  locationName: 'home',
  tone: 'playful',
  comedicLevel: 'light',
};

const SETTINGS_COLLECTION = 'settings';
const DOCUMENT_ID = 'commentary';

let cachedConfig: CommentaryConfig | null = null;
let lastFetched: number | null = null;
const CACHE_TTL_MS = 5 * 60 * 1000;

export async function getCommentaryConfig(): Promise<CommentaryConfig> {
  const now = Date.now();
  if (cachedConfig && lastFetched && now - lastFetched < CACHE_TTL_MS) {
    return cachedConfig;
  }

  try {
    const doc = await firestore.collection(SETTINGS_COLLECTION).doc(DOCUMENT_ID).get();
    if (doc.exists) {
      const data = doc.data() ?? {};
      cachedConfig = {
        ...DEFAULT_CONFIG,
        ...data,
      } as CommentaryConfig;
      lastFetched = now;
      return cachedConfig;
    }
  } catch (error) {
    console.warn('Failed to fetch commentary config, using defaults', error);
  }

  cachedConfig = DEFAULT_CONFIG;
  lastFetched = now;
  return cachedConfig;
}

export async function updateCommentaryConfig(partial: Partial<CommentaryConfig>): Promise<void> {
  const docRef = firestore.collection(SETTINGS_COLLECTION).doc(DOCUMENT_ID);
  await docRef.set(partial, { merge: true });
  cachedConfig = null;
  lastFetched = null;
}
