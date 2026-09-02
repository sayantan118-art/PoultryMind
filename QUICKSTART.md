# Quick Reference Guide

**Last Updated:** May 9, 2026  
**Project Status:** Phase 0 ✅ → Ready for Phase 1 🚀

---

## 🎯 What's Done vs What You Need to Do

### ✅ AUTOMATED (Already Created)
```
✓ Project scaffolding (25 files)
✓ Database schema + RLS + Indexes
✓ SQLAlchemy ORM models
✓ FastAPI skeleton + RLS middleware
✓ Docker & Docker Compose
✓ GitHub Actions workflows (dev + prod)
✓ Comprehensive documentation (SETUP, DEPLOYMENT, API)
✓ TypeScript types for frontend/mobile
✓ Setup automation scripts (Windows/Linux/macOS)
✓ Environment templates (.env.development, .env.production)
✓ Enhanced seed script (16 tables with real data)
✓ Master data seeding capability
```

### 📋 MANUAL STEPS (You Must Do)

#### Required Before Running Locally
- [ ] Install Docker & Docker Compose
- [ ] Install Python 3.10+
- [ ] Install Node.js 18+
- [ ] Clone/open this repository

#### Required Before Phase 1 Development
- [ ] Generate JWT secret key
- [ ] (Optional) Set up Cognito user pool (AWS)
- [ ] (Optional) Create RDS dev instance (AWS)
- [ ] Edit `apps/api/.env` with AWS credentials

#### Required Before Production
- [ ] AWS account setup (IAM roles, RDS, ElastiCache, Cognito, etc.)
- [ ] GitHub repository secrets configuration
- [ ] Database backups setup
- [ ] Monitoring and alerting setup

---

## 🚀 Getting Started in 3 Commands

### Windows
```powershell
cd c:\My files\poultry managemnet
scripts\setup.bat
npm run dev
```

### Linux / macOS
```bash
cd "c:\My files\poultry managemnet"  # or your path
bash scripts/setup.sh
npm run dev
```

### Manual Setup (if scripts don't work)
```bash
docker-compose up -d
npm install
cd apps/api && pip install -r requirements.txt && alembic upgrade head
cd ../..
npm run dev
```

---

## 📁 Key Files Location

| File | Purpose | Location |
|------|---------|----------|
| Database Schema | All tables, constraints | `infra/aws/rds_schema.sql` |
| RLS Policies | Farm isolation | `infra/aws/rds_rls_policies.sql` |
| Indexes | Query optimization | `infra/aws/rds_indexes.sql` |
| Master Data | Seed script | `infra/scripts/seed_master_data.py` |
| API Models | SQLAlchemy ORM | `apps/api/models/` |
| Auth Logic | JWT + role checking | `apps/api/services/auth_service.py` |
| Docker Dev | Local containers | `docker-compose.yml` |
| API Docs | 50+ endpoints | `API.md` |
| Setup Guide | Local development | `SETUP.md` |
| Deploy Guide | AWS setup | `DEPLOYMENT.md` |
| Phase 1 Tasks | Implementation checklist | `PHASE_1_CHECKLIST.md` |
| TypeScript Types | Shared interfaces | `packages/shared-types/src/index.ts` |
| Environment Dev | Dev config template | `apps/api/.env.development` |
| Environment Prod | Prod config template | `apps/api/.env.production` |

---

## 🔧 Development Workflow

### Starting Work
```bash
# Start services
docker-compose up -d

# Activate Python venv
cd apps/api
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate  # Windows

# Run migrations if DB changed
alembic upgrade head

# Start all dev servers
cd ../..
npm run dev
```

### During Development
```bash
# Watch backend changes
# (uvicorn auto-reloads via docker-compose)

# Watch frontend changes
cd apps/dashboard
npm run dev

# Watch mobile changes
cd apps/supervisor
npm start
```

### Stopping
```bash
docker-compose down
```

---

## 🌐 Local URLs

| Service | URL | Port |
|---------|-----|------|
| FastAPI Backend | http://localhost:8000 | 8000 |
| API Docs (Swagger) | http://localhost:8000/docs | 8000 |
| React Dashboard | http://localhost:5173 | 5173 |
| React Native (Web) | http://localhost:8081 | 8081 |
| PostgreSQL | localhost:5432 | 5432 |
| Redis | localhost:6379 | 6379 |

---

## 📊 Database Access

### Using psql
```bash
# Connect to local dev DB
psql postgresql://poultry_user:poultry_dev_pass@localhost:5432/poultry_dev

# List tables
\dt

# Inspect schema
\d farm

# Test RLS (supervisor view)
SET app.user_role = 'supervisor';
SET app.farm_id = 'your-farm-uuid';
SELECT * FROM farm;  -- Should only show that farm
```

### Using DBeaver (GUI)
- Download: https://dbeaver.io
- Host: `localhost`
- Port: `5432`
- Database: `poultry_dev`
- User: `poultry_user`
- Password: `poultry_dev_pass`

