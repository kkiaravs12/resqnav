@echo off
REM ResQNav Production Deployment Script for Windows

setlocal enabledelayedexpansion

echo.
echo ===============================================================
echo   ResQNav Production Deployment Script
echo ===============================================================
echo.

REM Step 1: Check Docker
echo [STEP 1] Checking Docker installation...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or not in PATH
    exit /b 1
)
echo OK: Docker is installed

REM Step 2: Check Docker Compose
echo [STEP 2] Checking Docker Compose installation...
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker Compose is not installed or not in PATH
    exit /b 1
)
echo OK: Docker Compose is installed

REM Step 3: Check .env file
echo [STEP 3] Checking environment configuration...
if not exist .env (
    echo WARNING: .env file not found
    echo Copying from .env.production...
    copy .env.production .env
    echo.
    echo IMPORTANT: Please edit .env with your production credentials:
    echo   - SENDGRID_API_KEY
    echo   - MSG91_AUTH_KEY
    echo   - SENTRY_DSN
    echo   - AWS credentials
    echo   - Database/Redis passwords
    echo.
    pause
)
echo OK: .env file exists

REM Step 4: Validate Docker Compose
echo [STEP 4] Validating Docker Compose configuration...
docker-compose config >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker Compose configuration is invalid
    exit /b 1
)
echo OK: Docker Compose configuration is valid

REM Step 5: Build Docker images
echo [STEP 5] Building Docker images...
docker-compose build --no-cache
if errorlevel 1 (
    echo ERROR: Failed to build Docker images
    exit /b 1
)
echo OK: Docker images built successfully

REM Step 6: Start services
echo [STEP 6] Starting services (PostgreSQL, Redis, Django, Celery)...
docker-compose up -d
if errorlevel 1 (
    echo ERROR: Failed to start services
    exit /b 1
)
echo OK: Services started

REM Step 7: Wait for services
echo [STEP 7] Waiting for services to be ready (this may take a few minutes)...
timeout /t 15 /nobreak

REM Step 8: Run migrations
echo [STEP 8] Running database migrations...
docker-compose exec -T backend python manage.py migrate --noinput
if errorlevel 1 (
    echo ERROR: Failed to run migrations
    exit /b 1
)
echo OK: Migrations completed

REM Step 9: Collect static files
echo [STEP 9] Collecting static files...
docker-compose exec -T backend python manage.py collectstatic --noinput
if errorlevel 1 (
    echo WARNING: Failed to collect static files (may not be critical)
)
echo OK: Static files collected

REM Step 10: Display status
echo [STEP 10] Checking service status...
echo.
docker-compose ps
echo.

REM Step 11: Display summary
echo.
echo ===============================================================
echo   DEPLOYMENT COMPLETE!
echo ===============================================================
echo.
echo NEXT STEPS:
echo   1. Access Swagger UI: http://localhost:8000/api/docs/
echo   2. Create superuser:
echo      docker-compose exec backend python manage.py createsuperuser
echo   3. Test API endpoint:
echo      curl http://localhost:8000/api/schema/
echo   4. View logs:
echo      docker-compose logs -f backend
echo.
echo USEFUL COMMANDS:
echo   Stop services:        docker-compose down
echo   View logs:            docker-compose logs -f backend
echo   Access backend shell: docker-compose exec backend bash
echo   Django shell:         docker-compose exec backend python manage.py shell
echo   Run tests:            docker-compose exec backend pytest tests/ -v
echo.
echo DATABASE BACKUP:
echo   docker-compose exec postgres pg_dump -U resqnav resqnav ^> backup.sql
echo.
echo DATABASE RESTORE:
echo   docker-compose exec -T postgres psql -U resqnav resqnav ^< backup.sql
echo.
echo ===============================================================
echo.

pause
