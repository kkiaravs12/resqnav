# ResQNav - Production Setup Guide

## 🚀 Production Deployment Checklist

### 1. SMS Service Setup (MSG91 - Recommended for India)

1. **Sign up for MSG91**
   - Go to https://msg91.com/
   - Create an account
   - Verify your phone number and email

2. **Get Your API Credentials**
   - Go to Dashboard → API Keys
   - Copy your AUTH KEY
   - Note your SENDER ID (default: RESQNV)

3. **Configure Backend**
   - Copy `backend/.env.example` to `backend/.env`
   - Add your MSG91 credentials:
   ```
   MSG91_AUTH_KEY=your-msg91-auth-key-here
   MSG91_SENDER_ID=RESQNV
   MSG91_ROUTE=4
   ```

### 2. Install Dependencies

```bash
# Backend
cd backend
pip install -r requirements.txt

# Create logs directory
mkdir logs

# Run migrations
python manage.py migrate

# Seed emergency services data
python manage.py seed_emergency_services

# Create superuser for admin access
python manage.py createsuperuser
```

### 3. Test SMS Functionality

```bash
# Start Django server
python manage.py runserver

# Test SMS by:
# 1. Register a user
# 2. Add emergency contacts with REAL phone numbers (+91XXXXXXXXXX)
# 3. Trigger SOS button
# 4. Check if SMS is received
```

### 4. Production Environment Variables

Create `backend/.env` with:

```env
# Django Settings
SECRET_KEY=generate-a-strong-random-secret-key-here
DEBUG=False
ALLOWED_HOSTS=your-domain.com,www.your-domain.com

# MSG91 SMS
MSG91_AUTH_KEY=your-msg91-auth-key
MSG91_SENDER_ID=RESQNV
MSG91_ROUTE=4

# Email (Optional - for email notifications)
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-gmail-app-password

# Database (Production - Use PostgreSQL)
DATABASE_URL=postgresql://user:password@localhost:5432/resqnav
```

### 5. Google Maps API Key

1. Go to https://console.cloud.google.com/
2. Create a new project or select existing
3. Enable these APIs:
   - Maps JavaScript API
   - Directions API  
   - Geocoding API
   - Places API

4. Create API Key and restrict it:
   - Application restrictions: HTTP referrers
   - Add your domains

5. Update `web/index.html`:
   ```html
   <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY&libraries=places"></script>
   ```

### 6. Frontend Build

```bash
# Build for production
flutter build web --release --web-renderer canvaskit

# Output will be in build/web/
```

### 7. Testing Real SMS

1. **Add Emergency Contacts**:
   - Use REAL phone numbers with country code
   - Format: +91XXXXXXXXXX (India)
   - Format: +1XXXXXXXXXX (USA/Canada)

2. **Trigger Emergency**:
   - Click SOS button
   - Confirm alert
   - Check if SMS arrives on real phones

3. **Verify SMS Content**:
   - Should include user name
   - Should include emergency message
   - Should include location link
   - Should be immediate (< 30 seconds)

### 8. Backend Deployment Options

#### Option A: Railway/Render (Easy)
1. Connect GitHub repository
2. Add environment variables
3. Deploy automatically

#### Option B: VPS (DigitalOcean/AWS/Azure)
```bash
# Install system dependencies
sudo apt update
sudo apt install python3-pip python3-venv nginx

# Setup application
cd /var/www/resqnav/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install gunicorn

# Configure Gunicorn
gunicorn config.wsgi:application --bind 0.0.0.0:8000

# Setup Nginx reverse proxy
# Setup SSL with Let's Encrypt
```

### 9. Frontend Deployment Options

#### Option A: Firebase Hosting (Recommended)
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
firebase deploy
```

#### Option B: Netlify
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
cd build/web
netlify deploy --prod
```

#### Option C: Vercel
```bash
npm install -g vercel
cd build/web
vercel --prod
```

### 10. Security Checklist

- [x] Change SECRET_KEY in production
- [x] Set DEBUG=False
- [x] Configure ALLOWED_HOSTS
- [x] Use HTTPS only
- [x] Restrict Google Maps API key
- [x] Enable CORS only for your domain
- [x] Use strong passwords
- [x] Enable rate limiting
- [x] Regular backups of database

### 11. Monitoring & Logging

1. **Setup Error Tracking**:
   - Sentry for error monitoring
   - Google Analytics for usage

2. **SMS Delivery Logs**:
   - Check Django admin panel
   - Monitor MSG91 dashboard
   - Set up delivery reports

3. **Application Logs**:
   ```python
   # Check logs
   tail -f backend/logs/resqnav.log
   ```

### 12. Cost Estimates

- **MSG91 SMS**: 
  - ₹0.15 - ₹0.50 per SMS (India)
  - Buy credits in advance
  
- **Google Maps API**:
  - $200 free credit monthly
  - Usually covers small-medium usage

- **Hosting**:
  - Backend: $5-20/month (Railway/Render)
  - Frontend: Free (Firebase/Netlify)

### 13. Support & Troubleshooting

**SMS not sending?**
- Check MSG91 dashboard for delivery reports
- Verify AUTH_KEY is correct
- Ensure phone numbers have country code
- Check backend logs for errors

**Maps not loading?**
- Verify API key is valid
- Check browser console for errors
- Ensure APIs are enabled in Google Cloud

**Database errors?**
- Run migrations: `python manage.py migrate`
- Check database connection in .env

## 📞 Emergency Contact Format

Always use international format:
- India: +91XXXXXXXXXX
- USA: +1XXXXXXXXXX  
- UK: +44XXXXXXXXXX

## 🎨 Theme Customization

Edit `lib/core/theme/app_theme.dart` to customize colors, gradients, and styling.

## 📧 Support

For issues and questions:
- Check documentation
- Review error logs
- Contact MSG91 support for SMS issues
- Contact Google Cloud support for Maps issues

---

**Ready for Production!** 🚀

Once setup is complete, your ResQNav app will send REAL SMS alerts to emergency contacts during actual emergencies.
