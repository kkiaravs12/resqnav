# ResQNav Production Deployment Guide

## Quick Start (Docker Compose)

```bash
# Clone and setup
git clone <repo>
cd resqnav

# Create .env file
cp .env.production .env
# Edit .env with real credentials (DATABASE_URL, REDIS_URL, API keys, etc.)

# Deploy with Docker Compose
docker-compose up -d

# Create superuser
docker-compose exec backend python manage.py createsuperuser

# Verify deployment
docker-compose ps
curl http://localhost:8000/docs/
```

## Production Deployment (Linux Server)

### 1. Prerequisites
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose postgresql-client redis-tools
sudo usermod -aG docker $USER
```

### 2. SSL/TLS Setup
```bash
# Using Let's Encrypt with Nginx
sudo apt-get install -y nginx certbot python3-certbot-nginx

# Generate certificate
sudo certbot certonly --standalone -d yourdomain.com

# Configure Nginx as reverse proxy (nginx.conf provided)
```

### 3. Environment Variables
Create `.env`:
```
DEBUG=False
SECRET_KEY=<generate-strong-key>
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
DATABASE_URL=postgresql://user:password@db:5432/resqnav
REDIS_URL=redis://:password@redis:6379/0
SENTRY_DSN=<sentry-dsn>
EMAIL_BACKEND=anymail.backends.sendgrid.EmailBackend
EMAIL_HOST_PASSWORD=<sendgrid-api-key>
MSG91_AUTH_KEY=<msg91-key>
AWS_ACCESS_KEY_ID=<aws-key>
AWS_SECRET_ACCESS_KEY=<aws-secret>
ENVIRONMENT=production
```

### 4. Deploy
```bash
docker-compose -f docker-compose.yml up -d

# Verify
docker-compose logs -f backend
```

### 5. Backup Strategy
```bash
# Daily PostgreSQL backups
docker-compose exec db pg_dump -U resqnav resqnav > backup.sql

# Redis persistence enabled in docker-compose.yml
```

## Monitoring

### Logs
```bash
docker-compose logs backend        # Django logs
docker-compose logs celery         # Async tasks
docker-compose logs db             # Database
docker-compose logs redis          # Cache
```

### Sentry Monitoring
- Set `SENTRY_DSN` in `.env` for error tracking
- All errors automatically reported to Sentry dashboard

### Health Checks
- Backend: `GET /api/schema/` → 200 OK
- Database: Connected via Docker Compose health checks
- Redis: Connected via Docker Compose health checks

## Performance Tuning

### Gunicorn Workers
Edit `Dockerfile`:
```
--workers 4          # CPU cores × 2-4
--worker-class sync  # Or use async workers for more concurrency
```

### PostgreSQL Connections
Edit `docker-compose.yml`:
```
POSTGRES_INIT_ARGS: -c max_connections=200
```

### Redis Memory
```bash
docker-compose exec redis redis-cli CONFIG SET maxmemory 1gb
docker-compose exec redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

## Security Checklist

- [x] SSL/TLS enabled (HTTPS)
- [x] Django security settings (DEBUG=False, SECURE_SSL_REDIRECT)
- [x] Rate limiting enabled
- [x] CORS properly configured
- [x] JWT token refresh system
- [x] Password reset tokens
- [x] 2FA backup codes
- [x] Sentry error tracking
- [x] Audit logging
- [x] Database backups

## Troubleshooting

### Backend won't start
```bash
docker-compose logs backend
docker-compose exec backend python manage.py check --deploy
```

### Database connection failed
```bash
docker-compose exec db psql -U resqnav -d resqnav -c "SELECT 1"
```

### Redis connection failed
```bash
docker-compose exec redis redis-cli ping
```

### Migrations failed
```bash
docker-compose exec backend python manage.py migrate --fake-initial
```

## Scaling

For production with high traffic:

1. **Load Balancer**: Use AWS ELB, Nginx load balancer, or similar
2. **Multiple Backends**: Run multiple backend containers behind load balancer
3. **Database**: Use managed PostgreSQL (AWS RDS, Azure Database, etc.)
4. **Cache**: Use managed Redis (AWS ElastiCache, etc.)
5. **Celery**: Separate worker instances for async tasks
6. **Static Files**: Use AWS S3 or CDN for static/media files

## Support

- GitHub Issues: <repo>/issues
- Documentation: /docs/
- API Docs: http://yourdomain.com/docs/ (Swagger UI)

---
Last Updated: 2026-09-27
Production Version: 1.0.0
