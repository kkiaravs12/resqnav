# ResQNav Backend Deployment Guide

**Production Deployment Instructions for Django Backend**

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Environment Setup](#environment-setup)
3. [Database Configuration](#database-configuration)
4. [Email Configuration](#email-configuration)
5. [SMS Configuration](#sms-configuration)
6. [Security Setup](#security-setup)
7. [Deployment](#deployment)
8. [Monitoring & Logging](#monitoring--logging)

---

## System Requirements

### Minimum Requirements

- **Python**: 3.8+
- **OS**: Ubuntu 20.04 LTS (or equivalent)
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 20GB minimum (depends on database size)

### Recommended Stack

```
- Python 3.11
- Django 6.1
- PostgreSQL 14+
- Redis 7+ (for caching and sessions)
- Nginx 1.24+
- Gunicorn 20+
- Supervisor (for process management)
```

---

## Environment Setup

### 1. Clone and Install Dependencies

```bash
git clone <repository-url> /opt/resqnav
cd /opt/resqnav/backend

# Create virtual environment
python3.11 -m venv .venv
source .venv/bin/activate

# Install requirements
pip install -r requirements.txt
pip install gunicorn psycopg2-binary redis
```

### 2. Create .env File

```bash
cp .env.example .env
nano .env
```

**Production .env Template:**

```env
# ─── Django Settings ────────────────────────────────────
DEBUG=False
SECRET_KEY=your-secret-key-here-use-strong-random-string
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,api.yourdomain.com

# ─── Security ────────────────────────────────────────
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True

# ─── Database ────────────────────────────────────────
DATABASE_ENGINE=django.db.backends.postgresql
DATABASE_NAME=resqnav_prod
DATABASE_USER=resqnav_user
DATABASE_PASSWORD=secure-password-here
DATABASE_HOST=db.yourdomain.com
DATABASE_PORT=5432

# ─── Email Configuration ──────────────────────────────
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-specific-password
DEFAULT_FROM_EMAIL=noreply@resqnav.com

# ─── SMS Configuration ────────────────────────────────
MSG91_AUTH_KEY=your-msg91-auth-key
MSG91_SENDER_ID=RESQNV
MSG91_ROUTE=4
MSG91_TEMPLATE_ID=your-template-id

# Alternative: Twilio
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=+1234567890

# ─── Frontend Configuration ──────────────────────────
FRONTEND_URL=https://yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# ─── Redis (Optional but Recommended) ─────────────────
REDIS_HOST=redis.yourdomain.com
REDIS_PORT=6379
REDIS_PASSWORD=secure-redis-password

# ─── Logging ────────────────────────────────────────
LOG_LEVEL=INFO
SENTRY_DSN=https://your-sentry-dsn
```

---

## Database Configuration

### Using PostgreSQL

#### 1. Create Database and User

```bash
sudo -u postgres psql

CREATE DATABASE resqnav_prod;
CREATE USER resqnav_user WITH PASSWORD 'secure-password-here';
ALTER ROLE resqnav_user SET client_encoding TO 'utf8';
ALTER ROLE resqnav_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE resqnav_user SET default_transaction_deferrable TO on;
ALTER ROLE resqnav_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE resqnav_prod TO resqnav_user;
\q
```

#### 2. Run Migrations

```bash
cd /opt/resqnav/backend
python manage.py migrate
```

#### 3. Create Superuser

```bash
python manage.py createsuperuser
# Enter your admin credentials
```

#### 4. Collect Static Files

```bash
python manage.py collectstatic --noinput
```

---

## Email Configuration

### Gmail SMTP Setup

1. Enable 2-Step Verification on your Google account
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use the 16-character password in `EMAIL_HOST_PASSWORD`

### Alternative: SendGrid

```env
EMAIL_BACKEND=sendgrid_backend.SendgridBackend
SENDGRID_API_KEY=SG.your-api-key
```

### Alternative: AWS SES

```env
EMAIL_BACKEND=django_ses.SESBackend
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_SES_REGION_NAME=us-east-1
AWS_SES_REGION_ENDPOINT=email.us-east-1.amazonaws.com
```

---

## SMS Configuration

### MSG91 Setup (Recommended for India)

1. Sign up at https://msg91.com/
2. Go to API section and get your Auth Key
3. Create a template for emergency alerts
4. Add to `.env`:
   ```env
   MSG91_AUTH_KEY=your-auth-key
   MSG91_SENDER_ID=RESQNV
   MSG91_ROUTE=4
   MSG91_TEMPLATE_ID=your-template-id
   ```

### Twilio Setup (International)

1. Sign up at https://www.twilio.com/
2. Get your Account SID and Auth Token
3. Verify sender phone number
4. Add to `.env`:
   ```env
   TWILIO_ACCOUNT_SID=your-sid
   TWILIO_AUTH_TOKEN=your-token
   TWILIO_PHONE_NUMBER=+1234567890
   ```

---

## Security Setup

### 1. Generate Secret Key

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### 2. SSL Certificate

Using Let's Encrypt:

```bash
sudo apt-get install certbot python3-certbot-nginx

sudo certbot certonly --standalone -d yourdomain.com -d api.yourdomain.com

# Auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

### 3. Firewall Configuration

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

### 4. Nginx Configuration

Create `/etc/nginx/sites-available/resqnav`:

```nginx
upstream resqnav_app {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name yourdomain.com api.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    client_max_body_size 20M;

    location /static/ {
        alias /opt/resqnav/backend/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /opt/resqnav/backend/media/;
        expires 7d;
    }

    location / {
        proxy_pass http://resqnav_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/resqnav /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## Deployment

### 1. Create Gunicorn Service

Create `/etc/systemd/system/resqnav.service`:

```ini
[Unit]
Description=ResQNav Gunicorn Application Server
After=network.target

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/opt/resqnav/backend
Environment="PATH=/opt/resqnav/backend/.venv/bin"
ExecStart=/opt/resqnav/backend/.venv/bin/gunicorn \
    --workers 4 \
    --worker-class sync \
    --worker-tmp-dir /dev/shm \
    --bind 127.0.0.1:8000 \
    --timeout 60 \
    --access-logfile /var/log/resqnav/access.log \
    --error-logfile /var/log/resqnav/error.log \
    config.wsgi:application

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo mkdir -p /var/log/resqnav
sudo chown www-data:www-data /var/log/resqnav
sudo chmod 755 /var/log/resqnav

sudo systemctl daemon-reload
sudo systemctl enable resqnav
sudo systemctl start resqnav
```

### 2. Database Backups

Create `/opt/backup-db.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/opt/backups/db"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/resqnav_db_$DATE.sql.gz"

mkdir -p $BACKUP_DIR

PGPASSWORD=$DATABASE_PASSWORD pg_dump \
    -h $DATABASE_HOST \
    -U $DATABASE_USER \
    -d $DATABASE_NAME | gzip > $BACKUP_FILE

# Keep only last 30 days of backups
find $BACKUP_DIR -name "resqnav_db_*.sql.gz" -mtime +30 -delete

echo "Database backed up to $BACKUP_FILE"
```

Setup cron job:

```bash
chmod +x /opt/backup-db.sh
# Add to crontab
0 2 * * * /opt/backup-db.sh
```

---

## Monitoring & Logging

### 1. Sentry Integration (Error Tracking)

```bash
pip install sentry-sdk

# Add to settings.py:
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

sentry_sdk.init(
    dsn=os.getenv('SENTRY_DSN'),
    integrations=[DjangoIntegration()],
    traces_sample_rate=0.1,
    send_default_pii=False
)
```

### 2. Log Rotation

Create `/etc/logrotate.d/resqnav`:

```
/var/log/resqnav/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        systemctl reload resqnav
    endscript
}
```

### 3. Health Check Endpoint

Add to `urls.py`:

```python
path('health/', lambda request: JsonResponse({'status': 'ok'}), name='health')
```

Monitor with:

```bash
curl https://api.yourdomain.com/health/
```

### 4. Performance Monitoring

Use APM tools like:
- New Relic
- Datadog
- Elastic APM

---

## Post-Deployment Checklist

- [ ] SSL certificate configured and auto-renewal enabled
- [ ] Database backup scheduled
- [ ] Email sending tested
- [ ] SMS service tested with real numbers
- [ ] Admin panel accessible at `/admin/`
- [ ] Health check endpoint working
- [ ] Logging configured and monitored
- [ ] Rate limiting verified
- [ ] CORS properly configured
- [ ] Secret key in environment (not in code)
- [ ] DEBUG set to False
- [ ] Allowed hosts configured
- [ ] Static files collected
- [ ] Database migrated
- [ ] Superuser created
- [ ] Firewall configured
- [ ] Backups automated

---

## Troubleshooting

### 502 Bad Gateway

```bash
# Check Gunicorn status
sudo systemctl status resqnav

# View logs
tail -f /var/log/resqnav/error.log

# Restart service
sudo systemctl restart resqnav
```

### Database Connection Issues

```bash
# Test connection
psql -h $DATABASE_HOST -U $DATABASE_USER -d $DATABASE_NAME

# Check Django connection
python manage.py dbshell
```

### Email Not Sending

```bash
# Test email configuration
python manage.py shell
>>> from django.core.mail import send_mail
>>> send_mail('Test', 'Message', 'from@example.com', ['to@example.com'])
```

### SMS Delivery Issues

```bash
# Check API credentials in .env
# Verify sender ID is registered
# Check account balance/quota
# Review message templates if using MSG91
```

---

## Performance Tips

1. **Enable Redis Caching**: Improves response times significantly
2. **Use CDN**: Serve static files through CloudFront or similar
3. **Enable Gzip Compression**: In Nginx configuration
4. **Use PostgreSQL Connection Pooling**: PgBouncer
5. **Implement Database Indexes**: On frequently queried fields
6. **Monitor Query Performance**: Use Django Debug Toolbar in development
7. **Optimize Images**: Use thumbnails for profiles
8. **Enable HSTS**: Already configured in production

---

## Support & Documentation

- Django Docs: https://docs.djangoproject.com/
- DRF Docs: https://www.django-rest-framework.org/
- Nginx Docs: https://nginx.org/en/docs/
- Gunicorn Docs: https://gunicorn.org/

---

**Last Updated:** September 25, 2026
**Version:** 1.0.0
