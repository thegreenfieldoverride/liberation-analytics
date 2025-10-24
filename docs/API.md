# Liberation Analytics API Documentation

## 🎯 API Overview

The Liberation Analytics API provides privacy-first event tracking and aggregate insights for the liberation movement.

**Base URL**: `https://analytics.greenfieldoverride.com`  
**Local Dev**: `http://localhost:8080`

## 🔒 Privacy Guarantees

- **No Individual Tracking**: All responses contain aggregate data only
- **Minimum Thresholds**: No insights shown for <10 events  
- **Geographic Privacy**: Country-level only (US, CA, UK, etc.)
- **Time Windowing**: Hourly/daily aggregation, no exact timestamps
- **Anonymous Sessions**: Rotated hashes, no persistent identifiers

## 📝 Event Tracking

### POST /api/events

Track a liberation analytics event.

**Request:**
```http
POST /api/events
Content-Type: application/json

{
  "app": "runway-calculator",
  "action": "calculate", 
  "attributes": {
    "runway_months": 8.5,
    "savings_band": "10k-25k",
    "expenses_band": "2k-4k",
    "industry": "tech"
  },
  "session_id": "sess_abc123"
}
```

**Response:**
```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "status": "recorded"
}
```

**Event Schema:**
```javascript
{
  "app": "string",           // Required: Tool identifier
  "action": "string",        // Required: User action
  "attributes": {            // Optional: Tool-specific data
    "key": "value"           // Flexible key-value pairs
  },
  "timestamp": "ISO8601",    // Optional: Auto-generated if not provided
  "session_id": "string"     // Required: Anonymous session identifier
}
```

**Tool-Specific Examples:**

**Runway Calculator:**
```json
{
  "app": "runway-calculator",
  "action": "calculate",
  "attributes": {
    "runway_months": 8.5,
    "savings_band": "10k-25k",
    "expenses_band": "2k-4k", 
    "industry": "tech"
  },
  "session_id": "sess_abc123"
}
```

**Real Hourly Wage:**
```json
{
  "app": "real-hourly-wage", 
  "action": "reveal",
  "attributes": {
    "salary_band": "80k-100k",
    "real_wage_diff": -23.5,
    "commute_minutes": 45,
    "industry": "finance"
  },
  "session_id": "sess_def456"
}
```

**Cognitive Debt Assessment:**
```json
{
  "app": "cognitive-debt-assessment",
  "action": "complete", 
  "attributes": {
    "debt_score": 72,
    "primary_category": "burnout",
    "recommendation": "immediate"
  },
  "session_id": "sess_ghi789"
}
```

## 📊 Insights API

### GET /api/insights/usage

Get usage patterns and tool effectiveness data.

**Request:**
```http
GET /api/insights/usage
```

**Response:**
```json
[
  {
    "app": "runway-calculator",
    "action": "calculate", 
    "count": 1247,
    "unique_sessions": 892,
    "hour": "2025-01-23T21:00:00Z"
  },
  {
    "app": "real-hourly-wage",
    "action": "reveal",
    "count": 891,
    "unique_sessions": 645,
    "hour": "2025-01-23T21:00:00Z"
  }
]
```

**Fields:**
- `app`: Liberation tool identifier
- `action`: User action type
- `count`: Total events in time window
- `unique_sessions`: Unique sessions (anonymous)
- `hour`: Time window (last 24 hours, hourly buckets)

### GET /api/insights/geographic

Get geographic liberation hotspots.

**Request:**
```http
GET /api/insights/geographic
```

**Response:**
```json
[
  {
    "country": "US",
    "app": "runway-calculator", 
    "usage_count": 2847,
    "unique_users": 1653
  },
  {
    "country": "CA",
    "app": "real-hourly-wage",
    "usage_count": 421,
    "unique_users": 287
  },
  {
    "country": "UK", 
    "app": "cognitive-debt-assessment",
    "usage_count": 189,
    "unique_users": 134
  }
]
```

**Fields:**
- `country`: ISO country code (US, CA, UK, etc.)
- `app`: Liberation tool
- `usage_count`: Total events from country (last 7 days)
- `unique_users`: Anonymous unique sessions

**Privacy Note**: Only countries with >10 events shown.

### GET /api/insights/financial

Get aggregate financial liberation insights.

**Request:**
```http
GET /api/insights/financial
```

