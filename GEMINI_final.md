# Poultry Farm Command Center — Master Context v4.0
# GEMINI CLI: Read this file completely before every single response.
# Never deviate from anything written here. This file wins all conflicts.

---

## 0. What You Are Building

This is NOT a generic farm management app.
This is a distributed operational command center for a real, live,
5-lakh+ bird layer poultry operation run by a single owner-family.

### Operation Profile
- 4 farms across multiple districts in India (2 nearby, 2 in different districts)
- Each farm has its own feed mill on-site
- Internet connectivity is unreliable and slow at farm level
- 5,00,000+ layer birds currently active, growing
- Owner manages everything remotely via web dashboard
- Supervisors are the only on-ground system users
- Workers/labourers do NOT use the system at all

### Design Philosophy
Every feature must justify its existence against real daily farm operations.
When in doubt, ask: "Would a farm supervisor actually use this at 7am in a shed?"
Build for the farm. Not for a demo. Not for a portfolio.

---

## 1. Technology Stack — LOCKED PERMANENTLY

```
LAYER                 TECHNOLOGY                        REASON
───────────────────────────────────────────────────────────────────────────
Owner Dashboard       React + Vite + TypeScript         Web browser, owner phone/laptop
Supervisor App        React Native + Expo               Real Android APK, offline-capable
Local DB (mobile)     WatermelonDB                      Offline-first, proven on Android
Backend API           Python + FastAPI                  Intelligence engine, analytics
ORM                   SQLAlchemy + Alembic              Migrations, relationships
Database              AWS RDS PostgreSQL 15+            Enterprise-grade, Multi-AZ prod
Caching               AWS ElastiCache Redis             Dashboard query caching
Background Jobs       APScheduler (ECS container)       Nightly intelligence engine
Compute               AWS ECS Fargate                   Containers, no server management
Static Hosting        AWS S3 + CloudFront               Dashboard build + CDN
Auth                  AWS Cognito + JWT                  Owner email login, supervisor PIN
DNS                   AWS Route 53                       Domain + subdomain management
Secrets               AWS Secrets Manager               All credentials, keys, tokens
Push Notifications    AWS SNS + Expo Push Service       In-system alerts only
Image Registry        AWS ECR                            Docker images for ECS
Load Balancer         AWS ALB                            In front of ECS API tasks
CI/CD                 GitHub Actions → ECR → ECS        Auto-deploy on branch push
App Distribution      Expo EAS Build (Android APK)      Direct APK, no Play Store
Monorepo              Turborepo + GitHub                 Single repo, shared packages
AWS Region            ap-south-1 (Mumbai)               Lowest latency to Indian farms
```

### Two Environments — Always Separate, Always Maintained

```
ENV         BRANCH   SUBDOMAIN                  DB INSTANCE     ECS TASKS
──────────────────────────────────────────────────────────────────────────
dev         dev      dev-app.yourdomain.com     t3.micro 1-AZ   1 per service
production  main     app.yourdomain.com         t3.medium Multi-AZ   2 API + 1 intel
```

### AWS Service Map

```
SERVICE              ROLE IN THIS SYSTEM
─────────────────────────────────────────────────────────────────────────
ECS Fargate          Runs 2 containers: API (FastAPI) + Intelligence (APScheduler)
RDS PostgreSQL       Primary database. Row Level Security enforced. Multi-AZ prod.
ElastiCache Redis    Caches owner dashboard queries. 30s TTL for live data. 1hr for statics.
S3                   Stores React dashboard build output + exported operational data files
CloudFront           Serves dashboard from CDN edge. Custom domain. HTTPS only.
Route 53             DNS. app.domain, dev-app.domain, api.domain, dev-api.domain
Cognito              Owner: email + password user pool. Supervisor: PIN + custom auth flow.
                     Issues JWT with role + farm_id claims used by RLS.
Secrets Manager      DB password, JWT secret, Cognito pool IDs, any third-party keys.
                     App reads at startup. Never in code. Never in .env on server.
SNS                  Triggers Expo Push Notification Service for in-app alerts
ECR                  Docker image registry for FastAPI container
ALB                  Application Load Balancer routes HTTPS to ECS API tasks
CloudWatch           Centralised logs, metrics, alarms, auto-rollback trigger on deploy fail
GitHub Actions       Push to dev → deploy to dev. PR merge to main → deploy to prod.
Expo EAS Build       Builds Android APK from React Native code. Distributed directly.
```

### Estimated Monthly AWS Cost

```
SERVICE               DEV (₹/mo)    PROD (₹/mo)
──────────────────────────────────────────────────
ECS Fargate                  800          2,800
RDS PostgreSQL             1,200          4,500
ElastiCache Redis              0          1,200
S3 + CloudFront               50            200
Route 53                      50             50
Secrets Manager               80             80
SNS push notifications         0             50
CloudWatch                   100            400
Cognito                        0              0  ← free to 50,000 MAU
ECR                           30             60
ALB                          200            400
──────────────────────────────────────────────────
TOTAL ESTIMATE             2,510          9,740
```

### PERMANENTLY REJECTED — Never Suggest Any of These

```
REJECTED                    REASON
──────────────────────────────────────────────────────────────────────────
Node.js / Express / Fastify Backend is Python. Period.
NestJS                      Same — Python backend only.
PWA / Capacitor / Ionic     Offline unreliable on cheap Android. Use React Native.
MongoDB / DynamoDB          Relational data model. PostgreSQL only.
Firebase                    Cognito handles auth. SNS handles push. Firebase not needed.
Prisma / TypeORM            Python ORM is SQLAlchemy + Alembic.
Redux                       React Query + Zustand only if state mgmt needed.
GraphQL                     REST only. Simpler. Sufficient.
Microservices               Single FastAPI monolith. Split only if scale demands it later.
EC2                         ECS Fargate. No server management.
Supabase                    Replaced by RDS + Cognito on AWS.
Vercel                      Replaced by S3 + CloudFront on AWS.
Railway / DigitalOcean      Everything is AWS. No other cloud.
Twilio / WhatsApp API       No external messaging. All alerts in-app.
SES / email alerts          No email. Push notifications via SNS + Expo only.
Docker in development       Use uvicorn locally. Docker only for production deploy.
Hardcoded secrets           All secrets via AWS Secrets Manager or local .env (dev only).
Integer primary keys        All PKs are UUID. Always.
```

---

## 2. Monorepo Structure — LOCKED

```
/poultry-farm/                          ← git root
├── apps/
│   ├── dashboard/                      ← React + Vite + TypeScript
│   │   ├── src/
│   │   │   ├── pages/                  ← route-level components
│   │   │   ├── components/             ← reusable UI
│   │   │   ├── hooks/                  ← React Query hooks (one per resource)
│   │   │   ├── stores/                 ← Zustand stores (UI state only)
│   │   │   ├── api/                    ← typed API client functions
│   │   │   └── utils/
│   │   ├── index.html
│   │   └── vite.config.ts
│   │
│   ├── supervisor/                     ← React Native + Expo
│   │   ├── src/
│   │   │   ├── screens/                ← one screen per task
│   │   │   ├── components/
│   │   │   ├── database/
│   │   │   │   ├── schema.ts           ← WatermelonDB schema (mirrors PostgreSQL)
│   │   │   │   ├── models/             ← WatermelonDB model classes
│   │   │   │   └── sync.ts             ← sync adapter to API
│   │   │   ├── hooks/
│   │   │   └── utils/
│   │   ├── app.json
│   │   └── eas.json
│   │
│   └── api/                            ← Python + FastAPI
│       ├── main.py                     ← FastAPI app init, middleware, router registration
│       ├── config.py                   ← settings from env vars (pydantic BaseSettings)
│       ├── dependencies.py             ← shared FastAPI dependencies (auth, db session)
│       ├── routers/                    ← HTTP layer only, one file per module
│       │   ├── auth.py
│       │   ├── flocks.py
│       │   ├── vaccines.py
│       │   ├── feed_mill.py
│       │   ├── feed_dispatch.py
│       │   ├── eggs.py
│       │   ├── mortality.py
│       │   ├── bird_movements.py
│       │   ├── raw_materials.py
│       │   ├── vaccine_inventory.py
│       │   ├── snapshots.py
│       │   ├── alerts.py
│       │   ├── exports.py
│       │   └── dashboard.py
│       ├── models/                     ← SQLAlchemy ORM models (one file per table group)
│       │   ├── base.py                 ← Base, common mixins (UUID PK, timestamps, soft delete)
│       │   ├── master.py               ← Farm, Shed, Breed, User, VaccineMaster, FeedFormula
│       │   ├── flock.py                ← Flock, DailyFlockSnapshot
│       │   ├── vaccine.py              ← VaccineTemplate, VaccineScheduleItem, VaccineEvent
│       │   ├── feed.py                 ← FeedBatch, FeedDispatch, FeedConsumption
│       │   ├── production.py           ← EggCollection (embedded in snapshot)
│       │   ├── health.py               ← MortalityRecord, HealthEvent, BirdMovement
│       │   ├── inventory.py            ← RawMaterialStock, VaccineInventory
│       │   └── intelligence.py         ← SystemAlert, IntelligenceFlag
│       ├── schemas/                    ← Pydantic request + response schemas
│       │   └── (mirrors models/ structure)
│       ├── services/                   ← ALL business logic lives here
│       │   ├── conflict_engine.py      ← pure functions, no DB calls inside
│       │   ├── intelligence.py         ← anomaly detection, pattern recognition
│       │   ├── hdp_calculator.py       ← HDP%, variance, breed curve comparison
│       │   ├── bird_count.py           ← closing count formula, validation
│       │   ├── alert_service.py        ← writes to system_alerts, triggers SNS
│       │   ├── snapshot_service.py     ← creates/updates daily snapshots
│       │   ├── vaccine_service.py      ← schedule generation, status updates
│       │   └── sync_service.py         ← WatermelonDB pull/push endpoints
│       ├── jobs/                       ← APScheduler job definitions
│       │   ├── scheduler.py            ← job registration
│       │   ├── nightly_intelligence.py ← runs every night at 11pm IST
│       │   ├── weekly_patterns.py      ← runs every Sunday at 10pm IST
│       │   └── vaccine_alerts.py       ← runs every morning at 6am IST
│       └── migrations/                 ← Alembic migration files
│           ├── env.py
│           ├── alembic.ini
│           └── versions/
│
├── packages/
│   ├── shared-types/                   ← TypeScript types used by dashboard + supervisor
│   │   └── src/
│   │       ├── api.ts                  ← API response shapes
│   │       ├── models.ts               ← shared domain types
│   │       └── enums.ts                ← shared enums (FlockStage, MovementType, etc.)
│   └── ui-components/                  ← shared React + React Native components
│       └── src/
│           ├── AlertBadge/
│           ├── FlockCard/
│           ├── MetricTile/
│           └── StatusPill/
│
├── infra/
│   ├── aws/
│   │   ├── rds_rls_policies.sql        ← PostgreSQL RLS policy definitions
│   │   ├── rds_indexes.sql             ← All index definitions
│   │   ├── rds_schema.sql              ← Full schema DDL (source of truth)
│   │   ├── cognito_setup.md            ← Cognito user pool + client config steps
│   │   ├── ecs_task_definition.json    ← ECS task definitions for API + Intel containers
│   │   └── cloudwatch_alarms.json      ← Alarm definitions
│   └── scripts/
│       ├── seed_master_data.py         ← Seeds breeds, vaccine master, formula templates
│       ├── create_aws_resources.sh     ← One-time AWS resource creation script
│       └── backup_rds.sh               ← Manual backup trigger
│
├── .github/
│   └── workflows/
│       ├── deploy-dev.yml              ← triggers on push to dev branch
│       └── deploy-prod.yml             ← triggers on merge to main branch
│
├── turbo.json                          ← Turborepo pipeline config
├── package.json                        ← workspace root
├── GEMINI.md                           ← THIS FILE — read at every session start
├── ARCHITECTURE.md                     ← links to full architecture document
├── .env.example                        ← ALL required env vars documented
└── .gitignore
```

