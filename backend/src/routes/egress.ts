import { Router } from 'express';
import { uploadSnapshotFrame } from '../services/gcs';
import { saveSnapshotMetadata } from '../services/snapshotStore';

interface IncomingFrame {
  frameId?: string;
  data: string;
  mimeType: string;
}

interface SnapshotPayload {
  burstId: string;
  capturedAt: string;
  frames: IncomingFrame[];
  roomName?: string;
  egressId?: string;
}

const MAX_FRAMES_PER_BURST = 10;

export const egressRouter = Router();

egressRouter.post('/snapshot', async (req, res) => {
  // Verify webhook secret (check multiple sources)
  const headerSecret = req.headers['x-webhook-secret'] as string;
  const querySecret = req.query.secret as string;
  const bodySecret = req.body?.secret as string;
  const webhookSecret = headerSecret || querySecret || bodySecret;
  
  const expectedSecret = process.env.WEBHOOK_SECRET;
  
  if (!expectedSecret) {
    console.error('WEBHOOK_SECRET not configured');
    return res.status(500).json({ message: 'Webhook secret not configured' });
  }
  
  if (!webhookSecret || webhookSecret !== expectedSecret) {
    console.error('Invalid webhook secret, received:', webhookSecret ? '[REDACTED]' : 'undefined');
    return res.status(401).json({ message: 'Unauthorized' });
  }

  const payload = req.body as SnapshotPayload;

  if (!payload || typeof payload !== 'object') {
    return res.status(400).json({ message: 'Invalid payload' });
  }

  const { burstId, capturedAt, frames, roomName = 'izzocam', egressId } = payload;

  if (!burstId || typeof burstId !== 'string') {
    return res.status(400).json({ message: 'burstId is required' });
  }

  if (!capturedAt || typeof capturedAt !== 'string') {
    return res.status(400).json({ message: 'capturedAt is required' });
  }

  if (!Array.isArray(frames) || frames.length === 0) {
    return res.status(400).json({ message: 'frames array is required' });
  }

  if (frames.length > MAX_FRAMES_PER_BURST) {
    return res.status(400).json({ message: `frames array exceeds limit of ${MAX_FRAMES_PER_BURST}` });
  }

  const captureDate = new Date(capturedAt);
  if (Number.isNaN(captureDate.getTime())) {
    return res.status(400).json({ message: 'capturedAt must be a valid ISO timestamp' });
  }

  try {
    const uploadedFrames = [];

    for (let index = 0; index < frames.length; index += 1) {
      const frame = frames[index];
      if (!frame || typeof frame.data !== 'string' || typeof frame.mimeType !== 'string') {
        return res.status(400).json({ message: `frames[${index}] is invalid` });
      }

      const buffer = decodeFrameData(frame.data);
      const frameId = frame.frameId ?? `frame-${index + 1}`;

      const result = await uploadSnapshotFrame({
        burstId,
        frameId,
        buffer,
        mimeType: frame.mimeType,
        capturedAt: captureDate,
      });

      uploadedFrames.push({
        frameId,
        gcsUri: result.gcsUri,
        storagePath: result.publicPath,
        mimeType: frame.mimeType,
      });
    }

    await saveSnapshotMetadata({
      burstId,
      roomName,
      egressId,
      capturedAt: captureDate,
      frames: uploadedFrames,
      receivedAt: new Date(),
    });

    return res.status(201).json({
      burstId,
      frameCount: uploadedFrames.length,
      frames: uploadedFrames,
    });
  } catch (error) {
    console.error('Failed to process snapshot payload', error);
    return res.status(500).json({ message: 'Failed to process snapshot payload' });
  }
});

function decodeFrameData(data: string): Buffer {
  const base64Match = data.match(/^data:[^;]+;base64,(.*)$/);
  const base64Payload = base64Match ? base64Match[1] : data;
  return Buffer.from(base64Payload, 'base64');
}

export default egressRouter;
