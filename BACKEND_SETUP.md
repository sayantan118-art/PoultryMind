# Backend Development Environment Setup

**Last Updated:** May 11, 2026  
**Status:** Ready for Local Development

---

## 📋 Prerequisites

Before starting, ensure you have installed:

1. **Docker & Docker Compose**
   - Windows: Download from https://www.docker.com/products/docker-desktop
   - macOS: Download from https://www.docker.com/products/docker-desktop
   - Linux: `sudo apt-get install docker.io docker-compose`
   - Verify: `docker --version && docker-compose --version`

2. **Python 3.10+**
   - Download from https://www.python.org/downloads/
   - Verify: `python --version`

3. **Git**
   - Download from https://git-scm.com/
   - Verify: `git --version`

---

## 🚀 Quick Start (5 minutes)

### Step 1: Start Docker Services

```bash
cd "c:\My files\poultry managemnet"
docker-compose up -d
```

Verify services are running:
```bash
docker-compose ps
```

Expected output:
```
NAME                COMMAND                STATUS
poultry_api_dev     uvicorn main:app...   Up (healthy)
poultry_db_dev      postgres:15-alpine     Up (healthy)
poultry_redis_dev   redis:7-alpine         Up (healthy)
```

### Step 2: Verify Backend is Running

```bash
# Check health endpoint
curl http://localhost:8000/api/v1/health

# Expected response:
# {"status": "healthy", "version": "1.0.0", "environment": "development"}
```

**That's it! Your backend is running.** 🎉

---

## 📦 Project Structure

```
apps/api/
├── main.py                 # FastAPI app entry point
├── config.py               # Settings and configuration
├── dependencies.py         # Database and dependency injection
├── requirements.txt        # Python dependencies
├── .env.development        # Dev environment template
│
├── models/                 # SQLAlchemy ORM models
│   ├── base.py            # Base class with UUID, timestamps, soft delete
│   ├── flock.py           # Flock and daily snapshot models
│   ├── feed.py            # Feed formula, batch, dispatch models
│   ├── vaccine.py         # Vaccine schedule and models
│   ├── health.py          # Health monitoring models
│   ├── inventory.py       # Inventory and material models
│   ├── master.py          # Master data models (farm, shed, breed, etc)
│   └── intelligence.py    # Intelligence and reporting models
│
├── services/              # Business logic
│   └── auth_service.py    # JWT authentication
│
├── routers/               # API route handlers (to be implemented)
│   └── (empty - routes will be added per endpoint)
│
├── schemas/               # Pydantic request/response schemas (to be implemented)
│   └── (empty - schemas will be added as needed)
│
├── jobs/                  # Background jobs (APScheduler, Celery tasks)
│   └── (empty - jobs will be added as needed)
│
└── migrations/            # Alembic database migrations
    ├── env.py             # Alembic environment configuration
    ├── script.py.mako     # Alembic migration template
    └── versions/          # Migration files (auto-generated)
```

---

## 🔧 Local Development Workflow

### Development Setup (First Time Only)

```bash
# 1. Clone the repository
git clone https://github.com/your-org/poultry-farm.git
cd poultry-farm

# 2. Copy environment file
cp apps/api/.env.development apps/api/.env

# 3. (Optional) Edit .env with your settings
# Editor of choice: apps/api/.env
```

### Starting Services

```bash
# Start Docker services (PostgreSQL, Redis, FastAPI)
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down
```

### Making Database Changes

```bash
# Generate migration from model changes
docker-compose exec api alembic revision --autogenerate -m "Add new column to flock"

# Review generated migration: apps/api/migrations/versions/xxxx_*.py

# Apply migration
docker-compose exec api alembic upgrade head

# Rollback migration
docker-compose exec api alembic downgrade -1
```

### Testing the API

```bash
# Health check
curl http://localhost:8000/api/v1/health

# View interactive API docs
# Open browser: http://localhost:8000/docs

# Test RLS context (requires valid JWT)
curl -X GET http://localhost:8000/api/v1/test-rls \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 🔐 JWT Token Generation

Generate a JWT token for local testing:

```python
# Run this in Python shell or create jwt_test.py
import jwt
import json
from datetime import datetime, timedelta

SECRET_KEY = "your_super_secret_dev_key_min_32_characters_very_secret"
ALGORITHM = "HS256"

payload = {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "farm_id": "550e8400-e29b-41d4-a716-446655440001",
    "user_role": "supervisor",
    "exp": datetime.utcnow() + timedelta(hours=24)
}

token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
print(f"Bearer token: {token}")
```

Use in requests:
```bash
curl -X GET http://localhost:8000/api/v1/test-rls \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🗄️ Database Management

### Connecting to PostgreSQL

**Using psql (Command Line):**
```bash
psql postgresql://poultry_user:poultry_dev_pass@localhost:5432/poultry_dev
```

**Using DBeaver (GUI):**
1. Download: https://dbeaver.io
2. Create new PostgreSQL connection:
   - Host: `localhost`
   - Port: `5432`
   - Database: `poultry_dev`
   - Username: `poultry_user`
   - Password: `poultry_dev_pass`

