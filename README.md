# Poultry Farm Command Center

A poultry operations command center for a multi-farm layer operation, covering farm operations, feed, flock health, vaccines, reporting, and owner oversight.

## Project structure

- `apps/api`: FastAPI backend
- `apps/dashboard`: owner dashboard
- `apps/supervisor`: supervisor mobile app
- `packages/shared-types`: shared TypeScript interfaces
- `infra/aws`: PostgreSQL schema, RLS policies, indexes, deployment assets

## Main docs

- Setup: [SETUP.md](SETUP.md)
- Architecture: [architecture.md](architecture.md)
- API contract: [API.md](API.md)
- Deployment: [DEPLOYMENT.md](DEPLOYMENT.md)
- Operational planning: [PHASE_1_CHECKLIST.md](PHASE_1_CHECKLIST.md)

## Quick start

```bash
# from repo root
cp .env.example .env
# adjust local secrets and URLs in .env

docker-compose up -d
```

Then follow the canonical setup guide in [SETUP.md](SETUP.md).

## Notes

- Local direct Python runs use `localhost` for Postgres and Redis.
- Dockerized API runs use the service hostnames `postgres` and `redis`.
- Secrets must be provided via environment variables; they are not defaulted in code.
- The repo is designed to allow a single-tenant start with a tenant-aware shape for later multi-tenant expansion.
