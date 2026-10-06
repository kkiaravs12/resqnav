# ResQNav - Complete Project Structure

## 📁 Project Organization

**Single Repository: `c:\Project\resqnav`**

This folder contains EVERYTHING:
- ✅ Flutter UI (Mobile + Web)
- ✅ Django Backend API
- ✅ Dark/Light Theme Toggle
- ✅ All deployment configurations

## 🌳 Folder Structure

```
resqnav/
├── backend/              # Django Backend API
│   ├── resqnav_backend/  # Django project settings
│   ├── services/         # Emergency services API
│   ├── manage.py         # Django management
│   └── requirements.txt  # Python dependencies
│
├── lib/                  # Flutter Source Code
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # Light & Dark themes
│   │   │   └── theme_provider.dart  # Theme state management
│   │   └── constants/
│   │
│   ├── features/
│   │   ├── home/         # Home page
│   │   ├── explore/      # Service search
│   │   ├── emergency/    # SOS page
│   │   ├── history/      # Search history
│   │   └── profile/      # Profile with theme toggle
│   │
│   ├── services/         # API services
│   └── main.dart         # App entry point
│
├── android/              # Android configuration
├── ios/                  # iOS configuration
├── web/                  # Web configuration
├── vercel.json           # Vercel deployment config
└── pubspec.yaml          # Flutter dependencies

```

## 🎨 Features Implemented

### ✅ Dark/Light Theme Toggle
- **Location**: Profile Page → Preferences Section
- **Package**: Provider for state management
- **Persistence**: SharedPreferences (saves user choice)
- **Colors**:
  - Light: Teal/Navy professional theme
  - Dark: Pure black (#121212) with red accent (#FF0844)

### ✅ 6 Emergency Services
- Hospital 🏥
- Ambulance 🚑
- Police 👮
- Fire Station 🚒
- Pharmacy 💊
- Mechanic 🔧

### ✅ SOS Alert System
- Share location via any app (WhatsApp, SMS, Email)
- Uses geolocator + geocoding + share_plus
- No backend SMS required

### ✅ OpenStreetMap Integration
- Global coverage (15km search radius)
- Nominatim API for search
- Overpass API for service locations

## 🚀 Deployments

### Web (Vercel)
- **URL**: https://resqnav-backend-rhb.vercel.app
- **Branch**: main
- **Build**: Flutter web with vercel.json configuration

### Backend (Render)
- **URL**: https://resqnav-ziqj.onrender.com
- **Framework**: Django REST API
- **Database**: PostgreSQL

### Mobile (Pending)
- **Status**: APK build to be done on different laptop
- **Transfer**: Via WhatsApp zip file
- **Process**: Flutter SDK + Android Studio → `flutter build apk`

## 📦 Dependencies

### Flutter (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0              # State management
  geolocator: ^9.0.0            # Location
  geocoding: ^2.1.0             # Address lookup
  share_plus: ^6.0.0            # Share functionality
  google_maps_flutter: ^2.2.0   # Maps
  google_fonts: ^3.0.0          # Typography
  shared_preferences: ^2.0.0    # Storage
  http: ^0.13.0                 # API calls
  go_router: ^10.0.0            # Navigation
  url_launcher: ^6.1.0          # External links
  lucide_icons: ^0.88.0         # Icons
```

### Backend (requirements.txt)
```
Django==4.2.5
djangorestframework==3.14.0
django-cors-headers==4.2.0
psycopg2-binary==2.9.7
python-decouple==3.8
gunicorn==21.2.0
```

## 🔧 How to Use

### Run Flutter Web Locally
```bash
cd c:\Project\resqnav
flutter run -d chrome
```

### Run Flutter Mobile
```bash
flutter run -d <device-id>
```

### Build APK (on different laptop)
```bash
flutter pub get
flutter build apk --no-tree-shake-icons
# APK: build\app\outputs\flutter-apk\app-release.apk
```

### Run Django Backend Locally
```bash
cd backend
python manage.py runserver
```

## 🎯 Git Branches

**ONLY ONE BRANCH: `main`**
- ✅ Contains all latest code
- ✅ Dark/light theme implemented
- ✅ Both backend and frontend
- ❌ No `master` branch (deleted for clarity)

## 📱 Theme Toggle Usage

1. Open the app
2. Go to **Profile** page (bottom right)
3. Scroll to **Preferences** section
4. Toggle **Dark Mode** switch (first option)
5. Theme changes instantly!
6. Preference is saved automatically

## 🌈 UI Mockups

Three HTML mockup files included:
- `UI_MOCKUPS.html` - First design attempt
- `UI_MOCKUPS_V2.html` - Second design attempt
- `UI_MOCKUPS_DARK.html` - Final dark theme design (APPROVED)

Open any HTML file in browser to preview designs.

## ✅ Clean Structure Benefits

1. **Single Repository** - Everything in one place
2. **Clear Organization** - Backend and frontend separated
3. **Easy Deployment** - Vercel for web, Render for backend
4. **No Confusion** - Only `main` branch
5. **Complete Package** - Ready for mobile APK build

## 🔥 Next Steps

1. ✅ Code is ready with dark/light theme
2. ⏳ Transfer project to different laptop via WhatsApp
3. ⏳ Build APK on that laptop
4. ⏳ Test mobile app with theme toggle
5. ✅ Web already deployed on Vercel
6. ✅ Backend already deployed on Render

---

**Last Updated**: September 27, 2026
**Status**: ✅ Production Ready
**Location**: `c:\Project\resqnav`