**Response:**
```json
[
  {
    "app": "runway-calculator",
    "salary_band": "80k-100k",
    "runway_months": 8.5,
    "real_wage_diff": null,
    "count": 234
  },
  {
    "app": "real-hourly-wage", 
    "salary_band": "80k-100k",
    "runway_months": null,
    "real_wage_diff": -23.5,
    "count": 189
  }
]
```

**Fields:**
- `app`: Liberation tool
- `salary_band`: Salary range ("40k-60k", "60k-80k", etc.)
- `runway_months`: Average runway calculation
- `real_wage_diff`: Average real wage difference (percentage)
- `count`: Number of events (last 30 days)

**Privacy Note**: Financial data aggregated into bands, not exact amounts.

## ✅ Health Check

### GET /api/health

Service health and status check.

**Request:**
```http
GET /api/health
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "ok",
  "service": "liberation-analytics",
  "timestamp": "2025-01-23T21:45:00Z", 
  "database": "connected"
}
```

## 🚨 Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid JSON", 
  "message": "Request body contains invalid JSON"
}
```

### 429 Too Many Requests
```json
{
  "error": "Rate limit exceeded",
  "message": "Maximum 100 requests per minute"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "message": "Database connection failed"
}
```

## 🔧 Client Libraries

### JavaScript Client

**Installation:**
```html
<script src="https://analytics.greenfieldoverride.com/client.js"></script>
```

**Usage:**
```javascript
const analytics = new LiberationAnalytics('https://analytics.greenfieldoverride.com');

// Track events
await analytics.track('runway-calculator', 'calculate', {
  runway_months: 8.5,
  savings_band: '10k-25k'
});

// Convenience methods
await analytics.trackRunwayCalculation(8.5, '10k-25k', '2k-4k', 'tech');
await analytics.trackRealWageReveal('80k-100k', -23.5, 45, 'finance');
await analytics.trackCognitiveDebtAssessment(72, 'burnout', 'immediate');
```

**Methods:**
```javascript
// Universal tracking
analytics.track(app, action, attributes)

// Tool-specific convenience methods
analytics.trackRunwayCalculation(runwayMonths, savingsBand, expensesBand, industry)
analytics.trackRealWageReveal(salaryBand, realWageDiff, commuteMinutes, industry)  
analytics.trackCognitiveDebtAssessment(score, primaryCategory, recommendation)
analytics.trackValuesVocationMatch(topValue, careerPivot, satisfactionChange)
analytics.trackAICoPilotConsultation(queryType, planGenerated, actionsTaken)
analytics.trackSmallBetsActivity(betCount, totalValue, topPerformer)
```

## 🔒 CORS Configuration

**Allowed Origins**: All origins (`*`) for development  
**Allowed Methods**: `GET`, `POST`, `OPTIONS`  
**Allowed Headers**: `Content-Type`

**Production**: Restrict origins to liberation domains only.

## 📈 Rate Limiting

**Limits:**
- 100 requests per minute per IP
- Burst allowance: 10 requests
- Window: 60 seconds

**Headers:**
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1643037600
```

## 🎯 Best Practices

### Event Tracking
1. **Use Convenience Methods**: Prefer tool-specific methods over generic `track()`
2. **Fail Silently**: Analytics should never break user experience
3. **Batch Events**: Consider batching for high-frequency actions
4. **Privacy Bands**: Use salary/savings bands, not exact amounts

### Data Privacy
1. **No PII**: Never include personally identifiable information
2. **Aggregate Attributes**: Use categories/bands instead of exact values
3. **Session Management**: Generate new session IDs periodically
4. **Minimal Data**: Only track what serves liberation goals

### Integration
```javascript
// Good: Privacy-friendly
analytics.track('runway-calculator', 'calculate', {
  runway_months: 8.5,
  savings_band: '10k-25k',    // Band, not exact amount
  industry: 'tech'            // General category
});

// Bad: Too specific/personal
analytics.track('runway-calculator', 'calculate', {
  exact_savings: 23847.32,    // Too precise
  employer: 'Acme Corp',      // Personally identifiable
  email: 'user@email.com'     // Personal information
});
```

## 🔮 Future API Extensions

### Planned Endpoints
- `GET /api/insights/journeys` - Liberation journey flow analysis
- `GET /api/insights/effectiveness` - Tool effectiveness scoring
- `GET /api/insights/trends` - Time-series liberation trends
- `GET /api/insights/cohorts` - Anonymous cohort analysis

### Experimental Features
- Real-time WebSocket events
- GraphQL query interface  
- Federation with other liberation platforms
- Privacy-preserving machine learning insights

---

**Built for liberation, designed for privacy.** 🚀

Track the movement, not the individuals! 📊