.PHONY: help deploy deploy-dashboard status health logs logs-dashboard stop clean build test

# Default target
help:
	@echo "Liberation Analytics - Available Commands:"
	@echo ""
	@echo "🚀 Deployment:"
	@echo "  make deploy           Deploy Liberation Analytics (API only)"
	@echo "  make deploy-dashboard Deploy Liberation Analytics with Dashboard"
	@echo ""
	@echo "📊 Monitoring:"
	@echo "  make status           Show service status"
	@echo "  make health           Check service health"
	@echo "  make logs             Show Analytics API logs"
	@echo "  make logs-dashboard   Show Dashboard logs"
	@echo ""
	@echo "🔧 Management:"
	@echo "  make stop             Stop all services"
	@echo "  make clean            Stop and remove containers"
	@echo "  make build            Build images locally"
	@echo "  make test             Run tests"
	@echo ""

# Deploy analytics API only
deploy:
	@./scripts/deploy.sh

# Deploy with dashboard
deploy-dashboard:
	@./scripts/deploy.sh --dashboard

# Show service status
status:
	@echo "🔍 Service Status:"
	@docker-compose ps
	@echo ""
	@echo "📊 Dashboard Status (if running):"
	@docker-compose -f docker-compose.dashboard.yml ps

# Check health endpoints
health:
	@echo "🔍 Checking Liberation Analytics health..."
	@curl -s http://localhost:8080/api/health | jq . || echo "❌ Analytics API not responding"
	@echo ""
	@echo "🔍 Checking Dashboard health..."
	@curl -s http://localhost:8081 > /dev/null && echo "✅ Dashboard is responding" || echo "❌ Dashboard not responding"

# Show analytics logs
logs:
	@docker-compose logs -f liberation-analytics

# Show dashboard logs
logs-dashboard:
	@docker-compose -f docker-compose.dashboard.yml logs -f liberation-dashboard

# Stop services
stop:
	@echo "🛑 Stopping Liberation Analytics services..."
	@docker-compose down
	@docker-compose -f docker-compose.dashboard.yml down

# Clean up containers and images
clean:
	@echo "🧹 Cleaning up containers and images..."
	@docker-compose down --rmi all --volumes
	@docker-compose -f docker-compose.dashboard.yml down --rmi all

# Build images locally
build:
	@echo "🔨 Building Liberation Analytics..."
	@docker-compose build
	@echo "🔨 Building Dashboard..."
	@docker-compose -f docker-compose.dashboard.yml build

# Run tests
test:
	@echo "🧪 Running Go tests..."
	@go test ./...
	@echo "🧪 Testing Dashboard build..."
	@cd dashboard && npm run build