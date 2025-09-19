// Mock OpenAI responses for testing
export const mockOpenAIResponse = {
  id: 'chatcmpl-test123',
  object: 'chat.completion',
  created: 1695115200,
  model: 'gpt-4o-mini',
  choices: [
    {
      index: 0,
      message: {
        role: 'assistant',
        content: JSON.stringify({
          title: "Izzo's Morning Adventures",
          summary: "Izzo has been quite the busy pup this hour! Our furry friend started by doing some serious couch surveillance, keeping watch for any suspicious squirrel activity.",
          highlights: [
            '🐕 Performed expert-level couch security patrol',
            '🧸 Engaged in intense toy reorganization project',
            '💤 Mastered the art of strategic napping positions'
          ],
          mood: 'energetic',
          activity_level: 'moderate',
          confidence: 0.85
        })
      },
      logprobs: null,
      finish_reason: 'stop'
    }
  ],
  usage: {
    prompt_tokens: 150,
    completion_tokens: 85,
    total_tokens: 235
  }
};

export const mockOnDemandResponse = {
  id: 'chatcmpl-ondemand456',
  object: 'chat.completion',
  created: 1695115800,
  model: 'gpt-4o-mini',
  choices: [
    {
      index: 0,
      message: {
        role: 'assistant',
        content: JSON.stringify({
          title: 'Recent Update on Izzo',
          summary: 'Since the last recap, Izzo has been up to some delightful shenanigans! The pup discovered a new favorite spot by the window and has been conducting important bird-watching research.',
          highlights: [
            '🪟 Established new bird surveillance headquarters',
            '🎾 Successfully relocated three tennis balls to strategic positions',
            '👀 Maintained vigilant guard duty for approximately 12 minutes'
          ],
          mood: 'curious',
          activity_level: 'low',
          confidence: 0.78
        })
      },
      logprobs: null,
      finish_reason: 'stop'
    }
  ],
  usage: {
    prompt_tokens: 200,
    completion_tokens: 95,
    total_tokens: 295
  }
};

export const mockErrorResponse = {
  error: {
    message: 'Rate limit exceeded',
    type: 'rate_limit_error',
    param: null,
    code: 'rate_limit_exceeded'
  }
};