### Common Database Commands

```sql
-- List all tables
\dt

-- Inspect table schema
\d flock

-- View Row Level Security policies
SELECT * FROM pg_policies;

-- Test RLS (as supervisor)
SET app.user_role = 'supervisor';
SET app.farm_id = '550e8400-e29b-41d4-a716-446655440001';
SELECT * FROM farm;  -- Should show only assigned farm
```

### Seeding Test Data

```bash
# Run seed script from container
docker-compose exec api python infra/scripts/seed_master_data.py

# Or from local machine
python infra/scripts/seed_master_data.py \
  --db-url "postgresql://poultry_user:poultry_dev_pass@localhost:5432/poultry_dev"
```

---

## 🐛 Troubleshooting

### Problem: Port 8000 Already in Use

```bash
# Find process using port 8000
lsof -i :8000
# Kill process
kill -9 <PID>

# Or use different port in docker-compose.yml
```

### Problem: PostgreSQL Connection Fails

```bash
# Check if container is running
docker ps | grep postgres

# View logs
docker-compose logs postgres

# Restart PostgreSQL
docker-compose restart postgres

# Force recreate (WARNING: deletes data)
docker-compose down -v
docker-compose up -d postgres
```

### Problem: Alembic Import Errors

```bash
# Issue: ModuleNotFoundError: No module named 'models'

# Solution: Ensure Python path is correct
docker-compose exec api python -c "import sys; print(sys.path)"

# Rebuild API container
docker-compose build --no-cache api
docker-compose up -d api
```

### Problem: FastAPI Not Starting

```bash
# View detailed logs
docker-compose logs -f api

# Check configuration
docker-compose exec api python -c "from config import settings; print(settings)"

# Test imports manually
docker-compose exec api python -c "from main import app; print('OK')"
```

### Problem: Redis Connection Error

```bash
# Check Redis is running
docker-compose logs redis

# Test connection
docker-compose exec redis redis-cli ping
# Should return: PONG

# Restart Redis
docker-compose restart redis
```

---

## 📝 Environment Variables Reference

### Required for Local Development

```env
# Database
DATABASE_URL=postgresql://poultry_user:poultry_dev_pass@localhost:5432/poultry_dev

# Redis
REDIS_URL=redis://localhost:6379/0

# JWT Secret (generate: python -c "import secrets; print(secrets.token_urlsafe(32))")
JWT_SECRET_KEY=your_super_secret_dev_key_min_32_characters_very_secret

# Environment
ENVIRONMENT=development
APP_PORT=8000
LOG_LEVEL=DEBUG
```

### Optional (AWS Integration)

```env
# AWS credentials (use IAM roles in production!)
AWS_ACCESS_KEY_ID=YOUR_KEY
AWS_SECRET_ACCESS_KEY=YOUR_SECRET
AWS_REGION=ap-south-1

# Cognito (set up in AWS Console first)
COGNITO_USER_POOL_ID=ap-south-1_XXXXXXXX
COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxx
```

See `apps/api/.env.development` for all available options.

---

## ✅ Verification Checklist

Before starting development, verify:

- [ ] Docker Desktop is running
- [ ] `docker-compose ps` shows 3 healthy containers
- [ ] `curl http://localhost:8000/api/v1/health` returns status: healthy
- [ ] PostgreSQL is accessible: `psql postgresql://poultry_user:poultry_dev_pass@localhost:5432/poultry_dev`
- [ ] Redis is responsive: `docker-compose exec redis redis-cli ping` returns PONG
- [ ] Models import correctly: `docker-compose exec api python -c "from models.base import Base; print('OK')"`
- [ ] Alembic is configured: `docker-compose exec api alembic current` shows current version

---

## 📚 Additional Resources

- **API Documentation:** Read `API.md` for endpoint specifications
- **Deployment Guide:** Read `DEPLOYMENT.md` for AWS production setup
- **Architecture:** Read `architecture.md` for system design
- **Phase 1 Tasks:** Read `PHASE_1_CHECKLIST.md` for implementation roadmap

---

## 🚦 Next Steps

1. **Understand the Database Schema**
   - Review `infra/aws/rds_schema.sql`
   - Review `infra/aws/rds_rls_policies.sql`

2. **Review API Models**
   - Read through `apps/api/models/*.py`
   - Understand relationships between tables

3. **Implement First Endpoint**
   - Create route in `apps/api/routers/flock.py`
   - Create schema in `apps/api/schemas/flock.py`
   - Test in Swagger UI: http://localhost:8000/docs

4. **Add Authentication**
   - Implement login endpoint
   - Generate JWT tokens
   - Protect routes with `Depends(get_current_user)`

---

**Ready to develop? Start with Phase 1 tasks in `PHASE_1_CHECKLIST.md`**

*Project: Poultry Farm Command Center v4.0*  
*Status: Phase 0 Complete, Phase 1 Ready* ✅
