# Liberation Analytics Deployment Guide

## 🚀 Quick Deployment

### Local Development
```bash
# Clone and setup
cd liberation-analytics
go mod tidy

# Run locally
go run main.go
# Server starts on http://localhost:8080
```

### Production Deployment (Hetzner VPS)

#### 1. Build and Deploy
```bash
# Build for production
CGO_ENABLED=1 GOOS=linux go build -o liberation-analytics

# Or use Docker
docker build -t liberation-analytics .
```

#### 2. Server Setup
```bash
# On production server
sudo mkdir -p /opt/liberation-analytics
sudo chown deploy-bot:deploy-bot /opt/liberation-analytics

# Upload binary or use Docker
scp liberation-analytics deploy-bot@your.server.ip:/opt/liberation-analytics/
```

#### 3. Caddy Configuration
Add to `/etc/caddy/Caddyfile`:
```
analytics.greenfieldoverride.com {
    reverse_proxy localhost:8080
    
    # CORS headers for liberation tools
    header {
        Access-Control-Allow-Origin *
        Access-Control-Allow-Methods "GET, POST, OPTIONS"
        Access-Control-Allow-Headers "Content-Type"
    }
    
    # Rate limiting
    rate_limit {
        zone static {
            events 100
            window 1m
        }
    }
}
```

#### 4. Systemd Service
Create `/etc/systemd/system/liberation-analytics.service`:
```ini
[Unit]
Description=Liberation Analytics Service
After=network.target

[Service]
Type=simple
User=deploy-bot
WorkingDirectory=/opt/liberation-analytics
ExecStart=/opt/liberation-analytics/liberation-analytics
Restart=always
RestartSec=10

# Environment
Environment=PORT=8080
Environment=DB_PATH=/opt/liberation-analytics/data/analytics.db

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ReadWritePaths=/opt/liberation-analytics/data

[Install]
WantedBy=multi-user.target
```

#### 5. Start Services
```bash
sudo systemctl daemon-reload
sudo systemctl enable liberation-analytics
sudo systemctl start liberation-analytics
sudo systemctl reload caddy
```

## 🔧 Configuration

### Environment Variables
```bash
# Server configuration
PORT=8080                    # Server port
DB_PATH=./analytics.db       # DuckDB database file
GEOIP_PATH=./GeoLite2-Country.mmdb  # Optional GeoIP database

# CORS configuration  
ALLOWED_ORIGINS=*            # Allowed origins (* for development)
```

### Database Setup
DuckDB creates database automatically on first run. For production:
```bash
# Create data directory
mkdir -p /opt/liberation-analytics/data
chown deploy-bot:deploy-bot /opt/liberation-analytics/data

# Set appropriate permissions
chmod 755 /opt/liberation-analytics/data
```

### GeoIP Setup (Optional)
```bash
# Download GeoLite2 database (free with MaxMind account)
wget https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=YOUR_KEY&suffix=tar.gz
tar -xzf GeoLite2-Country.tar.gz
cp GeoLite2-Country_*/GeoLite2-Country.mmdb /opt/liberation-analytics/
```

## 🐳 Docker Deployment

### Docker Compose
Create `docker-compose.yml`:
```yaml
version: '3.8'

services:
  liberation-analytics:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
      - ./GeoLite2-Country.mmdb:/app/GeoLite2-Country.mmdb:ro
    environment:
      - PORT=8080
      - DB_PATH=/app/data/analytics.db
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Run with Docker Compose
```bash
docker-compose up -d
```

## 📊 Monitoring & Health Checks

### Health Endpoint
```bash
curl http://localhost:8080/api/health
```

Expected response:
```json
{
  "status": "ok",
  "service": "liberation-analytics", 
  "timestamp": "2025-01-23T21:45:00Z",
  "database": "connected"
}
```

### Log Monitoring
```bash
# Check service logs
sudo journalctl -u liberation-analytics -f

# Check Docker logs
docker logs liberation-analytics -f
```

### Database Health
```bash
# Check database file
ls -la /opt/liberation-analytics/data/
# Should show: analytics.db, analytics.db-wal

# Query database directly (for debugging)
sqlite3 /opt/liberation-analytics/data/analytics.db ".tables"
```

## 🔒 Security Configuration

### Firewall Setup
```bash
# Allow only necessary ports
sudo ufw allow 80/tcp    # HTTP (Caddy)
sudo ufw allow 443/tcp   # HTTPS (Caddy)
sudo ufw allow 22/tcp    # SSH

