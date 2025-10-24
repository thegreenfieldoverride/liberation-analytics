#!/bin/bash
# Setup Hetzner Block Storage volumes for Liberation Analytics
# Run this script as root or with sudo

set -e

echo "🔧 Setting up Hetzner Block Storage volumes for Liberation Analytics..."

# Hetzner volume IDs - UPDATE THESE WITH YOUR ACTUAL VOLUME IDs
ANALYTICS_VOLUME_ID="scsi-0HC_Volume_XXXXXXXXX"  # Analytics/DuckDB volume
POSTGRES_VOLUME_ID="scsi-0HC_Volume_YYYYYYYYY"   # PostgreSQL volume  
REDIS_VOLUME_ID="scsi-0HC_Volume_ZZZZZZZZZ"      # Redis volume (optional)

# Mount points
ANALYTICS_MOUNT="/mnt/analytics-volume"
POSTGRES_MOUNT="/mnt/postgres-volume"
REDIS_MOUNT="/mnt/redis-volume"

echo "📋 Volume configuration:"
echo "  Analytics: /dev/disk/by-id/$ANALYTICS_VOLUME_ID → $ANALYTICS_MOUNT"
echo "  PostgreSQL: /dev/disk/by-id/$POSTGRES_VOLUME_ID → $POSTGRES_MOUNT"
echo "  Redis: /dev/disk/by-id/$REDIS_VOLUME_ID → $REDIS_MOUNT"
echo ""

# Function to setup a volume
setup_volume() {
    local volume_id=$1
    local mount_point=$2
    local volume_name=$3
    
    echo "🔧 Setting up $volume_name volume..."
    
    # Check if volume device exists
    if [ ! -e "/dev/disk/by-id/$volume_id" ]; then
        echo "❌ Volume device /dev/disk/by-id/$volume_id not found"
        echo "Please ensure the Hetzner volume is attached to this server"
        return 1
    fi
    
    # Format volume (WARNING: This will erase existing data!)
    echo "⚠️  Formatting $volume_name volume (this will erase existing data!)"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping format for $volume_name"
    else
        echo "📦 Formatting /dev/disk/by-id/$volume_id..."
        mkfs.ext4 -F "/dev/disk/by-id/$volume_id"
    fi
    
    # Create mount directory
    echo "📁 Creating mount directory $mount_point..."
    mkdir -p "$mount_point"
    
    # Mount volume
    echo "🔗 Mounting volume..."
    mount -o discard,defaults "/dev/disk/by-id/$volume_id" "$mount_point"
    
    # Add to fstab for persistent mounting
    echo "📝 Adding to /etc/fstab for persistent mounting..."
    if ! grep -q "$volume_id" /etc/fstab; then
        echo "/dev/disk/by-id/$volume_id $mount_point ext4 discard,nofail,defaults 0 0" >> /etc/fstab
        echo "✅ Added to /etc/fstab"
    else
        echo "ℹ️  Already exists in /etc/fstab"
    fi
    
    # Set permissions for Docker containers
    echo "👤 Setting permissions..."
    case $volume_name in
        "Analytics")
            chown -R 1000:1000 "$mount_point"
            mkdir -p "$mount_point/duckdb"
            chmod 755 "$mount_point/duckdb"
            ;;
        "PostgreSQL")
            chown -R 999:999 "$mount_point"  # PostgreSQL container user
            ;;
        "Redis")
            chown -R 999:999 "$mount_point"  # Redis container user
            ;;
    esac
    
    echo "✅ $volume_name volume setup complete!"
    echo ""
}

# Setup each volume
setup_volume "$ANALYTICS_VOLUME_ID" "$ANALYTICS_MOUNT" "Analytics"
setup_volume "$POSTGRES_VOLUME_ID" "$POSTGRES_MOUNT" "PostgreSQL"  
setup_volume "$REDIS_VOLUME_ID" "$REDIS_MOUNT" "Redis"

echo "🎉 All Hetzner volumes configured successfully!"
echo ""
echo "📊 Volume status:"
df -h "$ANALYTICS_MOUNT" "$POSTGRES_MOUNT" "$REDIS_MOUNT"
echo ""
echo "📋 Next steps:"
echo "1. Copy .env.example to .env and configure"
echo "2. Run: ./scripts/deploy.sh"
echo ""
echo "💾 Volumes are now persistent and will survive server reboots!"
echo "🔍 Verify with: lsblk && mount | grep /mnt"