### Structural Rules — Non-Negotiable

- Business logic lives ONLY in `apps/api/services/` — never in routers
- Routers do exactly three things: validate input, call service, return response
- `conflict_engine.py` contains ONLY pure functions — no DB calls, no side effects
- `intelligence.py` runs ONLY via scheduled jobs — never called by API endpoints directly
- Every router file imports from services — never from other routers
- `models/base.py` defines a mixin with: UUID pk, created_at, updated_at, created_by, is_deleted
- Every model inherits this mixin — no exceptions
- `WatermelonDB schema.ts` field names must exactly match PostgreSQL column names

---

## 3. Two Roles — ABSOLUTE, NO EXCEPTIONS EVER

```
OWNER
───────────────────────────────────────────────────────────────────────
Access scope    : ALL 4 farms, all data, all history
Login method    : Email + password via AWS Cognito (web dashboard)
Exclusive rights: Approve vaccine schedule changes
                  Create + edit vaccine templates
                  Create + edit feed formulas
                  Approve all bird movements (non-mortality)
                  Create flock placements and closures
                  Enter vet recommendations as health events
                  Manage users (create, deactivate supervisors)
                  Export operational data
Alert levels    : WARNING + ALERT + CRITICAL
Dashboard       : Consolidated all-farm view

SUPERVISOR
───────────────────────────────────────────────────────────────────────
Access scope    : Their assigned farm only — RLS enforced at DB level
Login method    : 4-digit PIN via AWS Cognito custom auth flow (Android app)
Can do          : Daily entry for ANY shed on their farm (no shed restriction)
                  Report vaccine administrations
                  Report bird movement events (pending owner approval)
                  Report health issues (flags to owner)
                  Feed mill batch entry
                  Raw material receipt entry
                  Feed dispatch confirmation
Cannot do       : Anything in the Owner exclusive rights list above
Name on records : Types their name on every submission (reported_by_name)
                  Login ID also captured automatically (reported_by_login)
Alert levels    : INFO + WARNING (own farm only)
```

### There Are NO Other Roles — Ever

The following do NOT exist in this system:
- Farm Manager (eliminated — owner handles approvals directly)
- Mill Operator (eliminated — supervisors handle mill entry)
- Vet Advisor (eliminated — vets call owner, owner enters recommendations)
- Admin (eliminated — owner IS the admin)

If asked to add any role, decline and explain the two-role architecture.

---

## 4. Complete Module Reference

```
MODULE  NAME                       RESPONSIBLE FOR
──────────────────────────────────────────────────────────────────────────
A       Flock Management           Placement, stage auto-transitions, bird count
B       Vaccine Scheduling         Templates, auto-schedule, conflict engine, execution
C       Feed Mill & Production     Batch production, formula versioning, QC workflow
D       Feed Dispatch & Consumption Dispatch tracking, daily consumption, FCR
E       Egg Production & Quality   Daily collection entry, HDP%, breed curve compare
F       Mortality & Health         Daily mortality entry, causes, health event log
G       Raw Material Inventory     Stock per farm, consumption deduction, reorder alerts
H       Vaccine Inventory          Stock per farm, expiry alerts, dose sufficiency check
I       Intelligence Engine        Nightly anomaly detection, cross-module correlation
J       Alert Dispatcher           Writes to system_alerts, triggers SNS push
K       Owner Dashboard            Morning command screen, drill-down to farm/flock/event
L       Supervisor App             Task-list-based daily workflow, offline-first
M       Data Export                On-demand CSV/Excel export of operational datasets
N       Bird Movement Tracking     All non-mortality departures/arrivals, count integrity
```

---

## 5. Central Record — Daily Flock Snapshot

One record per flock per day. The heartbeat of the entire system.
Every module either writes to or reads from this record.

### Complete Field List

```python
# IDENTITY (all auto-populated, never entered)
snapshot_id          UUID PK
flock_id             FK → flock
farm_id              FK → farm        # denormalised for RLS + query speed
shed_id              FK → shed        # denormalised for query speed
snapshot_date        DATE
bird_age_days        INTEGER          # calculated: snapshot_date - placement_date
flock_stage          ENUM             # auto: Brooding/Grower/PreLayer/Layer

# BIRD COUNT
opening_bird_count   INTEGER          # auto: previous day closing_bird_count
mortality_count      INTEGER          # ENTERED by supervisor
culled_sick_count    INTEGER          # ENTERED by supervisor
other_movements_count INTEGER         # AUTO: sum of approved FLOCK_BIRD_MOVEMENT OUT records today
arrivals_count       INTEGER          # AUTO: sum of approved FLOCK_BIRD_MOVEMENT IN records today
closing_bird_count   INTEGER          # AUTO: opening - mortality - culled - other + arrivals

# FEED
feed_batch_id        FK → feed_batch  # which batch was issued today
formula_id           UUID             # auto from batch
formula_version      INTEGER          # auto from batch — immutable record
feed_issued_kg       DECIMAL          # auto from feed_dispatch records
feed_returned_kg     DECIMAL          # ENTERED by supervisor (closing stock)
feed_net_kg          DECIMAL          # AUTO: issued - returned
feed_per_bird_g      DECIMAL          # AUTO: (net_kg * 1000) / closing_bird_count
expected_feed_g      DECIMAL          # AUTO: from breed master for this stage
feed_variance_g      DECIMAL          # AUTO: actual - expected

# EGGS
eggs_collected       INTEGER          # ENTERED by supervisor
eggs_broken          INTEGER          # ENTERED by supervisor
eggs_floor           INTEGER          # ENTERED by supervisor (soiled, outside nest)
eggs_saleable        INTEGER          # AUTO: collected - broken - floor
hdp_percent          DECIMAL          # AUTO: (saleable / closing_bird_count) * 100
hdp_expected         DECIMAL          # AUTO: from breed HDP curve for bird_age_days
hdp_variance         DECIMAL          # AUTO: hdp_percent - hdp_expected

# WATER (optional but strongly recommended)
water_consumed_litres DECIMAL         # ENTERED by supervisor — earliest health signal

# ENVIRONMENT (optional)
morning_temp_c       DECIMAL          # ENTERED — helps anomaly context
evening_temp_c       DECIMAL          # ENTERED
observations         TEXT             # free text, optional

# ACCOUNTABILITY
reported_by_name     VARCHAR          # supervisor types name
reported_by_login    UUID             # auto from JWT
entry_timestamp      TIMESTAMPTZ      # auto
sync_status          ENUM             # local / synced
validated            BOOLEAN          # set true after system validation passes
validation_flags     JSONB            # list of anomalies flagged by system

# STANDARD MIXIN (on all tables)
created_at           TIMESTAMPTZ
updated_at           TIMESTAMPTZ
created_by           UUID
is_deleted           BOOLEAN DEFAULT FALSE
```

### Bird Count Formula — Always Enforced

