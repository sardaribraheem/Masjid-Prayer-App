# 🕌 Masjid Prayer App - Setup & Deployment Guide

## Overview
A complete Flutter application for viewing and managing mosque prayer times with real-time updates from Firebase Firestore.

## ✨ Features Implemented

### User Features
- ✅ Browse available masjids
- ✅ Select a masjid to view prayer times
- ✅ Real-time prayer time updates
- ✅ View Jummah prayer times
- ✅ Persistent masjid selection (survives app restart)
- ✅ Clean, intuitive Material UI

### Admin Features
- ✅ Admin login with username/password
- ✅ Register new masjid
- ✅ Edit prayer times (Fajr, Dhuhr, Asr, Maghrib, Isha)
- ✅ Edit Jummah times
- ✅ Real-time synchronization across all users
- ✅ Admin logout

### Technical Features
- ✅ Firebase Firestore integration
- ✅ Real-time data streaming (Firestore listeners)
- ✅ Local storage with shared_preferences
- ✅ Offline fallback with local data
- ✅ Error handling and loading states
- ✅ Async/await for all operations
- ✅ Clean modular architecture

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point, initialization
├── models/
│   └── app_data.dart        # Data models: Masjid, PrayerTime, AppData
├── services/
│   ├── firebase_service.dart # Firebase/Firestore operations
│   └── storage_service.dart  # Shared preferences for local storage
└── screens/
    ├── masjid_selection_screen.dart  # User selects masjid
    ├── home_screen.dart              # User views prayer times
    ├── admin_login_screen.dart       # Admin login
    ├── admin_register_screen.dart    # Register new masjid
    └── admin_panel_screen.dart       # Edit prayer times
```

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK (≥3.9.0)
- Firebase project with Firestore enabled
- macOS/iOS or Android development environment

### Step 1: Install Dependencies
```bash
cd /Users/arslananwar/masjid_app
flutter pub get
```

### Step 2: Set Up Firebase

#### For iOS:
```bash
cd ios
pod install
cd ..
```

#### For Android:
No additional steps needed if using FlutterFire CLI.

#### Using FlutterFire CLI (Recommended):
```bash
# Install CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This will:
- Connect to your Firebase project
- Generate necessary configuration files
- Add required plugins

### Step 3: Enable Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Create a Cloud Firestore database
4. Start in **Test Mode** (for development)
5. Choose your region

### Step 4: Configure Firestore Security Rules

