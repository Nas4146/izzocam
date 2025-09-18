import { AccessToken } from 'livekit-server-sdk';
import { env } from '../env';

interface ViewerTokenOptions {
  identity: string;
  name?: string;
  metadata?: string;
}

export async function createViewerToken(options: ViewerTokenOptions) {
  const grant = {
    roomJoin: true,
    room: env.livekit.roomName,
    canPublish: false,
    canPublishData: false,
    canSubscribe: true,
  } as const;

  const token = new AccessToken(env.livekit.apiKey, env.livekit.apiSecret, {
    identity: options.identity,
    name: options.name,
    metadata: options.metadata,
  });

  token.addGrant(grant);

  return token.toJwt();
}

export const liveKitHost = env.livekit.host;