# Analytics service runs behind Caddy - no direct access
# Port 8080 should NOT be exposed externally
```

### SSL/TLS
Caddy automatically handles SSL certificates via Let's Encrypt. No manual configuration needed.

### Rate Limiting
Configured in Caddy:
- 100 requests per minute per IP
- Protects against DoS while allowing legitimate usage

## 🎯 Integration with Liberation Platform

### Client Integration
Add to liberation tools:
```html
<!-- Add to liberation tool pages -->
<script src="https://analytics.greenfieldoverride.com/client.js"></script>
<script>
const analytics = new LiberationAnalytics('https://analytics.greenfieldoverride.com');

// Track events
analytics.trackRunwayCalculation(8.5, '10k-25k', '2k-4k', 'tech');
</script>
```

### Environment-Specific URLs
```javascript
// Development
const analytics = new LiberationAnalytics('http://localhost:8080');

// Staging  
const analytics = new LiberationAnalytics('https://analytics-staging.greenfieldoverride.com');

// Production
const analytics = new LiberationAnalytics('https://analytics.greenfieldoverride.com');
```

## 🔄 Backup & Recovery

### Database Backup
```bash
# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/liberation-analytics/backups"
mkdir -p $BACKUP_DIR

# Stop service briefly for consistent backup
sudo systemctl stop liberation-analytics
cp /opt/liberation-analytics/data/analytics.db $BACKUP_DIR/analytics_$DATE.db
sudo systemctl start liberation-analytics

# Keep only last 7 days
find $BACKUP_DIR -name "analytics_*.db" -mtime +7 -delete
```

### Recovery
```bash
# Restore from backup
sudo systemctl stop liberation-analytics
cp /opt/liberation-analytics/backups/analytics_YYYYMMDD_HHMMSS.db /opt/liberation-analytics/data/analytics.db
sudo systemctl start liberation-analytics
```

## 📈 Performance Tuning

### DuckDB Optimization
```sql
-- Run these on database startup (TODO: add to Go code)
PRAGMA memory_limit='512MB';
PRAGMA threads=4;
PRAGMA enable_progress_bar=false;
```

### System Resources
**Minimum Requirements:**
- RAM: 512MB
- CPU: 1 core
- Storage: 10GB (database growth)
- Network: 100Mbps

**Recommended:**
- RAM: 2GB
- CPU: 2 cores  
- Storage: 50GB SSD
- Network: 1Gbps

## 🚨 Troubleshooting

### Common Issues

**Service won't start:**
```bash
# Check logs
sudo journalctl -u liberation-analytics -n 50

# Check permissions
ls -la /opt/liberation-analytics/
sudo chown -R deploy-bot:deploy-bot /opt/liberation-analytics/
```

**Database errors:**
```bash
# Check database file
file /opt/liberation-analytics/data/analytics.db
# Should show: SQLite 3.x database

# Test database access
sqlite3 /opt/liberation-analytics/data/analytics.db "SELECT COUNT(*) FROM liberation_events;"
```

**CORS errors:**
```bash
# Check Caddy config
sudo caddy validate --config /etc/caddy/Caddyfile

# Test CORS headers
curl -H "Origin: https://greenfieldoverride.com" -I https://analytics.greenfieldoverride.com/api/health
```

**High memory usage:**
```bash
# Monitor memory
top -p $(pgrep liberation-analytics)

# Check database size
du -h /opt/liberation-analytics/data/analytics.db
```

### Debug Mode
```bash
# Run with debug logging
LOG_LEVEL=debug ./liberation-analytics
```

## 🔄 Updates & Maintenance

### Update Process
```bash
# 1. Build new version
go build -o liberation-analytics-new

# 2. Stop service
sudo systemctl stop liberation-analytics

# 3. Backup current
cp liberation-analytics liberation-analytics.backup

# 4. Replace binary
mv liberation-analytics-new liberation-analytics

# 5. Start service
sudo systemctl start liberation-analytics

# 6. Verify health
curl http://localhost:8080/api/health
```

### Maintenance Tasks
```bash
# Weekly: Database optimization
sqlite3 /opt/liberation-analytics/data/analytics.db "VACUUM;"

# Monthly: Log rotation
sudo journalctl --vacuum-time=30d

# Quarterly: Full backup verification
# Test restore process with backup files
```

---

**Liberation analytics deployed and operational!** 🚀

Track the movement, measure the revolution, liberate the data! 📊