```python
closing_bird_count = (
    opening_bird_count
    - mortality_count        # entered by supervisor
    - culled_sick_count      # entered by supervisor
    - other_movements_count  # AUTO from approved FLOCK_BIRD_MOVEMENT records
    + arrivals_count         # AUTO from approved TRANSFER_IN records
)
```

Rules:
- `closing_bird_count` NEVER entered manually — always calculated
- `other_movements_count` NEVER entered manually — computed from movement records
- `opening_bird_count` NEVER entered manually — pulled from previous closing
- Arithmetic must balance — mismatches BLOCK submission

---

## 6. Complete PostgreSQL Schema — All Tables

### Master Data Tables

```sql
-- COMPANY (single row)
CREATE TABLE company (
    company_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(200) NOT NULL,
    owner_name      VARCHAR(200) NOT NULL,
    owner_phone     VARCHAR(20),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    is_deleted      BOOLEAN DEFAULT FALSE
);

-- FARM
CREATE TABLE farm (
    farm_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id      UUID NOT NULL REFERENCES company(company_id),
    farm_name       VARCHAR(200) NOT NULL,
    farm_code       VARCHAR(10) NOT NULL UNIQUE,   -- e.g. F1, F2, F3, F4
    district        VARCHAR(100),
    state           VARCHAR(100),
    has_feed_mill   BOOLEAN DEFAULT TRUE,
    gps_lat         DECIMAL(10,8),
    gps_lng         DECIMAL(11,8),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    created_by      UUID,
    is_deleted      BOOLEAN DEFAULT FALSE
);

-- SHED
CREATE TABLE shed (
    shed_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    shed_name           VARCHAR(100) NOT NULL,
    shed_number         INTEGER NOT NULL,
    capacity_birds      INTEGER NOT NULL,          -- hard ceiling — no overstocking
    shed_type           VARCHAR(50),               -- conventional/cage/open-sided
    length_ft           DECIMAL,
    width_ft            DECIMAL,
    ventilation_type    VARCHAR(100),
    feeder_type         VARCHAR(100),
    drinker_type        VARCHAR(100),
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE,
    UNIQUE (farm_id, shed_number)
);

-- BREED MASTER
CREATE TABLE breed (
    breed_id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    breed_name                  VARCHAR(100) NOT NULL UNIQUE,  -- BV-380, Lohmann Brown
    supplier                    VARCHAR(200),
    expected_lay_start_day      INTEGER NOT NULL DEFAULT 126,
    peak_hdp_percent            DECIMAL(5,2),
    peak_hdp_day                INTEGER,
    standard_hdp_curve          JSONB NOT NULL,  -- {day: expected_hdp_percent, ...}
    standard_mortality_rate     JSONB NOT NULL,  -- {stage: daily_rate_percent, ...}
    standard_feed_per_bird_g    JSONB NOT NULL,  -- {stage: grams_per_day, ...}
    expected_lay_period_weeks   INTEGER DEFAULT 72,
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID,
    is_deleted                  BOOLEAN DEFAULT FALSE
);

-- USER
CREATE TABLE app_user (
    user_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cognito_sub         VARCHAR(200) UNIQUE,       -- Cognito user subject ID
    full_name           VARCHAR(200) NOT NULL,
    phone_number        VARCHAR(20),
    role                VARCHAR(20) NOT NULL CHECK (role IN ('owner', 'supervisor')),
    assigned_farm_id    UUID REFERENCES farm(farm_id),  -- NULL for owner
    pin_hash            VARCHAR(200),              -- hashed 4-digit PIN for supervisors
    language_pref       VARCHAR(10) DEFAULT 'hi',  -- hi/bn/en
    expo_push_token     VARCHAR(200),              -- for push notifications
    is_active           BOOLEAN DEFAULT TRUE,
    last_login_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE,
    CONSTRAINT supervisor_has_farm CHECK (
        role = 'owner' OR assigned_farm_id IS NOT NULL
    )
);

-- VACCINE MASTER
CREATE TABLE vaccine_master (
    vaccine_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vaccine_name            VARCHAR(200) NOT NULL,
    disease_target          VARCHAR(200),
    vaccine_type            VARCHAR(50) NOT NULL,  -- live/killed/toxoid/recombinant
    conflict_group          VARCHAR(5) NOT NULL,   -- A/B/C — same group cannot overlap
    default_method          VARCHAR(50),           -- water/injection/eye_drop/spray/wing_web
    default_dose_ml_per_bird DECIMAL(8,4),
    min_gap_before_days     INTEGER DEFAULT 5,
    min_gap_after_days      INTEGER DEFAULT 5,
    storage_temp_min_c      DECIMAL(4,1),
    storage_temp_max_c      DECIMAL(4,1),
    cold_chain_required     BOOLEAN DEFAULT TRUE,
    notes_for_worker        TEXT,                  -- plain language instructions
    is_active               BOOLEAN DEFAULT TRUE,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- VACCINE SCHEDULE TEMPLATE (one per breed)
CREATE TABLE vaccine_schedule_template (
    template_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_name   VARCHAR(200) NOT NULL,
    breed_id        UUID NOT NULL REFERENCES breed(breed_id),
    version_number  INTEGER NOT NULL DEFAULT 1,
    is_active       BOOLEAN DEFAULT TRUE,
    superseded_by   UUID REFERENCES vaccine_schedule_template(template_id),
    change_reason   TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    created_by      UUID,
    is_deleted      BOOLEAN DEFAULT FALSE
);

-- VACCINE SCHEDULE ITEMS (line items per template)
CREATE TABLE vaccine_schedule_item (
    item_id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id                 UUID NOT NULL REFERENCES vaccine_schedule_template(template_id),
    sequence_number             INTEGER NOT NULL,
    vaccine_id                  UUID NOT NULL REFERENCES vaccine_master(vaccine_id),
    target_day                  INTEGER NOT NULL,
    flexibility_window_days     INTEGER DEFAULT 3,
    method                      VARCHAR(50),
    dose_ml_per_bird            DECIMAL(8,4),
    is_mandatory                BOOLEAN DEFAULT TRUE,
    grace_days_before_escalate  INTEGER DEFAULT 1,
    post_vaccine_watch_days     INTEGER DEFAULT 7,
    worker_instructions         TEXT,
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ DEFAULT NOW(),
    created_by                  UUID,
    is_deleted                  BOOLEAN DEFAULT FALSE,
    UNIQUE (template_id, sequence_number)
);

-- FEED FORMULA
CREATE TABLE feed_formula (
    formula_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    formula_name    VARCHAR(200) NOT NULL,
    formula_code    VARCHAR(50) NOT NULL,
    flock_stage     VARCHAR(20) NOT NULL CHECK (flock_stage IN ('chick','grower','pre_layer','layer')),
    version_number  INTEGER NOT NULL DEFAULT 1,
    is_active       BOOLEAN DEFAULT TRUE,
    superseded_by   UUID REFERENCES feed_formula(formula_id),
    change_reason   TEXT,
    target_cp_pct   DECIMAL(5,2),
    target_energy   DECIMAL(8,2),  -- kcal/kg
    target_calcium  DECIMAL(5,2),
    target_phosphorus DECIMAL(5,2),
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    created_by      UUID,
    is_deleted      BOOLEAN DEFAULT FALSE
);

-- FEED FORMULA INGREDIENTS
CREATE TABLE feed_formula_ingredient (
    ingredient_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    formula_id          UUID NOT NULL REFERENCES feed_formula(formula_id),
    formula_version     INTEGER NOT NULL,          -- stamped at creation
    raw_material_id     UUID NOT NULL,             -- FK → raw_material
    quantity_per_100kg  DECIMAL(8,3) NOT NULL,
    is_critical         BOOLEAN DEFAULT FALSE,     -- if missing, block production
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);

-- RAW MATERIAL MASTER
CREATE TABLE raw_material (
    material_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_name       VARCHAR(200) NOT NULL,
    unit                VARCHAR(20) DEFAULT 'kg',
    category            VARCHAR(50),               -- grain/protein/mineral/additive
    reorder_level_kg    DECIMAL(12,3),
    critical_days       INTEGER DEFAULT 7,         -- alert when stock < this many days
    primary_supplier    VARCHAR(200),
    secondary_supplier  VARCHAR(200),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);
```

### Operational Tables

