# ⚡ Quick Reference Card

**Saved to:** `QUICK_REFERENCE.md`  
**Use this:** When you need quick commands/info

---

## 🚀 Start Backend (Choose One)

### Windows (Easiest)
```powershell
.\scripts\start-backend.bat
```

### Linux/macOS (Easiest)
```bash
bash scripts/start-backend.sh
```

### Manual (Any OS)
```bash
docker-compose up -d
curl http://localhost:8000/api/v1/health
```

---

## 🛑 Stop Backend

```bash
docker-compose down
```

## 🔄 Restart Backend

```bash
docker-compose restart
```

---

## 🌐 Access Services (When Running)

| Service | URL | Purpose |
|---------|-----|---------|
| **Backend** | `http://localhost:8000` | REST API |
| **API Docs** | `http://localhost:8000/docs` | Swagger UI |
| **API Docs** | `http://localhost:8000/redoc` | ReDoc |
| **PostgreSQL** | `localhost:5432` | Database |
| **Redis** | `localhost:6379` | Cache |

---

## 🗄️ Database Commands

### Connect to PostgreSQL
```bash
psql postgresql://poultry_user:poultry_dev_pass@localhost:5432/poultry_dev
```

### List tables
```sql
\dt
```

### View table schema
```sql
\d flock
```

### Create migration
```bash
docker-compose exec api alembic revision --autogenerate -m "Description"
```

### Apply migrations
```bash
docker-compose exec api alembic upgrade head
```

### Rollback migration
```bash
docker-compose exec api alembic downgrade -1
```

---

## 🔑 JWT Token Generation

```python
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Then update `JWT_SECRET_KEY` in `apps/api/.env`

---

## 📊 View Logs

```bash
# All services
docker-compose logs

# Specific service
docker-compose logs postgres      # PostgreSQL
docker-compose logs redis         # Redis
docker-compose logs api           # FastAPI

# Follow logs (live)
docker-compose logs -f api
```

---

## 🔍 Check Status

```bash
# View running containers
docker-compose ps

# Check specific service
docker-compose exec postgres pg_isready -U poultry_user
docker-compose exec redis redis-cli ping
curl http://localhost:8000/api/v1/health
```

---

## 🧪 Test API

### Health Check
```bash
curl http://localhost:8000/api/v1/health
```

### Using Postman/Insomnia
1. Open: http://localhost:8000/docs
2. Find endpoint
3. Click "Try it out"
4. Set values
5. Click "Execute"

---

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Port 8000 in use | `docker-compose down` |
| PostgreSQL won't start | `docker-compose logs postgres` |
| FastAPI won't start | `docker-compose logs api` |
| Import errors | `docker-compose rebuild api` |
| Redis connection fails | `docker-compose restart redis` |

---

## 📂 Important Files

| File | Purpose |
|------|---------|
| `BACKEND_SETUP.md` | Full setup guide |
| `API.md` | API specifications |
| `PHASE_1_CHECKLIST.md` | Tasks to implement |
| `apps/api/main.py` | FastAPI entry point |
| `apps/api/models/` | Database models |
| `infra/aws/rds_schema.sql` | Database schema |

---

## 🎯 Development Workflow

```bash
# 1. Start services
docker-compose up -d

# 2. Create endpoint file
touch apps/api/routers/my_feature.py

# 3. Implement endpoint
# Edit apps/api/routers/my_feature.py

# 4. Test endpoint
# Open http://localhost:8000/docs

# 5. Make database changes?
docker-compose exec api alembic revision --autogenerate -m "Description"
docker-compose exec api alembic upgrade head

# 6. Stop when done
docker-compose down
```

---

## 🔗 Documentation Navigation

**Just starting?**
→ Read: `GET_STARTED.md`

**Setting up?**
→ Read: `BACKEND_SETUP.md`

**Want to code?**
→ Read: `API.md` and `PHASE_1_CHECKLIST.md`

**Understanding changes?**
→ Read: `IMPLEMENTATION_SUMMARY.md`

**Lost?**
→ Read: `DOCUMENTATION_INDEX.md`

---

## 💡 Pro Tips

1. **Auto-reload enabled** - Changes to code auto-reload
2. **Hot database** - Can modify models and migrate
3. **Swagger UI** - Test endpoints without Postman
4. **Docker volumes** - Code changes persist
5. **Health checks** - Services validate automatically

---

## 🆘 Getting Help

1. Check relevant documentation
2. Check Docker logs: `docker-compose logs service_name`
3. Check database: Connect via psql
4. Check network: `docker network ls`
5. Reset everything: `docker-compose down -v && docker-compose up -d`

---

## ✨ Quick Stats

- **Setup time:** 5 minutes
- **Services:** 3 (FastAPI, PostgreSQL, Redis)
- **Tables:** 25+ with RLS
- **Documentation:** 50KB+
- **API endpoints:** 50+ spec'd
- **Code files:** 8+ modified/created

---

**Last Updated:** May 11, 2026  
**Status:** ✅ Ready to Use  
**Print this:** Great as a desk reference!
