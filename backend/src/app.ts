import cors from 'cors';
import express, { type NextFunction, type Request, type Response } from 'express';
import { env } from './env';
import { commentaryRouter } from './routes/commentary';
import { cronRouter } from './routes/cron';
import { egressRouter } from './routes/egress';
import { viewerRouter } from './routes/viewer';
import monitoringRouter from './routes/monitoring';

export function createApp() {
  const app = express();

  const corsOrigins = env.corsOrigins.length > 0 ? env.corsOrigins : undefined;

  app.use(
    cors({
      origin: corsOrigins,
      credentials: true,
    }),
  );

  app.use(express.json({ limit: '25mb' }));
  app.use(express.urlencoded({ extended: true, limit: '25mb' }));

  app.use('/api', viewerRouter);
  app.use('/api/egress', egressRouter);
  app.use('/api/commentary', commentaryRouter);
  app.use('/api/cron', cronRouter);
  app.use('/api/monitoring', monitoringRouter);

  // Add healthz endpoint under /api path as well
  app.get('/api/healthz', (_req, res) => {
    res.json({ status: 'ok', uptime: process.uptime() });
  });

  app.get('/healthz', (_req, res) => {
    res.json({ status: 'ok', uptime: process.uptime() });
  });

  app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
    console.error('Unhandled error', err);
    res.status(500).json({ message: 'Unexpected server error' });
  });

  return app;
}
