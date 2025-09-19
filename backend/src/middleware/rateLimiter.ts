// Rate limiting middleware for API endpoints
import { Request, Response, NextFunction } from 'express';

// Extend Request type to include user from Firebase auth
declare global {
  namespace Express {
    interface Request {
      user?: {
        uid: string;
        email?: string;
      };
    }
  }
}

interface RateLimitStore {
  [key: string]: {
    count: number;
    resetTime: number;
  };
}

class RateLimiter {
  private store: RateLimitStore = {};
  private windowMs: number;
  private maxRequests: number;

  constructor(windowMs: number, maxRequests: number) {
    this.windowMs = windowMs;
    this.maxRequests = maxRequests;
    
    // Clean up expired entries every 5 minutes
    setInterval(() => this.cleanup(), 5 * 60 * 1000);
  }

  private cleanup() {
    const now = Date.now();
    for (const key in this.store) {
      if (this.store[key].resetTime <= now) {
        delete this.store[key];
      }
    }
  }

  middleware = (req: Request, res: Response, next: NextFunction) => {
    const key = this.getKey(req);
    const now = Date.now();
    
    if (!this.store[key] || this.store[key].resetTime <= now) {
      this.store[key] = {
        count: 1,
        resetTime: now + this.windowMs
      };
      return next();
    }

    if (this.store[key].count >= this.maxRequests) {
      const timeUntilReset = Math.ceil((this.store[key].resetTime - now) / 1000);
      
      // Log rate limit exceeded
      console.warn(`[RateLimit] Rate limit exceeded for ${key}. Reset in ${timeUntilReset}s`);
      
      return res.status(429).json({
        error: 'Rate limit exceeded',
        message: `Too many requests. Try again in ${timeUntilReset} seconds.`,
        retryAfter: timeUntilReset
      });
    }

    this.store[key].count++;
    next();
  };

  private getKey(req: Request): string {
    // Use user ID if authenticated, otherwise IP address
    const uid = req.user?.uid;
    const ip = req.ip || req.connection.remoteAddress || 'unknown';
    return uid ? `user:${uid}` : `ip:${ip}`;
  }

  // Get current usage for monitoring
  getUsage(key: string) {
    return this.store[key] || { count: 0, resetTime: 0 };
  }
}

// Different rate limiters for different endpoints
export const commentaryRequestLimiter = new RateLimiter(
  10 * 60 * 1000, // 10 minutes
  2 // 2 requests per 10 minutes
);

export const generalApiLimiter = new RateLimiter(
  60 * 1000, // 1 minute
  60 // 60 requests per minute
);

export const configLimiter = new RateLimiter(
  60 * 1000, // 1 minute
  10 // 10 requests per minute
);