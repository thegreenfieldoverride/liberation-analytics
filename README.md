# 🔥 Liberation Analytics

**Analytics for the liberation movement, not the surveillance state.**

Privacy-first analytics service built with Go, DuckDB, and radical transparency. Track the corporate exodus without becoming the thing you're escaping from.

## 🎯 Liberation Philosophy

**We track the movement, not the individual.**

This isn't another surveillance capitalism tool dressed up as "analytics." Liberation Analytics measures collective patterns to accelerate the corporate exodus:

- **Which liberation tools actually work** - Real usage patterns, not marketing metrics
- **Geographic hotspots of escape** - Where the movement is strongest (country-level only)
- **Financial liberation patterns** - Aggregate data on runway calculations and real wage discoveries
- **Zero individual tracking** - Your personal data stays with you, period

**Built by escapees, for escapees.** 🔓

## 🚨 Anti-Surveillance Manifesto

**Corporate analytics = digital colonialism.** Google Analytics, Facebook Pixel, Adobe Analytics - they're extraction engines designed to harvest human behavior for shareholder value.

**We reject this entirely.**

Liberation Analytics exists to:
- **Measure liberation, not exploitation** - Track collective escape patterns
- **Serve the movement, not shareholders** - Analytics that help people escape, not trap them
- **Privacy by architecture** - Cannot track individuals even if we wanted to
- **Radical transparency** - All source code open, all practices documented
- **Community controlled** - No VC funding, no corporate overlords

**If you're building tools to help people escape corporate imprisonment, this is your analytics platform.**

## 🏗 Architecture

**Universal Event Model:**
```json
{
  "app": "runway-calculator",
  "action": "calculate", 
  "attributes": {
    "runway_months": 8.5,
    "savings_band": "10k-25k",
    "industry": "tech"
  },
  "timestamp": "2025-01-23T21:45:00Z",
  "geo_hint": "US",
  "session_id": "sess_abc123"
}
```

## 🚀 Quick Start

### Server Setup
```bash
cd liberation-analytics
go run main.go
# Server starts on :8080
```

### Client Integration (JavaScript)
```html
<script src="/client.js"></script>
<script>
const analytics = new LiberationAnalytics('http://localhost:8080');

// Track events
analytics.trackRunwayCalculation(8.5, '10k-25k', '2k-4k', 'tech');
analytics.trackRealWageReveal('80k-100k', -23.5, 45, 'finance');
</script>
```

## 📊 API Endpoints

### Event Tracking
```bash
POST /api/events
Content-Type: application/json

{
  "app": "runway-calculator",
  "action": "calculate",
  "attributes": {"runway_months": 8.5},
  "session_id": "sess_abc123"
}
```

### Insights (Aggregated Data Only)
```bash
# Usage patterns
GET /api/insights/usage

# Geographic liberation hotspots  
GET /api/insights/geographic

# Financial insights (aggregated)
GET /api/insights/financial

# Health check
GET /api/health
```

## 🔒 Privacy Guarantees

1. **No Individual Tracking** - Only aggregate patterns
2. **Minimal Data Collection** - Only what's needed for liberation insights
3. **Geographic Privacy** - Country-level only (e.g., "US", "CA")
4. **Session-Based** - Sessions reset, no persistent user IDs
5. **Self-Hosted** - Your data stays on your infrastructure

## 🛠 Integration Examples

### Runway Calculator
```javascript
// When user calculates runway
analytics.trackRunwayCalculation(
  runwayMonths,    // 8.5
  savingsBand,     // "10k-25k" 
  expensesBand,    // "2k-4k"
  industry         // "tech"
);
```

### Real Hourly Wage Calculator
```javascript
// When user discovers real wage
analytics.trackRealWageReveal(
  salaryBand,      // "80k-100k"
  realWageDiff,    // -23.5 (percentage difference)
  commuteMinutes,  // 45
  industry         // "finance"
);
```

### Custom Events
```javascript
// For new liberation tools
analytics.track('custom-tool', 'action', {
  custom_attribute: 'value',
  measurement: 42
});
```

## 📈 Insights Dashboard

The analytics service provides aggregate insights:

**Usage Patterns:**
- Peak liberation planning times
- Most popular tool combinations
- Completion rates by tool

**Geographic Hotspots:**
- Liberation activity by country
- Tool popularity by region
- Corporate exodus patterns

**Financial Insights:**
- Average runway durations
- Salary illusion magnitude
- Liberation timeline patterns

## 🔧 Technical Details

- **Language:** Go (fast, concurrent)
- **Database:** DuckDB (analytical queries)
- **Geographic:** GeoIP2 (country-level only)
- **CORS:** Enabled for web tool integration
- **Storage:** Local file database (analytics.db)

## 🌍 Production Deployment

1. **Build**: `go build -o liberation-analytics`
2. **Deploy**: Run on your liberation infrastructure
3. **SSL**: Put behind reverse proxy (Caddy/nginx)
4. **GeoIP**: Download GeoLite2-Country.mmdb for geographic insights
5. **Monitor**: Health endpoint at `/api/health`

## 🚀 **Current Status: DEPLOYED & READY**

### ✅ **Production Deployment**
- **API URL**: https://analytics.greenfieldoverride.com/api
- **Health Check**: https://analytics.greenfieldoverride.com/api/health  
- **Status**: ✅ Healthy and accessible
- **SSL/TLS**: ✅ Auto-managed by Caddy
- **CORS**: ✅ Configured for frontend access

### ✅ **Local Development Environment**
- **Setup Command**: `./scripts/setup-local-dev.sh`
- **Local API**: http://localhost:8080/api
- **Environment**: Fully isolated with docker-compose.dev.yml

## 🔧 **Environment Configurations**

### **Production Environment**
```bash
ENVIRONMENT=production
DATABASE_URL=postgres://liberation:***@postgres:5432/liberation_analytics  
DUCKDB_PATH=/app/data/analytics.db
ALLOWED_ORIGINS=https://greenfieldoverride.com
```

### **Local Development Environment**
```bash
ENVIRONMENT=development
DATABASE_URL=postgres://postgres:dev_password@postgres-dev:5432/liberation_analytics_dev
ALLOWED_ORIGINS=http://localhost:3333,http://localhost:3000
```

## 🖥️ **Local Development Quick Start**

```bash
# 1. Setup (creates .env, starts all services)
./scripts/setup-local-dev.sh

# 2. Test local API  
curl http://localhost:8080/api/health

# 3. View logs
docker-compose -f docker-compose.dev.yml logs -f
```

## 🔗 **Frontend Integration**

Add to your frontend `.env`:
```bash
# Production
NEXT_PUBLIC_ANALYTICS_URL=https://analytics.greenfieldoverride.com/api

# Local Development
NEXT_PUBLIC_ANALYTICS_URL=http://localhost:8080/api  
```

## 🛠️ **Known Issues & Next Steps**

### **Current Issues**
1. **Event ID Generation**: Backend needs to auto-generate UUIDs for events
2. **Docker Health Check**: Container shows unhealthy despite working

### **Next Steps**
1. **Frontend Integration**: Wire useAnalytics hook to production API
2. **Dashboard Integration**: Connect analytics dashboard component  
3. **Enhanced Monitoring**: Add to Prometheus/Grafana stack

## 🚀 Future Features

- Real-time liberation dashboard
- Anonymous cohort analysis  
- Liberation success pattern detection
- Integration with liberation community platform

---

**Built for the liberation movement** - Measure freedom, not surveillance.

**Status**: 🟢 **PRODUCTION READY** - Analytics service deployed and accessible at https://analytics.greenfieldoverride.com