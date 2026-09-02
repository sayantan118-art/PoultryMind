@echo off
REM Backend startup script for local development on Windows

setlocal enabledelayedexpansion

REM Colors don't work well in batch, so we'll use text
echo.
echo ========================================
echo 🚀 Poultry Farm Backend - Startup Script
echo ========================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed or not in PATH
    exit /b 1
)

REM Get the directory of this script
for %%i in ("%~dp0..") do set "PROJECT_ROOT=%%~fi"

echo 📍 Project Root: %PROJECT_ROOT%
echo.

REM Step 1: Copy environment file if it doesn't exist
if not exist "%PROJECT_ROOT%\apps\api\.env" (
    echo 📝 Creating .env from template...
    copy "%PROJECT_ROOT%\apps\api\.env.development" "%PROJECT_ROOT%\apps\api\.env"
    echo ✅ Created apps/api/.env
) else (
    echo ✅ apps/api/.env already exists
)

REM Step 2: Build and start containers
echo.
echo 🐳 Starting Docker Compose services...
cd /d "%PROJECT_ROOT%"
docker-compose build --no-cache api
docker-compose up -d

REM Step 3: Wait for PostgreSQL to be ready
echo.
echo ⏳ Waiting for PostgreSQL to be healthy...
set "max_attempts=30"
set "attempt=0"

:wait_postgres
if %attempt% gtr %max_attempts% (
    echo ❌ PostgreSQL failed to start
    docker-compose logs postgres
    exit /b 1
)

docker-compose exec -T postgres pg_isready -U poultry_user >nul 2>&1
if errorlevel 1 (
    set /a attempt+=1
    timeout /t 1 /nobreak >nul
    goto wait_postgres
)
echo ✅ PostgreSQL is healthy

REM Step 4: Verify Redis
docker-compose exec -T redis redis-cli ping >nul 2>&1
if errorlevel 1 (
    echo ❌ Redis failed to respond
    docker-compose logs redis
    exit /b 1
)
echo ✅ Redis is healthy

REM Step 5: Verify FastAPI
echo.
echo ⏳ Waiting for FastAPI to be healthy...
set "attempt=0"

:wait_fastapi
if %attempt% gtr %max_attempts% (
    echo ❌ FastAPI failed to start
    docker-compose logs api
    exit /b 1
)

curl -s http://localhost:8000/api/v1/health >nul 2>&1
if errorlevel 1 (
    set /a attempt+=1
    timeout /t 1 /nobreak >nul
    goto wait_fastapi
)
echo ✅ FastAPI is healthy

REM Step 6: Display summary
echo.
echo ✅ All services are running!
echo.
echo 📊 Service URLs:
echo    🔵 FastAPI Backend:     http://localhost:8000
echo    📚 API Docs (Swagger):  http://localhost:8000/docs
echo    🗄️  PostgreSQL:          localhost:5432
echo    🚀 Redis:                localhost:6379
echo.
echo 💡 Next Steps:
echo    1. Generate JWT token: python -c "import secrets; print(secrets.token_urlsafe(32))"
echo    2. Update JWT_SECRET_KEY in apps/api/.env
echo    3. Test health endpoint: curl http://localhost:8000/api/v1/health
echo    4. Visit Swagger UI: http://localhost:8000/docs
echo.
echo 📖 Documentation:
echo    • Backend Setup: Read BACKEND_SETUP.md
echo    • API Endpoints: Read API.md
echo    • Deployment: Read DEPLOYMENT.md
echo.
echo 🛑 To stop services:
echo    docker-compose down
echo.