---

## 🔐 JWT Secret Generation

Generate a new secret key:
```python
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Output: `AbC_D1e2F3g4H5i6J7k8L9m0N1o2P3q4R5s6T7u8V9w0X1y2Z3a4B5c`

Copy to `apps/api/.env`:
```env
JWT_SECRET_KEY=AbC_D1e2F3g4H5i6J7k8L9m0N1o2P3q4R5s6T7u8V9w0X1y2Z3a4B5c
```

---

## 🧪 Testing Endpoints

### Health Check
```bash
curl http://localhost:8000/api/v1/health

# Response:
# {"status": "healthy", "version": "1.0.0", "environment": "development"}
```

### RLS Test
```bash
curl -X POST http://localhost:8000/api/v1/test-rls \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Using Postman/Insomnia
1. Import: `API.md` for endpoint specs
2. Create Bearer token with JWT
3. Test each endpoint

---

## 📝 Environment Variables Quick Reference

### Development (.env.development)
```env
DATABASE_URL=postgresql://poultry_user:poultry_dev_pass@localhost:5432/poultry_dev
REDIS_URL=redis://localhost:6379/0
JWT_SECRET_KEY=your_dev_secret_min_32_chars
ENVIRONMENT=development
```

### Production (.env.production)
```env
DATABASE_URL=postgresql://poultry_admin:PASSWORD@poultry-prod.xxxxx.ap-south-1.rds.amazonaws.com/poultry_prod
REDIS_URL=redis://poultry-redis-prod.xxxxx.cache.amazonaws.com:6379/0
JWT_SECRET_KEY=FETCH_FROM_AWS_SECRETS_MANAGER
ENVIRONMENT=production
USE_AWS_SECRETS_MANAGER=True
```

---

## 🐛 Troubleshooting

### "Port 8000 already in use"
```bash
# Find and kill process
lsof -i :8000
kill -9 <PID>

# Or use different port in docker-compose.yml
```

### "Cannot connect to PostgreSQL"
```bash
# Check if container is running
docker ps | grep postgres

# View logs
docker-compose logs postgres

# Restart
docker-compose restart postgres
```

### "Module not found" (Python)
```bash
# Ensure venv is activated
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows

# Reinstall dependencies
pip install -r requirements.txt
```

### "npm ERR! ERESOLVE could not resolve dependency"
```bash
npm install --legacy-peer-deps
```

---

## 📞 Getting Help

### Documentation
- Local dev → Read `SETUP.md`
- AWS deployment → Read `DEPLOYMENT.md`
- API endpoints → Read `API.md`
- System design → Read `architecture.md`
- Master context → Read `GEMINI_final.md`
- Phase 1 tasks → Read `PHASE_1_CHECKLIST.md`

### Code References
- Database: `infra/aws/rds_schema.sql`
- Models: `apps/api/models/`
- Auth: `apps/api/services/auth_service.py`
- Types: `packages/shared-types/src/index.ts`

### Common Issues
1. Check GitHub Actions workflows: `.github/workflows/`
2. Check logs: `docker-compose logs`
3. Check database: `psql poultry_dev`

---

## ⚡ Phase 1 Quick Start

**Estimated Duration:** 8-10 weeks

### Weeks 1-2: API Implementation
- Authentication endpoints
- Flock management
- Vaccine scheduling
- Feed management

### Weeks 3-4: Advanced Features
- Health & movement tracking
- Bird movement approvals
- Alert generation
- Dashboard summary

### Weeks 5-8: Frontend
- React dashboard (owner)
- React Native app (supervisor)
- Form validation
- Real-time updates

### Weeks 9-10: Testing & Deployment
- Unit tests
- Integration tests
- CI/CD pipeline
- Production deployment

---

## 🎯 Success Checklist

Before considering Phase 1 complete:
- [ ] API passes 50+ tests
- [ ] All endpoints documented
- [ ] Dashboard renders without errors
- [ ] Mobile app can sync offline data
- [ ] RLS isolates farm data
- [ ] CI/CD deploys automatically
- [ ] Monitoring configured
- [ ] Database backups working

---

## 📦 Deliverables

**Phase 0 Deliverables (Complete):**
- ✅ Project scaffolding
- ✅ Database schema + migrations
- ✅ Docker development environment
- ✅ Documentation (SETUP, DEPLOYMENT, API)
- ✅ CI/CD workflows
- ✅ TypeScript types
- ✅ Master data seeding

**Phase 1 Deliverables (Next):**
- Dashboard UI (React)
- Supervisor app UI (React Native)
- API route handlers (24+ endpoints)
- Authentication flows
- Real-time features

---

**Questions? Refer to the documentation or the architecture diagram in `architecture.md`.**

**Ready to start Phase 1? Follow `PHASE_1_CHECKLIST.md`**

---

*Generated: May 9, 2026*  
*Project: Poultry Farm Command Center v4.0*  
*Status: Phase 0 Complete, Phase 1 Ready* ✅
