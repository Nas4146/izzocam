import { Router } from 'express';
import { authenticate, type AuthenticatedRequest } from '../middleware/authenticate';
import { commentaryRequestLimiter, configLimiter } from '../middleware/rateLimiter';
import { monitoring } from '../services/monitoring';
import { getCommentaryConfig } from '../services/commentaryConfig';
import {
  addCommentaryEntry,
  getLatestCommentary,
  getLatestEntryByMode,
  type CommentaryEntry,
  type CommentaryMode,
} from '../services/commentaryStore';
import { generateAndStoreCommentary } from '../services/commentaryGenerator';

export const commentaryRouter = Router();

commentaryRouter.get('/latest', authenticate, async (req, res) => {
  const startTime = Date.now();
  const limit = Math.min(Number((req.query.limit as string) ?? 20), 100);
  
  try {
    const entries = await getLatestCommentary(limit);
    const duration = Date.now() - startTime;
    
    // Log successful Firebase operation
    await monitoring.logFirebaseUsage('get_latest_commentary', true, duration, req.user?.uid);
    
    res.json(entries.map(serialiseEntry));
  } catch (error) {
    const duration = Date.now() - startTime;
    
    // Log failed operation
    await monitoring.logFirebaseUsage('get_latest_commentary', false, duration, req.user?.uid);
    await monitoring.logError({
      timestamp: new Date(),
      service: 'commentary',
      operation: 'get_latest',
      userId: req.user?.uid,
      error: error instanceof Error ? error.message : 'Unknown error',
      severity: 'medium'
    });
    
    console.error('Failed to get latest commentary:', error);
    res.status(500).json({ error: 'Failed to retrieve commentary' });
  }
});

commentaryRouter.post('/request', authenticate, commentaryRequestLimiter.middleware, async (req, res) => {
  const authed = req as AuthenticatedRequest;
  const userId = authed.user?.uid ?? 'anonymous';
  const startTime = Date.now();

  try {
    const entry = await generateAndStoreCommentary({ mode: 'adhoc', requesterId: userId });
    const duration = Date.now() - startTime;
    
    // Log successful operation
    await monitoring.logUsage({
      timestamp: new Date(),
      service: 'commentary',
      operation: 'user_request',
      userId,
      success: true,
      duration
    });
    
    res.status(201).json(serialiseEntry(entry));
  } catch (error) {
    const duration = Date.now() - startTime;
    
    // Log failed operation
    await monitoring.logError({
      timestamp: new Date(),
      service: 'commentary',
      operation: 'user_request',
      userId,
      error: error instanceof Error ? error.message : 'Unknown error',
      severity: 'high'
    });
    
    console.error('Failed to generate on-demand commentary', error);
    res.status(500).json({ message: 'Unable to generate commentary at this time.' });
  }
});

commentaryRouter.post('/generate', authenticate, async (req, res) => {
  const authed = req as AuthenticatedRequest;
  const body = (req.body ?? {}) as { mode?: CommentaryMode };
  const mode = body.mode ?? 'hourly';
  if (!['hourly', 'adhoc'].includes(mode)) {
    return res.status(400).json({ message: 'mode must be "hourly" or "adhoc"' });
  }

  try {
    const entry = await generateAndStoreCommentary({
      mode,
      requesterId: authed.user?.uid ?? 'manual-trigger',
    });
    res.status(201).json(serialiseEntry(entry));
  } catch (error) {
    console.error('Failed to generate commentary via manual trigger', error);
    res.status(500).json({ message: 'Unable to generate commentary right now.' });
  }
});

commentaryRouter.get('/config', configLimiter.middleware, async (req, res) => {
  const startTime = Date.now();
  
  try {
    const config = await getCommentaryConfig();
    const duration = Date.now() - startTime;
    
    // Log successful Firebase operation
    await monitoring.logFirebaseUsage('get_config', true, duration, req.user?.uid);
    
    // Add system status for UI feedback
    const systemStatus = {
      commentaryEnabled: true, // Could be made configurable later
      lastSuccessfulRecap: null, // Could track last successful generation
    };
    
    res.json({
      ...config,
      systemStatus
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    
    // Log failed operation
    await monitoring.logFirebaseUsage('get_config', false, duration, req.user?.uid);
    await monitoring.logError({
      timestamp: new Date(),
      service: 'commentary',
      operation: 'get_config',
      userId: req.user?.uid,
      error: error instanceof Error ? error.message : 'Unknown error',
      severity: 'medium'
    });
    
    console.error('Failed to get commentary config:', error);
    res.status(500).json({ 
      message: 'Unable to load configuration',
      systemStatus: {
        commentaryEnabled: false,
        lastSuccessfulRecap: null
      }
    });
  }
});

commentaryRouter.get('/latest/hourly', authenticate, async (_req, res) => {
  const latest = await getLatestEntryByMode('hourly');
  if (!latest) {
    return res.status(404).json({ message: 'No hourly commentary available yet.' });
  }
  res.json(serialiseEntry(latest));
});

function serialiseEntry(entry: CommentaryEntry) {
  return {
    id: entry.id,
    mode: entry.mode,
    summary: entry.summary,
    bursts: entry.bursts,
    provider: entry.provider,
    meta: entry.meta ?? {},
    timeframeStart: entry.timeframeStart,
    timeframeEnd: entry.timeframeEnd,
    createdAt: entry.createdAt,
  };
}
