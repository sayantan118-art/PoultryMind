# PoultryMind — Development Guide (Coding Agent Execution Manual)

**Audience:** an AI coding agent working inside VS Code on this repository, and any human reviewing its work.
**Purpose:** tell the agent WHAT to build, IN WHAT ORDER, UNDER WHICH RULES, HOW TO VERIFY IT, and WHEN it is actually done — without re-deciding architecture that is already settled.
**Status of the underlying architecture:** fully designed, ~0% implemented. See Part 0 for the verified current state. Do not trust older status docs (`IMPLEMENTATION_SUMMARY.md`, `DELIVERY_SUMMARY.md`, `PHASE_1_CHECKLIST.md`) about what's "complete" — this guide supersedes them for implementation sequencing.

This document is the primary operating manual. `NEXT_TASK.md` always contains the single next concrete task; this file explains the rules and the full backlog that task is drawn from.

---

## PART 0 — LOCKED ARCHITECTURE (do not re-decide these)

These decisions are final. If you (the agent) believe one must change, follow the protocol in Part 6 — do not silently override.

| Decision | Value |
|---|---|
| Backend | FastAPI, modular monolith (routers/services/models/schemas by domain), no microservices |
| Database | PostgreSQL on AWS RDS (`ap-south-1`), single instance |
| Isolation | Row-Level Security (RLS) for farm-level data isolation — never bypassed |
| Owner frontend | React + Vite + TypeScript, **online-only** |
| Supervisor frontend | React Native + Expo (Android), **offline-first** |
| Offline storage | WatermelonDB on the supervisor's phone only — **no local farm servers, ever** |
| Roles | Exactly two: `owner`, `supervisor` — no others |
| Alerts | In-app + native push (Expo/SNS) only — **no WhatsApp, SMS, or email, ever** |
| Database source of truth | SQLAlchemy models → Alembic migrations. `infra/aws/rds_schema.sql` becomes a generated snapshot, not a hand-edited file, once migrations exist |
| Multi-tenancy | Deferred. Single `company` row. Do not build tenant switching, tenant-scoped auth, or a company picker |
| Domain model | 24 core tables (see `infra/aws/rds_schema.sql` and Part 3 of `PoultryMind_Architecture_Blueprint.md`) |
| Accounting/finance | Explicitly out of scope. Bird movements, feed, vaccine records have **no financial fields**. Design only for exportability (CSV/Excel), never build billing/invoicing/GST |

Read before touching code: `architecture.md`, `ON_GROUND_OPERATIONS.md`, `infra/aws/rds_schema.sql`, `infra/aws/rds_rls_policies.sql`, `packages/shared-types/src/index.ts`, and `PoultryMind_Architecture_Blueprint.md` (the architecture audit that produced this guide).

---

## PART 1 — BEFORE CHANGING ANYTHING

Every session, in this order:

1. **Read `IMPLEMENTATION_STATUS.md` first.** It tells you what the last session did and what's next. If it doesn't exist yet, your first task is to create it (see Part 10).
2. **Inspect the actual repository state** for the area you're about to touch — do not trust any doc's claim of "complete." Open the real files. Run the real commands (`python -c "import ..."`, `alembic history`, `pytest`, `ls`).
3. **Cross-check against `architecture.md` / `ON_GROUND_OPERATIONS.md` / the schema files** for the domain rule that applies.
4. **Search for existing implementation** of what you're about to build (`grep`/file search across `apps/api`) before writing anything new. Never recreate a router, model, or utility that already exists, even partially — extend it.
5. **Check `requirements.txt` / `package.json`** before adding any dependency. If it's not already there, follow the "required dependency" protocol in Part 6.
6. Documentation existing ≠ implementation existing. A `.md` file saying a feature is done is not evidence. Only working code, passing tests, and a runnable verification command are evidence.

---

## PART 2 — AGENT OPERATING RULES