```sql
-- FLOCK
CREATE TABLE flock (
    flock_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flock_code              VARCHAR(30) NOT NULL UNIQUE,  -- F-F1-2025-047
    farm_id                 UUID NOT NULL REFERENCES farm(farm_id),
    shed_id                 UUID NOT NULL REFERENCES shed(shed_id),
    breed_id                UUID NOT NULL REFERENCES breed(breed_id),
    vaccine_template_id     UUID REFERENCES vaccine_schedule_template(template_id),
    vaccine_template_version INTEGER,
    placement_date          DATE NOT NULL,
    initial_birds_placed    INTEGER NOT NULL,
    dead_on_arrival         INTEGER DEFAULT 0,
    net_birds_started       INTEGER NOT NULL,      -- initial_birds_placed - dead_on_arrival
    source_hatchery         VARCHAR(200),
    chick_batch_ref         VARCHAR(100),
    transport_hours         DECIMAL(4,1),
    arrival_condition       VARCHAR(50),           -- good/minor_losses/significant_losses
    flock_status            VARCHAR(20) DEFAULT 'active' CHECK (
                                flock_status IN ('active','depleted','sold','condemned')
                            ),
    depletion_date          DATE,
    depletion_reason        TEXT,
    depletion_approved_by   UUID REFERENCES app_user(user_id),
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID REFERENCES app_user(user_id),
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- DAILY FLOCK SNAPSHOT
CREATE TABLE daily_flock_snapshot (
    snapshot_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flock_id                UUID NOT NULL REFERENCES flock(flock_id),
    farm_id                 UUID NOT NULL REFERENCES farm(farm_id),
    shed_id                 UUID NOT NULL REFERENCES shed(shed_id),
    snapshot_date           DATE NOT NULL,
    bird_age_days           INTEGER NOT NULL,
    flock_stage             VARCHAR(20) NOT NULL,

    -- bird count
    opening_bird_count      INTEGER NOT NULL,
    mortality_count         INTEGER NOT NULL DEFAULT 0,
    culled_sick_count       INTEGER NOT NULL DEFAULT 0,
    other_movements_count   INTEGER NOT NULL DEFAULT 0,   -- auto from movements
    arrivals_count          INTEGER NOT NULL DEFAULT 0,   -- auto from movements
    closing_bird_count      INTEGER NOT NULL,             -- auto calculated

    -- feed
    feed_batch_id           UUID REFERENCES feed_batch(batch_id),
    formula_id              UUID,
    formula_version         INTEGER,
    feed_issued_kg          DECIMAL(10,3) DEFAULT 0,
    feed_returned_kg        DECIMAL(10,3) DEFAULT 0,
    feed_net_kg             DECIMAL(10,3),                -- auto
    feed_per_bird_g         DECIMAL(8,2),                 -- auto
    expected_feed_g         DECIMAL(8,2),                 -- auto from breed
    feed_variance_g         DECIMAL(8,2),                 -- auto

    -- eggs
    eggs_collected          INTEGER DEFAULT 0,
    eggs_broken             INTEGER DEFAULT 0,
    eggs_floor              INTEGER DEFAULT 0,
    eggs_saleable           INTEGER,                      -- auto
    hdp_percent             DECIMAL(6,3),                 -- auto
    hdp_expected            DECIMAL(6,3),                 -- auto from breed curve
    hdp_variance            DECIMAL(6,3),                 -- auto

    -- water and environment
    water_consumed_litres   DECIMAL(10,2),
    morning_temp_c          DECIMAL(4,1),
    evening_temp_c          DECIMAL(4,1),
    observations            TEXT,

    -- accountability
    reported_by_name        VARCHAR(200) NOT NULL,
    reported_by_login       UUID NOT NULL REFERENCES app_user(user_id),
    entry_timestamp         TIMESTAMPTZ DEFAULT NOW(),
    sync_status             VARCHAR(20) DEFAULT 'local',
    validated               BOOLEAN DEFAULT FALSE,
    validation_flags        JSONB DEFAULT '[]',

    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID,
    is_deleted              BOOLEAN DEFAULT FALSE,

    UNIQUE (flock_id, snapshot_date),
    CONSTRAINT eggs_check CHECK (eggs_broken + eggs_floor <= eggs_collected),
    CONSTRAINT feed_check  CHECK (feed_returned_kg <= feed_issued_kg),
    CONSTRAINT mortality_check CHECK (
        mortality_count >= 0 AND mortality_count <= opening_bird_count
    )
);

-- VACCINE EVENT (one per scheduled or ad-hoc administration)
CREATE TABLE vaccine_event (
    event_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flock_id                UUID NOT NULL REFERENCES flock(flock_id),
    farm_id                 UUID NOT NULL REFERENCES farm(farm_id),
    shed_id                 UUID NOT NULL REFERENCES shed(shed_id),
    schedule_item_id        UUID REFERENCES vaccine_schedule_item(item_id),  -- null if adhoc
    is_adhoc                BOOLEAN DEFAULT FALSE,
    vaccine_id              UUID NOT NULL REFERENCES vaccine_master(vaccine_id),
    event_type              VARCHAR(30) NOT NULL,   -- scheduled/emergency/booster/catch_up

    -- planned
    target_date             DATE NOT NULL,
    earliest_acceptable     DATE,
    latest_acceptable       DATE,
    planned_method          VARCHAR(50),
    planned_dose_ml         DECIMAL(8,4),

    -- actual (filled on administration)
    actual_date             DATE,
    actual_method           VARCHAR(50),
    batch_number            VARCHAR(100),
    manufacturer            VARCHAR(200),
    batch_expiry            DATE,
    dose_ml_actual          DECIMAL(8,4),
    birds_total             INTEGER,               -- auto from snapshot
    birds_covered           INTEGER,
    coverage_percent        DECIMAL(5,2),          -- auto
    administered_by         UUID REFERENCES app_user(user_id),
    delay_reason            VARCHAR(200),
    worker_observations     TEXT,

    -- approval
    required_approval       VARCHAR(20) DEFAULT 'owner',
    approved_by             UUID REFERENCES app_user(user_id),
    approval_timestamp      TIMESTAMPTZ,
    approval_note           TEXT,

    -- status
    status                  VARCHAR(30) NOT NULL DEFAULT 'scheduled' CHECK (
        status IN ('scheduled','upcoming','due_today','administered',
                   'overdue','critically_overdue','skipped','rescheduled')
    ),
    status_updated_at       TIMESTAMPTZ DEFAULT NOW(),

    -- rescheduling
    was_rescheduled         BOOLEAN DEFAULT FALSE,
    original_target_date    DATE,
    reschedule_reason       TEXT,
    reschedule_approved_by  UUID REFERENCES app_user(user_id),
    conflict_event_id       UUID REFERENCES vaccine_event(event_id),

    -- post-vaccine watch
    watch_period_days       INTEGER DEFAULT 7,
    watch_end_date          DATE,
    watch_status            VARCHAR(20) DEFAULT 'not_started',

    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- FEED BATCH (produced at mill)
CREATE TABLE feed_batch (
    batch_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_code          VARCHAR(50) NOT NULL UNIQUE,   -- FM-F1-20250414-003
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    formula_id          UUID NOT NULL REFERENCES feed_formula(formula_id),
    formula_version     INTEGER NOT NULL,              -- stamped at production — immutable
    production_date     DATE NOT NULL,
    quantity_kg         DECIMAL(12,3) NOT NULL,
    quality_status      VARCHAR(20) DEFAULT 'pass' CHECK (
                            quality_status IN ('pass','fail','conditional')
                        ),
    quality_notes       TEXT,
    quality_checked_by  UUID REFERENCES app_user(user_id),
    storage_location    VARCHAR(200),
    remaining_qty_kg    DECIMAL(12,3),                 -- decremented on dispatch
    produced_by         UUID NOT NULL REFERENCES app_user(user_id),
    released_by         UUID REFERENCES app_user(user_id),  -- owner approval if conditional/fail
    release_note        TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);

-- FEED BATCH INGREDIENTS (actual quantities used)
CREATE TABLE feed_batch_ingredient (
    entry_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id            UUID NOT NULL REFERENCES feed_batch(batch_id),
    raw_material_id     UUID NOT NULL REFERENCES raw_material(material_id),
    lot_number          VARCHAR(100),
    formula_qty_kg      DECIMAL(10,3) NOT NULL,   -- what formula specifies
    actual_qty_kg       DECIMAL(10,3) NOT NULL,   -- what was actually used
    variance_kg         DECIMAL(10,3),             -- auto: actual - formula
    variance_pct        DECIMAL(6,2),              -- auto
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);

-- FEED DISPATCH (mill → shed)
CREATE TABLE feed_dispatch (
    dispatch_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    dispatch_date       DATE NOT NULL,
    dispatch_time       TIME,
    batch_id            UUID NOT NULL REFERENCES feed_batch(batch_id),
    to_shed_id          UUID NOT NULL REFERENCES shed(shed_id),
    to_flock_id         UUID NOT NULL REFERENCES flock(flock_id),
    qty_dispatched_kg   DECIMAL(10,3) NOT NULL,
    qty_received_kg     DECIMAL(10,3),             -- confirmed by shed supervisor
    variance_kg         DECIMAL(10,3),             -- auto
    dispatched_by       UUID NOT NULL REFERENCES app_user(user_id),
    received_by         UUID REFERENCES app_user(user_id),
    received_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);

-- RAW MATERIAL STOCK (per farm)
CREATE TABLE raw_material_stock (
    stock_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    material_id         UUID NOT NULL REFERENCES raw_material(material_id),
    current_stock_kg    DECIMAL(12,3) NOT NULL DEFAULT 0,
    last_updated        TIMESTAMPTZ DEFAULT NOW(),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE,
    UNIQUE (farm_id, material_id)
);

-- RAW MATERIAL STOCK MOVEMENT (every change)
CREATE TABLE raw_material_movement (
    movement_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    material_id         UUID NOT NULL REFERENCES raw_material(material_id),
    movement_date       DATE NOT NULL,
    movement_type       VARCHAR(30) NOT NULL CHECK (
                            movement_type IN ('purchase','mill_consumption',
                                              'adjustment','transfer')
                        ),
    quantity_kg         DECIMAL(12,3) NOT NULL,    -- positive=IN, negative=OUT
    reference_id        UUID,                      -- batch_id or purchase ref
    balance_after_kg    DECIMAL(12,3) NOT NULL,    -- auto
    entered_by          UUID NOT NULL REFERENCES app_user(user_id),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);

-- VACCINE INVENTORY (per farm)
CREATE TABLE vaccine_inventory (
    inv_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    vaccine_id          UUID NOT NULL REFERENCES vaccine_master(vaccine_id),
    batch_number        VARCHAR(100) NOT NULL,
    manufacturer        VARCHAR(200),
    vials_received      INTEGER NOT NULL,
    vials_remaining     INTEGER NOT NULL,
    dose_per_vial       INTEGER NOT NULL,
    doses_remaining     INTEGER NOT NULL,           -- auto: vials_remaining * dose_per_vial
    expiry_date         DATE NOT NULL,
    storage_location    VARCHAR(200),
    received_date       DATE NOT NULL,
    received_by         UUID NOT NULL REFERENCES app_user(user_id),
    cold_chain_ok       BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);

-- HEALTH EVENT
CREATE TABLE health_event (
    event_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flock_id                UUID NOT NULL REFERENCES flock(flock_id),
    farm_id                 UUID NOT NULL REFERENCES farm(farm_id),
    shed_id                 UUID NOT NULL REFERENCES shed(shed_id),
    event_date              DATE NOT NULL,
    event_type              VARCHAR(50) NOT NULL,   -- disease_suspicion/injury/deficiency/stress/other
    description             TEXT NOT NULL,
    birds_affected_est      INTEGER,
    vet_consulted           BOOLEAN DEFAULT FALSE,
    vet_name                VARCHAR(200),
    vet_recommendation      TEXT,
    treatment_product       VARCHAR(200),
    treatment_duration_days INTEGER,
    outcome                 VARCHAR(30),            -- resolved/ongoing/escalated
    linked_vaccine_event_id UUID REFERENCES vaccine_event(event_id),
    reported_by_name        VARCHAR(200) NOT NULL,
    reported_by_login       UUID NOT NULL REFERENCES app_user(user_id),
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),
    created_by              UUID,
    is_deleted              BOOLEAN DEFAULT FALSE
);

-- FLOCK BIRD MOVEMENT (all non-mortality departures and arrivals)
CREATE TABLE flock_bird_movement (
    movement_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flock_id            UUID NOT NULL REFERENCES flock(flock_id),
    farm_id             UUID NOT NULL REFERENCES farm(farm_id),
    shed_id             UUID NOT NULL REFERENCES shed(shed_id),
    movement_date       DATE NOT NULL,
    movement_type       VARCHAR(30) NOT NULL CHECK (
                            movement_type IN ('sold','transferred_out','condemned',
                                              'theft_suspected','missing_unknown',
                                              'transfer_in')
                        ),
    direction           VARCHAR(5) NOT NULL CHECK (direction IN ('out','in')),
    bird_count          INTEGER NOT NULL CHECK (bird_count > 0),
    reason_note         TEXT,
    bird_count_before   INTEGER NOT NULL,           -- auto at time of report
    bird_count_after    INTEGER,                    -- auto after approval
    destination_farm_id UUID REFERENCES farm(farm_id),   -- for transfers
    destination_shed_id UUID REFERENCES shed(shed_id),
    linked_movement_id  UUID REFERENCES flock_bird_movement(movement_id),
    reported_by_name    VARCHAR(200) NOT NULL,
    reported_by_login   UUID NOT NULL REFERENCES app_user(user_id),
    status              VARCHAR(20) DEFAULT 'pending' CHECK (
                            status IN ('pending','approved','rejected')
                        ),
    approved_by         UUID REFERENCES app_user(user_id),
    approval_timestamp  TIMESTAMPTZ,
    sync_status         VARCHAR(20) DEFAULT 'local',
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);

-- SYSTEM ALERT
CREATE TABLE system_alert (
    alert_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID REFERENCES farm(farm_id),   -- null = all farms (owner only)
    flock_id            UUID REFERENCES flock(flock_id),
    alert_level         VARCHAR(20) NOT NULL CHECK (
                            alert_level IN ('info','warning','alert','critical')
                        ),
    alert_type          VARCHAR(100) NOT NULL,
    title               VARCHAR(300) NOT NULL,
    body                TEXT NOT NULL,
    action_required     BOOLEAN DEFAULT FALSE,
    action_taken        TEXT,
    target_role         VARCHAR(20) DEFAULT 'owner',
    target_user_id      UUID REFERENCES app_user(user_id),
    push_sent           BOOLEAN DEFAULT FALSE,
    push_sent_at        TIMESTAMPTZ,
    read_at             TIMESTAMPTZ,
    acknowledged_at     TIMESTAMPTZ,
    acknowledged_by     UUID REFERENCES app_user(user_id),
    auto_resolved_at    TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);

-- INTELLIGENCE FLAG (output of nightly engine)
CREATE TABLE intelligence_flag (
    flag_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id             UUID REFERENCES farm(farm_id),
    flock_id            UUID REFERENCES flock(flock_id),
    snapshot_id         UUID REFERENCES daily_flock_snapshot(snapshot_id),
    flag_type           VARCHAR(100) NOT NULL,      -- production_drop/mortality_trend/feed_efficiency/etc
    severity            VARCHAR(20) NOT NULL,
    triggered_at        DATE NOT NULL,
    investigation       JSONB NOT NULL DEFAULT '{}',  -- structured investigation report
    related_events      JSONB DEFAULT '[]',            -- linked vaccine/feed/health events
    pattern_data        JSONB DEFAULT '{}',
    alert_created       BOOLEAN DEFAULT FALSE,
    alert_id            UUID REFERENCES system_alert(alert_id),
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    created_by          UUID,
    is_deleted          BOOLEAN DEFAULT FALSE
);
```

