#!/bin/bash
# Deploy Liberation Analytics with Hetzner volumes

set -e

# Parse command line arguments
INCLUDE_DASHBOARD=false
COMPOSE_FILE="docker-compose.yml"

while [[ $# -gt 0 ]]; do
    case $1 in
        --dashboard)
            INCLUDE_DASHBOARD=true
            COMPOSE_FILE="docker-compose.dashboard.yml"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dashboard]"
            exit 1
            ;;
    esac
done

if [ "$INCLUDE_DASHBOARD" = true ]; then
    echo "🚀 Deploying Liberation Analytics with Dashboard..."
else
    echo "🚀 Deploying Liberation Analytics..."
fi

# Check if volumes are mounted
if ! mountpoint -q /mnt/analytics-volume; then
    echo "❌ Analytics volume not mounted at /mnt/analytics-volume"
    echo "Please mount Hetzner volumes first:"
    echo "  sudo mount /dev/sdb /mnt/analytics-volume"
    exit 1
fi

if ! mountpoint -q /mnt/postgres-volume; then
    echo "❌ PostgreSQL volume not mounted at /mnt/postgres-volume"
    echo "Please mount Hetzner volumes first:"
    echo "  sudo mount /dev/sdc /mnt/postgres-volume"
    exit 1
fi

if ! mountpoint -q /mnt/redis-volume; then
    echo "❌ Redis volume not mounted at /mnt/redis-volume"
    echo "Please mount Hetzner volumes first:"
    echo "  sudo mount /dev/sdd /mnt/redis-volume"
    exit 1
fi

# Check for .env file
if [ ! -f .env ]; then
    echo "❌ .env file not found"
    echo "Please copy .env.example to .env and configure:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Ensure proper permissions
echo "🔧 Setting volume permissions..."
sudo chown -R 1000:1000 /mnt/analytics-volume
sudo chown -R 999:999 /mnt/postgres-volume
sudo chown -R 999:999 /mnt/redis-volume

# Create necessary directories
echo "📁 Creating directories..."
sudo mkdir -p /mnt/analytics-volume/duckdb
sudo chmod 755 /mnt/analytics-volume/duckdb

# Pull latest images
echo "📥 Pulling latest images..."
docker-compose -f $COMPOSE_FILE pull

# Stop existing services
echo "🛑 Stopping existing services..."
docker-compose -f $COMPOSE_FILE down

# Start services
if [ "$INCLUDE_DASHBOARD" = true ]; then
    echo "🟢 Starting Liberation Analytics with Dashboard..."
else
    echo "🟢 Starting Liberation Analytics services..."
fi
docker-compose -f $COMPOSE_FILE up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check health
echo "🔍 Checking service health..."
for i in {1..30}; do
    if curl -f -s http://localhost:8080/api/health > /dev/null; then
        echo "✅ Liberation Analytics is healthy!"
        break
    elif [ $i -eq 30 ]; then
        echo "❌ Health check failed after 30 attempts"
        docker-compose -f $COMPOSE_FILE logs liberation-analytics
        exit 1
    else
        echo "⏳ Health check $i/30: waiting..."
        sleep 5
    fi
done

# Check dashboard health if included
if [ "$INCLUDE_DASHBOARD" = true ]; then
    echo "🔍 Checking dashboard health..."
    for i in {1..30}; do
        if curl -f -s http://localhost:8081 > /dev/null; then
            echo "✅ Liberation Dashboard is healthy!"
            break
        elif [ $i -eq 30 ]; then
            echo "❌ Dashboard health check failed after 30 attempts"
            docker-compose -f $COMPOSE_FILE logs liberation-dashboard
            exit 1
        else
            echo "⏳ Dashboard check $i/30: waiting..."
            sleep 5
        fi
    done
fi

echo ""
if [ "$INCLUDE_DASHBOARD" = true ]; then
    echo "🎉 Liberation Analytics with Dashboard deployed successfully!"
    echo "📊 Analytics API: http://localhost:8080"
    echo "🖥️  Dashboard: http://localhost:8081"
    echo "🔍 Health check: http://localhost:8080/api/health"
    echo ""
    echo "📋 Next steps:"
    echo "1. Configure reverse proxy for analytics.greenfieldoverride.com"
    echo "2. Configure dashboard routing at /dashboard"
    echo "3. Set up SSL certificate"
    echo "4. Configure firewall rules"
    echo "5. Set up monitoring and backups"
    echo ""
    echo "📈 Monitor with:"
    echo "  docker-compose -f $COMPOSE_FILE logs -f liberation-analytics"
    echo "  docker-compose -f $COMPOSE_FILE logs -f liberation-dashboard"
    echo "  docker-compose -f $COMPOSE_FILE ps"
else
    echo "🎉 Liberation Analytics deployed successfully!"
    echo "📊 Analytics API: http://localhost:8080"
    echo "🔍 Health check: http://localhost:8080/api/health"
    echo ""
    echo "📋 Next steps:"
    echo "1. Configure reverse proxy for analytics.greenfieldoverride.com"
    echo "2. Set up SSL certificate"
    echo "3. Configure firewall rules"
    echo "4. Set up monitoring and backups"
    echo ""
    echo "📈 Monitor with:"
    echo "  docker-compose -f $COMPOSE_FILE logs -f liberation-analytics"
    echo "  docker-compose -f $COMPOSE_FILE ps"
fi