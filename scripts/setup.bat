@echo off
REM Local Development Quick Start (Windows)
REM Automates setup. Only manual steps: AWS keys, Cognito

setlocal enabledelayedexpansion

echo ==========================================
echo Poultry Farm Command Center - Dev Setup
echo ==========================================
echo.

REM Check Docker
echo Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker not installed
    exit /b 1
)
echo ^> Docker installed
echo.

REM Check Python
echo Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not installed
    exit /b 1
)
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo ^> Python %PYTHON_VERSION% installed
echo.

REM Check Node
echo Checking Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js not installed
    exit /b 1
)
for /f %%i in ('node --version') do set NODE_VERSION=%%i
echo ^> Node %NODE_VERSION% installed
echo.

echo Starting Docker Compose services...
docker-compose up -d

echo Waiting for services to be healthy...
timeout /t 10 /nobreak

echo.
echo Setting up Python environment...
cd apps\api

if not exist "venv\" (
    echo Creating virtual environment...
    python -m venv venv
)

call venv\Scripts\activate.bat

echo Installing Python packages...
pip install -q --upgrade pip setuptools wheel
pip install -q -r requirements.txt
pip install -q alembic

cd ..\..

echo.
echo Setting up Node packages...

echo Installing root packages...
call npm install -q

echo Installing dashboard packages...
cd apps\dashboard
call npm install -q
cd ..\..

echo Installing supervisor packages...
cd apps\supervisor
call npm install -q
cd ..\..

echo Installing shared-types packages...
cd packages\shared-types
call npm install -q
cd ..\..

echo.
echo Configuring environment...

if not exist "apps\api\.env" (
    echo Creating .env from template...
    copy apps\api\.env.development apps\api\.env
    echo.
    echo WARNING: Edit apps\api\.env with your AWS keys and Cognito IDs
)

echo.
echo Running database migrations...
cd apps\api

call venv\Scripts\activate.bat

echo Applying migrations...
alembic upgrade head >nul 2>&1

cd ..\..

echo.
echo ==========================================
echo Setup Complete!
echo ==========================================
echo.
echo MANUAL STEPS REQUIRED:
echo 1. Edit apps\api\.env and add:
echo    - AWS_ACCESS_KEY_ID
echo    - AWS_SECRET_ACCESS_KEY
echo    - COGNITO_USER_POOL_ID
echo    - COGNITO_CLIENT_ID
echo.
echo Start development servers:
echo   npm run dev
echo.
echo This will start:
echo   * FastAPI backend:     http://localhost:8000
echo   * React dashboard:     http://localhost:5173
echo   * React Native (web):  http://localhost:8081
echo.
echo Stop services:
echo   docker-compose down
echo.
