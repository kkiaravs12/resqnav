# ResQNav Backend - Production Setup Guide

## 🎯 Quick Start

### 1. Install Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### 2. Setup Environment
```bash
# Copy the example .env file
cp .env.example .env

# Edit .env with your actual credentials
# Most important: MSG91_AUTH_KEY
```

### 3. Setup Database
```bash
python manage.py migrate
python manage.py seed_emergency_services
```

### 4. Create Admin User
```bash
python manage.py createsuperuser
# Enter: username, email, password
```

### 5. Run Development Server
```bash
python manage.py runserver
# Server runs on http://127.0.0.1:8000
# Admin at http://127.0.0.1:8000/admin
```

---

## 🔧 Configuration

### MSG91 SMS Setup (For Real SMS Alerts)

1. **Create Account**
   - Go to https://msg91.com/
   - Sign up and verify email + phone

2. **Get API Key**
   - Dashboard → API Keys
   - Copy your AUTH KEY
   - Default SENDER_ID: RESQNAV

3. **Configure Backend**
   ```
   MSG91_AUTH_KEY=your-actual-api-key
   MSG91_SENDER_ID=RESQNAV
   MSG91_ROUTE=4
   ```

4. **Add Credits**
   - Buy SMS credits (₹0.15-0.50 per SMS in India)
   - Test with small amount first

### Test SMS Sending

```python
# Django shell
python manage.py shell

from api.services import SMSService

# Test SMS
result = SMSService.send_emergency_alert(
    phone_number="+919876543210",  # Replace with real number
    message="Test emergency alert from ResQNav",
    user_name="Test User",
    location="Test Location"
)

print(result)
# Should show: {'success': True, 'provider': 'msg91', ...}
```

---

## 📱 Emergency Alert Workflow

### 1. User Saves Emergency Contact
```
User Profile → Add Emergency Contact
- Name: Mom
- Phone: +919876543210 (MUST have country code)
- Relationship: Family
- Set as Primary
```

### 2. User Triggers SOS
```
- Click SOS Button (red button)
- Confirm alert
- System gets user location
- SMS sent to ALL emergency contacts
```

### 3. SMS Message Received
```
Format:
🚨 EMERGENCY: John Doe needs help!
Emergency alert triggered from ResQNav.
📍 Location: https://www.google.com/maps?q=19.1234,72.5678
```

---

## 🗄️ Database Tables

### Emergency Services (70 services seeded)
- **Hospital**: 24 services
- **Police**: 12 services
- **Fire Station**: 8 services
- **Ambulance**: 10 services
- **Pharmacy**: 11 services
- **Plumber**: 2 services
- **Electrician**: 1 service
- **Mechanic**: 1 service
- **Locksmith**: 1 service

### Emergency Alerts
- Stores all SOS alerts triggered
- Contains: alert_type, status, user_id, location, timestamp

### Emergency Notifications
- Tracks each SMS/Email sent
- Status: pending, sent, failed, delivered
- Contains: phone number, message, timestamp

---

## 🔐 API Endpoints

### Authentication
```
POST /api/auth/register/
{
    "full_name": "John Doe",
    "email": "john@example.com",
    "password": "securepass123"
}

POST /api/auth/login/
{
    "username": "john@example.com",
    "password": "securepass123"
}
```

### Emergency Services
```
GET /api/emergency-services/
GET /api/emergency-services/?category=Hospital
GET /api/emergency-services/?latitude=19.1&longitude=72.8&radius=5

Returns: List of services with distance_km calculated
```

### Emergency Contacts
```
GET /api/emergency-contacts/
POST /api/emergency-contacts/
{
    "name": "Mom",
    "phone": "+919876543210",
    "relationship": "Family",
    "is_primary": true
}
```

### Emergency Alerts (MAIN)
```
POST /api/emergency-alert/
{
    "alert_type": "sos",
    "message": "Emergency alert triggered",
    "latitude": 19.1234,
    "longitude": 72.5678,
    "address": "Location name"
}

Returns: {
    "alert": {...},
    "notifications_sent": 2,
    "notifications_failed": 0,
    "message": "Emergency alert sent to 2 contacts"
}
```

