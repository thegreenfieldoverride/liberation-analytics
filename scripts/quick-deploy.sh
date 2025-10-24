#!/bin/bash
# Quick deploy Liberation Analytics with 2 Hetzner volumes
# Usage: ./quick-deploy.sh ANALYTICS_VOLUME_ID POSTGRES_VOLUME_ID
# Example: ./quick-deploy.sh scsi-0HC_Volume_103803900 scsi-0HC_Volume_103803901

set -e

echo "🚀 Quick Deploy Liberation Analytics..."

# Get volume IDs from command line arguments or environment variables
ANALYTICS_VOLUME="${1:-$ANALYTICS_VOLUME_ID}"
POSTGRES_VOLUME="${2:-$POSTGRES_VOLUME_ID}"

# Check if volume IDs are provided
if [ -z "$ANALYTICS_VOLUME" ] || [ -z "$POSTGRES_VOLUME" ]; then
    echo "❌ Volume IDs required!"
    echo ""
    echo "Usage:"
    echo "  ./quick-deploy.sh ANALYTICS_VOLUME_ID POSTGRES_VOLUME_ID"
    echo ""
    echo "Example:"
    echo "  ./quick-deploy.sh scsi-0HC_Volume_103803900 scsi-0HC_Volume_103803901"
    echo ""
    echo "Or set environment variables:"
    echo "  export ANALYTICS_VOLUME_ID=scsi-0HC_Volume_103803900"
    echo "  export POSTGRES_VOLUME_ID=scsi-0HC_Volume_103803901"
    echo "  ./quick-deploy.sh"
    exit 1
fi

echo "📋 Using Hetzner volumes:"
echo "  Analytics: $ANALYTICS_VOLUME → /mnt/analytics-volume"
echo "  PostgreSQL: $POSTGRES_VOLUME → /mnt/postgres-volume"
echo ""

# Quick volume setup (format + mount + fstab)
setup_volume() {
    local volume_id=$1
    local mount_point=$2
    local volume_name=$3
    
    echo "🔧 Setting up $volume_name volume..."
    
    # Check if already mounted
    if mountpoint -q "$mount_point"; then
        echo "✅ $mount_point already mounted"
        return 0
    fi
    
    # Format if needed (be careful!)
    if [ ! -e "/dev/disk/by-id/$volume_id" ]; then
        echo "❌ Volume /dev/disk/by-id/$volume_id not found!"
        echo "Please attach the Hetzner volume to this server first"
        exit 1
    fi
    
    # Create mount directory
    mkdir -p "$mount_point"
    
    # Format volume (WARNING!)
    echo "⚠️  About to format $volume_name volume!"
    echo "This will ERASE all existing data on /dev/disk/by-id/$volume_id"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Formatting..."
        mkfs.ext4 -F "/dev/disk/by-id/$volume_id"
    fi
    
    # Mount
    echo "🔗 Mounting..."
    mount -o discard,defaults "/dev/disk/by-id/$volume_id" "$mount_point"
    
    # Add to fstab
    if ! grep -q "$volume_id" /etc/fstab; then
        echo "/dev/disk/by-id/$volume_id $mount_point ext4 discard,nofail,defaults 0 0" >> /etc/fstab
    fi
    
    # Set permissions
    case $volume_name in
        "Analytics")
            chown -R 1000:1000 "$mount_point"
            mkdir -p "$mount_point/duckdb"
            chmod 755 "$mount_point/duckdb"
            ;;
        "PostgreSQL")
            chown -R 999:999 "$mount_point"
            ;;
    esac
    
    echo "✅ $volume_name volume ready!"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root or with sudo"
    exit 1
fi

# Setup volumes
setup_volume "$ANALYTICS_VOLUME" "/mnt/analytics-volume" "Analytics"
setup_volume "$POSTGRES_VOLUME" "/mnt/postgres-volume" "PostgreSQL"

# Check for .env
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please edit .env and set POSTGRES_PASSWORD:"
    echo "  nano .env"
    echo ""
    echo "Then run: docker-compose -f docker-compose.minimal.yml up -d"
    exit 0
fi

# Deploy with minimal compose file
echo "🚀 Deploying Liberation Analytics..."
docker-compose -f docker-compose.minimal.yml pull
docker-compose -f docker-compose.minimal.yml down
docker-compose -f docker-compose.minimal.yml up -d

# Health check
echo "⏳ Waiting for service to be healthy..."
sleep 15

for i in {1..20}; do
    if curl -f -s http://localhost:8080/api/health > /dev/null; then
        echo "✅ Liberation Analytics is live!"
        break
    elif [ $i -eq 20 ]; then
        echo "❌ Health check failed"
        docker-compose -f docker-compose.minimal.yml logs liberation-analytics
        exit 1
    else
        echo "⏳ Health check $i/20..."
        sleep 5
    fi
done

echo ""
echo "🎉 Liberation Analytics deployed successfully!"
echo "📊 API: http://localhost:8080"
echo "🔍 Health: http://localhost:8080/api/health"
echo ""
echo "📋 Next: Configure reverse proxy for analytics.greenfieldoverride.com"