/**
 * Liberation Analytics Client
 * Privacy-first analytics for liberation tools
 */

class LiberationAnalytics {
  constructor(baseURL = 'http://localhost:8080') {
    this.baseURL = baseURL;
    this.sessionID = this.generateSessionID();
  }

  /**
   * Track a liberation analytics event
   * @param {string} app - App name (e.g., 'runway-calculator')
   * @param {string} action - Action taken (e.g., 'calculate', 'complete')
   * @param {object} attributes - Custom attributes for the event
   */
  async track(app, action, attributes = {}) {
    const event = {
      app,
      action,
      attributes,
      timestamp: new Date().toISOString(),
      session_id: this.sessionID
    };

    try {
      const response = await fetch(`${this.baseURL}/api/events`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(event)
      });

      if (!response.ok) {
        console.warn('Liberation Analytics: Failed to track event', response.status);
      }
    } catch (error) {
      // Fail silently - analytics should never break the user experience
      console.warn('Liberation Analytics: Network error', error.message);
    }
  }

  // Convenience methods for specific liberation tools

  /**
   * Track runway calculation
   */
  async trackRunwayCalculation(runwayMonths, savingsBand, expensesBand, industry = null) {
    return this.track('runway-calculator', 'calculate', {
      runway_months: runwayMonths,
      savings_band: savingsBand,
      expenses_band: expensesBand,
      industry
    });
  }

  /**
   * Track real hourly wage revelation
   */
  async trackRealWageReveal(salaryBand, realWageDiff, commuteMinutes, industry = null) {
    return this.track('real-hourly-wage', 'reveal', {
      salary_band: salaryBand,
      real_wage_diff: realWageDiff,
      commute_minutes: commuteMinutes,
      industry
    });
  }

  /**
   * Track cognitive debt assessment completion
   */
  async trackCognitiveDebtAssessment(score, primaryCategory, recommendation) {
    return this.track('cognitive-debt-assessment', 'complete', {
      debt_score: score,
      primary_category: primaryCategory,
      recommendation
    });
  }

  /**
   * Track values-vocation matching
   */
  async trackValuesVocationMatch(topValue, careerPivot, satisfactionChange) {
    return this.track('values-vocation-matcher', 'match', {
      top_value: topValue,
      career_pivot: careerPivot,
      satisfaction_change: satisfactionChange
    });
  }

  /**
   * Track AI co-pilot interactions
   */
  async trackAICoPilotConsultation(queryType, planGenerated, actionsTaken) {
    return this.track('ai-copilot', 'consult', {
      query_type: queryType,
      plan_generated: planGenerated,
      actions_taken: actionsTaken
    });
  }

  /**
   * Track small bets portfolio activity
   */
  async trackSmallBetsActivity(betCount, totalValue, topPerformer) {
    return this.track('small-bets-portfolio', 'update', {
      bet_count: betCount,
      total_value: totalValue,
      top_performer: topPerformer
    });
  }

  /**
   * Generate a random session ID
   */
  generateSessionID() {
    return 'sess_' + Math.random().toString(36).substr(2, 16) + 
           Date.now().toString(36);
  }
}

// Usage examples:
/*
const analytics = new LiberationAnalytics('https://analytics.greenfieldoverride.com');

// Track runway calculation
analytics.trackRunwayCalculation(8.5, '10k-25k', '2k-4k', 'tech');

// Track real wage revelation
analytics.trackRealWageReveal('80k-100k', -23.5, 45, 'finance');

// Track custom events
analytics.track('custom-tool', 'experiment', {
  custom_metric: 42,
  user_satisfaction: 'high'
});
*/

// Export for both CommonJS and ES modules
if (typeof module !== 'undefined' && module.exports) {
  module.exports = LiberationAnalytics;
}
if (typeof window !== 'undefined') {
  window.LiberationAnalytics = LiberationAnalytics;
}