# Quickstart

Use [SETUP.md](SETUP.md) as the canonical setup guide.

## Fastest path

```bash
cp .env.example .env
# set your local secrets in .env

docker-compose up -d
```

Then verify:

```bash
curl http://localhost:8000/api/v1/health
```

## Important notes

- direct local Python uses `localhost`
- Docker uses `postgres` and `redis`
- secrets are required and not defaulted in code

For the full instructions, see [SETUP.md](SETUP.md).

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
