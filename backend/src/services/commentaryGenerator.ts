import { differenceInMinutes, format } from 'date-fns';
import { env } from '../env';
import { generateSignedUrl } from './gcs';
import { getCommentaryConfig } from './commentaryConfig';
import type { CommentaryMode, CommentarySummary } from './commentaryStore';
import { addCommentaryEntry, getLatestEntryByMode } from './commentaryStore';
import { fetchSnapshotsBetween, fetchSnapshotsSince, SnapshotRecord } from './snapshotStore';
import { getOpenAIClient } from './openaiClient';
import { monitoring } from './monitoring';

interface GenerateOptions {
  mode: CommentaryMode;
  requesterId?: string;
  since?: Date;
}

interface CommentaryResult {
  summary: CommentarySummary;
  bursts: Array<{ burstId: string; capturedAt: Date; frameCount: number }>;
  timeframeStart: Date;
  timeframeEnd: Date;
}

const MAX_SNAPSHOTS = 50;
const MAX_IMAGES_FOR_PROMPT = 6;

export async function generateAndStoreCommentary(options: GenerateOptions) {
  const range = await resolveTimeframe(options);
  const snapshots = range.snapshots;

  if (snapshots.length === 0) {
    const summary: CommentarySummary = {
      title: 'Quiet hour at IzzoCam',
      body: "Izzo took it easy—no significant movement detected in the selected timeframe.",
      bulletPoints: ['No major activity detected.'],
      confidence: 'low',
      tags: ['idle'],
    };

    return addCommentaryEntry({
      mode: options.mode,
      timeframeStart: range.timeframeStart,
      timeframeEnd: range.timeframeEnd,
      summary,
      bursts: [],
      provider: {
        name: 'openai',
        model: env.openai.visionModel,
      },
      meta: {
        reason: 'no_snapshots',
        requesterId: options.requesterId ?? null,
      },
    });
  }

  const config = await getCommentaryConfig();
  const selectedFrames = await selectFramesForPrompt(snapshots);
  const prompt = buildUserPrompt(config, range.timeframeStart, range.timeframeEnd, snapshots.length);

  const openai = getOpenAIClient();
  const startTime = Date.now();

  try {
    const response = await openai.responses.create({
      model: env.openai.visionModel,
      input: [
        {
          role: 'system',
          content: [
            {
              type: 'input_text',
              text: `You are IzzoCam AI, a cheerful commentator describing the adventures of a dog named ${config.dogName}.` +
                ' Keep summaries informative, lightly comedic, and family-friendly. Always respond with compact JSON (no markdown).',
            },
          ],
        },
        {
          role: 'user',
          content: [
            { type: 'input_text', text: prompt },
            ...selectedFrames.map((frame) => ({
              type: 'input_image' as const,
              image_url: frame.signedUrl,
              detail: 'low' as const,
            })),
          ],
        },
      ],
    });

    const latency = Date.now() - startTime;
    const summary = parseResponse(response.output_text);

    // Log successful OpenAI usage
    await monitoring.logOpenAIUsage(
      options.mode === 'hourly' ? 'hourly_recap' : 'user_request',
      {
        prompt_tokens: Math.floor(prompt.length / 4), // Rough estimate
        completion_tokens: Math.floor(response.output_text.length / 4),
        total_tokens: Math.floor((prompt.length + response.output_text.length) / 4),
        model: env.openai.visionModel
      },
      options.requesterId
    );

    return addCommentaryEntry({
      mode: options.mode,
      timeframeStart: range.timeframeStart,
      timeframeEnd: range.timeframeEnd,
      summary,
      bursts: snapshots.map((snapshot) => ({
        burstId: snapshot.burstId,
        capturedAt: snapshot.capturedAt,
        frameCount: snapshot.frames.length,
      })),
      provider: {
        name: 'openai',
        model: env.openai.visionModel,
        latencyMs: latency,
      },
      meta: {
        requesterId: options.requesterId ?? null,
        snapshotCount: snapshots.length,
        selectedFrameCount: selectedFrames.length,
      },
    });
  } catch (error) {
    const latency = Date.now() - startTime;
    
    // Log failed OpenAI request
    await monitoring.logError({
      timestamp: new Date(),
      service: 'openai',
      operation: options.mode === 'hourly' ? 'hourly_recap' : 'user_request',
      userId: options.requesterId,
      error: error instanceof Error ? error.message : 'Unknown OpenAI error',
      severity: 'high'
    });

    throw error; // Re-throw to be handled by caller
  }
}

async function resolveTimeframe(options: GenerateOptions) {
  const end = new Date();
  let start = options.since ?? new Date(end.getTime() - 60 * 60 * 1000);
  let snapshots: SnapshotRecord[];

  if (options.mode === 'hourly') {
    start = new Date(end.getTime() - 60 * 60 * 1000);
    snapshots = await fetchSnapshotsBetween(start, end, MAX_SNAPSHOTS);
  } else {
    const latestHourly = await getLatestEntryByMode('hourly');
    if (latestHourly) {
      start = latestHourly.timeframeEnd;
    }
    snapshots = await fetchSnapshotsSince(start, MAX_SNAPSHOTS);
  }

  return {
    timeframeStart: start,
    timeframeEnd: end,
    snapshots,
  };
}

async function selectFramesForPrompt(snapshots: SnapshotRecord[]) {
  const frames: Array<{ signedUrl: string; capturedAt: Date }> = [];

  for (const snapshot of snapshots) {
    const frame = snapshot.frames[0];
    if (!frame) continue;
    const signedUrl = await generateSignedUrl(frame.storagePath, 300);
    frames.push({ signedUrl, capturedAt: snapshot.capturedAt });
    if (frames.length >= MAX_IMAGES_FOR_PROMPT) {
      break;
    }
  }

  return frames;
}

function buildUserPrompt(
  config: Awaited<ReturnType<typeof getCommentaryConfig>>,
  start: Date,
  end: Date,
  snapshotCount: number,
): string {
  const rangeText = `${format(start, 'MMM d, h:mm a')} to ${format(end, 'h:mm a')}`;
  const duration = differenceInMinutes(end, start);

  return [
    `You are observing ${config.dogName} at ${config.locationName}.`,
    `You will receive up to ${snapshotCount} photos captured over the last ${duration} minutes (${rangeText}).`,
    'Describe notable movements, interactions, or scenery changes.',
    'Keep tone ' + config.tone + ' with ' + config.comedicLevel + ' humor.',
    'Respond in JSON with keys: title, summary, bulletPoints (array), optional confidence (low/medium/high), optional tags (array).',
    'Avoid speculation beyond the images; note if activity is calm or unchanging.',
  ].join(' ');
}

function parseResponse(text?: string): CommentarySummary {
  if (!text) {
    return {
      title: 'Izzo update unavailable',
      body: 'IzzoCam AI could not generate a summary right now.',
      bulletPoints: ['Try again later for a fresh recap.'],
      confidence: 'low',
      tags: ['error'],
    };
  }

  try {
    const result = JSON.parse(text);
    return {
      title: result.title ?? 'Izzo update',
      body: result.summary ?? '',
      bulletPoints: Array.isArray(result.bulletPoints) ? result.bulletPoints : [],
      confidence: result.confidence ?? 'medium',
      tags: Array.isArray(result.tags) ? result.tags : [],
    };
  } catch (error) {
    console.warn('Failed to parse OpenAI commentary response', error, text);
    return {
      title: 'Izzo update',
      body: text,
      bulletPoints: [],
      confidence: 'low',
      tags: ['fallback'],
    };
  }
}
