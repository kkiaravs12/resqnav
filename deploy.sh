#!/bin/bash

# ResQNav Production Deployment Script
# This script automates the entire deployment process

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  ResQNav Production Deployment Script"
echo "═══════════════════════════════════════════════════════════════"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Verify Prerequisites
echo -e "\n${YELLOW}[STEP 1]${NC} Verifying prerequisites..."

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker installed${NC}"

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose installed${NC}"

# Step 2: Check Environment File
echo -e "\n${YELLOW}[STEP 2]${NC} Checking environment configuration..."

if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠ .env file not found, copying from .env.production${NC}"
    cp .env.production .env
    echo -e "${RED}Please edit .env with your production credentials:${NC}"
    echo "  - SENDGRID_API_KEY"
    echo "  - MSG91_AUTH_KEY"
    echo "  - SENTRY_DSN"
    echo "  - AWS credentials"
    echo "  - Database/Redis passwords"
    echo ""
    read -p "Have you updated .env? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo -e "${GREEN}✓ .env configured${NC}"

# Step 3: Validate Docker Compose Configuration
echo -e "\n${YELLOW}[STEP 3]${NC} Validating Docker Compose configuration..."

if docker-compose config > /dev/null; then
    echo -e "${GREEN}✓ Docker Compose configuration valid${NC}"
else
    echo -e "${RED}✗ Docker Compose configuration invalid${NC}"
    exit 1
fi

# Step 4: Build Docker Images
echo -e "\n${YELLOW}[STEP 4]${NC} Building Docker images..."

docker-compose build --no-cache

echo -e "${GREEN}✓ Docker images built${NC}"

# Step 5: Start Services
echo -e "\n${YELLOW}[STEP 5]${NC} Starting services (PostgreSQL, Redis, Django, Celery)..."

docker-compose up -d

# Wait for services to be healthy
echo -e "\n${YELLOW}[STEP 6]${NC} Waiting for services to be healthy..."

for i in {1..30}; do
    if docker-compose ps | grep -q "backend.*healthy"; then
        echo -e "${GREEN}✓ Services are healthy${NC}"
        break
    fi
    echo "  Checking... ($i/30)"
    sleep 2
done

# Step 7: Run Migrations
echo -e "\n${YELLOW}[STEP 7]${NC} Running database migrations..."

docker-compose exec -T backend python manage.py migrate --noinput

echo -e "${GREEN}✓ Migrations completed${NC}"

# Step 8: Collect Static Files
echo -e "\n${YELLOW}[STEP 8]${NC} Collecting static files..."

docker-compose exec -T backend python manage.py collectstatic --noinput

echo -e "${GREEN}✓ Static files collected${NC}"

# Step 9: Create Superuser (Optional)
echo -e "\n${YELLOW}[STEP 9]${NC} Creating superuser (optional)..."
echo "If you want to create a superuser now, run:"
echo "  docker-compose exec backend python manage.py createsuperuser"

# Step 10: Verify Deployment
echo -e "\n${YELLOW}[STEP 10]${NC} Verifying deployment..."

echo -e "\n${GREEN}✓ Service Status:${NC}"
docker-compose ps

# Wait a moment for services to fully start
sleep 3

# Check health endpoint
if curl -s http://localhost:8000/api/schema/ > /dev/null; then
    echo -e "${GREEN}✓ API health check passed${NC}"
else
    echo -e "${YELLOW}⚠ API health check failed (services may still be starting)${NC}"
fi

# Step 11: Display Summary
echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Deployment Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Access Swagger UI: http://localhost:8000/api/docs/"
echo "2. Create superuser: docker-compose exec backend python manage.py createsuperuser"
echo "3. Test endpoints: curl http://localhost:8000/api/schema/"
echo "4. View logs: docker-compose logs -f backend"

echo -e "\n${YELLOW}Useful Commands:${NC}"
echo "  Stop services:    docker-compose down"
echo "  View logs:        docker-compose logs -f backend"
echo "  SSH into backend: docker-compose exec backend bash"
echo "  Database shell:   docker-compose exec backend python manage.py dbshell"
echo "  Django shell:     docker-compose exec backend python manage.py shell"
echo "  Run tests:        docker-compose exec backend pytest tests/ -v"

echo -e "\n${YELLOW}Database Backup:${NC}"
echo "  docker-compose exec postgres pg_dump -U resqnav resqnav > backup.sql"

echo -e "\n${YELLOW}Database Restore:${NC}"
echo "  docker-compose exec -T postgres psql -U resqnav resqnav < backup.sql"

echo ""
