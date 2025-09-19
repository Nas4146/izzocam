import { createApp } from './app';
import { env } from './env';

export const app = createApp();

if (require.main === module) {
  app.listen(env.port, () => {
    console.log(`IzzoCam backend listening on port ${env.port}`);
  });
}