### Architecture discipline
- Do not invent new architecture. Do not introduce microservices, message queues, GraphQL, or a second database technology.
- Do not create abstractions (base classes, generic repositories, plugin systems) until at least two concrete cases need them. Prefer the boring, direct implementation.
- Do not duplicate domain logic — if a calculation (e.g., `closing_bird_count`, `hdp_percent`) already has a home, extend it there, don't reimplement it in a router or a frontend component.
- Keep domain boundaries aligned with the existing module list (flock, vaccine, feed, health, movement, dashboard/alerts) — one router/service/schema file per domain, matching `apps/api/models/*.py`'s grouping.
- Follow existing naming conventions once Part 3's PK-naming decision (below) is applied consistently — don't mix conventions file to file.
- Never silently change a database invariant (a `CHECK` constraint, an RLS policy, a uniqueness rule) to make a feature pass. If an invariant blocks a feature, that's a signal to fix the feature's logic, or to flag a real architecture conflict (Part 6) — not to weaken the constraint.
- Never bypass RLS, even in a "temporary" debug endpoint. `main.py`'s `/test-rls` route is a reference example of how RLS context is set — not a template to leave in production code.
- Never weaken validation (e.g., relaxing an egg/mortality arithmetic check) to make a demo work.

### Database discipline
- SQLAlchemy models (`apps/api/models/*.py`) are canonical, going forward. `infra/aws/rds_schema.sql` is a reference for what the schema *should* contain during the migration-from-SQL transcription (Stage 1) — after that, it is regenerated from Alembic, never hand-edited again.
- Every schema change is an Alembic migration. No manual `ALTER TABLE`, ever, including in local dev.
- Migrations should be reversible (`downgrade()` implemented) unless genuinely impossible (e.g., dropping a column with data loss) — in that case, say so in the migration docstring.
- Preserve historical operational data: prefer additive migrations and "correction record" patterns (Part 8, rule 9 of the architecture blueprint) over destructive edits to `daily_flock_snapshot`, `vaccine_event`, `flock_bird_movement` once those tables have real rows.
- Enforce important invariants at both the database (`CHECK` constraints / triggers) and application (Pydantic schema / service-layer validation) level — the DB is the backstop, the API is the fast, readable error message.

### API discipline
- Organize routers by domain (`routers/flock.py`, `routers/vaccine.py`, etc.), matching `API.md`'s domain grouping.
- Validate every input with a Pydantic schema in `schemas/` — no raw dict bodies.
- Return predictable, structured errors (consistent error shape, HTTP status codes matching the failure type) — never leak a raw SQLAlchemy/Postgres exception message to the client. Translate constraint violations into the plain-language messages `architecture.md` Section 9 (API contract corrections) calls for, since these surface on a low-literacy supervisor's phone.
- Every write path respects the RLS context (`app.user_role`, `app.farm_id`, `app.user_id` session variables) — set them in a real auth-dependent middleware/dependency, not the placeholder in current `main.py`.
- Keep response shapes aligned with `packages/shared-types/src/index.ts`. If a field is added to a model, add it to shared-types in the same change.

### Frontend discipline
- No decorative dashboard widgets. Every dashboard metric must trace to a row in Part 7 of the architecture blueprint (source → calculation → meaning → action). If it doesn't trace to a real decision the owner makes, don't build it.
- No mock/hardcoded data once the real endpoint exists. It's acceptable to stub a screen behind a real (even if empty) API call while the backend catches up, but never wire a chart to invented numbers and call it done.
- Every screen handles loading, empty, error, and (for the supervisor app) offline states explicitly — not just the happy path.
- Supervisor workflows are optimized for speed and low literacy: large tap targets, minimal typing, pre-filled defaults, under-60-second vaccine entry / under-45-second egg entry as specified in `architecture.md` Sections 6.4 and 9.1. If a screen you're building takes more taps or more typing than the spec describes, that's a defect, not a style choice.

---

## PART 3 — KNOWN DEFECTS TO FIX AS PART OF STAGE 0/1 (verified by inspection, not assumed)

These are real, confirmed bugs/gaps in the current repo — not hypothetical. Fix them as part of the relevant stage below rather than rediscovering them later.

