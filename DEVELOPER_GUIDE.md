# 🚀 Masjid Prayer App - Developer Guide & Troubleshooting

## Quick Start Checklist

- [ ] Clone/download project
- [ ] Run `flutter pub get`
- [ ] Configure Firebase with `flutterfire configure`
- [ ] Enable Firestore in Firebase Console
- [ ] Set Firestore rules to allow read/write
- [ ] Run `flutter run` on iOS or Android
- [ ] Test with sample admin credentials (admin1/pass123)

## Common Workflows

### Workflow 1: Local Development Without Firebase

If you don't have Firebase configured yet, the app will:
1. Fall back to local hardcoded data
2. Store selection in shared_preferences
3. Work on simulator/emulator

**Note:** Admin changes won't sync to other users in this mode.

### Workflow 2: Development With Firebase

1. **Set up Firebase project:**
   ```bash
   flutterfire configure
   ```

2. **Verify Firestore is running:**
   - Go to Firebase Console
   - Check "Cloud Firestore" section
   - Should show your database region

3. **Test real-time sync:**
   - Open app on 2 simulators
   - Admin changes on one → appears on other instantly

### Workflow 3: Testing Admin Flow

```
Emulator 1 (Regular User)          Emulator 2 (Admin)
    ↓                                   ↓
Select "Central Masjid"            Admin Login (admin1/pass123)
    ↓                                   ↓
View prayer times                   Edit times
(waiting for updates)                   ↓
                              Tab "Save Changes"
    ↓                                   ↓
    ←──── Real-time update ────→
    ↓
See updated times instantly!
```

## Debugging Guide

### Enable Debug Logging

Add to `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable Firebase debug logging
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // ...rest of initialization
}
```

### Check Firestore Connection

```dart
// Add debug method to FirebaseService
Future<bool> checkConnection() async {
  try {
    await _firestore.collection('masjids').limit(1).get();
    debugPrint('✅ Firestore connected');
    return true;
  } catch (e) {
    debugPrint('❌ Firestore error: $e');
    return false;
  }
}
```

### Monitor Real-time Listeners

```dart
// Add in getMasjidStream:
Stream<Masjid?> getMasjidStream(String masjidId) {
  final stream = _firestore
      .collection('masjids')
      .doc(masjidId)
      .snapshots();
  
  stream.listen(
    (snapshot) => debugPrint('📡 Received update: ${snapshot.data()}'),
    onError: (error) => debugPrint('❌ Stream error: $error'),
  );
  
  return stream.map((snapshot) {
    if (snapshot.exists) {
      return Masjid.fromFirestore(snapshot.data() ?? {}, snapshot.id);
    }
    return null;
  });
}
```

### Android Debugging

```bash
# View Logcat
adb logcat | grep flutter

# Check connected devices
adb devices

# Run on specific device
flutter run -d <device_id>
```

### iOS Debugging

```bash
# Run with verbose output
flutter run -v

# Check Xcode build
flutter run -v 2>&1 | grep -i error

# View device logs
xcrun simctl spawn booted log show --predicate 'eventMessage contains[cd] "flutter"' --level debug
```

## Common Issues & Solutions

### Issue 1: "No Firestore Instance"
**Error:**
```
FirebaseFirestore was not initialized in time
```

**Solution:**
```dart
// Ensure Firebase is initialized in main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Add this line
  // ... rest
}
```

### Issue 2: "Connection Timeout"
**Error:**
```
The database is not responding. Check your internet connection.
```

**Solutions:**
1. Verify internet connection
2. Check Firestore status: https://status.firebase.google.com
3. Verify Firebase project is active
4. Restart emulator/simulator
5. Clear app cache:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Issue 3: "Permission Denied" on Firestore
**Error:**
```
[cloud_firestore/permission-denied] Missing or insufficient permissions
```

**Solution:**
Update Firestore rules to:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /masjids/{id} {
      allow read: if true;
      allow write: if true;  // For development only!
    }
  }
}
```

### Issue 4: "StreamBuilder never updates"
**Cause:** Listener not properly subscribed

**DEBUG:**
```dart
StreamBuilder<List<Masjid>>(
  stream: _firebaseService.getMasjidsStream(),
  builder: (context, snapshot) {
    debugPrint('ConnectionState: ${snapshot.connectionState}');
    debugPrint('HasData: ${snapshot.hasData}');
    debugPrint('HasError: ${snapshot.hasError}');
    debugPrint('Error: ${snapshot.error}');
    
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    // ... rest
  }
)
```

### Issue 5: "Data not persisting locally"
**Cause:** shared_preferences not initialized

**Solution:**
```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storage = StorageService();
  await storage.initialize();  // Add this
  
  // ... rest
}
```

### Issue 6: "Admin login always fails"
**Debug:**
```dart
// In AdminLoginScreen
print('Username: $username');
print('Password: $password');

final masjid = await _firebaseService.authenticateAdmin(username, password);
print('Authenticated: ${masjid?.name}');
```

**Check Firestore:**
1. Go to Firebase Console
2. Cloud Firestore → masjids collection
3. Verify documents exist with username/password fields

### Issue 7: "Flutter can't find devices"
```bash
# List available devices
flutter devices

# Ensure emulator is running
emulator -list-avds
emulator @device_name

