# Liberation Analytics Makefile
# Simple commands for production deployment

.PHONY: help deploy status logs clean test health restart

# Default target
help:
	@echo "🚀 Liberation Analytics Deployment Commands"
	@echo "==========================================="
	@echo ""
	@echo "📦 Deployment:"
	@echo "  make deploy    - Deploy to production (zero-downtime)"
	@echo "  make restart   - Restart services"
	@echo ""
	@echo "📊 Monitoring:"
	@echo "  make status    - Show current status"
	@echo "  make health    - Check health endpoint"
	@echo "  make logs      - Show recent logs"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  make test      - Test current deployment"
	@echo ""
	@echo "🧹 Maintenance:"
	@echo "  make clean     - Clean up Docker resources"
	@echo "  make menu      - Interactive maintenance menu"
	@echo ""
	@echo "🔧 Direct access:"
	@echo "  ./scripts/production-deploy.sh  - Full deployment script"
	@echo "  ./scripts/maintenance.sh        - Interactive maintenance"

# Deploy to production
deploy:
	@echo "🚀 Deploying Liberation Analytics to production..."
	./scripts/production-deploy.sh

# Check current status
status:
	@echo "📊 Liberation Analytics Status:"
	@docker compose -f docker-compose.minimal.yml ps
	@echo ""
	@echo "💾 Volume usage:"
	@du -sh /mnt/analytics-volume/data /mnt/postgres-volume/data 2>/dev/null || echo "Volume check skipped"

# Check health endpoint
health:
	@echo "🔍 Health check:"
	@curl -s http://localhost:8080/api/health | jq . || curl -s http://localhost:8080/api/health

# Show recent logs
logs:
	@echo "📋 Recent logs (last 50 lines):"
	@docker compose -f docker-compose.minimal.yml logs --tail=50

# Follow logs in real time
logs-follow:
	@echo "📋 Following logs (Ctrl+C to stop):"
	@docker compose -f docker-compose.minimal.yml logs -f

# Test deployment
test:
	@echo "🧪 Testing deployment:"
	./scripts/production-deploy.sh test

# Clean up Docker resources
clean:
	@echo "🧹 Cleaning up Docker resources:"
	./scripts/cleanup-docker.sh

# Restart services
restart:
	@echo "🔄 Restarting Liberation Analytics:"
	@docker compose -f docker-compose.minimal.yml down
	@docker compose -f docker-compose.minimal.yml up -d
	@echo "⏳ Waiting for startup..."
	@sleep 10
	@make health

# Interactive maintenance menu
menu:
	@echo "🔧 Opening maintenance menu:"
	./scripts/maintenance.sh

# Build only (no deployment)
build:
	@echo "🏗️ Building Liberation Analytics:"
	@docker compose -f docker-compose.minimal.yml build

# Quick development setup
dev-setup:
	@echo "🛠️ Setting up development environment:"
	@if [ ! -f .env ]; then cp .env.example .env; echo "📝 Created .env - please configure it"; fi
	@echo "✅ Development setup complete"

# Show Docker resource usage
docker-stats:
	@echo "🐳 Docker resource usage:"
	@docker system df
	@echo ""
	@echo "📊 Container stats:"
	@docker stats --no-stream liberation-analytics liberation-postgres 2>/dev/null || echo "Containers not running"