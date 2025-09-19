import { Router } from 'express';
import { SnapshotCaptureService } from '../services/snapshotCapture';
import { HourlyRecapService } from '../services/hourlyRecap';
import { monitoring } from '../services/monitoring';

export const cronRouter = Router();

// 5-minute snapshot capture job
cronRouter.post('/capture-snapshots', async (req, res) => {
  const authHeader = req.header('X-Cloudscheduler');
  if (!authHeader) {
    return res.status(401).json({ message: 'Unauthorized: Missing Cloud Scheduler header' });
  }

  try {
    console.log('Starting scheduled snapshot capture...');
    const captureService = new SnapshotCaptureService();
    const burstId = await captureService.triggerSnapshotCapture();
    
    res.json({
      success: true,
      burstId,
      timestamp: new Date().toISOString(),
      message: 'Snapshot capture triggered successfully'
    });
  } catch (error) {
    console.error('Scheduled snapshot capture failed:', error);
    res.status(500).json({
      success: false,
      message: 'Snapshot capture failed',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Hourly recap generation job
cronRouter.post('/generate-recap', async (req, res) => {
  const authHeader = req.header('X-Cloudscheduler');
  if (!authHeader) {
    return res.status(401).json({ message: 'Unauthorized: Missing Cloud Scheduler header' });
  }

  try {
    console.log('Starting scheduled hourly recap generation...');
    const recapService = new HourlyRecapService();
    await recapService.generateHourlyRecap();
    
    res.json({
      success: true,
      timestamp: new Date().toISOString(),
      message: 'Hourly recap generated successfully'
    });
  } catch (error) {
    console.error('Scheduled hourly recap generation failed:', error);
    res.status(500).json({
      success: false,
      message: 'Hourly recap generation failed',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Health check for cron jobs
cronRouter.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'cron-jobs',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Cost monitoring cron job - runs every hour
cronRouter.post('/monitor-costs', async (req, res) => {
  const authHeader = req.header('X-Cloudscheduler');
  if (!authHeader) {
    return res.status(401).json({ message: 'Unauthorized: Missing Cloud Scheduler header' });
  }

  try {
    console.log('Starting cost monitoring check...');
    await monitoring.checkCostAlerts();
    
    res.json({
      success: true,
      timestamp: new Date().toISOString(),
      message: 'Cost monitoring check completed'
    });
  } catch (error) {
    console.error('Cost monitoring check failed:', error);
    res.status(500).json({
      success: false,
      message: 'Cost monitoring failed',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});