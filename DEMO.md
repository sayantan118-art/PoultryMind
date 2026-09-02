# Local Demo Guide

This repository is intentionally set up for local development only. It does not require AWS, Cognito, or any cloud deployment credentials to run the demo flow.

## 1. Prepare the local environment

From the repository root:

```bash
copy .env.example .env
```

If you are using PowerShell instead of Command Prompt:

```powershell
Copy-Item .env.example .env
```

The default values in `.env.example` are valid for the local Docker stack.

## 2. Start the local stack

```bash
docker compose up --build -d postgres redis api
```

This starts:
- PostgreSQL on `localhost:5432`
- Redis on `localhost:6379`
- the FastAPI app on `http://localhost:8000`

The API container waits until Postgres and Redis are healthy, then seeds demo master data automatically.

## 3. Verify the app is healthy

```bash
curl http://localhost:8000/api/v1/health
```

Expect a JSON response like:

```json
{
  "status": "healthy",
  "version": "1.0.0",
  "environment": "development"
}
```

## 4. Verify the demo data is loaded

```bash
docker exec -it poultry_db_dev psql -U poultry_user -d poultry_dev -c "SELECT COUNT(*) FROM company;"
```

The result should be at least `1`.

## 5. Stop the stack when done

```bash
docker compose down -v
```

## Notes

- No AWS deployment is required for this flow.
- The app is configured to use local development credentials by default.
- If you want to reset the local database, run the stop command above and start the stack again.
