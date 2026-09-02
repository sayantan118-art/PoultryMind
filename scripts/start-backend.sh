#!/bin/bash
# Backend startup script for local development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Poultry Farm Backend - Startup Script${NC}"
echo "========================================"

# Check if Docker is running
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed or not in PATH${NC}"
    exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}📍 Project Root: $PROJECT_ROOT${NC}"

# Step 1: Copy environment file if it doesn't exist
if [ ! -f "$PROJECT_ROOT/apps/api/.env" ]; then
    echo -e "${YELLOW}📝 Creating .env from template...${NC}"
    cp "$PROJECT_ROOT/apps/api/.env.development" "$PROJECT_ROOT/apps/api/.env"
    echo -e "${GREEN}✅ Created apps/api/.env${NC}"
else
    echo -e "${GREEN}✅ apps/api/.env already exists${NC}"
fi

# Step 2: Build and start containers
echo -e "${YELLOW}🐳 Starting Docker Compose services...${NC}"
cd "$PROJECT_ROOT"
docker-compose build --no-cache api
docker-compose up -d

# Step 3: Wait for services to be healthy
echo -e "${YELLOW}⏳ Waiting for services to be healthy...${NC}"
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if docker-compose exec -T postgres pg_isready -U poultry_user >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL is healthy${NC}"
        break
    fi
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${RED}❌ PostgreSQL failed to start${NC}"
        docker-compose logs postgres
        exit 1
    fi
    sleep 1
done

# Step 4: Verify Redis
if docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Redis is healthy${NC}"
else
    echo -e "${RED}❌ Redis failed to respond${NC}"
    docker-compose logs redis
    exit 1
fi

# Step 5: Verify FastAPI
attempt=0
max_attempts=30

while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:8000/api/v1/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ FastAPI is healthy${NC}"
        break
    fi
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${RED}❌ FastAPI failed to start${NC}"
        docker-compose logs api
        exit 1
    fi
    sleep 1
done

# Step 6: Display summary
echo ""
echo -e "${GREEN}✅ All services are running!${NC}"
echo ""
echo -e "${YELLOW}📊 Service URLs:${NC}"
echo "  🔵 FastAPI Backend:     http://localhost:8000"
echo "  📚 API Docs (Swagger):  http://localhost:8000/docs"
echo "  🗄️  PostgreSQL:          localhost:5432"
echo "  🚀 Redis:                localhost:6379"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "  1. Generate JWT token: python -c \"import secrets; print(secrets.token_urlsafe(32))\""
echo "  2. Update JWT_SECRET_KEY in apps/api/.env"
echo "  3. Test health endpoint: curl http://localhost:8000/api/v1/health"
echo "  4. Visit Swagger UI: http://localhost:8000/docs"
echo ""
echo -e "${YELLOW}📖 Documentation:${NC}"
echo "  • Backend Setup: Read BACKEND_SETUP.md"
echo "  • API Endpoints: Read API.md"
echo "  • Deployment: Read DEPLOYMENT.md"
echo ""
echo -e "${YELLOW}🛑 To stop services:${NC}"
echo "  docker-compose down"
echo ""