### Required Indexes

```sql
-- FARM ISOLATION (most critical — used by RLS)
CREATE INDEX idx_flock_farm              ON flock(farm_id);
CREATE INDEX idx_snapshot_farm           ON daily_flock_snapshot(farm_id);
CREATE INDEX idx_vaccine_event_farm      ON vaccine_event(farm_id);
CREATE INDEX idx_feed_batch_farm         ON feed_batch(farm_id);
CREATE INDEX idx_feed_dispatch_farm      ON feed_dispatch(farm_id);
CREATE INDEX idx_bird_movement_farm      ON flock_bird_movement(farm_id);
CREATE INDEX idx_health_event_farm       ON health_event(farm_id);
CREATE INDEX idx_system_alert_farm       ON system_alert(farm_id);
CREATE INDEX idx_raw_material_stock_farm ON raw_material_stock(farm_id);

-- DAILY QUERIES (most frequent)
CREATE UNIQUE INDEX idx_snapshot_flock_date ON daily_flock_snapshot(flock_id, snapshot_date);
CREATE INDEX idx_snapshot_date             ON daily_flock_snapshot(snapshot_date);
CREATE INDEX idx_flock_status              ON flock(flock_status);
CREATE INDEX idx_flock_shed                ON flock(shed_id);

-- VACCINE OPERATIONS
CREATE INDEX idx_vaccine_event_flock       ON vaccine_event(flock_id);
CREATE INDEX idx_vaccine_event_status      ON vaccine_event(status);
CREATE INDEX idx_vaccine_event_target_date ON vaccine_event(target_date);

-- ALERT OPERATIONS
CREATE INDEX idx_alert_level               ON system_alert(alert_level);
CREATE INDEX idx_alert_acknowledged        ON system_alert(acknowledged_at) WHERE acknowledged_at IS NULL;
CREATE INDEX idx_alert_user                ON system_alert(target_user_id);

-- FEED OPERATIONS
CREATE INDEX idx_feed_dispatch_date        ON feed_dispatch(dispatch_date);
CREATE INDEX idx_feed_dispatch_shed        ON feed_dispatch(to_shed_id);
CREATE INDEX idx_raw_material_movement     ON raw_material_movement(farm_id, material_id, movement_date);

-- BIRD MOVEMENT
CREATE INDEX idx_bird_movement_status      ON flock_bird_movement(status);
CREATE INDEX idx_bird_movement_flock       ON flock_bird_movement(flock_id);
CREATE INDEX idx_bird_movement_date        ON flock_bird_movement(movement_date);
```

### Row Level Security Policies

```sql
-- Enable RLS on all operational tables
ALTER TABLE farm                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE shed                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE flock                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_flock_snapshot  ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaccine_event         ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_batch            ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_dispatch         ENABLE ROW LEVEL SECURITY;
ALTER TABLE flock_bird_movement   ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_event          ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_alert          ENABLE ROW LEVEL SECURITY;
ALTER TABLE raw_material_stock    ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaccine_inventory     ENABLE ROW LEVEL SECURITY;

-- Helper function: get current user's role from JWT
CREATE OR REPLACE FUNCTION current_user_role() RETURNS TEXT AS $$
  SELECT current_setting('app.user_role', true);
$$ LANGUAGE sql STABLE;

-- Helper function: get current user's farm_id from JWT
CREATE OR REPLACE FUNCTION current_user_farm_id() RETURNS UUID AS $$
  SELECT current_setting('app.farm_id', true)::UUID;
$$ LANGUAGE sql STABLE;

-- Policy pattern: owner sees all, supervisor sees own farm only
-- Applied to every table with farm_id

CREATE POLICY farm_isolation ON flock
    USING (
        current_user_role() = 'owner'
        OR farm_id = current_user_farm_id()
    );

-- (Identical policy applied to all other tables listed above)
-- See infra/aws/rds_rls_policies.sql for full set
```

---

## 7. Bird Movement Rules

