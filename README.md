# Poultry Farm Command Center — Enterprise Monorepo

Enterprise operational command center for a 5-lakh+ bird layer poultry operation.

## Structure

- `apps/api`: Python + FastAPI backend (Intelligence Engine, REST API)
- `apps/dashboard`: React + Vite + TypeScript (Owner web dashboard)
- `apps/supervisor`: React Native + Expo + WatermelonDB (Supervisor mobile app)
- `packages/shared-types`: TypeScript types shared between dashboard and supervisor
- `packages/ui-components`: Shared React components
- `infra/aws`: RDS Schema, Indexes, RLS Policies, and Task Definitions

## Technology Stack

- **Backend**: Python 3.10+, FastAPI, SQLAlchemy, Alembic
- **Frontend**: React 18, Vite, TypeScript, React Query, Zustand
- **Mobile**: React Native, Expo, WatermelonDB (Offline-first)
- **Database**: AWS RDS PostgreSQL 15+, Redis (Caching)
- **Auth**: AWS Cognito + JWT
- **Infrastructure**: AWS ECS Fargate, S3, CloudFront, Route 53

## Getting Started

### 🚀 Quick Start (Docker) - Recommended

**Windows:**
```powershell
cd "c:\My files\poultry managemnet"
.\scripts\start-backend.bat
```

**Linux/macOS:**
```bash
cd "c:\My files\poultry managemnet"
bash scripts/start-backend.sh
```

**Manual:**
```bash
docker-compose up -d
# Check: curl http://localhost:8000/api/v1/health
```

### Backend (Traditional)
```bash
cd apps/api
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

### Dashboard
```bash
cd apps/dashboard
npm install
npm run dev
```

### Supervisor
```bash
cd apps/supervisor
npm install
npx expo start
```

## Phase 0 Status
- [x] Monorepo Initialized
- [x] PostgreSQL Schema Defined (infra/aws/)
- [x] SQLAlchemy Models Scaffolded
- [x] API Skeleton with Auth & RLS Context
- [x] Dashboard & Supervisor Package Manifests Created
- [x] Backend Environment Stabilized (May 11, 2026)
- [x] Startup Scripts & Documentation Created

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **BACKEND_SETUP.md** | Complete backend setup and development guide |
| **QUICKSTART.md** | Quick reference for common tasks |
| **API.md** | API endpoint specifications (50+ endpoints) |
| **DEPLOYMENT.md** | AWS production deployment guide |
| **PHASE_1_CHECKLIST.md** | Phase 1 implementation tasks |
| **SETUP.md** | Local environment setup |
| **architecture.md** | System design and architecture |
| **IMPLEMENTATION_SUMMARY.md** | Recent implementation details |

## 🔗 Quick Links

- 🔵 **FastAPI Docs**: http://localhost:8000/docs (when running)
- 📊 **Database Schema**: `infra/aws/rds_schema.sql`
- 🔐 **RLS Policies**: `infra/aws/rds_rls_policies.sql`
- 📈 **Indexes**: `infra/aws/rds_indexes.sql`
- 🤖 **Models**: `apps/api/models/`
- 🔑 **Authentication**: `apps/api/services/auth_service.py`
- 🎯 **Types**: `packages/shared-types/src/index.ts`
