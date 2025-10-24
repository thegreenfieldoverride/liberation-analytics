#!/bin/bash
# Docker cleanup script for Liberation Analytics
# Removes unused containers, images, and build cache

set -e

echo "🧹 Liberation Analytics Docker Cleanup"
echo "======================================="

# Show current disk usage
echo "📊 Current Docker disk usage:"
docker system df
echo ""

# Confirm cleanup
read -p "🗑️  Proceed with Docker cleanup? This will remove unused images and containers. (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo ""
echo "🧹 Starting cleanup..."

# Remove stopped containers
echo "🗑️  Removing stopped containers..."
docker container prune -f

# Remove dangling/unused images
echo "🗑️  Removing unused images..."
docker image prune -f

# Remove build cache
echo "🗑️  Removing build cache..."
docker builder prune -f

# Remove unused networks
echo "🗑️  Removing unused networks..."
docker network prune -f

# Optional: Remove ALL unused images (not just dangling)
read -p "🗑️  Remove ALL unused images? This includes images not currently used by containers. (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing all unused images..."
    docker image prune -a -f
fi

# Show space saved
echo ""
echo "✅ Cleanup complete!"
echo "📊 Updated Docker disk usage:"
docker system df

echo ""
echo "💾 Space savings summary:"
echo "  - Removed unused containers, images, and build cache"
echo "  - Liberation Analytics containers are preserved"
echo "  - Active volumes are preserved"

echo ""
echo "🔍 To see running Liberation Analytics containers:"
echo "  docker compose ps"
echo ""
echo "🚀 To restart Liberation Analytics if needed:"
echo "  docker compose -f docker-compose.minimal.yml up -d"