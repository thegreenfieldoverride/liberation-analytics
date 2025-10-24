#!/bin/bash
# Production Liberation Analytics Deployment Script
# Handles all the complexity for smooth deployments

set -e

echo "🚀 Liberation Analytics Production Deployment"
echo "============================================="

# Function to check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.minimal.yml" ]; then
        echo "❌ Must run from liberation-analytics directory"
        exit 1
    fi
    
    # Check if volumes exist
    if [ ! -d "/mnt/analytics-volume/data" ] || [ ! -d "/mnt/postgres-volume/data" ]; then
        echo "❌ Volume subdirectories not found"
        echo "Run: sudo mkdir -p /mnt/analytics-volume/data /mnt/postgres-volume/data"
        echo "     sudo chown 1000:1000 /mnt/analytics-volume/data"
        echo "     sudo chown 999:999 /mnt/postgres-volume/data"
        exit 1
    fi
    
    # Check .env file
    if [ ! -f .env ]; then
        echo "📝 Creating .env from template..."
        cp .env.example .env
        echo "⚠️  Please edit .env and set POSTGRES_PASSWORD:"
        echo "  nano .env"
        echo ""
        echo "Then run this script again."
        exit 0
    fi
    
    # Verify .env has required variables
    if ! grep -q "POSTGRES_PASSWORD=" .env || grep -q "your_secure_postgres_password_here" .env; then
        echo "⚠️  Please set POSTGRES_PASSWORD in .env file"
        echo "  nano .env"
        exit 1
    fi
    
    echo "✅ Prerequisites check passed"
}

# Function for zero-downtime deployment
deploy_services() {
    echo ""
    echo "🔄 Performing zero-downtime deployment..."
    
    # Build new images
    echo "🏗️ Building new images..."
    docker compose -f docker-compose.minimal.yml build --no-cache
    
    # Rolling update strategy
    echo "🔄 Rolling update..."
    
    # Start new containers
    docker compose -f docker-compose.minimal.yml up -d
    
    # Wait for health
    echo "⏳ Waiting for services to be healthy..."
    sleep 15
    
    # Health check
    for i in {1..24}; do
        if curl -f -s http://localhost:8080/api/health > /dev/null; then
            echo "✅ Health check passed!"
            break
        elif [ $i -eq 24 ]; then
            echo "❌ Health check failed after 2 minutes"
            echo "🔍 Container logs:"
            docker compose -f docker-compose.minimal.yml logs liberation-analytics --tail 20
            exit 1
        else
            echo "⏳ Health check $i/24: waiting 5s..."
            sleep 5
        fi
    done
}

# Function to cleanup old resources
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    
    # Remove unused images
    docker image prune -f > /dev/null 2>&1 || true
    
    # Show final status
    echo "📊 Final status:"
    docker compose -f docker-compose.minimal.yml ps
    
    echo ""
    echo "💾 Volume usage:"
    du -sh /mnt/analytics-volume/data /mnt/postgres-volume/data 2>/dev/null || echo "Volume usage check skipped"
}

# Function to test deployment
test_deployment() {
    echo ""
    echo "🧪 Testing deployment..."
    
    # Test health endpoint
    if curl -f -s http://localhost:8080/api/health | grep -q "ok"; then
        echo "✅ Health endpoint working"
    else
        echo "❌ Health endpoint failed"
        exit 1
    fi
    
    # Test database connection
    if curl -f -s http://localhost:8080/api/health | grep -q "connected"; then
        echo "✅ Database connection working"
    else
        echo "❌ Database connection failed"
        exit 1
    fi
    
    echo "✅ All tests passed!"
}

# Main deployment flow
main() {
    check_prerequisites
    deploy_services
    test_deployment
    cleanup
    
    echo ""
    echo "🎉 Liberation Analytics deployed successfully!"
    echo "========================================"
    echo "📊 Local API: http://localhost:8080"
    echo "🔍 Health: http://localhost:8080/api/health"
    echo "🌍 Public URL: https://analytics.greenfieldoverride.com"
    echo ""
    echo "📈 Monitor with:"
    echo "  docker compose -f docker-compose.minimal.yml logs -f"
    echo "  ./scripts/maintenance.sh"
    echo ""
    echo "🔧 Maintenance commands:"
    echo "  ./scripts/maintenance.sh        # Interactive maintenance menu"
    echo "  ./scripts/cleanup-docker.sh     # Clean up Docker resources"
    echo ""
    echo "🚀 Deployment complete! Liberation Analytics is ready."
}

# Parse command line arguments
case "${1:-}" in
    "test")
        echo "🧪 Testing current deployment..."
        test_deployment
        ;;
    "status")
        echo "📊 Current status:"
        docker compose -f docker-compose.minimal.yml ps
        echo ""
        curl -s http://localhost:8080/api/health || echo "Health check failed"
        ;;
    *)
        main "$@"
        ;;
esac