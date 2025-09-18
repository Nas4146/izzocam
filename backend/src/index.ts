import cors from 'cors';
import express, { type NextFunction, type Request, type Response } from 'express';
import { env } from './env';
import { viewerRouter } from './routes/viewer';

const app = express();

const corsOrigins = env.corsOrigins.length > 0 ? env.corsOrigins : undefined;

app.use(
  cors({
    origin: corsOrigins,
    credentials: true,
  }),
);
app.use(express.json());

app.get('/healthz', (_req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

app.use('/api', viewerRouter);

app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error('Unhandled error', err);
  res.status(500).json({ message: 'Unexpected server error' });
});

app.listen(env.port, () => {
  console.log(`IzzoCam backend listening on port ${env.port}`);
});
