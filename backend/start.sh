#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting ResQNav Backend..."

# Run migrations
echo "📦 Running database migrations..."
python manage.py migrate --noinput

# Collect static files
echo "📁 Collecting static files..."
python manage.py collectstatic --noinput --clear

echo "✅ Setup complete! Starting Gunicorn..."

# Start Gunicorn
exec gunicorn --bind 0.0.0.0:8000 \
    --workers 4 \
    --worker-class sync \
    --timeout 120 \
    --access-logfile - \
    --error-logfile - \
    config.wsgi:application