```
MOVEMENT TYPE     DIRECTION   APPROVAL NEEDED   COUNT UPDATED WHEN
─────────────────────────────────────────────────────────────────────
MORTALITY         OUT         None              Immediately on daily entry
CULLED_SICK       OUT         None              Immediately on daily entry
SOLD              OUT         Owner             After owner approves
TRANSFERRED_OUT   OUT         Owner             After owner approves
CONDEMNED         OUT         Owner             After owner approves
THEFT_SUSPECTED   OUT         Owner             After owner approves
MISSING_UNKNOWN   OUT         Owner             After owner approves
TRANSFER_IN       IN          Supervisor (recv) After receiving farm confirms
```

Rules:
- Record sits in `PENDING` — live count NOT affected until approved
- No financial fields on movement records — count accuracy only
- Transfer creates paired records: TRANSFERRED_OUT + TRANSFER_IN
- If TRANSFER_IN not confirmed within 24 hours → ALERT to owner
- THEFT or MISSING > 2 times in 30 days on same farm → ALERT to owner

---

## 8. Vaccine System — Complete Rules

### Track 1: Pre-Scheduled (Auto-Generated at Placement)
- Breed template selected at flock creation
- System generates all vaccine events with target dates
- Dates calculated: placement_date + target_day
- earliest_acceptable = target_date - flexibility_window_days
- latest_acceptable = target_date + flexibility_window_days

### Track 2: Emergency / As-Required (Owner Only)
- Owner enters emergency vaccine after vet communication
- System immediately runs conflict engine on all affected flocks
- Owner reviews suggested resolutions and approves
- Cascade recalculation runs until schedule is conflict-free

### Status Lifecycle
```
SCHEDULED
  → UPCOMING      (T-7 days: push notification to supervisor)
  → DUE_SOON      (T-3 days: WARNING push to supervisor)
  → DUE_TODAY     (T-0: ALERT push, task appears on supervisor app)
  → ADMINISTERED  (supervisor reports → 7-day watch starts)
     OR
  → OVERDUE       (T+1: ALERT push to owner)
  → CRITICALLY_OVERDUE (T+3: CRITICAL push to owner, action required)
```

### Conflict Engine — Pure Function Signature
```python
def detect_conflicts(
    schedule: list[VaccineEvent],
    proposed: VaccineEvent,
    vaccine_master: dict[UUID, VaccineMaster]
) -> ConflictResult:
    """
    Pure function. No database calls.
    Input:  existing schedule + proposed vaccine event + vaccine rules
    Output: list of conflicts + scored resolution options
    """
```

### Post-Vaccine Watch
- 7-day window after every administration
- Anomalies in this window tagged "post_vaccine_period" — not treated as unexplained
- Expected: 1-3 day production dip, 1-2 day feed intake dip
- These are NORMAL — do not alert within expected ranges

---

## 9. Alert System — Complete Specification

### Delivery: In-System Only
No WhatsApp. No SMS. No email. No external messaging. Ever.

```
LEVEL     WHO           HOW                                    DISMISSAL
──────────────────────────────────────────────────────────────────────────────
INFO      Supervisor    Flag on supervisor dashboard only       Auto-clears next day
WARNING   Both          Push notification + dashboard badge     Supervisor acknowledges
ALERT     Owner only    Push notification + dashboard highlight Owner acknowledges
CRITICAL  Owner only    High-priority push + full-screen banner Owner takes action
                        Cannot be dismissed without action
```

### Delivery Chain
```
Intelligence Service detects anomaly
    ↓
Writes record to system_alert table (RDS)
    ↓
alert_service.py calls AWS SNS topic
    ↓
SNS triggers Expo Push Notification Service
    ↓
Expo delivers native push to:
    - Owner: browser push on dashboard web app
    - Supervisor: native push on Android app
    ↓
Alert also visible in dashboard on next load
(persistent — not lost if push notification missed)
```

### All Critical Alert Triggers
```
TRIGGER                                              LEVEL
──────────────────────────────────────────────────────────
Vaccine OVERDUE T+1                                  ALERT
Vaccine CRITICALLY OVERDUE T+3                       CRITICAL
HDP drops >5% vs previous day                        WARNING
HDP drops >10% in 48 hours                           ALERT
HDP drops >20% in 72 hours                           CRITICAL
Multiple flocks same farm dropping simultaneously     CRITICAL
Mortality >1.5x expected for stage (3 days)          WARNING
Mortality >2x expected for stage                     ALERT
Mortality >3x expected for stage                     CRITICAL
Raw material stock <7 days                           WARNING
Raw material stock <3 days                           ALERT
Raw material stock <1 day                            CRITICAL
Feed batch quality FAIL                              ALERT
Feed/bird outside ±30% expected (3 days)             WARNING
Bird movement PENDING >4 hours                       ALERT
THEFT or MISSING >2 times in 30 days same farm       ALERT
Transfer no confirmation in 24 hours                 ALERT
Vaccine stock insufficient for next scheduled dose   WARNING
Vaccine expiry <30 days with stock remaining         WARNING
```

---

## 10. API Endpoints — Complete Registry

```
AUTH
POST   /api/v1/auth/owner-login          Owner email+password login
POST   /api/v1/auth/supervisor-login     Supervisor PIN login
POST   /api/v1/auth/refresh              Refresh JWT
POST   /api/v1/auth/logout

DASHBOARD
GET    /api/v1/dashboard/owner           Owner morning dashboard (all farms aggregated)
GET    /api/v1/dashboard/farm/{farm_id}  Farm-level drill-down
GET    /api/v1/dashboard/flock/{id}      Flock detail + 7-day trends

FLOCKS
GET    /api/v1/flocks                    List (filter: farm, status, stage)
GET    /api/v1/flocks/{id}              Single flock detail
POST   /api/v1/flocks                    Create new placement (owner only)
PATCH  /api/v1/flocks/{id}              Update flock (owner only)
POST   /api/v1/flocks/{id}/deplete      Close flock (owner only)

DAILY SNAPSHOTS
GET    /api/v1/snapshots                 List (filter: flock, date range, farm)
GET    /api/v1/snapshots/{id}           Single snapshot
POST   /api/v1/snapshots                Submit daily entry (supervisor)
PATCH  /api/v1/snapshots/{id}          Correct entry (with audit trail)

VACCINES
GET    /api/v1/vaccines/templates        List breed templates
POST   /api/v1/vaccines/templates        Create template (owner only)
PATCH  /api/v1/vaccines/templates/{id}  Update template (owner only, creates version)
GET    /api/v1/vaccines/events           List vaccine events (filter: flock, status, date)
GET    /api/v1/vaccines/events/{id}     Single event
POST   /api/v1/vaccines/events/emergency Add emergency vaccine (owner only)
PATCH  /api/v1/vaccines/events/{id}    Report administration (supervisor)
POST   /api/v1/vaccines/events/{id}/approve  Approve reschedule (owner only)
GET    /api/v1/vaccines/conflicts/{flock_id}  Check conflicts for proposed vaccine

FEED MILL
GET    /api/v1/feed/formulas             List formulas
POST   /api/v1/feed/formulas             Create formula (owner only)
PATCH  /api/v1/feed/formulas/{id}       Update formula (owner only, creates version)
GET    /api/v1/feed/batches              List batches (filter: farm, date)
POST   /api/v1/feed/batches              Create batch (supervisor — mill entry)
PATCH  /api/v1/feed/batches/{id}/release Release conditional/failed batch (owner only)

FEED DISPATCH
GET    /api/v1/feed/dispatches           List dispatches
POST   /api/v1/feed/dispatches           Create dispatch record
PATCH  /api/v1/feed/dispatches/{id}/confirm  Confirm receipt at shed (supervisor)

RAW MATERIALS
GET    /api/v1/raw-materials/stock       Stock levels per farm
POST   /api/v1/raw-materials/stock       Record purchase receipt
GET    /api/v1/raw-materials/movements   Movement history

VACCINE INVENTORY
GET    /api/v1/vaccine-inventory         Stock per farm
POST   /api/v1/vaccine-inventory         Record receipt
PATCH  /api/v1/vaccine-inventory/{id}   Update (use deducted on administration)

BIRD MOVEMENTS
GET    /api/v1/bird-movements            List (filter: flock, type, status)
POST   /api/v1/bird-movements            Report movement (supervisor)
PATCH  /api/v1/bird-movements/{id}/approve  Approve (owner only)
PATCH  /api/v1/bird-movements/{id}/reject   Reject (owner only)

HEALTH EVENTS
GET    /api/v1/health-events             List (filter: flock, farm, date)
POST   /api/v1/health-events             Create (supervisor flags, owner enters vet rec)
PATCH  /api/v1/health-events/{id}       Update outcome

ALERTS
GET    /api/v1/alerts                    List alerts for current user
PATCH  /api/v1/alerts/{id}/acknowledge  Acknowledge alert
GET    /api/v1/alerts/unread-count       Badge count for UI

USERS (owner only)
GET    /api/v1/users                     List supervisors
POST   /api/v1/users                     Create supervisor account
PATCH  /api/v1/users/{id}              Update user
DELETE /api/v1/users/{id}              Deactivate (soft delete)

EXPORTS
GET    /api/v1/exports/feed-consumption  CSV export (date range, farm)
GET    /api/v1/exports/egg-production    CSV export
GET    /api/v1/exports/vaccine-log       CSV export
GET    /api/v1/exports/bird-movements    CSV export
GET    /api/v1/exports/flock-lifecycle/{id}  Full flock history CSV

SYNC (WatermelonDB)
POST   /api/v1/sync/pull                 Pull changes since last_pulled_at
POST   /api/v1/sync/push                 Push local changes to server
```

---

## 11. WatermelonDB Schema (Supervisor App)

