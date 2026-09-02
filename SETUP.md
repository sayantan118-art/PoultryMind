# Local Development Setup Guide

This guide walks you through setting up the Poultry Farm Command Center for local development.

---

## Prerequisites

- **Node.js** 18+ (for dashboard and supervisor app)
- **Python** 3.10+ (for FastAPI backend)
- **Docker** + Docker Compose (optional, for database/redis)
- **Git** (version control)
- **PostgreSQL** 15+ (if not using Docker)

---

## Quick Start (with Docker)

### 1. Clone and Install

```bash
git clone <your-repo> poultry-farm
cd poultry-farm

# Install root dependencies (Turborepo)
npm install

# Install app-specific dependencies
cd apps/api
pip install -r requirements.txt
pip install alembic

cd ../dashboard
npm install

cd ../supervisor
npm install

cd ../../packages/shared-types
npm install
```

### 2. Start Development Environment

```bash
# From root directory
docker-compose up -d

# Verify services are running
docker ps
# Should show: postgres, redis, api containers
```

### 3. Run Database Migrations

```bash
cd apps/api

# Create initial migration from existing schema
alembic revision --autogenerate -m "Initial schema"

# Apply migration
alembic upgrade head
```

### 4. Start All Services

```bash
# From root directory
npm run dev

# This starts:
# - FastAPI backend at http://localhost:8000
# - React dashboard at http://localhost:5173
# - Supervisor app (web) at http://localhost:8081
```

### 5. Test the Setup

```bash
# Health check
curl http://localhost:8000/api/v1/health

# Should return:
# {"status": "healthy", "version": "1.0.0", "environment": "development"}

# RLS test endpoint
curl http://localhost:8000/api/v1/test-rls
```

---

## Manual Setup (without Docker)

### 1. PostgreSQL Setup

```bash
# Create database
createdb poultry_dev

# Run schema scripts in order
psql poultry_dev < infra/aws/rds_schema.sql
psql poultry_dev < infra/aws/rds_rls_policies.sql
psql poultry_dev < infra/aws/rds_indexes.sql

# Seed master data
python infra/scripts/seed_master_data.py | psql poultry_dev
```

### 2. Redis Setup

```bash
# On macOS with Homebrew
brew install redis
brew services start redis

# On Linux
sudo apt-get install redis-server
sudo systemctl start redis-server

# Verify
redis-cli ping  # Should return PONG
```

### 3. Environment Configuration

```bash
# Create .env file at root or in apps/api
cp .env.example .env

# Edit .env with your local details
cat > .env << EOF
DATABASE_URL=postgresql://user:pass@localhost:5432/poultry_dev
REDIS_URL=redis://localhost:6379/0
ENVIRONMENT=development
JWT_SECRET_KEY=your_super_secret_key_min_32_chars
APP_PORT=8000
COGNITO_USER_POOL_ID=
COGNITO_CLIENT_ID=
EOF
```

### 4. Python Backend

```bash
cd apps/api

# Create virtual environment
python -m venv venv

# Activate
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install alembic

# Run migrations
alembic upgrade head

# Start backend
uvicorn main:app --reload
# Runs on http://localhost:8000
```

### 5. Frontend Setup

```bash
# Dashboard (React + Vite)
cd apps/dashboard
npm install
npm run dev
# Runs on http://localhost:5173

# Supervisor App (React Native + Expo)
cd apps/supervisor
npm install
npm start
# Runs on http://localhost:8081 (web)
# Or use: npm run android / npm run ios
```

---

## Project Structure

```
poultry-farm/
├── apps/
│   ├── api/
│   │   ├── main.py              # FastAPI entry point
│   │   ├── config.py            # Settings
│   │   ├── models/              # SQLAlchemy ORM
│   │   ├── services/            # Auth, business logic
│   │   ├── requirements.txt
│   │   ├── alembic.ini
│   │   └── migrations/          # Database migrations
│   ├── dashboard/               # React web app
│   └── supervisor/              # React Native app
├── packages/
│   ├── shared-types/            # TypeScript types
│   └── ui-components/           # Shared React components
├── infra/
│   ├── aws/                     # AWS SQL scripts
│   └── scripts/                 # Data seeding
├── .github/workflows/           # CI/CD pipelines
├── docker-compose.yml
├── Dockerfile
├── package.json                 # Root Turborepo
└── .env.example
```

---

## Common Commands

### Backend (FastAPI)

```bash
cd apps/api
source venv/bin/activate

# Start development server
uvicorn main:app --reload

# Run tests
pytest

# Format code
black .

# Type checking
mypy .
```

### Frontend (React Dashboard)

```bash
cd apps/dashboard

# Start dev server
npm run dev

# Build for production
npm run build

# Lint
npm run lint

# Preview build
npm run preview
```

### Mobile (React Native)

```bash
cd apps/supervisor

# Start Expo development server
npm start

# Web
npm run web

# Android
npm run android

# iOS
npm run ios
```

### Root (Monorepo)

```bash
# Build all apps
npm run build

# Run all dev servers
npm run dev

# Lint all apps
npm run lint

# Run tests in all apps
npm run test
```

---

## Database Debugging

### Connect to PostgreSQL

```bash
# Using psql
psql postgresql://user:pass@localhost:5432/poultry_dev

# List all tables
\dt

# View schema for a table
\d farm

# Test RLS policies
SET app.user_role = 'supervisor';
SET app.farm_id = 'your-farm-uuid';
SELECT * FROM farm;  -- Should filter by farm_id
```

### Redis Commands

```bash
redis-cli

# Check all keys
KEYS *

# Monitor operations
MONITOR

# Flush cache
FLUSHALL
```

---

## Troubleshooting

### "Cannot connect to PostgreSQL"

```bash
# Check if service is running
# Docker:
docker ps | grep postgres

# Native:
pg_isready -h localhost -p 5432

# If not running, start it
docker-compose up -d postgres
# or
brew services start postgresql
```

### "Module not found" (Python)

```bash
# Ensure venv is activated
source venv/bin/activate

# Reinstall requirements
pip install --upgrade -r requirements.txt
```

### "Port 8000 already in use"

```bash
# Kill process using port
# Windows:
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# macOS/Linux:
lsof -i :8000
kill -9 <PID>
```

### "CORS error"

Ensure `ALLOWED_ORIGINS` in `.env` includes your frontend:

```env
ALLOWED_ORIGINS=["http://localhost:5173", "http://localhost:8081", "http://localhost:3000"]
```

---

## Next Steps

- Read [DEPLOYMENT.md](DEPLOYMENT.md) for AWS setup
- Read [API.md](API.md) for endpoint documentation
- Check [architecture.md](architecture.md) for system design details

---

## Support

For issues, check:
1. [architecture.md](architecture.md) - System design overview
2. [GEMINI_final.md](GEMINI_final.md) - Master context document
3. GitHub Issues in the repository
