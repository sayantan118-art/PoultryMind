Good — that matches what T-001 required, and catching the two stray `Decimal` references in the `Breed` class before declaring it done is exactly the right instinct (grep once isn't enough; re-verify after every fix pass). The extra pass on `flock.py` is fine too as long as it was scoped narrowly — if it touched more than a leftover `Decimal` reference (e.g., the `hdp_percent` type or the mutable-default bug), just make sure `IMPLEMENTATION_STATUS.md` credits that under T-003, not folded silently into T-001, so the backlog stays honest about what's actually been done. If it was just a stray import, ignore this note.

One thing to double check before moving on: the verification you ran used `importlib.import_module` with `sys.path` pointed at `apps/api`, which confirms the four files parse and their *direct* SQLAlchemy type usage is clean — but it doesn't yet build the full model graph through `Base.metadata` (that still fails today because `models/__init__.py` doesn't import these classes, and several `ForeignKey("farm.id")`-style references won't resolve until PKs are renamed). That's expected and is exactly what T-002/T-004 exist to fix — just flagging so nobody mistakes "imports cleanly in isolation" for "full metadata builds," which is a different, later milestone.

Here's **T-002**, ready to hand to the agent as the new `NEXT_TASK.md`:

---

# NEXT_TASK.md

**Task ID:** T-002
**Priority:** P0
**Stage:** 1 (database foundation)

## Objective
Resolve the primary-key naming mismatch. `apps/api/models/base.py`'s `AuditMixin` currently auto-generates a generic `id` column as the primary key for every table. But the design source of truth — `infra/aws/rds_schema.sql` and `packages/shared-types/src/index.ts` — uses domain-specific PK names (`company_id`, `farm_id`, `shed_id`, `breed_id`, `flock_id`, `snapshot_id`, `event_id`, `batch_id`, etc.), and every `ForeignKey(...)` in the models points at `"<table>.id"`, which won't match once this is fixed. Since the SQL schema and shared-types are the more complete, mutually consistent artifacts, models change to match them — not the other way around.

## Files affected
Every file in `apps/api/models/`: `base.py`, `master.py`, `flock.py`, `feed.py`, `health.py`, `intelligence.py`, `inventory.py`, `vaccine.py`.

## Implementation tasks
1. In `base.py`, remove the auto-generated `id` column from `AuditMixin`. Each model now declares its own PK explicitly (don't try to derive it magically from the class/table name — explicit is safer and matches how `rds_schema.sql` names each PK independently, e.g. `event_id` is reused across two different tables with different meanings).
2. For every model class, add its PK column using the exact name from `rds_schema.sql` (e.g. `Company.company_id`, `Farm.farm_id`, `Shed.shed_id`, `Flock.flock_id`, `DailyFlockSnapshot.snapshot_id`, `VaccineEvent.event_id`, `HealthEvent.event_id`, `FeedBatch.batch_id`, etc.) — `UUID(as_uuid=True), primary_key=True, default=uuid.uuid4`.
3. Update every `ForeignKey("<table>.id")` reference across all model files to `ForeignKey("<table>.<table>_id")` matching step 2 (e.g. `ForeignKey("farm.id")` → `ForeignKey("farm.farm_id")`).
4. Update every `relationship(...)` that relies on implicit PK/FK matching — SQLAlchemy usually infers this correctly once the FK column is right, but check any explicit `primaryjoin=` if present (there don't appear to be any yet, but verify).
5. Do not rename any non-PK column, and do not add new tables/columns in this task — that's Stage 1's later tasks (T-004 onward).

## Acceptance criteria
- Every model's primary key column name matches its table's PK name in `rds_schema.sql` exactly.
- No model retains a bare `id` column.
- Every `ForeignKey` string resolves to a real `<table>.<column>` pair once all models are imported together (verified in the next step, since full-graph resolution needs T-004's `__init__.py` fix too — for T-002 alone, acceptance is: no FK string still says `.id`).

## Verification
```bash
grep -rn "primary_key=True" apps/api/models/*.py    # every hit should be a domain-specific column, not "id ="
grep -rn '"\.id"' apps/api/models/*.py               # expect no output (no ForeignKey still pointing at ".id")
grep -rn 'ForeignKey(".*\.id")' apps/api/models/*.py # expect no output
```

## Definition of Done
- [ ] `base.py`'s `AuditMixin` no longer defines `id`.
- [ ] Every model declares its own correctly-named PK.
- [ ] All FK strings updated to match.
- [ ] Both grep checks above return empty.
- [ ] `IMPLEMENTATION_STATUS.md` updated: T-002 → Completed, T-003 → next recommended (fix `hdp_percent` type + mutable `validation_flags` default in `flock.py`, if not already folded into your T-001 bonus pass — check before starting so it isn't done twice).
- [ ] Session handoff written per `DEVELOPMENT_GUIDE.md` Part 12.

## After this task
Proceed to **T-003** (if not already resolved) then **T-004** (wire all model classes into `models/__init__.py`) — that's when you'll get the first real signal on whether the full metadata graph builds cleanly end to end.