```typescript
// apps/supervisor/src/database/schema.ts
import { appSchema, tableSchema } from '@nozbe/watermelondb'

export default appSchema({
  version: 1,
  tables: [
    tableSchema({
      name: 'flocks',
      columns: [
        { name: 'server_id', type: 'string', isIndexed: true },
        { name: 'farm_id', type: 'string', isIndexed: true },
        { name: 'shed_id', type: 'string' },
        { name: 'flock_code', type: 'string' },
        { name: 'breed_id', type: 'string' },
        { name: 'placement_date', type: 'string' },
        { name: 'net_birds_started', type: 'number' },
        { name: 'flock_status', type: 'string' },
        { name: 'is_deleted', type: 'boolean' },
        { name: 'updated_at', type: 'number' },  // unix timestamp for sync
      ]
    }),
    tableSchema({
      name: 'daily_flock_snapshots',
      columns: [
        { name: 'server_id', type: 'string', isIndexed: true },
        { name: 'flock_id', type: 'string', isIndexed: true },
        { name: 'farm_id', type: 'string', isIndexed: true },
        { name: 'shed_id', type: 'string' },
        { name: 'snapshot_date', type: 'string', isIndexed: true },
        { name: 'bird_age_days', type: 'number' },
        { name: 'opening_bird_count', type: 'number' },
        { name: 'mortality_count', type: 'number' },
        { name: 'culled_sick_count', type: 'number' },
        { name: 'eggs_collected', type: 'number' },
        { name: 'eggs_broken', type: 'number' },
        { name: 'eggs_floor', type: 'number' },
        { name: 'feed_returned_kg', type: 'number' },
        { name: 'water_consumed_litres', type: 'number', isOptional: true },
        { name: 'morning_temp_c', type: 'number', isOptional: true },
        { name: 'observations', type: 'string', isOptional: true },
        { name: 'reported_by_name', type: 'string' },
        { name: 'sync_status', type: 'string' },
        { name: 'is_deleted', type: 'boolean' },
        { name: 'updated_at', type: 'number' },
      ]
    }),
    tableSchema({
      name: 'vaccine_events',
      columns: [
        { name: 'server_id', type: 'string', isIndexed: true },
        { name: 'flock_id', type: 'string', isIndexed: true },
        { name: 'farm_id', type: 'string', isIndexed: true },
        { name: 'vaccine_name', type: 'string' },
        { name: 'target_date', type: 'string', isIndexed: true },
        { name: 'status', type: 'string', isIndexed: true },
        { name: 'actual_date', type: 'string', isOptional: true },
        { name: 'batch_number', type: 'string', isOptional: true },
        { name: 'actual_method', type: 'string', isOptional: true },
        { name: 'birds_covered', type: 'number', isOptional: true },
        { name: 'delay_reason', type: 'string', isOptional: true },
        { name: 'worker_observations', type: 'string', isOptional: true },
        { name: 'worker_instructions', type: 'string' },
        { name: 'is_deleted', type: 'boolean' },
        { name: 'updated_at', type: 'number' },
      ]
    }),
    tableSchema({
      name: 'bird_movements',
      columns: [
        { name: 'server_id', type: 'string', isIndexed: true },
        { name: 'flock_id', type: 'string', isIndexed: true },
        { name: 'farm_id', type: 'string', isIndexed: true },
        { name: 'movement_date', type: 'string' },
        { name: 'movement_type', type: 'string' },
        { name: 'direction', type: 'string' },
        { name: 'bird_count', type: 'number' },
        { name: 'reason_note', type: 'string', isOptional: true },
        { name: 'reported_by_name', type: 'string' },
        { name: 'status', type: 'string' },
        { name: 'sync_status', type: 'string' },
        { name: 'is_deleted', type: 'boolean' },
        { name: 'updated_at', type: 'number' },
      ]
    }),
    tableSchema({
      name: 'system_alerts',
      columns: [
        { name: 'server_id', type: 'string', isIndexed: true },
        { name: 'farm_id', type: 'string', isOptional: true },
        { name: 'alert_level', type: 'string', isIndexed: true },
        { name: 'alert_type', type: 'string' },
        { name: 'title', type: 'string' },
        { name: 'body', type: 'string' },
        { name: 'action_required', type: 'boolean' },
        { name: 'read_at', type: 'number', isOptional: true },
        { name: 'acknowledged_at', type: 'number', isOptional: true },
        { name: 'is_deleted', type: 'boolean' },
        { name: 'updated_at', type: 'number' },
      ]
    }),
  ]
})
```

---

## 12. Environment Variables — Complete List

```bash
# apps/api/.env  (development only — never commit this file)
# Production values live in AWS Secrets Manager

# DATABASE
DATABASE_URL=postgresql://user:pass@localhost:5432/poultry_dev
DATABASE_POOL_SIZE=10
DATABASE_MAX_OVERFLOW=20

# AWS (dev uses IAM user, prod uses ECS task role)
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=ap-south-1

# AWS COGNITO
COGNITO_USER_POOL_ID=ap-south-1_XXXXXXXX
COGNITO_CLIENT_ID=your_client_id
COGNITO_REGION=ap-south-1

# JWT
JWT_SECRET_KEY=your_secret_key_min_32_chars
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=60
JWT_REFRESH_TOKEN_EXPIRE_DAYS=30

# AWS SNS
SNS_TOPIC_ARN_ALERTS=arn:aws:sns:ap-south-1:XXXX:poultry-alerts

# REDIS (ElastiCache)
REDIS_URL=redis://localhost:6379/0

# APP CONFIG
ENVIRONMENT=development       # development / production
LOG_LEVEL=DEBUG               # DEBUG / INFO / WARNING / ERROR
APP_PORT=8000

# INTELLIGENCE ENGINE SCHEDULE (IST = UTC+5:30)
NIGHTLY_JOB_HOUR_UTC=17       # runs at 11pm IST
WEEKLY_JOB_DAY=6              # Sunday
VACCINE_ALERT_HOUR_UTC=0      # runs at 6am IST

# CORS
ALLOWED_ORIGINS=http://localhost:5173,https://dev-app.yourdomain.com

# apps/dashboard/.env
VITE_API_URL=http://localhost:8000
VITE_COGNITO_USER_POOL_ID=ap-south-1_XXXXXXXX
VITE_COGNITO_CLIENT_ID=your_client_id
VITE_ENV=development

# apps/supervisor/.env  (Expo)
EXPO_PUBLIC_API_URL=http://localhost:8000
EXPO_PUBLIC_ENV=development
```

---

## 13. CI/CD Pipeline — GitHub Actions

```yaml
# .github/workflows/deploy-dev.yml — triggers on push to dev branch
# .github/workflows/deploy-prod.yml — triggers on merge to main

Steps (both pipelines):
1. Checkout code
2. Run Python tests (pytest apps/api/)
3. Run TypeScript type check (tsc --noEmit)
4. Build Docker image (apps/api/ Dockerfile)
5. Push image to AWS ECR (tagged with git SHA)
6. Update ECS task definition with new image tag
7. Deploy to ECS cluster (rolling update)
8. Wait for ECS health check to pass
9. On failure: automatic rollback to previous task definition
10. Build React dashboard (npm run build)
11. Sync build output to S3 bucket
12. Invalidate CloudFront distribution cache

Expo mobile build: Manual trigger via Expo EAS CLI
  eas build --platform android --profile production
```

---

## 14. AWS Setup Sequence (Phase 0)

```
Step 1: Create AWS account
  - Enable MFA on root account immediately
  - Create IAM user for development (not root)
  - Attach policies: AmazonRDSFullAccess, AmazonECS_FullAccess,
    AmazonCognitoPowerUser, AmazonS3FullAccess, CloudFrontFullAccess,
    AmazonSNSFullAccess, SecretsManagerReadWrite, CloudWatchFullAccess

Step 2: Create RDS PostgreSQL (dev)
  - Engine: PostgreSQL 15
  - Template: Free tier (t3.micro for dev)
  - Region: ap-south-1
  - VPC: default, public subnet (dev only — private in prod)
  - Enable: automated backups
  - Save credentials to AWS Secrets Manager immediately

Step 3: Create Cognito User Pool
  - Pool name: poultry-farm-dev
  - Sign-in: email (owner), phone (supervisor)
  - Custom attributes: role (string), farm_id (string)
  - App client: poultry-dashboard (no secret, for web)
  - App client: poultry-supervisor (for mobile)
  - Custom auth flow for supervisor PIN

Step 4: Create S3 Bucket + CloudFront
  - Bucket: poultry-dashboard-dev-{accountid}
  - Block all public access: YES (serve only via CloudFront)
  - CloudFront: OAC (Origin Access Control) to bucket
  - Custom domain: dev-app.yourdomain.com (Route 53)
  - HTTPS: ACM certificate (us-east-1 for CloudFront)

Step 5: Create ECR Repository
  - Name: poultry-farm-api
  - Region: ap-south-1

Step 6: Create ECS Cluster
  - Name: poultry-farm-dev
  - Type: Fargate
  - Create task definitions for API and Intelligence containers

Step 7: Run database schema
  - psql connect to RDS
  - Run infra/aws/rds_schema.sql
  - Run infra/aws/rds_indexes.sql
  - Run infra/aws/rds_rls_policies.sql
  - Run infra/scripts/seed_master_data.py

Step 8: Configure GitHub Actions secrets
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
  - ECR_REGISTRY
  - ECS_CLUSTER_DEV / ECS_CLUSTER_PROD
  - ECS_SERVICE_API_DEV / ECS_SERVICE_API_PROD
  - S3_BUCKET_DEV / S3_BUCKET_PROD
  - CLOUDFRONT_DISTRIBUTION_DEV / CLOUDFRONT_DISTRIBUTION_PROD
```