---

## 📊 Admin Dashboard

Access: http://localhost:8000/admin

### Manage
- Emergency Services: View, edit, filter by category
- Emergency Alerts: View all SOS alerts triggered
- Emergency Notifications: Track SMS delivery status
- Users: Manage accounts
- Emergency Contacts: View user's emergency contacts

### Monitor
- SMS delivery status (sent/failed)
- Alert statistics
- User activity

---

## 🚀 Deployment

### Production Checklist
- [ ] Change SECRET_KEY
- [ ] Set DEBUG=False
- [ ] Configure ALLOWED_HOSTS
- [ ] Setup PostgreSQL database
- [ ] Add MSG91_AUTH_KEY
- [ ] Setup SSL/HTTPS
- [ ] Configure static files
- [ ] Setup logging
- [ ] Enable rate limiting

### Deploy to Railway/Render
```bash
# Already configured in .env
# Just connect GitHub repo
```

### Deploy to VPS
```bash
# Install Gunicorn
pip install gunicorn

# Run server
gunicorn config.wsgi:application --bind 0.0.0.0:8000

# Setup Nginx reverse proxy
# Setup SSL with Let's Encrypt
```

---

## 🧪 Testing Real SMS

### Step 1: Test Setup
```bash
# In backend/.env, add your MSG91 key
MSG91_AUTH_KEY=abc123def456...
```

### Step 2: Create Test User
```bash
python manage.py shell
from django.contrib.auth.models import User
User.objects.create_user(
    username='testuser',
    email='test@example.com',
    password='testpass123'
)
```

### Step 3: Add Real Emergency Contact
```bash
# Via API
POST /api/emergency-contacts/
{
    "name": "Real Contact",
    "phone": "+919876543210",  # YOUR REAL PHONE
    "relationship": "Family",
    "is_primary": true
}
```

### Step 4: Trigger SOS
```bash
# Via API
POST /api/emergency-alert/
{
    "alert_type": "sos",
    "message": "Test emergency alert",
    "latitude": 19.0760,
    "longitude": 72.8777,
    "address": "Mumbai, India"
}
```

### Step 5: Check SMS
- Look for message on real phone
- Should arrive within 30 seconds
- Check MSG91 dashboard for delivery report

---

## 📝 Logging & Monitoring

### View Logs
```bash
# Application logs
tail -f logs/resqnav.log

# Django logs
python manage.py tail  # if installed

# Error monitoring
# Configure Sentry for production
```

### Monitor SMS Delivery
1. Check Django Admin → Emergency Notifications
2. Check MSG91 Dashboard for delivery reports
3. Check server logs for any errors

---

## ❌ Troubleshooting

### SMS Not Sending?
```
1. Check MSG91_AUTH_KEY in .env
2. Verify phone number format: +919876543210
3. Check MSG91 account has credit
4. Check server logs: tail -f logs/resqnav.log
5. Test via Django shell
```

### Emergency Alert Fails?
```
1. Check user has emergency contacts saved
2. Verify phone numbers have country codes
3. Check backend logs
4. Test SMS service independently
```

### Database Issues?
```
1. Run: python manage.py migrate
2. Check database connection in .env
3. Backup database before major changes
```

---

## 📞 Support

### Quick Contacts
- MSG91 Support: https://msg91.com/support
- Django Docs: https://docs.djangoproject.com
- DRF Docs: https://www.django-rest-framework.org

---

## ✅ Final Checklist

- [x] Dependencies installed
- [x] Database migrated
- [x] Services seeded (70 services)
- [x] Admin user created
- [x] SMS service configured
- [x] Emergency alert endpoints working
- [x] Real SMS notifications implemented
- [x] Production .env created
- [x] Documentation complete

**Ready for Production! 🚀**
