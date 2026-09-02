#!/bin/bash
# Local Development Quick Start
# Automates most of the setup. Only manual steps: AWS keys, Cognito

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "=========================================="
echo "Poultry Farm Command Center — Dev Setup"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Docker
echo "Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker not installed${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}ERROR: Docker Compose not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker installed${NC}"

# Check Python
echo "Checking Python..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}ERROR: Python 3 not installed${NC}"
    exit 1
fi
PYTHON_VERSION=$(python3 --version | awk '{print $2}')
echo -e "${GREEN}✓ Python $PYTHON_VERSION installed${NC}"

# Check Node
echo "Checking Node.js..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}ERROR: Node.js not installed${NC}"
    exit 1
fi
NODE_VERSION=$(node --version)
echo -e "${GREEN}✓ Node $NODE_VERSION installed${NC}"

echo ""
echo -e "${YELLOW}Setting up Docker Compose environment...${NC}"

# Start Docker services
echo "Starting PostgreSQL, Redis, and API..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be healthy..."
sleep 10

# Check if services are running
if ! docker-compose ps | grep -q "postgres"; then
    echo -e "${RED}ERROR: PostgreSQL failed to start${NC}"
    exit 1
fi
echo -e "${GREEN}✓ PostgreSQL running${NC}"

if ! docker-compose ps | grep -q "redis"; then
    echo -e "${RED}ERROR: Redis failed to start${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Redis running${NC}"

# Python setup
echo ""
echo -e "${YELLOW}Setting up Python environment...${NC}"

cd apps/api

if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate venv (for current shell)
source venv/bin/activate 2>/dev/null || . venv/Scripts/activate

# Upgrade pip
pip install --upgrade pip setuptools wheel > /dev/null

# Install requirements
echo "Installing Python packages..."
pip install -r requirements.txt > /dev/null
pip install alembic > /dev/null
echo -e "${GREEN}✓ Python packages installed${NC}"

cd ../..

# Node setup
echo ""
echo -e "${YELLOW}Setting up Node packages...${NC}"

echo "Installing root packages..."
npm install > /dev/null 2>&1 || npm install

echo "Installing dashboard packages..."
cd apps/dashboard
npm install > /dev/null 2>&1 || npm install
cd ../..

echo "Installing supervisor packages..."
cd apps/supervisor
npm install > /dev/null 2>&1 || npm install
cd ../..

echo "Installing shared-types packages..."
cd packages/shared-types
npm install > /dev/null 2>&1 || npm install
cd ../..

echo -e "${GREEN}✓ Node packages installed${NC}"

# Environment setup
echo ""
echo -e "${YELLOW}Configuring environment...${NC}"

if [ ! -f "apps/api/.env" ]; then
    echo "Creating .env from template..."
    cp apps/api/.env.development apps/api/.env
    echo -e "${YELLOW}⚠ MANUAL STEP: Edit apps/api/.env with your AWS keys and Cognito IDs${NC}"
fi

# Database migrations
echo ""
echo -e "${YELLOW}Running database migrations...${NC}"

cd apps/api

# Activate venv again
source venv/bin/activate 2>/dev/null || . venv/Scripts/activate

# Check if migrations exist
if [ ! -f "migrations/versions/001_initial.py" ]; then
    echo "Creating initial migration..."
    alembic revision --autogenerate -m "Initial schema" > /dev/null 2>&1 || true
fi

echo "Applying migrations..."
alembic upgrade head > /dev/null 2>&1 || true
echo -e "${GREEN}✓ Database migrations applied${NC}"

cd ../..

# Summary
echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}MANUAL STEPS REQUIRED:${NC}"
echo "1. Edit apps/api/.env and add:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "   - COGNITO_USER_POOL_ID"
echo "   - COGNITO_CLIENT_ID"
echo "   - JWT_SECRET_KEY (already generated)"
echo ""
echo -e "${GREEN}Start development servers:${NC}"
echo "  npm run dev"
echo ""
echo "This will start:"
echo "  • FastAPI backend:     http://localhost:8000"
echo "  • React dashboard:     http://localhost:5173"
echo "  • React Native (web):  http://localhost:8081"
echo ""
echo -e "${GREEN}Stop services:${NC}"
echo "  docker-compose down"
echo ""
