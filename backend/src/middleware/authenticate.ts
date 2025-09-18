import type { RequestHandler } from 'express';
import type { DecodedIdToken } from 'firebase-admin/auth';
import { firebaseAuth } from '../services/firebaseAdmin';

export interface AuthenticatedRequest extends Express.Request {
  user?: DecodedIdToken;
}

export const authenticate: RequestHandler = async (req, res, next) => {
  const authorization = req.headers.authorization;

  if (!authorization?.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Missing or invalid Authorization header' });
  }

  const idToken = authorization.slice('Bearer '.length);

  try {
    const decoded = await firebaseAuth.verifyIdToken(idToken);
    (req as AuthenticatedRequest).user = decoded;
    return next();
  } catch (error) {
    console.error('Failed to verify Firebase ID token', error);
    return res.status(401).json({ message: 'Invalid credentials' });
  }
};
