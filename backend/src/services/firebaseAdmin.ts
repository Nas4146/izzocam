import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { env } from '../env';

const apps = getApps();

const app =
  apps.length > 0
    ? apps[0]
    : initializeApp({
        credential: cert({
          projectId: env.firebase.projectId,
          clientEmail: env.firebase.clientEmail,
          privateKey: env.firebase.privateKey,
        }),
      });

export const firebaseAuth = getAuth(app);
export const firestore = getFirestore(app);
