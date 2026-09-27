# 🚀 ResQNav - Deploy Now (Quick Guide)

**Total Time:** 2-3 hours  
**Order:** Backend → Android → Web → iOS

---

## STEP 1: DEPLOY BACKEND (30 min) ⚙️

### Using Railway.app (Easiest)

1. **Go to:** https://railway.app/
2. **Sign in with GitHub**
3. **New Project** → Deploy from GitHub
4. **Select:** Your ResQNav repository
5. **Add Services:**
   - Click "+ New" → PostgreSQL
   - Click "+ New" → Redis

6. **Add Environment Variables:**
   ```
   SECRET_KEY=generate-new-django-secret-key
   DEBUG=False
   ALLOWED_HOSTS=*.railway.app
   MSG91_AUTH_KEY=575721Ax2TwHTwuzY6ab8fb81P1
   MSG91_SENDER_ID=RESQNV
   MSG91_ROUTE=4
   ```

7. **Deploy** → Wait 10 minutes
8. **Run in Shell:**
   ```bash
   python manage.py migrate
   python manage.py createsuperuser
   python manage.py seed_emergency_services
   ```

✅ **Backend Live!** URL: `https://your-app.up.railway.app`

---

## STEP 2: DEPLOY ANDROID (30 min) 📱

### Update API URL

**File:** `lib/core/constants/api_constants.dart`
```dart
static const String baseUrl = 'https://your-app.up.railway.app';
```

### Build APK

```bash
flutter clean
flutter pub get
flutter build apk --release
```

**File created:** `build/app/outputs/apk/release/app-release.apk`

### Upload to Google Play

1. **Create account:** https://play.google.com/console/ (₹2,000 fee)
2. **Create app** → Fill details
3. **Upload APK/AAB**
4. **Add screenshots** (1080x1920px, at least 2)
5. **Submit for review**

✅ **Live in 2-24 hours!**

---

## STEP 3: DEPLOY WEB (30 min) 🌐

### Build Web

```bash
flutter build web --release
```

### Deploy to Firebase

```bash
# Install Firebase
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init hosting
# Select: build/web as public directory

# Deploy
firebase deploy --only hosting
```

✅ **Web Live!** URL: `https://resqnav-xxxxx.web.app`

---

## STEP 4: DEPLOY iOS (2 hours + 5-7 days) 🍎

### Prepare

```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. **Signing & Capabilities** → Select Team
2. **Bundle ID:** com.resqnav.emergency
3. **Version:** 1.0.0

### Create Apple Developer Account

1. **Go to:** https://developer.apple.com/
2. **Enroll** → $99/year
3. **Wait 1-2 days for approval**

### Create App in App Store Connect

1. **Go to:** https://appstoreconnect.apple.com/
2. **My Apps** → + → New App
3. **Fill:** Name, Bundle ID, SKU

### Build & Upload

In Xcode:
1. **Product** → Archive
2. **Distribute App** → App Store Connect
3. **Upload**

### Complete Listing

- Add screenshots (iPhone 6.7" and iPad)
- Add description
- Add privacy policy
- Set pricing (Free)
- Submit for review

✅ **Live in 5-7 days after approval!**

---

## 📋 QUICK CHECKLIST

**Before Starting:**
- [ ] Backend code tested locally
- [ ] Flutter app tested on device
- [ ] API URL ready
- [ ] SMS credentials ready

**During Deployment:**
- [ ] Backend deployed ✅
- [ ] Environment variables set ✅
- [ ] Database migrated ✅
- [ ] Android APK built ✅
- [ ] Web app built ✅
- [ ] iOS archived ✅

**After Deployment:**
- [ ] Test backend API
- [ ] Test Android app
- [ ] Test web app
- [ ] Monitor errors
- [ ] Wait for iOS approval

---

## 🆘 QUICK FIXES

**Problem:** API not connecting  
**Fix:** Check API URL in `api_constants.dart`

**Problem:** SMS not sending  
**Fix:** Verify MSG91_AUTH_KEY in Railway

**Problem:** Build failed  
**Fix:** Run `flutter clean` and rebuild

**Problem:** iOS archive failed  
**Fix:** Update Xcode, clean build folder

---

## 📞 IMPORTANT URLS

**Railway Dashboard:** https://railway.app/dashboard  
**Google Play Console:** https://play.google.com/console/  
**Firebase Console:** https://console.firebase.google.com/  
**App Store Connect:** https://appstoreconnect.apple.com/  

---

## ✅ SUCCESS!

After completing all steps:

✅ Backend API live on Railway  
✅ Android app on Google Play  
✅ Web app on Firebase  
✅ iOS app submitted to Apple  

**Your ResQNav is now deployed and ready to save lives!** 🎉

---

**For detailed instructions, see:** `DEPLOYMENT_TO_MOBILE_WEB.md`