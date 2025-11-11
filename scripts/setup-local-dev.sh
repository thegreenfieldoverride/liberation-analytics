#!/bin/bash
# Liberation Analytics - Local Development Setup
# This script sets up everything needed for local development

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Liberation Analytics - Local Development Setup${NC}"
echo "================================================="

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is running${NC}"

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose is not installed. Please install Docker Compose.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker Compose is available${NC}"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Creating .env file from .env.development...${NC}"
    cp .env.development .env
    echo -e "${GREEN}✅ Created .env file${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Create data directories
echo -e "${YELLOW}📁 Creating local data directories...${NC}"
mkdir -p data/analytics
mkdir -p data/postgres
mkdir -p data/redis

# Set proper permissions
chmod 755 data/analytics
chmod 700 data/postgres  # PostgreSQL needs restricted permissions
chmod 755 data/redis

echo -e "${GREEN}✅ Created data directories${NC}"

# Check for Go installation (needed for building)
if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}⚠️  Go is not installed. You'll need Go 1.21+ to build the analytics service.${NC}"
    echo -e "${YELLOW}   Visit https://golang.org/dl/ to install Go${NC}"
else
    echo -e "${GREEN}✅ Go is installed: $(go version)${NC}"
fi

# Build the analytics service
if command -v go &> /dev/null; then
    echo -e "${YELLOW}🔨 Building analytics service...${NC}"
    go mod download
    CGO_ENABLED=1 go build -o liberation-analytics-dev ./main.go
    echo -e "${GREEN}✅ Built analytics service${NC}"
else
    echo -e "${YELLOW}⚠️  Skipping build - Go not available${NC}"
fi

# Stop any existing development containers
echo -e "${YELLOW}🛑 Stopping any existing development containers...${NC}"
docker-compose -f docker-compose.dev.yml down 2>/dev/null || true

# Pull required Docker images
echo -e "${YELLOW}📥 Pulling Docker images...${NC}"
docker-compose -f docker-compose.dev.yml pull

# Start the development environment
echo -e "${YELLOW}🚀 Starting Liberation Analytics development environment...${NC}"
docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 10

# Check service health
echo -e "${YELLOW}🔍 Checking service health...${NC}"

# Check PostgreSQL
echo -n "PostgreSQL: "
if docker exec liberation-postgres-dev pg_isready -U postgres -d liberation_analytics_dev >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Healthy${NC}"
else
    echo -e "${RED}❌ Not responding${NC}"
fi

# Check Redis
echo -n "Redis: "
if docker exec liberation-redis-dev redis-cli ping >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Healthy${NC}"
else
    echo -e "${RED}❌ Not responding${NC}"
fi

# Check Analytics API
echo -n "Analytics API: "
sleep 5  # Give analytics a bit more time to start
for i in {1..6}; do
    if curl -s http://localhost:8080/api/health >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Healthy${NC}"
        break
    elif [ $i -eq 6 ]; then
        echo -e "${RED}❌ Not responding after 30 seconds${NC}"
        echo -e "${YELLOW}📋 Check logs with: docker-compose -f docker-compose.dev.yml logs liberation-analytics-dev${NC}"
    else
        sleep 5
    fi
done

echo ""
echo -e "${GREEN}🎉 Liberation Analytics development environment is ready!${NC}"
echo "================================================="
echo ""
echo -e "${GREEN}🔗 Service URLs:${NC}"
echo "  📊 Analytics API:  http://localhost:8080"
echo "  🔍 Health Check:   http://localhost:8080/api/health"
echo "  🗄️  PostgreSQL:     localhost:5433 (user: postgres, db: liberation_analytics_dev)"
echo "  📦 Redis:          localhost:6380"
echo ""
echo -e "${GREEN}📋 Development Commands:${NC}"
echo "  View logs:         docker-compose -f docker-compose.dev.yml logs -f"
echo "  Stop services:     docker-compose -f docker-compose.dev.yml down"
echo "  Restart:           docker-compose -f docker-compose.dev.yml restart"
echo "  View containers:   docker-compose -f docker-compose.dev.yml ps"
echo ""
echo -e "${GREEN}🧪 Test the API:${NC}"
echo "  curl http://localhost:8080/api/health"
echo ""
echo -e "${GREEN}🔧 Integration with Frontend:${NC}"
echo "  Set NEXT_PUBLIC_ANALYTICS_URL=http://localhost:8080/api in your frontend .env"
echo ""
echo -e "${GREEN}✨ Happy developing!${NC}"