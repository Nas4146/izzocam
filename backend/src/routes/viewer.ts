import { Router } from 'express';
import type { AuthenticatedRequest } from '../middleware/authenticate';
import { authenticate } from '../middleware/authenticate';
import { createViewerToken, liveKitHost } from '../services/livekit';

const router = Router();

router.post('/viewer-token', authenticate, async (req, res) => {
  const { user } = req as AuthenticatedRequest;

  if (!user) {
    return res.status(401).json({ message: 'Unauthenticated request' });
  }

  try {
    const token = await createViewerToken({
      identity: user.uid,
      name: user.name ?? user.email ?? user.uid,
      metadata: JSON.stringify({
        email: user.email,
        picture: user.picture,
        roles: user.firebase.sign_in_provider,
      }),
    });

    res.json({
      token,
      liveKitUrl: liveKitHost,
    });
  } catch (error) {
    console.error('Failed to generate LiveKit token', error);
    res.status(500).json({ message: 'Unable to create viewer token' });
  }
});

router.get('/metrics/viewers', authenticate, (req, res) => {
  const { user } = req as AuthenticatedRequest;

  if (!user) {
    return res.status(401).json({ message: 'Unauthenticated request' });
  }

  res.json({
    currentViewers: 0,
    peakToday: 0,
    totalSessions: 0,
    lastUpdated: new Date().toISOString(),
    streamStatus: 'online',
  });
});

export const viewerRouter = router;
