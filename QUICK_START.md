# 🚀 ResQNav Quick Start Guide

## ⚡ 5 Minute Setup

### 1. Backend Start
```bash
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_emergency_services
python manage.py runserver
# Visit: http://127.0.0.1:8000/admin
```

### 2. Frontend Start
```bash
flutter pub get
flutter run -d chrome
# Or: flutter run -d windows
```

### 3. Add SMS (Real Alerts)
```bash
# Edit backend/.env
MSG91_AUTH_KEY=your-key-from-msg91
```

---

## 📱 Test Emergency Alert

### 1. Register User
```
App → Login → Register
Email: test@example.com
Password: test123
```

### 2. Add Emergency Contact
```
Profile → Emergency Contacts → Add
Name: Mom
Phone: +919876543210  (YOUR REAL PHONE)
Set as Primary
```

### 3. Trigger SOS
```
Click RED SOS Button
Confirm alert
Check phone for SMS!
```

---

## 📊 What You Get

| Feature | Status |
|---------|--------|
| Real SMS Alerts | ✅ Ready |
| 70 Services | ✅ Seeded |
| Location Finder | ✅ Working |
| Admin Dashboard | ✅ Ready |
| Modern Theme | ✅ Applied |
| Production Config | ✅ Complete |

---

## 🔧 Key Files

```
backend/.env                  → Add SMS API key
backend/api/services/sms_service.py  → SMS logic
backend/api/views.py          → Emergency endpoints
lib/main.dart                 → SOS button
lib/core/theme/app_theme.dart → Modern colors
```

---

## 📞 API Quick Test

```bash
# Register
curl -X POST http://localhost:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Test","email":"test@example.com","password":"test123"}'

# Trigger Emergency
curl -X POST http://localhost:8000/api/emergency-alert/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"alert_type":"sos","latitude":19.07,"longitude":72.87}'
```

---

## ✅ Checklist

- [ ] Backend running on 8000
- [ ] Flutter app running
- [ ] Emergency services seeded (70 total)
- [ ] Admin user created
- [ ] Test user registered
- [ ] Real phone number added to emergency contacts
- [ ] MSG91 API key configured
- [ ] SOS button tested
- [ ] SMS received on phone
- [ ] Ready for deployment

---

## 🎯 For Production

1. Get MSG91 API key (https://msg91.com/)
2. Deploy backend (Railway/Render/VPS)
3. Deploy frontend (Firebase/Netlify)
4. Add custom domain + SSL
5. Monitor admin dashboard
6. Go live!

---

**Everything is ready. Deploy now!** 🚀
