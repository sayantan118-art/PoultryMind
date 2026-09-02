# Backend setup

Use [SETUP.md](SETUP.md) as the main setup guide.

## Quick start

```bash
cp .env.example .env
# set your local values

docker-compose up -d
```

Then verify the API:

```bash
curl http://localhost:8000/api/v1/health
```

## Important runtime note

- local Python: `localhost`
- Docker container: `postgres`

This is intentional and is required for the Dockerized app to reach Postgres correctly.

## Full developer setup

See [SETUP.md](SETUP.md) for the canonical instructions and environment rules.

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