# For iOS
open -a Simulator
```

## Testing Scenarios

### Test 1: User Selection Persistence
1. Select a masjid
2. Kill app (force close)
3. Reopen app
4. **Expected:** Same masjid is selected

**Why it works:**
```dart
// In main.dart
final selectedId = storageService.getSelectedMasjidId();
if (selectedId != null) {
  AppData.selectedMasjidId = selectedId;
}
```

### Test 2: Real-time Prayer Time Updates
1. Open app on 2 simulators
2. On device 1: Go to Home Screen
3. On device 2: Login as admin, edit a prayer time, click Save
4. **Expected:** Device 1 shows updated time instantly

**Debug:**
```dart
// Check stream subscription in HomeScreen
debugPrint('Listening to: ${AppData.selectedMasjid?.id}');

// Check if data flows through
(context, snapshot) {
  debugPrint('New data received: ${snapshot.data?.prayerTimes}');
}
```

### Test 3: Admin Registration
1. Click "Admin / Imam?"
2. Click "Register New Masjid"
3. Fill form with unique username
4. Click "Register"
5. **Expected:** Success message, then back to login screen
6. Try login with new credentials
7. **Expected:** Login succeeds

### Test 4: Offline Fallback
1. Enable airplane mode
2. Open previously used masjid
3. **Expected:** Still shows prayer times (from cache or local data)
4. Disable airplane mode
5. **Expected:** Real-time data starts flowing again

### Test 5: Error Handling
1. Set incorrect Firestore rules
2. Try to login/save
3. **Expected:** Error message displayed to user
4. Fix rules
5. Try again
6. **Expected:** Works again

## Performance Testing

### Monitor App Size
```bash
flutter build apk --split-per-abi
# Check build/app/outputs/flutter-apk/
```

### Check Memory Usage
```dart
// Add to main.dart
void _printMemoryUsage() {
  final info = await DeviceInfoPlugin().androidInfo;
  debugPrint('Memory info: ${info.totalMemory}');
}
```

### Profile Startup Time
```bash
flutter run --profile
# Then in Flutter DevTools: Timeline tab
```

## Firebase Console Checks

### Before Running App
- [ ] Project created
- [ ] Firestore database created
- [ ] Database in test mode
- [ ] Rules allow read/write
- [ ] Google Cloud credentials configured

### After Running App
- [ ] Check collection "masjids" was created
- [ ] Verify documents have expected fields
- [ ] Check "Firestore" → "Usage" for activity
- [ ] Monitor Firestore billing

## Advanced Debugging

### View Firestore Activity
```dart
// In FirebaseService
void _enableDebug() {
  FirebaseFirestore.instance.enableNetwork();
  debugPrint('Firestore network enabled');
}

void _disableDebug() {
  FirebaseFirestore.instance.disableNetwork();
  debugPrint('Firestore network disabled (offline mode)');
}
```

### Mock Firestore for Testing
```dart
// test/mock_firebase.dart
class MockFirebaseService implements FirebaseService {
  @override
  Stream<List<Masjid>> getMasjidsStream() async* {
    yield [
      Masjid(
        id: 'test_1',
        name: 'Test Masjid',
        location: 'Test Location',
        username: 'test',
        password: 'test123',
        prayerTimes: [],
      ),
    ];
  }
}
```

## Performance Optimization Tips

### 1. Reduce Firestore Reads
```dart
// ❌ Bad: Creates listener on every build
@override
build(BuildContext context) {
  return StreamBuilder(
    stream: _firebaseService.getMasjidsStream(),  // New stream each time!
    builder: (context, snapshot) { ... }
  );
}

// ✅ Good: Create stream once
@override
void initState() {
  _masjidsStream = _firebaseService.getMasjidsStream();
}
```

### 2. Use Pagination
```dart
// Future: Implement pagination for large lists
Future<List<Masjid>> getPaginatedMasjids(int page, int pageSize) async {
  return _firestore
      .collection('masjids')
      .limit(pageSize)
      .offset((page - 1) * pageSize)
      .get()
      .then((snapshot) => snapshot.docs
          .map((doc) => Masjid.fromFirestore(doc.data(), doc.id))
          .toList());
}
```

### 3. Index Important Queries
```javascript
// In Firestore Indexes
// Add index on: username, password
// (Firestore will prompt you when needed)
```

## Deployment Checklist

### Before Production
- [ ] Remove debug print statements
- [ ] Change Firestore rules (restrict access)
- [ ] Implement proper authentication
- [ ] Test on physical devices
- [ ] Check app performance (no memory leaks)
- [ ] Update privacy policy
- [ ] Set up error reporting (Crashlytics)
- [ ] Remove hardcoded admin credentials

### Launch Commands
```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Useful Commands

```bash
# Clean everything
flutter clean && flutter pub get

# Run in verbose mode
flutter run -v

# Run on specific device
flutter run -d <device_id>

# Profile mode (production-like performance)
flutter run --profile

# Release mode
flutter run --release

# Generate app bundle for Play Store
flutter build appbundle --release

# Generate APK
flutter build apk --release

# Check Flutter doctor
flutter doctor -v

# Format code
dart format lib/

# Analyze code
dart analyze

# Run tests
flutter test
```

## Key Metrics to Monitor

### Firestore Usage
- **Read Operations**: Each query/stream update
- **Write Operations**: Save changes
- **Delete Operations**: Remove masjids
- **Storage**: Data stored + indexes

### App Performance
- **Startup Time**: Time to first screen
- **Frame Rate**: Should be consistent 60fps
- **Memory**: Shouldn't grow indefinitely
- **Battery**: Streaming shouldn't drain battery fast

### User Analytics (when implemented)
- **Active Users**: Daily/Monthly
- **Retention**: % returning users
- **Session Duration**: Average time in app
- **Crashes**: Error reporting

---

**Remember:** Test thoroughly before deploying to production! 🧪

For more help:
- Flutter Docs: https://flutter.dev
- Firebase Docs: https://firebase.google.com/docs
- Dart Docs: https://dart.dev