Add these rules to your Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow everyone to read masjids
    match /masjids/{id} {
      allow read: if true;
      // For development: allow all writes
      // For production: implement proper authentication
      allow write: if true;
    }
  }
}
```

### Step 5: Run the App

#### Development mode (with sample data initialization):
```bash
flutter run
```

The app will:
1. Initialize Firebase
2. Initialize shared_preferences
3. Populate sample masjids automatically
4. Show the masjid selection screen

## 📊 Firestore Database Schema

### Collection: `masjids`

Each document represents a masjid:

```json
{
  "name": "Central Masjid",
  "location": "Downtown",
  "username": "admin1",
  "password": "pass123",
  "jummah": "1:00 PM",
  "lastUpdated": "2024-01-15T10:30:00",
  "prayerTimes": [
    {
      "name": "Fajr",
      "time": "5:30 AM"
    },
    {
      "name": "Dhuhr",
      "time": "12:45 PM"
    },
    {
      "name": "Asr",
      "time": "3:30 PM"
    },
    {
      "name": "Maghrib",
      "time": "6:15 PM"
    },
    {
      "name": "Isha",
      "time": "7:45 PM"
    }
  ]
}
```

## 🧪 Testing the App

### User Flow:
1. App launches → Masjid Selection screen
2. Tap a masjid → Home screen displays prayer times
3. Tap "Change" button → Return to masjid selection
4. Changes made by admins appear in real-time

### Admin Flow:
1. From Masjid Selection screen, tap "Admin / Imam?"
2. Enter admin credentials:
   - Username: `admin1`
   - Password: `pass123`
3. Edit prayer times
4. Tap "Save Changes" → Updates appear in real-time for all users
5. Tap "Logout" to return

### Register New Masjid:
1. From Admin Login screen, tap "Register New Masjid"
2. Fill in form:
   - Masjid Name: e.g., "My Masjid"
   - Location: e.g., "My City"
   - Admin Username: (must be unique)
   - Password: (at least 6 characters)
3. Tap "Register Masjid"
4. New masjid appears in the main list

## 🔐 Security Considerations

### Current Implementation
- Simple username/password authentication
- Credentials stored in Firestore (for development)

### Production Recommendations
1. **Use Firebase Authentication:**
   ```dart
   // Add to services/firebase_service.dart
   Future<UserCredential> authenticateWithEmail(
       String email, String password) async {
     return await FirebaseAuth.instance
         .signInWithEmailAndPassword(email: email, password: password);
   }
   ```

2. **Update Firestore Rules:**
   ```javascript
   match /masjids/{id} {
     allow read: if true;
     allow write: if request.auth != null && 
                     request.auth.uid == resource.data.adminId;
   }
   ```

3. **Hash Passwords** (use bcrypt or similar)

4. **Use Environment Variables** for API keys

## 📱 Data Persistence

### Local Storage (shared_preferences)
- `selectedMasjidId`: Remember user's selected masjid
- `adminMasjidId`: Track logged-in admin
- `adminUsername`: Remember admin username
- `language`: App language preference
- `theme`: Theme preference

### Firestore
- Real-time prayer time data
- Masjid information
- Update timestamps

## 🚀 Deployment

### iOS:
```bash
flutter build ios --release
# Then upload to App Store
```

### Android:
```bash
flutter build apk --release
# or for App Bundle:
flutter build appbundle --release
```

## 📦 Dependencies

### Firebase
- `firebase_core: ^3.5.0`
- `cloud_firestore: ^5.4.0`
- `firebase_auth: ^5.3.0` (optional, for future auth)

### Local Storage
- `shared_preferences: ^2.3.2`

### Utilities
- `intl: ^0.19.0` (for date formatting)

## 🐛 Troubleshooting

### Firebase Connection Issues
1. Verify Firebase configuration with `flutterfire configure`
2. Check Firestore database is enabled
3. Verify security rules allow read/write

### Data Not Updating
1. Check internet connection
2. Verify Firestore listener is active
3. Check browser console for Firebase errors

### Build Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

## 📝 API Reference

### FirebaseService
```dart
// Get all masjids (one-time fetch)
Future<List<Masjid>> getAllMasjids()

// Real-time stream of all masjids
Stream<List<Masjid>> getMasjidsStream()

// Real-time stream of specific masjid
Stream<Masjid?> getMasjidStream(String masjidId)

// Authenticate admin
Future<Masjid?> authenticateAdmin(String username, String password)

// Register new masjid
Future<bool> registerMasjid(Masjid masjid)

// Update prayer times
Future<bool> updatePrayerTimes(String masjidId, List<PrayerTime> prayerTimes)

// Update Jummah time
Future<bool> updateJummahTime(String masjidId, String jummahTime)
```

### StorageService
```dart
// Save/retrieve selected masjid
Future<bool> saveSelectedMasjidId(String masjidId)
String? getSelectedMasjidId()

// Admin login status
Future<bool> saveAdminLoginStatus(String masjidId, String username)
Map<String, String?>? getAdminLoginStatus()
```

## 🎯 Future Enhancements

1. **Notifications**: Send prayer time reminders
2. **Multi-language**: Support Arabic, Urdu, etc.
3. **Prayer Tracker**: Track attendance/participation
4. **Announcements**: Masjid-specific news/events
5. **Dark Mode**: Theme support
6. **Analytics**: Track most-viewed masjids
7. **Payment Integration**: Donations/Sadaqah
8. **Calendar View**: Monthly prayer schedule
9. **Map Integration**: Show masjid location
10. **Rating System**: User reviews and ratings

## 📞 Support

For issues or questions:
1. Check this guide first
2. Review Flutter documentation: https://flutter.dev
3. Check Firebase documentation: https://firebase.google.com
4. Review code comments in the implementation

## 📄 License

This app is designed for educational and community purposes. Modify as needed for your use case.

---

**Happy coding!** 🚀 Your Masjid Prayer App is now ready to bring the community together.
