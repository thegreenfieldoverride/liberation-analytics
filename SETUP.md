# Liberation Analytics Setup Guide

## Quick Start for Production Deployment

### 1. Environment Configuration

Create `.env` file in the `liberation-analytics/` directory:

```bash
# Copy from example
cp .env.example .env

# Edit the configuration
nano .env
```

Required environment variables:

```bash
# Dashboard Authentication
DASHBOARD_USERNAME=analytics_admin
DASHBOARD_PASSWORD=your_secure_password_here

# API Token Security  
API_TOKEN_SECRET=generate_a_random_256_bit_secret_for_jwt_signing

# CORS Security - Restrict to your liberation domains
ALLOWED_ORIGINS=https://thegreenfieldoverride.com,https://staging.thegreenfieldoverride.com

# Server Configuration
PORT=8080
ENVIRONMENT=production
```

### 2. Generate API Tokens

Create an API token for the frontend to access analytics insights:

```bash
cd liberation-analytics

# Generate a token for frontend access
go run cmd/token-manager/main.go \
  -command=create \
  -name="Frontend Analytics" \
  -permissions="read:insights,read:health"
```

This will output:
- A secure API token (save this!)
- SQL command to insert the token into the database

### 3. Database Setup

Initialize the analytics database:

```bash
# Run the analytics service to auto-create tables
go run main.go

# Or manually initialize with SQL
sqlite3 analytics.db < scripts/init-db.sql
```

Insert your API token:

```sql
-- Use the SQL command from step 2
INSERT INTO api_tokens (token_hash, name, permissions, expires_at, is_active) 
VALUES ('your_token_hash', 'Frontend Analytics', '["read:insights","read:health"]', NULL, true);
```

### 4. Update Frontend Configuration

Add the API token to your main app's `.env`:

```bash
# In the main project root
echo "ANALYTICS_API_TOKEN=your_generated_token_here" >> .env
```

### 5. Start the Services

```bash
# Start analytics service
cd liberation-analytics
go run main.go

# Start main application (in another terminal)
cd apps/web
pnpm dev
```

### 6. Test Authentication

Test the protected endpoints:

```bash
# This should work (with your token)
curl -H "X-API-Key: your_token_here" http://localhost:8080/api/health

# This should fail (no token)
curl http://localhost:8080/api/insights/usage

# This should work (public endpoint)
curl -X POST http://localhost:8080/api/events \
  -H "Content-Type: application/json" \
  -d '{"app":"test","action":"test","attributes":{},"session_id":"test"}'
```

### 7. Access Dashboard

Visit the analytics dashboard:

```bash
# Navigate to dashboard
open http://localhost:8081

# Login with your configured credentials
Username: analytics_admin
Password: your_secure_password_here
```

## Production Deployment

### Docker Deployment

1. Build the analytics service:

```bash
cd liberation-analytics
docker build -t liberation-analytics .
```

2. Run with environment variables:

```bash
docker run -d \
  --name liberation-analytics \
  -p 8080:8080 \
  -e DASHBOARD_USERNAME=analytics_admin \
  -e DASHBOARD_PASSWORD=your_secure_password \
  -e ANALYTICS_API_TOKEN=your_token_here \
  -e ALLOWED_ORIGINS=https://thegreenfieldoverride.com \
  -v $(pwd)/data:/app/data \
  liberation-analytics
```

### Security Checklist

- [ ] ✅ **Strong dashboard password** set
- [ ] ✅ **API token generated** and secured
- [ ] ✅ **CORS origins restricted** to legitimate domains
- [ ] ✅ **HTTPS enabled** (handled by Caddy/reverse proxy)
- [ ] ✅ **Environment variables** not exposed in logs
- [ ] ✅ **Database backups** configured
- [ ] ✅ **Rate limiting** enabled (default: 100 req/min)

### Token Management

#### Create Additional Tokens

```bash
# Admin token for dashboard management
go run cmd/token-manager/main.go \
  -command=create \
  -name="Admin Token" \
  -permissions="admin:all"

# Read-only token for monitoring
go run cmd/token-manager/main.go \
  -command=create \
  -name="Monitoring" \
  -permissions="read:health"
```

#### Revoke Tokens

```bash
# Via API (requires admin token)
curl -X DELETE \
  -H "X-API-Key: your_admin_token" \
  http://localhost:8080/api/admin/tokens/token_id_here

# Via database
sqlite3 analytics.db "UPDATE api_tokens SET is_active = false WHERE id = 'token_id';"
```

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   ```bash
   # Check if token exists in database
   sqlite3 analytics.db "SELECT name, permissions, is_active FROM api_tokens;"
   
   # Verify token hash matches
   echo "Check token hash in auth.go hashToken function"
   ```

2. **CORS Errors**
   ```bash
   # Update ALLOWED_ORIGINS
   export ALLOWED_ORIGINS="https://yoursite.com,http://localhost:3333"
   ```

3. **Dashboard Access Denied**
   ```bash
   # Verify credentials
   echo $DASHBOARD_USERNAME
   echo $DASHBOARD_PASSWORD
   ```

4. **Analytics Not Collecting**
   ```bash
   # Check public endpoint
   curl -X POST http://localhost:8080/api/events \
     -H "Content-Type: application/json" \
     -d '{"app":"test","action":"test","session_id":"test","attributes":{}}'
   ```

### Logs and Monitoring

```bash
# View authentication failures
grep "AUTH_FAILURE" analytics.log

# Monitor token usage
sqlite3 analytics.db "SELECT name, last_used FROM api_tokens ORDER BY last_used DESC;"

# Check endpoint access
tail -f analytics.log | grep "GET /api"
```

## Integration with Main App

The main liberation platform is already configured to:

1. ✅ Send events to `/api/analytics/events` (public, no auth required)
2. ✅ Fetch insights from `/api/analytics/insights` (protected, requires token)
3. ✅ Display analytics dashboard component (with graceful fallback)

No additional frontend changes needed - just configure the environment variables!

## Next Steps

1. **Monitor Usage**: Check dashboard for analytics collection
2. **Create Alerts**: Set up monitoring for authentication failures
3. **Backup Strategy**: Regular database backups of `analytics.db`
4. **Token Rotation**: Periodically rotate API tokens for security
5. **Scale Up**: Monitor performance and scale analytics service as needed

The analytics system is now secure and production-ready! 🔒📊