1. **`Decimal` is imported from `sqlalchemy` in four model files** (`master.py`, `feed.py`, `inventory.py`, `vaccine.py`) — this is not a valid SQLAlchemy export (Python's `decimal.Decimal` and SQLAlchemy's `Numeric` type are being confused). Importing any of these modules currently raises `ImportError`. **This means the model layer cannot currently be imported at all.** Fix: replace `Decimal` with SQLAlchemy's `Numeric` in the import and every `Column(Decimal(...))` usage.
2. **Primary key naming mismatch**: `apps/api/models/base.py`'s `AuditMixin` generates a generic `id` primary key column for every table, but `infra/aws/rds_schema.sql` (the design source of truth) and `packages/shared-types/src/index.ts` use domain-specific PK names (`farm_id`, `company_id`, `flock_id`, etc.), and all `ForeignKey(...)` references in the models currently point at `"farm.id"`, `"company.id"`, etc. **Decision needed and applied here:** switch to domain-specific PK names to match the SQL schema and shared types (they're the more complete, already-consistent artifacts) — `AuditMixin` should stop auto-generating `id` and each model should declare its own `<table>_id` primary key column, with FKs updated to match.
3. **`models/__init__.py` does not import the actual model classes** — only `Base`/mixins. Alembic's `target_metadata` currently sees zero tables. Fix in Stage 1.
4. **`daily_flock_snapshot.hdp_percent` is typed as `String`** in `flock.py` with a comment admitting it should be a decimal — fix to `Numeric(6,3)` to match `rds_schema.sql`.
5. **`docker-compose.yml` currently bootstraps the local Postgres container directly from `infra/aws/rds_schema.sql`** (via `docker-entrypoint-initdb.d`), bypassing Alembic entirely. Once Alembic migrations exist, this needs to change: either drop the SQL-file bootstrap and let `alembic upgrade head` create the schema, or keep the SQL bootstrap only for a from-scratch demo seed and `alembic stamp head` immediately after — document whichever is chosen in `DATABASE.md` and do not run both against the same empty DB without stamping (running the SQL file AND then `alembic upgrade head` on an already-populated schema will fail).
6. **`validation_flags = Column(JSONB, default=[])`** in `flock.py` uses a mutable default — should be `default=list` (a callable), not a shared literal `[]`, to avoid SQLAlchemy's known mutable-default pitfall.
7. **`apps/dashboard/` and `apps/supervisor/` contain only `package.json`** — no scaffolding (no Vite config, no Expo config, no entry point). Stage 6/7 must scaffold these from scratch, they are not "started."

---

## PART 4 — IMPLEMENTATION ORDER (STAGES)

Work stage by stage, in order. Do not start Stage N+1 with Stage N's acceptance criteria unmet. Each stage is broken into milestones in Part 5's format where the work is non-trivial.

