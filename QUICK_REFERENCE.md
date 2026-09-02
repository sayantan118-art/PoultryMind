# Quick reference

Use this for the most common commands.

## Start the stack

```bash
docker-compose up -d
```

## Health check

```bash
curl http://localhost:8000/api/v1/health
```

## Stop the stack

```bash
docker-compose down
```

## Restart a service

```bash
docker-compose restart api
docker-compose restart postgres
docker-compose restart redis
```

## Database access

```bash
psql postgresql://poultry_user:poultry_dev_pass@localhost:5432/poultry_dev
```

## API docs

- Swagger: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Full setup details

See [SETUP.md](SETUP.md).
