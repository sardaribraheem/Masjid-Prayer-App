
# 🔥 Firebase Setup Checklist for Masjid Prayer App

## 📅 Date: May 4, 2026

## ✅ Pre-Setup (Already Done ✓)
- [x] Flutter 3.35.1 installed
- [x] Dart 3.9.0 installed  
- [x] FlutterFire CLI installed
- [x] Dependencies downloaded (`flutter pub get`)
- [x] Project structure ready

---

## 📋 Setup Steps (YOU NEED TO DO)

### Step 1️⃣: Create or Select Firebase Project
**Time: 2-3 minutes**

```
Option A: Use Existing Project
  1. Go to: https://console.firebase.google.com
  2. Select your existing project from the dropdown
  Skip to Step 2

Option B: Create New Project
  1. Go to: https://console.firebase.google.com
  2. Click "Add project"
  3. Name: "Masjid Prayer App"
  4. Continue through wizard
  5. Wait for project to be created (1-2 minutes)
  6. Click "Continue"
```

### Step 2️⃣: Connect Flutter App to Firebase
**Time: 2-3 minutes**

Open terminal and run:

```bash
cd /Users/arslananwar/masjid_app
export PATH="$PATH":"$HOME/.pub-cache/bin"
flutterfire configure
```

This will:
- Open a browser window
- Ask you to log in with Google account
- Ask you to select your Firebase project
- Generate configuration files automatically
- Add Firebase to your iOS & Android projects

**If you get stuck:** Follow the on-screen prompts - FlutterFire CLI is very user-friendly!

### Step 3️⃣: Enable Firestore Database
**Time: 2-3 minutes**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Left sidebar → **Build** → **Firestore Database**
4. Click **"Create Database"**
5. Choose:
   - Start Mode: **"Start in test mode"**
   - Region: **Choose closest to you**
6. Click **"Enable"**

✅ Firestore is now ready!

### Step 4️⃣: Set Firestore Security Rules
**Time: 1-2 minutes**

1. In Firebase Console, go to **Firestore Database** → **Rules** tab
2. Delete everything and paste this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /masjids/{id} {
      allow read: if true;
      allow write: if true;
    }
  }
}
```

⚠️ **WARNING:** This allows anyone to read/write. 
For production, you'll want proper authentication.

3. Click **"Publish"**

✅ Rules are now published!

### Step 5️⃣: Verify the Connection
**Time: 30 seconds**

In Firebase Console:
1. Click on your project
2. Look at the top left - should show your project name
3. Look for "Firestore Database" showing your region
4. You should see an empty "masjids" collection section

✅ Everything is connected!

---

## 🚀 Run and Test the App

### Option 1: Run on Android/iOS Emulator
```bash
# First time (will populate sample data)
flutter run

# Choose emulator when prompted
# Wait for app to load
# Tap a masjid to view prayer times
```

### Option 2: Run on Chrome (Web)
```bash
# First time (will populate sample data)  
flutter run -d chrome

# Chrome will open with your app
# Tap a masjid to view prayer times
```

### Option 3: Run on Physical Device
```bash
# Connect your iOS/Android device via USB
flutter devices  # See list of devices
flutter run -d <device_id>
```

---

## 🧪 Test Checklist After Running

### User Features:
- [ ] App loads and shows masjid list
- [ ] Can select each masjid
- [ ] Prayer times display correctly
- [ ] Can change masjid with "Change" button
- [ ] Selection persists if you restart the app

### Admin Features:
1. Tap **"Admin / Imam?"** button
2. Login with:
   - Username: `admin1`
   - Password: `pass123`
3. Should see admin panel with prayer times
4. [ ] Can edit prayer times
5. [ ] Can edit Jummah time
6. [ ] "Save Changes" works
7. [ ] See success message
8. [ ] [ ] Can tap "Logout"

### Real-Time Sync (Advanced Test):
1. Open app on TWO devices/emulators
2. On Device 1: Select "Central Masjid" → view prayer times
3. On Device 2: Admin login → Edit "Fajr" time to "6:00 AM" → Save
4. On Device 1: **Prayer times update automatically!** ✨

---

## 🐛 Troubleshooting

### "MissingPluginException" Error
**Solution:** Run `flutter clean && flutter pub get`

### "Firebase not initialized" 
**Solution:** 
- Make sure Firestore database is enabled
- Restart the app (`flutter run`)

### "Permission denied" in Firestore
**Solution:**
- Check Firestore rules are published correctly
- Rules should allow read/write for development

### App doesn't show masjids
**Solution:**
- Check Firestore database has "masjids" collection
- First run should auto-populate sample data
- If not, check Firebase Console → Firestore → Collections

### Changes not syncing in real-time
**Solution:**
- Check internet connection
- Restart app
- Check both devices have same WiFi network
- Check Firestore listener is active in code

---

## 📊 What Gets Created in Firestore

After first run, you'll have:

```
Firestore Database
└── Collection: "masjids"
    ├── Document (auto-ID)
    │   ├── name: "Central Masjid"
    │   ├── location: "Downtown"
    │   ├── username: "admin1"
    │   ├── password: "pass123"
    │   ├── jummah: "1:00 PM"
    │   ├── lastUpdated: (timestamp)
    │   └── prayerTimes: Array
    │       ├── Fajr: 5:30 AM
    │       ├── Dhuhr: 12:45 PM
    │       ├── Asr: 3:30 PM
    │       ├── Maghrib: 6:15 PM
    │       └── Isha: 7:45 PM
    ├── Document (auto-ID)
    │   └── ... New Mosque ...
    └── Document (auto-ID)
        └── ... Green Valley Mosque ...
```

---

## ✨ Next Steps After Testing

### If Everything Works:
🎉 Congratulations! Your Firebase integration is complete!

You can now:
- Deploy to App Store/Play Store
- Add more masjids
- Customize admin features
- Add notifications (future feature)

### Production Setup:
- [ ] Implement proper Firebase Authentication
- [ ] Update Firestore rules for security
- [ ] Add error reporting (Sentry/Crashlytics)
- [ ] Set up CI/CD pipeline
- [ ] Test on production Firebase project

---

## 📞 Need Help?

**Error during setup?** Here's what to check:

1. **Internet Connected?** - Firebase requires internet
2. **Google Account Active?** - Log out other accounts if multiple logged in
3. **Right Project?** - Make sure you're using correct Firebase project
4. **Firestore Enabled?** - Check it's created and shows in console
5. **Rules Published?** - Check Firestore Rules show your custom rules

---

## 🎓 After Setup is Complete

Once all tests pass, I can help you with:
- ✅ Deploy to production
- ✅ Add new features
- ✅ Optimize performance
- ✅ Fix any bugs
- ✅ Scale to more users

**Estimated Time to Complete Setup:** 10-15 minutes

**Ready?** Start with Step 1️⃣ above! 🚀
