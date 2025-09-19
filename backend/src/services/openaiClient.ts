import OpenAI from 'openai';
import { env } from '../env';

let client: OpenAI | null = null;

export function getOpenAIClient(): OpenAI {
  if (!client) {
    client = new OpenAI({
      apiKey: env.openai.apiKey,
      timeout: env.openai.requestTimeoutMs,
    });
  }
  return client;
}
