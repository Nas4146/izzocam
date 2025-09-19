// Monitoring and metrics service for the commentary system
import admin from 'firebase-admin';

export interface UsageMetrics {
  timestamp: Date;
  service: string;
  operation: string;
  userId?: string;
  cost?: number;
  success: boolean;
  duration?: number;
  metadata?: Record<string, any>;
}

export interface ErrorMetrics {
  timestamp: Date;
  service: string;
  operation: string;
  userId?: string;
  error: string;
  stack?: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
}

class MonitoringService {
  private db: admin.firestore.Firestore;

  constructor() {
    this.db = admin.firestore();
  }

  // Log usage metrics
  async logUsage(metrics: UsageMetrics) {
    try {
      await this.db.collection('monitoring_usage').add({
        ...metrics,
        timestamp: admin.firestore.Timestamp.fromDate(metrics.timestamp)
      });
      
      // Also log to console for immediate visibility
      console.log(`[Usage] ${metrics.service}:${metrics.operation} - ${metrics.success ? 'SUCCESS' : 'FAILURE'}${metrics.cost ? ` ($${metrics.cost.toFixed(4)})` : ''}`);
    } catch (error) {
      console.error('[Monitoring] Failed to log usage metrics:', error);
    }
  }

  // Log error metrics
  async logError(metrics: ErrorMetrics) {
    try {
      await this.db.collection('monitoring_errors').add({
        ...metrics,
        timestamp: admin.firestore.Timestamp.fromDate(metrics.timestamp)
      });
      
      // Log to console based on severity
      const logLevel = metrics.severity === 'critical' || metrics.severity === 'high' ? 'error' : 'warn';
      console[logLevel](`[${metrics.severity.toUpperCase()}] ${metrics.service}:${metrics.operation} - ${metrics.error}`);
    } catch (error) {
      console.error('[Monitoring] Failed to log error metrics:', error);
    }
  }

  // Log OpenAI API usage and costs
  async logOpenAIUsage(operation: string, usage: any, userId?: string) {
    // Approximate costs based on GPT-4o mini pricing
    const inputCost = (usage.prompt_tokens || 0) * 0.00000015; // $0.15 per 1M tokens
    const outputCost = (usage.completion_tokens || 0) * 0.0000006; // $0.60 per 1M tokens
    const totalCost = inputCost + outputCost;

    await this.logUsage({
      timestamp: new Date(),
      service: 'openai',
      operation,
      userId,
      cost: totalCost,
      success: true,
      metadata: {
        prompt_tokens: usage.prompt_tokens,
        completion_tokens: usage.completion_tokens,
        total_tokens: usage.total_tokens,
        model: usage.model || 'gpt-4o-mini'
      }
    });
  }

  // Log Firebase operations
  async logFirebaseUsage(operation: string, success: boolean, duration?: number, userId?: string) {
    await this.logUsage({
      timestamp: new Date(),
      service: 'firebase',
      operation,
      userId,
      success,
      duration,
      cost: 0.00001 // Approximate Firestore operation cost
    });
  }

  // Log LiveKit operations
  async logLiveKitUsage(operation: string, success: boolean, duration?: number) {
    await this.logUsage({
      timestamp: new Date(),
      service: 'livekit',
      operation,
      success,
      duration,
      cost: 0.001 // Approximate LiveKit operation cost
    });
  }

  // Get usage summary for the last 24 hours
  async getUsageSummary() {
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    
    try {
      const snapshot = await this.db
        .collection('monitoring_usage')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(yesterday))
        .get();

      const summary = {
        totalOperations: 0,
        totalCost: 0,
        successRate: 0,
        services: {} as Record<string, { operations: number; cost: number; success: number }>
      };

      let successCount = 0;

      snapshot.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
        const data = doc.data();
        summary.totalOperations++;
        summary.totalCost += data.cost || 0;
        
        if (data.success) successCount++;

        if (!summary.services[data.service]) {
          summary.services[data.service] = { operations: 0, cost: 0, success: 0 };
        }
        
        summary.services[data.service].operations++;
        summary.services[data.service].cost += data.cost || 0;
        if (data.success) summary.services[data.service].success++;
      });

      summary.successRate = summary.totalOperations > 0 ? (successCount / summary.totalOperations) * 100 : 0;

      return summary;
    } catch (error) {
      console.error('[Monitoring] Failed to get usage summary:', error);
      return null;
    }
  }

  // Get error summary for the last 24 hours
  async getErrorSummary() {
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    
    try {
      const snapshot = await this.db
        .collection('monitoring_errors')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(yesterday))
        .get();

      const summary = {
        totalErrors: 0,
        bySeverity: { low: 0, medium: 0, high: 0, critical: 0 },
        byService: {} as Record<string, number>
      };

      snapshot.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
        const data = doc.data();
        summary.totalErrors++;
        summary.bySeverity[data.severity as keyof typeof summary.bySeverity]++;
        
        if (!summary.byService[data.service]) {
          summary.byService[data.service] = 0;
        }
        summary.byService[data.service]++;
      });

      return summary;
    } catch (error) {
      console.error('[Monitoring] Failed to get error summary:', error);
      return null;
    }
  }

  // Alert if costs exceed threshold
  async checkCostAlerts() {
    const summary = await this.getUsageSummary();
    if (!summary) return;

    const dailyCostThreshold = 10.0; // $10 per day threshold
    const hourlyCostThreshold = 1.0; // $1 per hour threshold

    if (summary.totalCost > dailyCostThreshold) {
      await this.logError({
        timestamp: new Date(),
        service: 'monitoring',
        operation: 'cost_alert',
        error: `Daily cost threshold exceeded: $${summary.totalCost.toFixed(4)} > $${dailyCostThreshold}`,
        severity: 'high'
      });
    }

    // Check hourly costs
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const hourlySnapshot = await this.db
      .collection('monitoring_usage')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(oneHourAgo))
      .get();

    let hourlyCost = 0;
    hourlySnapshot.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
      hourlyCost += doc.data().cost || 0;
    });

    if (hourlyCost > hourlyCostThreshold) {
      await this.logError({
        timestamp: new Date(),
        service: 'monitoring',
        operation: 'cost_alert',
        error: `Hourly cost threshold exceeded: $${hourlyCost.toFixed(4)} > $${hourlyCostThreshold}`,
        severity: 'medium'
      });
    }
  }
}

export const monitoring = new MonitoringService();