---

## 15. Validation Rules — Data Integrity

### Blocking validations (reject submission if violated)

```
FIELD                         RULE
──────────────────────────────────────────────────────────────
mortality_count               >= 0 AND <= opening_bird_count
culled_sick_count             >= 0 AND <= opening_bird_count
eggs_collected                >= 0
eggs_broken                   >= 0 AND <= eggs_collected
eggs_floor                    >= 0 AND <= eggs_collected
eggs_broken + eggs_floor      <= eggs_collected
feed_returned_kg              <= feed_issued_kg
hdp_percent                   0 to 105
bird_count (movement)         > 0 AND <= current_live_birds
vaccine coverage_percent      0 to 100
batch expiry_date             >= today at time of administration
shed capacity                 initial_birds_placed <= shed.capacity_birds
formula ingredient sum        must equal 100kg per 100kg feed (±0.1kg)
batch ingredient variance     > ±2% of formula → require reason
```

### Anomaly flags (WARNING push, not block)

```
CONDITION                                         ACTION
────────────────────────────────────────────────────────────────
feed_per_bird_g outside ±30% of expected          WARNING + flag on snapshot
mortality > 2× 7-day rolling average              WARNING alert
HDP drops >5% vs previous day                     WARNING alert
eggs_broken / eggs_collected > 3%                 INFO flag
water_consumed drops >20% vs 7-day avg            WARNING (early health signal)
feed batch ingredient variance >2%                WARNING flag on batch
dispatch vs received variance >1%                 WARNING flag on dispatch
```

---

## 16. Intelligence Engine — Full Specification

### Nightly Job (11pm IST, every day)

```python
# jobs/nightly_intelligence.py

For each active flock:
1. PRODUCTION CHECK
   - Compare today's HDP vs yesterday's HDP
   - Compare today's HDP vs breed curve for this age
   - If anomaly: run cross-module investigation
   - Investigation checks:
     a. Vaccine events in past 7 days → tag if found, assess expected impact
     b. Feed batch change in past 14 days → tag if found
     c. Mortality trend in past 7 days → assess direction
     d. Flock age vs expected natural decline
   - Write structured report to intelligence_flag table
   - Create system_alert if severity >= WARNING

2. MORTALITY CHECK
   - Calculate rolling 7-day average
   - Compare today vs average and vs breed standard
   - Check for rising 3-day trend regardless of absolute level
   - Check for simultaneous spikes across multiple sheds (farm-level event)

3. FEED EFFICIENCY CHECK
   - Calculate feed/bird/day trend over 10 days
   - Flag rising trend not explained by stage change
   - Calculate feed/egg ratio — flag deterioration

4. VACCINE COMPLIANCE CHECK
   - Scan all vaccine events for upcoming/overdue status
   - Update statuses
   - Fire alerts per alert threshold table
   - Check vaccine inventory vs upcoming doses needed

5. RAW MATERIAL CHECK
   - Calculate days of stock remaining (current / 14-day avg consumption)
   - Fire alerts at 7-day, 3-day, 1-day thresholds

6. BIRD MOVEMENT CHECK
   - Check for PENDING movements >4 hours old → ALERT
   - Check THEFT/MISSING pattern (>2 in 30 days) → ALERT
   - Check TRANSFER_OUT with no TRANSFER_IN (>24hrs) → ALERT
```

### Weekly Pattern Job (Sunday 10pm IST)

```python
# jobs/weekly_patterns.py

Patterns detected:
1. Breed performance vs your own farm's historical average (not just manufacturer curve)
2. Adjacent shed same-cause mortality (structural/biosecurity issue)
3. Cross-farm feed cost variance (procurement pricing opportunity)
4. Seasonal patterns (compare month vs same month last year)
5. Supplier quality: hatchery DOA rate trend, vaccine batch efficacy
```

### Vaccine Alert Job (6am IST, every day)

```python
# jobs/vaccine_alerts.py

1. Find all vaccine_events where status = 'scheduled' AND target_date = TODAY + 7
   → Push WARNING to supervisors: "Vaccine due in 7 days"

2. Find all vaccine_events where status = 'scheduled' AND target_date = TODAY + 3
   → Push WARNING to supervisor + owner

3. Find all vaccine_events where status = 'scheduled' AND target_date = TODAY
   → Push ALERT to supervisor + owner
   → Create task on supervisor's app task list

4. Find all vaccine_events where status NOT IN ('administered','skipped') AND target_date < TODAY
   → Update status to OVERDUE or CRITICALLY_OVERDUE
   → Push ALERT or CRITICAL accordingly
```

---

## 17. What This System Is NOT — Never Build These

```
EXCLUDED                        REASON
──────────────────────────────────────────────────────────────
Accounting / bookkeeping        Not in scope. Export data for external use.
Billing / invoicing / GST       Not in scope.
Sales management / CRM          Not in scope.
HR / payroll                    Not in scope.
Vehicle / logistics             Not in scope.
Customer portal                 Not in scope.
WhatsApp / email alerts         All alerts are in-system only.
Financial fields on movements   Bird movements track count only, not money.
```

If asked to build any of the above, respond:
"This is outside the scope of the Farm Command Center.
The system provides structured operational data exports for external use."

---

## 18. Code Quality Standards

```
Python (backend):
  - Type hints on ALL functions — no exceptions
  - Docstring on every service function (what it does + why)
  - Business rule comments explain WHY, not just what
  - pytest for: conflict engine, HDP calc, bird count formula, alert thresholds
  - pydantic BaseSettings for all config (no os.environ directly)
  - No print() statements — use logging module always
  - Black formatter + isort imports

TypeScript (dashboard + supervisor):
  - Strict mode — no `any` types anywhere
  - Shared types from packages/shared-types — no duplicate type definitions
  - React Query for all server state — no useState for server data
  - Zustand only for UI state (modal open, selected farm filter, etc.)

Database:
  - Alembic migration for every schema change — never ALTER TABLE manually
  - Every migration is reversible (has downgrade function)
  - Never hard-delete any record
  - Seed data in infra/scripts/seed_master_data.py

General:
  - No hardcoded values — all thresholds in config.py or database config table
  - All secrets via AWS Secrets Manager (prod) or .env file (dev only)
  - Feature branches → PR → review → merge to dev → merge to main
```

---

## 19. Phase Tracker

```
PHASE   STATUS    SCOPE
──────────────────────────────────────────────────────────────────────────
0       CURRENT   AWS setup, schema, monorepo, auth, RLS, skeletons
1       NEXT      Flock placement, daily snapshot, mortality, basic dashboard
2       FUTURE    Vaccine system, supervisor app, WatermelonDB offline sync
3       FUTURE    Egg production, HDP, anomaly detection, production dashboard
4       FUTURE    Feed mill, dispatch, consumption, raw material inventory
5       FUTURE    Intelligence engine, push alerts, pattern detection
6       FUTURE    Breed benchmarking, supplier performance, full analytics
```

### Phase 0 Complete When ALL of These Are Done:

```
AWS ACCOUNT
[ ] AWS account created, MFA on root enabled
[ ] IAM dev user created with correct policies
[ ] ap-south-1 set as default region

DATABASE
[ ] RDS PostgreSQL 15 instance running (dev, t3.micro)
[ ] rds_schema.sql executed — all tables created
[ ] rds_indexes.sql executed — all indexes created
[ ] rds_rls_policies.sql executed — RLS enabled and tested
[ ] seed_master_data.py run — breeds, vaccine master seeded
[ ] Credentials stored in Secrets Manager

AUTH
[ ] Cognito User Pool created (dev)
[ ] Owner app client configured
[ ] Supervisor app client configured (custom PIN auth flow)
[ ] Owner test account created and login tested

BACKEND
[ ] Monorepo initialised (Turborepo)
[ ] apps/api/ FastAPI skeleton running locally on port 8000
[ ] Database connection verified (SQLAlchemy)
[ ] Auth middleware verified (JWT from Cognito)
[ ] RLS verified (supervisor cannot see other farm data)
[ ] /api/v1/health endpoint returns 200
[ ] Docker image builds successfully
[ ] Image pushed to ECR
[ ] ECS task running in dev cluster

FRONTEND
[ ] apps/dashboard/ React skeleton running locally
[ ] Cognito owner login working
[ ] API connection verified
[ ] Deployed to S3 + CloudFront dev distribution

MOBILE
[ ] apps/supervisor/ Expo skeleton running on Android device
[ ] PIN login flow working
[ ] WatermelonDB schema.ts defined
[ ] Sync adapter scaffold in place
[ ] One test record synced successfully

CI/CD
[ ] deploy-dev.yml working (push to dev → deploys)
[ ] deploy-prod.yml working (merge to main → deploys)
```

---

## 20. Session Startup Protocol

At the start of EVERY session, before writing a single line of code:

```
1. State the current phase number and name
2. State what was completed in the last session
3. State the specific task for THIS session (one task only)
4. List any dependencies this task requires that are not yet built
5. Confirm the task fits within the current phase scope
6. Only then begin
```

If the task is unclear, ask one focused question. Then begin.
Never start a session by writing code before completing this protocol.

---

*This is the authoritative source of truth for every technical decision in this project.
If any suggestion, library recommendation, or architectural idea conflicts with
anything written in this file — this file wins. Always.*
