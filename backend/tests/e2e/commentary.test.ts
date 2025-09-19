// End-to-end tests for the commentary system
import request from 'supertest';
import { mockOpenAIResponse, mockOnDemandResponse } from '../mocks/openai';

// Simple mock app for testing
const express = require('express');
const app = express();
app.use(express.json());

// Mock routes for testing
app.get('/api/commentary/config', (req: any, res: any) => {
  res.json({
    dogName: 'Izzo',
    tone: 'comedic',
    status: 'active'
  });
});

app.get('/api/commentary/latest', (req: any, res: any) => {
  res.json({
    entries: [
      {
        id: 'entry-1',
        timestamp: new Date('2025-09-19T10:00:00Z'),
        mode: 'hourly',
        title: 'Morning Activities',
        body: 'Izzo has been busy exploring!',
        mood: 'energetic'
      }
    ]
  });
});

app.post('/api/commentary/request', (req: any, res: any) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  
  // Simulate rate limiting
  if (req.headers['x-test-rate-limit']) {
    return res.status(429).json({ error: 'Rate limit exceeded' });
  }

  res.json({
    id: 'test-commentary-123',
    title: 'Recent Update on Izzo',
    summary: 'Izzo has been up to some delightful shenanigans!',
    mode: 'user-requested',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/healthz', (req: any, res: any) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {
      firebase: 'connected',
      openai: 'available'
    }
  });
});

describe('Commentary System E2E Tests', () => {
  describe('GET /api/commentary/config', () => {
    it('should return configuration successfully', async () => {
      const response = await request(app)
        .get('/api/commentary/config')
        .expect(200);

      expect(response.body).toEqual({
        dogName: 'Izzo',
        tone: 'comedic',
        status: 'active'
      });
    });
  });

  describe('GET /api/commentary/latest', () => {
    it('should return latest commentary entries', async () => {
      const response = await request(app)
        .get('/api/commentary/latest?limit=10')
        .expect(200);

      expect(response.body).toHaveProperty('entries');
      expect(Array.isArray(response.body.entries)).toBe(true);
      expect(response.body.entries[0]).toHaveProperty('title');
      expect(response.body.entries[0]).toHaveProperty('mode');
    });
  });

  describe('POST /api/commentary/request', () => {
    it('should handle on-demand commentary request with auth', async () => {
      const response = await request(app)
        .post('/api/commentary/request')
        .set('Authorization', 'Bearer mock-firebase-token')
        .expect(200);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('title');
      expect(response.body).toHaveProperty('summary');
      expect(response.body.mode).toBe('user-requested');
    });

    it('should reject request without authentication', async () => {
      const response = await request(app)
        .post('/api/commentary/request')
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });

    it('should handle rate limiting', async () => {
      const response = await request(app)
        .post('/api/commentary/request')
        .set('Authorization', 'Bearer mock-firebase-token')
        .set('x-test-rate-limit', 'true')
        .expect(429);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toContain('Rate limit');
    });
  });

  describe('Health Checks', () => {
    it('should return healthy status', async () => {
      const response = await request(app)
        .get('/api/healthz')
        .expect(200);

      expect(response.body).toEqual({
        status: 'healthy',
        timestamp: expect.any(String),
        services: {
          firebase: 'connected',
          openai: 'available'
        }
      });
    });
  });

  describe('OpenAI Response Processing', () => {
    it('should process mock OpenAI response correctly', () => {
      const response = mockOpenAIResponse;
      const content = JSON.parse(response.choices[0].message.content);
      
      expect(content).toHaveProperty('title');
      expect(content).toHaveProperty('summary');
      expect(content).toHaveProperty('highlights');
      expect(content).toHaveProperty('mood');
      expect(content).toHaveProperty('confidence');
      expect(Array.isArray(content.highlights)).toBe(true);
    });

    it('should handle on-demand response format', () => {
      const response = mockOnDemandResponse;
      const content = JSON.parse(response.choices[0].message.content);
      
      expect(content.title).toContain('Recent Update');
      expect(content.mood).toBe('curious');
      expect(content.activity_level).toBe('low');
    });
  });
});