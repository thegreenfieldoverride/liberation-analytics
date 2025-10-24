#!/bin/bash
# Liberation Analytics Maintenance Script
# Combined maintenance tasks for production deployment

set -e

echo "🔧 Liberation Analytics Maintenance"
echo "===================================="

# Function to show menu
show_menu() {
    echo ""
    echo "Select maintenance task:"
    echo "1) 🧹 Docker cleanup (remove unused images/containers)"
    echo "2) 📊 System status (containers, volumes, disk usage)"
    echo "3) 📋 View logs (last 50 lines)"
    echo "4) 🔄 Restart services"
    echo "5) 🔍 Health check"
    echo "6) 💾 Database status (PostgreSQL + DuckDB)"
    echo "7) 🗂️  Volume status (Hetzner volumes)"
    echo "8) 🚀 Full maintenance (cleanup + restart + health check)"
    echo "0) Exit"
    echo ""
}

# Docker cleanup
docker_cleanup() {
    echo "🧹 Running Docker cleanup..."
    ./scripts/cleanup-docker.sh
}

# System status
system_status() {
    echo "📊 System Status"
    echo "================"
    echo ""
    echo "🐳 Docker containers:"
    docker compose ps
    echo ""
    echo "💾 Volume usage:"
    df -h /mnt/analytics-volume /mnt/postgres-volume 2>/dev/null || echo "Volumes not mounted"
    echo ""
    echo "🖥️  System resources:"
    free -h | head -2
    echo ""
    echo "💿 Disk usage:"
    df -h / | tail -1
}

# View logs
view_logs() {
    echo "📋 Liberation Analytics Logs (last 50 lines)"
    echo "============================================"
    docker compose logs --tail=50 liberation-analytics
}

# Restart services
restart_services() {
    echo "🔄 Restarting Liberation Analytics..."
    docker compose -f docker-compose.minimal.yml down
    docker compose -f docker-compose.minimal.yml up -d
    echo "✅ Services restarted"
    sleep 5
    health_check
}

# Health check
health_check() {
    echo "🔍 Health Check"
    echo "==============="
    echo ""
    
    # Check containers
    echo "🐳 Container status:"
    docker compose ps
    echo ""
    
    # Check HTTP health
    echo "🌐 HTTP health check:"
    if curl -f -s http://localhost:8080/api/health > /dev/null; then
        echo "✅ Liberation Analytics API is healthy"
        curl -s http://localhost:8080/api/health | head -3
    else
        echo "❌ Liberation Analytics API health check failed"
        echo "Recent logs:"
        docker compose logs --tail=10 liberation-analytics
    fi
}

# Database status
database_status() {
    echo "💾 Database Status"
    echo "=================="
    echo ""
    
    echo "🐘 PostgreSQL status:"
    docker compose exec postgres pg_isready -U liberation -d liberation_analytics || echo "❌ PostgreSQL not accessible"
    
    echo ""
    echo "🦆 DuckDB files:"
    ls -la /mnt/analytics-volume/ | grep -E "(\.db|\.duckdb)" || echo "No DuckDB files found"
    
    echo ""
    echo "📊 Database sizes:"
    du -h /mnt/postgres-volume/ 2>/dev/null | tail -1 || echo "PostgreSQL volume not accessible"
    du -h /mnt/analytics-volume/ 2>/dev/null | tail -1 || echo "Analytics volume not accessible"
}

# Volume status
volume_status() {
    echo "🗂️  Volume Status"
    echo "=================="
    echo ""
    
    echo "📁 Mount points:"
    mount | grep -E "(analytics|postgres)" || echo "No liberation volumes mounted"
    
    echo ""
    echo "💿 Volume usage:"
    df -h | grep -E "(analytics|postgres)" || echo "Volume usage not available"
    
    echo ""
    echo "🔗 Symlinks:"
    ls -la /mnt/ | grep -E "(analytics|postgres)" || echo "No liberation symlinks found"
}

# Full maintenance
full_maintenance() {
    echo "🚀 Running Full Maintenance"
    echo "==========================="
    
    system_status
    echo ""
    
    docker_cleanup
    echo ""
    
    restart_services
    echo ""
    
    database_status
    echo ""
    
    echo "✅ Full maintenance complete!"
}

# Main menu loop
while true; do
    show_menu
    read -p "Enter choice [0-8]: " choice
    
    case $choice in
        1) docker_cleanup ;;
        2) system_status ;;
        3) view_logs ;;
        4) restart_services ;;
        5) health_check ;;
        6) database_status ;;
        7) volume_status ;;
        8) full_maintenance ;;
        0) echo "👋 Goodbye!"; exit 0 ;;
        *) echo "❌ Invalid option. Please choose 0-8." ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done