### Stage 0 — Repository / development foundation
Verify (and fix where broken) local dev works end-to-end: Docker Compose brings up Postgres + Redis + API; `apps/api` imports cleanly; `.env` handling works with sane defaults; `pytest` runs (even if it only has 2 tests today); linting/type-checking tooling exists and runs; CI workflow at least runs install + lint + test on push. This stage is mostly verification and small fixes (including defect #1 above, which currently blocks even importing the app in some configurations) — it should be fast.

### Stage 1 — Database foundation
Fix defects #2, #3, #6 above. Port every table in `rds_schema.sql` into the corresponding SQLAlchemy model (transcription, not redesign — see Part 0.2 of the architecture blueprint). Import all models in `models/__init__.py`. Generate the first Alembic migration from the complete model set. Add the missing invariants from the blueprint's Part 3.4/Part 8: bird-count integrity trigger + `CHECK` constraints, flock-status-active-before-snapshot-insert check, 24-hour placement lock. Add indexes (`infra/aws/rds_indexes.sql` as reference). Confirm RLS policies apply cleanly against the Alembic-created schema. Add database-level tests (constraint violations actually raise, RLS actually isolates farms).

### Stage 2 — Authentication & authorization
Owner login (email + password, local JWT per `PHASE_1_CHECKLIST.md`'s Phase-1 decision — Cognito deferred). Supervisor login (phone + 4-digit PIN, hashed). Role enforcement dependency. Farm-assignment enforcement for supervisors. Real RLS-context-setting middleware/dependency (replacing the placeholder in `main.py`). Token issuance/validation, refresh handling.

### Stage 3 — Master data
Company, Farm, Shed, Breed, Vaccine master, Feed formula (+ ingredients), Raw material. Owner-only CRUD. Seed script for the four real farms (extend `infra/scripts/seed_master_data.py` rather than replacing it, if it already covers some of this).

### Stage 4 — Flock lifecycle
Create/place flock, 24h field lock, `flock_status` transitions (`active → depleted/sold/condemned`), depletion approval flow, historical view.

### Stage 5 — Daily flock operations
`daily_flock_snapshot` create/read endpoint (mortality, culling, feed, eggs, water, environment all in one submission per `architecture.md` Section 5.3 — this is the single most important entry point in the system, build it carefully). Server-side validation matching Part 8's business rules. Correction-record pattern for edits >48h old.

### Stage 6 — Owner dashboard
Scaffold `apps/dashboard` (Vite + React + TS) for real. Build against **live API data only** — every widget maps to a row in the blueprint's Part 7 table (live birds, vaccine compliance, flock ranking, feed efficiency, inventory risk, anomaly flags). No fake charts.

### Stage 7 — Supervisor application
Scaffold `apps/supervisor` (Expo + React Native) for real. PIN login, assigned-farm task list, daily entry form, WatermelonDB local queue, sync status indicator, retry/error handling.

### Stage 8 — Vaccination / health
Vaccine schedule generation at placement, event status lifecycle, conflict-detection engine, supervisor reporting flow (<60s), health event log, in-app alerting (no WhatsApp/SMS).

### Stage 9 — Feed / inventory
Feed formula versioning, batch production + ingredient variance flagging, dispatch/receipt variance, raw-material stock decrement, days-of-stock alerting.

### Stage 10 — Egg production / analytics
Daily egg entry (<45s), HDP calculation against breed curve, anomaly detection (Part 12 thresholds from `architecture.md`, in-app only), production milestones.

### Stage 11 — Hardening
Security review, audit-trail completeness check, error-handling pass, load/performance check at realistic scale (500k+ birds, 4 farms, years of snapshots), backup/recovery drill, deployment pipeline to AWS, CloudWatch monitoring/alarms.

**Work incrementally.** Never attempt to jump straight to Stage 6 because it's the most visible. A dashboard with no real backend behind it is not progress — it's technical debt with a UI.

---

## PART 5 — MILESTONE TEMPLATE

Every non-trivial unit of work (most tasks within a Stage) should be planned in this shape before code is written:

```
### Milestone: <name>

**Objective:** one sentence — what this accomplishes and why it matters now.

**Files/components affected:** exact paths expected to change or be created.

**Dependencies:** what must already exist/pass before starting (reference prior milestones/tasks by ID).

**Implementation tasks:** concrete, ordered steps.

**Acceptance criteria:** specific, checkable conditions (not "works well" — "POST /flocks with initial_birds_placed > shed.capacity_birds returns 422 with a specific error code").

**Tests:** what test(s) must exist and pass.

**Verification:** exact command(s) to run to confirm the milestone (e.g., `pytest apps/api/tests/test_flock.py -v`, `alembic upgrade head && alembic downgrade -1`, `curl -X POST ...`).

**Definition of Done:** checklist — code merged to the working branch, tests passing, IMPLEMENTATION_STATUS.md updated, no known regressions.
```

Use this template for every task ID in Part 7's backlog before implementing it — write the milestone block into `IMPLEMENTATION_STATUS.md`'s "in progress" section, then execute it.

---

## PART 6 — WHEN THE AGENT GETS STUCK

| Situation | Protocol |
|---|---|
| Missing information | Search the repo and `architecture.md`/`ON_GROUND_OPERATIONS.md`/the schema files first. Most answers already exist there. |
| Ambiguous implementation detail | Choose the simplest implementation consistent with the locked architecture (Part 0). Write down the assumption in `IMPLEMENTATION_STATUS.md`'s decision log. Don't block on it. |
| Architectural conflict (a locked decision in Part 0 seems wrong for what you're building) | **STOP that specific change.** Do not silently redesign. Write it up as: `Current decision → Problem → Proposed change → Consequences` in `IMPLEMENTATION_STATUS.md`'s "Architecture decisions" section, and move to a different unblocked task. Wait for explicit approval before implementing the change. |
| Bug in existing code, clearly within current architectural scope | Fix it. Note the fix in your session handoff (Part 9). |
| Need a new dependency | Check if an existing dependency already covers it. If genuinely needed, confirm it's compatible with the locked stack (no new database, no new frontend framework, no service mesh) and add it with a one-line justification in the commit/handoff. |
| Large architectural change seems necessary | Do not implement it automatically. Record it as a proposed architecture decision (same four-part format above) and stop there. This requires explicit human approval. |

---

## PART 7 — TASK BACKLOG

Priorities: **P0** = must do before any feature development. **P1** = required for MVP (Stages 3–7 core paths). **P2** = important enhancement (Stages 8–10, hardening polish). **P3** = future / deferred (everything flagged "Phase 2+" in the architecture blueprint: shed biosecurity log, supplier performance tracking, water quality test log, breed benchmarking, intelligence pattern engine).

Always pick the **highest-priority unblocked task**. A task is "blocked" only if its listed dependency is not yet done — not because a later, more interesting task exists.

| ID | Description | Priority | Dependencies | Expected files/modules | Acceptance criteria |
|---|---|---|---|---|---|
| T-001 | Fix invalid `Decimal` import in `master.py`, `feed.py`, `inventory.py`, `vaccine.py` → use `Numeric` | P0 | none | `apps/api/models/*.py` | `python -c "from apps.api.models import master, feed, inventory, vaccine"` succeeds with no ImportError |
| T-002 | Resolve PK-naming mismatch: domain-specific PKs (`farm_id`, `company_id`, etc.) instead of generic `id`; fix all `ForeignKey` references | P0 | T-001 | `apps/api/models/base.py`, all `models/*.py` | Every model's PK column name matches `rds_schema.sql`'s PK name for that table; all FKs resolve |
| T-003 | Fix `hdp_percent` type (`String` → `Numeric(6,3)`), fix mutable-default on `validation_flags` | P0 | T-001 | `apps/api/models/flock.py` | Column types match `rds_schema.sql`; no shared-list bug (verify by creating two instances and confirming independent lists) |
| T-004 | Import all model classes in `models/__init__.py` so Alembic sees full metadata | P0 | T-001, T-002 | `apps/api/models/__init__.py` | `alembic revision --autogenerate` produces a migration containing all 24 tables, not zero |
| T-005 | Generate first Alembic migration from complete model set | P0 | T-004 | `apps/api/migrations/versions/*.py` | `alembic upgrade head` on an empty DB creates all tables; `alembic downgrade base` cleanly drops them |
| T-006 | Add bird-count integrity trigger + `CHECK` constraints (blueprint Part 3.4/Part 8 items 1–2) | P0 | T-005 | new migration | Inserting a snapshot with `mortality_count + culled_sick_count > opening_bird_count` is rejected at the DB level; `closing_bird_count` is server-computed, not trusted from input |
| T-007 | Add flock-status-active check before snapshot insert (Part 8 item 3) | P0 | T-005 | new migration or service-layer check | Snapshot insert against a `depleted`/`sold`/`condemned` flock is rejected |
| T-008 | Add 24h placement-lock enforcement (Part 8 item 4) | P0 | T-005 | service layer + test | `PATCH` on `placement_date`/`initial_birds_placed` after 24h from `flock.created_at` is rejected |
| T-009 | Decide and document Alembic-vs-SQL-file docker-compose bootstrap (defect #5) | P0 | T-005 | `docker-compose.yml`, `DATABASE.md` | Fresh `docker-compose up` produces a working schema via one clear path, documented |
| T-010 | Database tests: constraints, RLS isolation | P0 | T-006–T-009 | `apps/api/tests/test_db_constraints.py`, `test_rls.py` | Tests fail on old schema, pass on new |
| T-011 | Owner auth (email+password, JWT) | P1 | T-005 | `routers/auth.py`, `services/auth_service.py`, `schemas/auth.py` | Valid login returns token matching `AuthResponse` shape in shared-types; invalid returns 401 |
| T-012 | Supervisor auth (phone+PIN, JWT) | P1 | T-005 | same as above | Same, with `assigned_farm_id` present in response |
| T-013 | Real RLS-context dependency (replace placeholder in `main.py`) | P1 | T-011, T-012 | `dependencies.py` | A supervisor token cannot read another farm's data via any endpoint (integration test) |
| T-014 | Master data CRUD (company/farm/shed/breed/vaccine-master/feed-formula) — owner only | P1 | T-013 | `routers/master.py`, `schemas/master.py` | All fields from `rds_schema.sql` master tables round-trip; supervisor gets 403 on write |
| T-015 | Flock placement + lifecycle endpoints | P1 | T-014 | `routers/flock.py` | Matches Part 8 rules 3–4; shed capacity respected as hard ceiling |
| T-016 | Daily flock snapshot endpoint (the heartbeat record) | P1 | T-015 | `routers/snapshot.py` | All arithmetic checks from Part 12.1 of `architecture.md` enforced server-side with plain-language errors |
| T-017 | Bird movement + approval workflow | P1 | T-015 | `routers/bird_movement.py` | Non-mortality movement stays `pending` until owner approves; live count only updates on approval |
| T-018 | Owner dashboard scaffold + live-data widgets (Part 7 metrics) | P1 | T-016, T-017 | `apps/dashboard/*` | Every widget's data traces to a real endpoint; no hardcoded numbers |
| T-019 | Supervisor app scaffold + offline daily entry + sync queue | P1 | T-016 | `apps/supervisor/*` | Entry works with network disabled, syncs on reconnect, visible sync status |
| T-020 | Vaccine schedule generation + event lifecycle + supervisor reporting | P2 | T-015 | `routers/vaccine.py` | Full lifecycle per `architecture.md` 6.2 implemented; <60s reporting flow |
| T-021 | Vaccine conflict-detection engine | P2 | T-020 | `services/vaccine_conflict.py` | Same-conflict-group overlap within min-gap is caught and surfaced with resolution options |
| T-022 | Feed batch production + dispatch + consumption | P2 | T-015 | `routers/feed.py` | Formula version stamped and immutable on batches; variance flagged at >2% |
| T-023 | Raw material inventory + reorder alerting | P2 | T-022 | `routers/inventory.py` | Days-of-stock calculation matches spec; alert thresholds match `architecture.md` 11.1 |
| T-024 | Egg production entry + HDP calculation | P2 | T-016 | part of `routers/snapshot.py` or `routers/egg.py` | HDP vs. breed curve variance calculated correctly; anomaly thresholds match `architecture.md` 9.2 (in-app only) |
| T-025 | In-app alert center (system_alert) | P2 | T-013 | `routers/alerts.py` | All severities route in-app/native-push only; no WhatsApp/SMS/email field anywhere |
| T-026 | Data export (CSV/Excel, no accounting) | P2 | T-016, T-020, T-022 | `routers/export.py` | Matches `architecture.md` Section 15 datasets exactly |
| T-027 | Intelligence: cross-module anomaly investigation | P3 | T-024, T-025 | `services/intelligence.py` | Production-drop investigation report checks vaccine/feed/mortality/age per `architecture.md` 9.3 |
| T-028 | Nightly pattern recognition | P3 | T-027 | background job | Matches `architecture.md` 12.2 examples; runs as a scheduled job, does not block request-time endpoints |
| T-029 | Shed biosecurity log, supplier performance, water quality log | P3 | Stage 3 tables | new migration + routers | Matches blueprint Part 3.5 |
| T-030 | Production hardening pass (Stage 11) | P3 | most of P1/P2 done | repo-wide | Security review complete, backups configured, CloudWatch alarms live, load-tested at realistic scale |

---

## PART 8 — CONTINUOUS PROGRESS RULE

Do not spend an entire session re-analyzing the repository if the architecture is already sufficiently defined (it is, per Part 0 and the blueprint). The loop is:

**Inspect → Plan small step (one Part 7 task, using the Part 5 template) → Implement → Test → Verify → Update `IMPLEMENTATION_STATUS.md` → Commit-ready state → Move to next unblocked task.**

Avoid endless planning. If you find yourself producing another architecture document instead of code, stop — that phase is over. The goal from here is measurable, tested repository progress, one task at a time.

---

## PART 9 — TESTING STRATEGY

**Backend**
- Unit tests for services (auth, validation logic, conflict detection).
- API tests per router (happy path + validation failure + auth failure).
- Database tests: every `CHECK` constraint and trigger from Part 3 must have a test that proves it rejects bad data.
- Authorization/RLS tests: for every table with an RLS policy, a test proving a supervisor cannot see/write another farm's rows.
- Business-rule tests: every numbered rule in Part 8 of the architecture blueprint needs at least one test.

**Frontend (owner dashboard)**
- Component tests where logic exists (not for pure layout).
- API integration tests against a running (or mocked) backend for each dashboard widget's data path.
- Critical workflow tests: login → view dashboard → drill into a flagged flock → approve a bird movement.

**Supervisor app**
- Offline entry: form submission with network mocked off, verify it queues locally.
- Sync: queued entries actually reach the server once connectivity resumes.
- Retry/conflict handling: a failed sync retries; a last-write-wins conflict resolves without data loss of the winning write.

Every P0/P1 task in Part 7 is not "done" until its tests exist and pass — see Part 11.

---

## PART 10 — DOCUMENTATION TO MAINTAIN

Keep a small, authoritative set — do not create new markdown files per feature. Maintain:

- `architecture.md`, `ON_GROUND_OPERATIONS.md` — update only if a genuine architecture/domain change is approved (Part 6 protocol), not for routine implementation notes.
- `DATABASE.md` (create once Stage 1 begins; consolidates schema + RLS + indexes + invariant notes, replacing the drift risk between `rds_schema.sql` and the models).
- `API.md` — keep current with actually-implemented endpoints; remove speculative endpoints not yet built or mark them clearly as planned.
- `SETUP.md` / `BACKEND_SETUP.md` — development setup, keep current.
- `IMPLEMENTATION_STATUS.md` — see Part 11, updated after every session.
- A running decision log **inside** `IMPLEMENTATION_STATUS.md` (don't create a separate `DECISIONS.md`) for any assumption made under ambiguity or any proposed architecture change per Part 6.
- Changelog: use git commit history as the changelog; do not maintain a parallel hand-written `CHANGELOG.md` unless a release process later requires it.

Do not resurrect `DEMO.md`, `QUICK_REFERENCE.md`, `VERIFICATION_CHECKLIST.md`, `DELIVERY_SUMMARY.md`, `IMPLEMENTATION_SUMMARY.md`, or `DOCUMENTATION_INDEX.md` as active documents — per the architecture blueprint's Part 11, fold anything still useful from them into the above and let them retire.

---

## PART 11 — `IMPLEMENTATION_STATUS.md` (progress tracking file)

Create this file (if absent) as the first action of Stage 0. Structure:

```markdown
# Implementation Status

**Last updated:** <date> by <session/agent>

## Current phase
Stage <N> — <name>

## Current milestone
<Task ID + name>, using the Part 5 template

## Completed tasks
- T-00X — <one line, date, files touched>

## In progress
- T-00Y — <milestone block per Part 5, with current step marked>

## Blocked tasks
- T-00Z — blocked on <dependency>, since <date>

## Known issues
- <bug/defect, file, severity, workaround if any>

## Architecture decisions log
- <date> — <Current decision → Problem → Proposed change → Consequences> — <approved/pending>

## Assumptions made under ambiguity
- <date> — <what was ambiguous> — <assumption chosen> — <why>

## Next recommended task
T-00N — <one line>, see NEXT_TASK.md
```

Update this file after every meaningful unit of work — not just at session end. A new agent session must be able to read this file alone and know exactly where to resume.

---

## PART 12 — SESSION HANDOFF FORMAT

At the end of every working session, report in this shape (and mirror it into `IMPLEMENTATION_STATUS.md`):

```
### Completed
<what was actually implemented — working code, not intentions>

### Files changed
<exact paths>

### Tests
<what was added, what passed, what failed and why>

### Architecture decisions
<any raised per Part 6, and their status>

### Known issues
<anything left unresolved, with enough detail to resume>

### Next task
<single highest-priority next action, matching Part 7's backlog and NEXT_TASK.md>
```

Do not claim a task complete unless every item in its acceptance criteria (Part 5 template) is actually true and verified by running the stated command.

---

## PART 13 — DO NOT FAKE PROGRESS

Explicitly, none of the following count as implementation, ever, regardless of how they look in a diff or a status update:

- Creating empty files or stub modules.
- Defining types/schemas with no behavior wired to them.
- Adding API routes that don't persist to or read from the real database.
- Dashboard cards or charts bound to hardcoded/sample numbers.
- Placeholder functions (`pass`, `# TODO implement`, `raise NotImplementedError`) reported as done.
- Marking a doc as "✅ Complete" for something that isn't runnable and tested.

`IMPLEMENTATION_STATUS.md` must reflect only actually-working, tested functionality as "completed." Everything else stays in "in progress" or "blocked" until it genuinely passes its acceptance criteria.

---

## PART 14 — INITIAL EXECUTION PLAN (first tasks, in order)

Execute in this exact order. Each is a single Part-7 task; use the Part 5 template before starting each one.

1. **T-001** — Fix the `Decimal` import bug (see `NEXT_TASK.md` — this is today's task).
2. **T-002** — Resolve PK naming to domain-specific IDs across all models.
3. **T-003** — Fix `hdp_percent` type and the mutable-default bug.
4. **T-004** — Wire all model classes into `models/__init__.py`.
5. **T-005** — Generate the first Alembic migration; verify upgrade/downgrade both work cleanly against a throwaway local DB.
6. **T-006** — Bird-count integrity trigger + constraints.
7. **T-007** — Flock-status-active check before snapshot insert.
8. **T-008** — 24h placement lock.
9. **T-009** — Decide and implement the docker-compose Alembic-vs-SQL-bootstrap path; update `DATABASE.md`.
10. **T-010** — Database/RLS test suite covering everything above.
11. **T-011** — Owner auth.
12. **T-012** — Supervisor auth.
13. **T-013** — Real RLS-context dependency, replacing the `main.py` placeholder.
14. **T-014** — Master data CRUD.
15. **T-015** — Flock placement + lifecycle.
16. **T-016** — Daily flock snapshot endpoint.
17. **T-017** — Bird movement + approval workflow.
18. **T-018** — Owner dashboard scaffold with the first two or three live widgets (start with "Total live birds" and "Vaccine compliance" — the highest-priority signals per the stated operational hierarchy: vaccine accuracy → egg production → feed efficiency → mortality).
19. **T-019** — Supervisor app scaffold with PIN login and the daily-entry form wired to T-016's endpoint.
20. **T-010 revisited** — full regression pass once 1–19 are done, before moving into Stage 8 (vaccine module depth) and beyond.

Do not skip ahead to Stage 6/7 (dashboards) before Stage 1–5's foundation is real and tested — a dashboard over an unenforced database is exactly the kind of "looks done, isn't" progress this guide exists to prevent.
