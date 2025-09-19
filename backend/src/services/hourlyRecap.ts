import { firestore } from './firebaseAdmin';
import { generateAndStoreCommentary } from './commentaryGenerator';

export class HourlyRecapService {
  /**
   * Runs the hourly recap process:
   * 1. Check if we should generate a recap
   * 2. Generate commentary using existing service
   * 3. Commentary is automatically stored by the generator
   */
  async generateHourlyRecap(): Promise<void> {
    try {
      console.log('Starting hourly recap generation...');
      
      // Check if we should generate a recap (avoid duplicates)
      const shouldGenerate = await this.shouldGenerateRecap();
      if (!shouldGenerate) {
        console.log('Hourly recap already generated recently, skipping');
        return;
      }

      // Check if we have recent snapshots
      const recentSnapshotCount = await this.getRecentSnapshotCount();
      if (recentSnapshotCount === 0) {
        console.log('No recent snapshots found, skipping recap generation');
        return;
      }

      console.log(`Found ${recentSnapshotCount} recent snapshots, generating hourly recap`);

      // Generate and store commentary using existing service
      const entry = await generateAndStoreCommentary({
        mode: 'hourly',
        requesterId: 'hourly-cron-job'
      });
      
      console.log('Successfully generated and stored hourly recap', {
        commentaryId: entry.id,
        title: entry.summary.title,
        createdAt: entry.createdAt
      });

    } catch (error) {
      console.error('Failed to generate hourly recap:', error);
      throw error;
    }
  }

  /**
   * Get count of recent snapshots
   */
  private async getRecentSnapshotCount(): Promise<number> {
    try {
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
      
      const snapshot = await firestore
        .collection('snapshots')
        .where('capturedAt', '>=', oneHourAgo)
        .count()
        .get();

      return snapshot.data().count;
    } catch (error) {
      console.error('Failed to count recent snapshots:', error);
      return 0;
    }
  }

  /**
   * Check if we should generate a recap (avoid duplicates)
   */
  async shouldGenerateRecap(): Promise<boolean> {
    try {
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
      
      // Check if we already have a recap from the last hour
      const existingRecap = await firestore
        .collection('commentary')
        .where('mode', '==', 'hourly')
        .where('timestamp', '>=', oneHourAgo)
        .limit(1)
        .get();

      return existingRecap.empty;
    } catch (error) {
      console.error('Failed to check existing recaps:', error);
      return false;
    }
  }
}