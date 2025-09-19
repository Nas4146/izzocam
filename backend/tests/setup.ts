// Test setup file for Jest
import { config } from 'dotenv';

// Load test environment variables
config({ path: '.env.test' });

// Set test environment
process.env.NODE_ENV = 'test';
process.env.FIREBASE_PROJECT_ID = 'test-project';
process.env.OPENAI_API_KEY = 'test-key';

// Mock console methods in tests to reduce noise
global.console = {
  ...console,
  // Uncomment to suppress logs in tests
  // log: jest.fn(),
  // info: jest.fn(),
  // warn: jest.fn(),
  // error: jest.fn(),
};