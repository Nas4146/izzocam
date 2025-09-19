// Monitoring and metrics routes
import { Router, Request, Response } from 'express';
import { monitoring } from '../services/monitoring';
import { commentaryRequestLimiter } from '../middleware/rateLimiter';

const router = Router();

// Get system health and monitoring status
router.get('/health', async (req: Request, res: Response) => {
  try {
    const [usageSummary, errorSummary] = await Promise.all([
      monitoring.getUsageSummary(),
      monitoring.getErrorSummary()
    ]);

    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      services: {
        firebase: usageSummary ? 'connected' : 'error',
        monitoring: 'active'
      },
      usage: usageSummary,
      errors: errorSummary
    };

    // Check if error rate is too high
    if (errorSummary && errorSummary.totalErrors > 50) {
      health.status = 'degraded';
    }

    res.json(health);
  } catch (error) {
    console.error('[Monitoring] Health check failed:', error);
    res.status(500).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: 'Health check failed'
    });
  }
});

// Get detailed usage metrics (admin only)
router.get('/usage', async (req: Request, res: Response) => {
  try {
    const summary = await monitoring.getUsageSummary();
    if (!summary) {
      return res.status(500).json({ error: 'Failed to retrieve usage metrics' });
    }

    res.json({
      summary,
      timestamp: new Date().toISOString(),
      period: '24 hours'
    });
  } catch (error) {
    console.error('[Monitoring] Usage metrics failed:', error);
    res.status(500).json({ error: 'Failed to retrieve usage metrics' });
  }
});

// Get error metrics (admin only)
router.get('/errors', async (req: Request, res: Response) => {
  try {
    const summary = await monitoring.getErrorSummary();
    if (!summary) {
      return res.status(500).json({ error: 'Failed to retrieve error metrics' });
    }

    res.json({
      summary,
      timestamp: new Date().toISOString(),
      period: '24 hours'
    });
  } catch (error) {
    console.error('[Monitoring] Error metrics failed:', error);
    res.status(500).json({ error: 'Failed to retrieve error metrics' });
  }
});

// Trigger cost alert check (admin only)
router.post('/check-costs', async (req: Request, res: Response) => {
  try {
    await monitoring.checkCostAlerts();
    res.json({
      success: true,
      message: 'Cost alert check completed',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('[Monitoring] Cost check failed:', error);
    res.status(500).json({ error: 'Cost check failed' });
  }
});

// Get rate limiter status
router.get('/rate-limits', (req: Request, res: Response) => {
  const userKey = req.user?.uid ? `user:${req.user.uid}` : `ip:${req.ip}`;
  
  const commentaryUsage = commentaryRequestLimiter.getUsage(userKey);
  
  res.json({
    user: userKey,
    limits: {
      commentary: {
        current: commentaryUsage.count,
        max: 2,
        resetTime: new Date(commentaryUsage.resetTime).toISOString(),
        window: '10 minutes'
      }
    },
    timestamp: new Date().toISOString()
  });
});

export default router;