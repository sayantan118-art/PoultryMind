# Phase 0 → Phase 1 Transition Checklist

## ✅ Completed (Phase 0)

- [x] Monorepo structure initialized
- [x] PostgreSQL schema designed (70+ tables)
- [x] SQLAlchemy ORM models created
- [x] FastAPI skeleton with RLS middleware
- [x] Authentication service (JWT + role-based)
- [x] Architecture documentation
- [x] Database RLS policies defined
- [x] Performance indexes created
- [x] Master data seed script
- [x] .env templates for dev/prod
- [x] Docker & Docker Compose setup
- [x] GitHub Actions workflows
- [x] API documentation (50+ endpoints)
- [x] TypeScript shared types
- [x] Setup scripts (Linux/macOS/Windows)

---

## 🔧 Manual Setup Required (DO THIS BEFORE PHASE 1)

### AWS Account Setup
- [ ] Create AWS Account (if not already done)
- [ ] Set up IAM user for CLI access
- [ ] Configure AWS CLI: `aws configure`
- [ ] Create S3 bucket for state files (optional but recommended)

### AWS Development Environment
- [ ] Create RDS PostgreSQL dev instance (t3.micro)
  - Endpoint: `poultry-dev.xxxxx.ap-south-1.rds.amazonaws.com`
  - Save endpoint to notes
- [ ] Create Redis dev instance (cache.t3.micro)
  - Endpoint: `poultry-redis-dev.xxxxx.aps1.cache.amazonaws.com`
  - Save endpoint to notes
- [ ] Create AWS Cognito user pool
  - Pool ID: `ap-south-1_XXXXXXXXX`
  - Client ID: `xxxxxxxxxxxxxxxxxxxx`
  - Save both to `.env`

### AWS Production Environment (Optional for Phase 1)
- [ ] Create RDS PostgreSQL prod instance (t3.medium, Multi-AZ)
- [ ] Create Redis prod instance (cache.t3.small)
- [ ] Create separate Cognito clients for prod

### Key Generation
- [ ] Generate JWT secret: `python -c "import secrets; print(secrets.token_urlsafe(32))"`
- [ ] Store in `apps/api/.env` under `JWT_SECRET_KEY`
- [ ] (Later in AWS Secrets Manager for prod)

### GitHub Setup
- [ ] Push repo to GitHub
- [ ] Create GitHub repository secrets (see below)
- [ ] Enable branch protection on `main` (require PR reviews)

---

## 📋 Phase 1 Tasks (Implementation)

### Backend API (30 hours)

#### Authentication & Authorization
- [ ] Implement owner login endpoint (email + password)
- [ ] Implement supervisor login endpoint (PIN)
- [ ] JWT token generation and validation
- [ ] Cognito integration (optional for Phase 1, use local JWT)
- [ ] RLS context middleware testing

#### Flock Management
- [ ] `POST /farms/{farm_id}/flocks` - Create flock placement
- [ ] `GET /farms/{farm_id}/flocks` - List flocks (with filters)
- [ ] `GET /farms/{farm_id}/flocks/{flock_id}` - Get flock details
- [ ] `POST /farms/{farm_id}/flocks/{flock_id}/snapshot` - Daily entry submission
- [ ] `GET /farms/{farm_id}/flocks/{flock_id}/snapshot/today` - Get today's snapshot

#### Vaccine Management
- [ ] `GET /vaccines` - List all vaccines
- [ ] `GET /vaccines/schedule/breed/{breed_id}` - Get vaccine schedule
- [ ] `POST /farms/{farm_id}/flocks/{flock_id}/vaccine-event` - Report vaccine
- [ ] `GET /farms/{farm_id}/flocks/{flock_id}/vaccine-events` - List vaccine events
- [ ] Vaccine conflict detection algorithm

#### Feed Management
- [ ] `GET /feeds/formulas` - List formulas
- [ ] `GET /feeds/formulas/{formula_id}` - Formula details with ingredients
- [ ] `POST /farms/{farm_id}/feed-batch` - Create batch
- [ ] `POST /farms/{farm_id}/feed-dispatch` - Dispatch feed
- [ ] `GET /farms/{farm_id}/feed-batches` - List batches

#### Health & Movements
- [ ] `POST /farms/{farm_id}/flocks/{flock_id}/health-event` - Report health issue
- [ ] `POST /farms/{farm_id}/flocks/{flock_id}/bird-movement` - Report bird movement
- [ ] `PATCH /farms/{farm_id}/bird-movement/{movement_id}` - Owner approve/reject

#### Dashboard & Alerts
- [ ] `GET /dashboard/summary` - Owner dashboard
- [ ] `GET /dashboard/farms/{farm_id}` - Farm details
- [ ] `GET /alerts` - Get user alerts
- [ ] `PATCH /alerts/{alert_id}` - Mark alert read

### Frontend Dashboard (25 hours)

