#!/bin/bash
# Setup Hetzner Block Storage volumes for Liberation Analytics

set -e

echo "🔧 Setting up Hetzner volumes for Liberation Analytics..."

# Volume mount points
ANALYTICS_MOUNT="/mnt/analytics-volume"
POSTGRES_MOUNT="/mnt/postgres-volume" 
REDIS_MOUNT="/mnt/redis-volume"

# Create mount points
echo "📁 Creating mount points..."
sudo mkdir -p $ANALYTICS_MOUNT
sudo mkdir -p $POSTGRES_MOUNT
sudo mkdir -p $REDIS_MOUNT

# Set proper ownership for Docker containers
echo "👤 Setting ownership..."
sudo chown -R 1000:1000 $ANALYTICS_MOUNT
sudo chown -R 999:999 $POSTGRES_MOUNT    # PostgreSQL container user
sudo chown -R 999:999 $REDIS_MOUNT       # Redis container user

# Create subdirectories
echo "📂 Creating subdirectories..."
sudo mkdir -p $ANALYTICS_MOUNT/duckdb
sudo chmod 755 $ANALYTICS_MOUNT/duckdb

echo "✅ Volume setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Attach Hetzner volumes to this server"
echo "2. Mount volumes to the created mount points:"
echo "   sudo mount /dev/sdb $ANALYTICS_MOUNT"
echo "   sudo mount /dev/sdc $POSTGRES_MOUNT"  
echo "   sudo mount /dev/sdd $REDIS_MOUNT"
echo "3. Add to /etc/fstab for persistent mounting"
echo "4. Run: docker-compose up -d"
echo ""
echo "💾 Volume mount points:"
echo "  Analytics (DuckDB): $ANALYTICS_MOUNT"
echo "  PostgreSQL:         $POSTGRES_MOUNT"
echo "  Redis:              $REDIS_MOUNT"