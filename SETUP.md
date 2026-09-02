# Setup guide

This is the canonical setup guide for the project.

## Requirements

- Python 3.10+
- Node.js 18+
- Docker + Docker Compose
- Git

## 1) Local environment file

```bash
cp .env.example .env
```

Required values include:

```env
POSTGRES_DB=poultry_dev
POSTGRES_USER=poultry_user
POSTGRES_PASSWORD=change_me_local_dev_password
DATABASE_URL=postgresql://poultry_user:change_me_local_dev_password@localhost:5432/poultry_dev
REDIS_URL=redis://localhost:6379/0
JWT_SECRET_KEY=replace_with_local_dev_secret_min_32_chars
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:8081,http://localhost:3000
```

## 2) Run with Docker

```bash
docker-compose up -d
```

This starts:

- PostgreSQL on `localhost:5432`
- Redis on `localhost:6379`
- FastAPI on `http://localhost:8000`

Check:

```bash
curl http://localhost:8000/api/v1/health
```

## 3) Important networking rule

Local direct Python runs use `localhost` for Postgres and Redis. Dockerized API runs use the service names `postgres` and `redis`.

This is intentional. The Docker compose file should build the internal URL as:

```yaml
DATABASE_URL: postgresql://${POSTGRES_USER:-poultry_user}:${POSTGRES_PASSWORD:-change_me_local_dev_password}@postgres:5432/${POSTGRES_DB:-poultry_dev}
```

Do not use a root `.env` `DATABASE_URL` that points to `localhost` when the app is running in Docker.

## 4) Run the backend directly

```bash
cd apps/api
python -m venv .venv
# Windows
.\.venv\Scripts\activate
# macOS/Linux
# source .venv/bin/activate

pip install -r requirements.txt
uvicorn main:app --reload
```

## 5) Run the dashboard and supervisor app

```bash
cd apps/dashboard
npm install
npm run dev
```

```bash
cd apps/supervisor
npm install
npm start
```

## 6) Troubleshooting

- PostgreSQL connection fails: check whether you are using `localhost` for local Python or `postgres` inside Docker.
- CORS errors: ensure the frontend origin is included in the comma-separated `ALLOWED_ORIGINS` value.
- Missing config: check the root `.env` before running the app.

## 7) Related docs

- [README.md](README.md)
- [architecture.md](architecture.md)
- [API.md](API.md)
- [DEPLOYMENT.md](DEPLOYMENT.md)
- [PHASE_1_CHECKLIST.md](PHASE_1_CHECKLIST.md)