#### Pages
- [ ] Login page (email + password)
- [ ] Dashboard/home page (all farms overview)
- [ ] Farm detail page (sheds, flocks, statistics)
- [ ] Flock detail page (daily data, vaccines, health)
- [ ] Daily entry form (bird count, eggs, mortality)
- [ ] Vaccine schedule view & reporting
- [ ] Feed management page
- [ ] Alerts/notifications page

#### Components
- [ ] NavBar with farm selector
- [ ] Card components (farm, flock, alert)
- [ ] Form components (date picker, number inputs)
- [ ] Charts (HDP%, mortality trend, egg production)
- [ ] Real-time notifications

#### Features
- [ ] Authentication flow
- [ ] Protected routes (redirect if not logged in)
- [ ] React Query for API calls
- [ ] Zustand state management
- [ ] Error handling and loading states
- [ ] Responsive design (mobile-friendly)

### Supervisor App (20 hours)

#### Screens
- [ ] PIN login screen
- [ ] Farm/shed selector
- [ ] Daily task list (morning/evening)
- [ ] Quick entry form (bird count, eggs, mortality)
- [ ] Vaccine reporting screen
- [ ] Health issue reporting screen
- [ ] Alerts/notifications screen

#### Features
- [ ] WatermelonDB offline-first sync
- [ ] Local data queue (submits when online)
- [ ] Push notifications (Expo)
- [ ] Voice input (optional for bird counts)
- [ ] Photo capture for health issues (optional)
- [ ] Background sync

### Testing & Deployment (10 hours)

#### Backend Tests
- [ ] Unit tests for auth service
- [ ] Unit tests for RLS policies
- [ ] Integration tests for API endpoints
- [ ] Database migration tests

#### Frontend Tests
- [ ] Component tests (React Testing Library)
- [ ] API integration tests
- [ ] Form validation tests

#### CI/CD Pipeline
- [ ] Test GitHub Actions workflows locally
- [ ] Build Docker image and push to ECR
- [ ] Deploy to ECS dev environment
- [ ] Smoke tests after deployment

---

## 🔑 GitHub Repository Secrets Required

Add these to GitHub (Settings → Secrets → New Repository Secret):

### For CI/CD
- `AWS_ACCOUNT_ID` - Your AWS account ID (12 digits)
- `AWS_ROLE_ARN_DEV` - ARN for GitHub Actions dev role
- `AWS_ROLE_ARN_PROD` - ARN for GitHub Actions prod role

### For Development (if needed)
- `DEV_DATABASE_URL` - PostgreSQL connection string
- `DEV_REDIS_URL` - Redis connection string
- `COGNITO_CLIENT_ID` - Cognito app client ID

---

## 📝 Running Phase 1 Development

### Local Setup
```bash
# Windows
scripts/setup.bat

# Linux/macOS
bash scripts/setup.sh

# Manual
docker-compose up -d
npm install
cd apps/api && pip install -r requirements.txt && alembic upgrade head
npm run dev
```

### Monitoring Development
```bash
# Check Docker services
docker-compose logs -f

# Check database
psql postgresql://user:pass@localhost/poultry_dev

# Check API
curl http://localhost:8000/api/v1/health

# Frontend at http://localhost:5173
# Mobile at http://localhost:8081
```

### Key Environment Variables
- Set in `apps/api/.env`
- Generate JWT secret if not done
- Add Cognito credentials (or leave empty for local JWT)
- AWS keys needed only for S3/SNS features

---

## 🚀 Success Criteria for Phase 1

- [ ] API passes 50+ endpoint tests
- [ ] Dashboard renders without errors
- [ ] Supervisor app can log in and submit data
- [ ] Daily entry validation works
- [ ] Vaccine schedule enforces conflicts
- [ ] Feed dispatch tracks consumption
- [ ] RLS isolates farm data correctly
- [ ] CI/CD pipeline deploys to dev ECS
- [ ] Database backups configured
- [ ] Monitoring/alerts set up (CloudWatch)

---

## ⚠️ Known Limitations for Phase 1

- Cognito integration optional (using local JWT)
- Intelligence engine not implemented (analytics/alerts)
- Push notifications (Expo) - basic setup only
- WhatsApp integration not included
- Offline sync (WatermelonDB) - basic setup only
- Export functionality (CSV/PDF) - not included
- Advanced analytics dashboard - deferred to Phase 2

---

## 📞 Getting Help

- Refer to `SETUP.md` for local development
- Refer to `DEPLOYMENT.md` for AWS setup
- Refer to `API.md` for endpoint specs
- Check `architecture.md` for system design
- Review `GEMINI_final.md` for master context

---

## Timeline

**Estimated Phase 1 Duration: 8-10 weeks**

- Weeks 1-2: API implementation (auth, flock, vaccine)
- Weeks 3-4: Feed & health modules
- Weeks 5-6: Dashboard UI (React)
- Weeks 7-8: Supervisor app (React Native)
- Weeks 9-10: Testing, fixes, deployment

---

**Last Updated:** May 9, 2026
**Status:** Ready for Phase 1 Start
