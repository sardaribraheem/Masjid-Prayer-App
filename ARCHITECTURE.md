# 🏗️ Masjid Prayer App - Architecture & Implementation Details

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Flutter UI Layer (Material)                │
│  (MasjidSelectionScreen, HomeScreen, AdminPanelScreen, etc)  │
└──────┬───────────────────────────────────────────────────────┘
       │
┌──────▼───────────────────────────────────────────────────────┐
│                   App State Layer (AppData)                  │
│  (selectedMasjid, allMasjids, selectedMasjidId)              │
└──────┬───────────────────────────────────────────────────────┘
       │
┌──────┼───────────────────────────────────────────────────────┐
│      │         Service Layer (Singleton Pattern)             │
│      ├─► FirebaseService (Firestore operations)              │
│      └─► StorageService (shared_preferences)                 │
└──────┬───────────────────────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────────────────────┐
│          Backend & Persistence Layer                        │
│  ┌─────────────────┐         ┌──────────────────┐          │
│  │  Firestore DB   │         │  Local Storage   │          │
│  │ (Cloud Real-time)│ ◄─────► │ (shared_prefs)   │          │
│  └─────────────────┘         └──────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

## Design Patterns Used

### 1. Singleton Pattern
Both `FirebaseService` and `StorageService` use singleton pattern to ensure only one instance exists:

```dart
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  factory FirebaseService() {
    return _instance;
  }
  
  FirebaseService._internal();
}
```

**Benefits:**
- Single source of truth for Firebase connection
- Efficient resource usage
- Consistent state across the app

### 2. Repository Pattern
`FirebaseService` acts as a repository, abstracting Firestore operations from UI:

```dart
// UI doesn't know about Firestore details
final masjid = await firebaseService.getMasjidById(id);
```

**Benefits:**
- Easy to test (mock the service)
- Easy to switch backend (change service implementation)
- Separation of concerns

### 3. Stream Pattern
Real-time updates use Firestore streams:

```dart
StreamBuilder<Masjid?>(
  stream: firebaseService.getMasjidStream(masjidId),
  builder: (context, snapshot) { ... }
)
```

**Benefits:**
- Real-time synchronization
- Automatic rebuilds when data changes
- Built-in connection state handling

### 4. State Management with SetState
Apps use `StatefulWidget` with `setState`:

```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void updateUI() {
    setState(() {
      // Trigger rebuild
    });
  }
}
```

**Benefits for this app:**
- Simple and sufficient for current scope
- Easy to understand
- No external dependencies

## Data Flow

### User Journey - Viewing Prayer Times

```
1. App Launches
   └─► main.dart initializes Firebase & StorageService
   └─► Restores previously selected masjid (if any)
   └─► Shows MasjidSelectionScreen

2. User Selects Masjid
   └─► MasjidSelectionScreen fetches masjids from Firestore stream
   └─► User taps a masjid
   └─► AppData.selectedMasjid is set
   └─► Masjid ID saved to shared_preferences
   └─► Navigate to HomeScreen

3. HomeScreen Displays Prayer Times
   └─► Subscribes to Firestore stream for selected masjid
   └─► Renders UI with current prayer times
   └─► Listens for real-time updates
   └─► If admin updates times → StreamBuilder automatically rebuilds
   └─► User sees changes instantly

4. Admin Updates Prayer Times
   └─► Admin edits times in AdminPanelScreen
   └─► Clicks "Save Changes"
   └─► HomeScreen listener detects change
   └─► All users' screens update automatically
```

### Admin Flow - Updating Prayer Times

```
1. Admin Login
   └─► Enters username & password in AdminLoginScreen
   └─► FirebaseService.authenticateAdmin() queries Firestore
   └─► Credentials validated
   └─► AppData.selectedMasjid set to admin's masjid
   └─► Navigate to AdminPanelScreen

2. Edit Prayer Times
   └─► Admin modifies TextEditingControllers
   └─► Changes are local only (not yet saved)

3. Save Changes
   └─► FirebaseService.updatePrayerTimes() called
   └─► Firestore document updated
   └─► lastUpdated timestamp set
   └─► HomeScreen listeners detect change
   └─► All connected users receive update in real-time
   └─► HomeScreen rebuilds automatically
```

## Model Architecture

### PrayerTime Model
```dart
class PrayerTime {
  String name;      // "Fajr", "Dhuhr", etc.
  String time;      // "5:30 AM"
  
  // Serialization for Firestore
  Map<String, dynamic> toJson() { ... }
  factory PrayerTime.fromJson() { ... }
}
```

### Masjid Model
```dart
class Masjid {
  String id;                          // Firestore doc ID
  String name;                        // "Central Masjid"
  String location;                    // "Downtown"
  String username;                    // Admin username
  String password;                    // Admin password
  List<PrayerTime> prayerTimes;      // [Fajr, Dhuhr, Asr, Maghrib, Isha]
  String? jummahTime;                 // Optional Jummah time
  DateTime? lastUpdated;              // When last modified
  
  // Firestore serialization
  Map<String, dynamic> toJson() { ... }
  factory Masjid.fromFirestore() { ... }
}
```

### AppData Global State
```dart
class AppData {
  static Masjid? selectedMasjid;      // Current user's selected masjid
  static List<Masjid> allMasjids;     // Cached list of all masjids
  static String? selectedMasjidId;    // ID for persistence
}
```

## Service Architecture

### FirebaseService
Encapsulates all Firestore operations:

```dart
class FirebaseService {
  // Real-time feeds
  Stream<List<Masjid>> getMasjidsStream()
  Stream<Masjid?> getMasjidStream(String masjidId)
  
  // One-time fetches
  Future<List<Masjid>> getAllMasjids()
  Future<Masjid?> getMasjidById(String masjidId)
  
  // Admin operations
  Future<Masjid?> authenticateAdmin(String username, String password)
  Future<bool> registerMasjid(Masjid masjid)
  Future<bool> updatePrayerTimes(String masjidId, List<PrayerTime> prayerTimes)
  Future<bool> updateJummahTime(String masjidId, String jummahTime)
  
  // Admin management
  Future<bool> deleteMasjid(String masjidId)
  
  // Sample data
  Future<void> initializeSampleData()
}
```

### StorageService
Manages local persistence:

```dart
class StorageService {
  // Masjid selection persistence
  Future<bool> saveSelectedMasjidId(String masjidId)
  String? getSelectedMasjidId()
  Future<bool> clearSelectedMasjidId()
  
  // Admin session management
  Future<bool> saveAdminLoginStatus(String masjidId, String username)
  Map<String, String?>? getAdminLoginStatus()
  Future<bool> clearAdminLoginStatus()
  
  // Preferences
  Future<bool> saveLanguage(String language)
  Future<bool> saveTheme(String theme)
  
  // Utility
  Future<bool> clearAll()
}
```

## Error Handling Strategy

### Try-Catch Pattern
All async operations are wrapped:

```dart
try {
  final masjid = await _firebaseService.authenticateAdmin(username, password);
  if (masjid != null) {
    // Success path
  } else {
    errorMessage = 'Invalid credentials';
  }
} catch (e) {
  errorMessage = 'Error: $e';
}
```

### Firestore Error Recovery
```dart
Stream<List<Masjid>> getMasjidsStream() {
  return _firestore.collection('masjids').snapshots()
      .map((snapshot) {
        // Convert documents to masjids
        return snapshot.docs.map((doc) => 
            Masjid.fromFirestore(doc.data(), doc.id)
        ).toList();
      })
      .handleError((error) {
        print('Stream error: $error');
        // Stream continues; UI shows ConnectionState.error
      });
}
```

### UI Error Display
All screens show error states:

```dart
StreamBuilder<List<Masjid>>(
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return ErrorWidget(error: snapshot.error);
    }
    // ... normal UI
  }
)
```

## Performance Considerations

### 1. Firestore Optimization
- **Index Creation**: Automatic or manual for complex queries
- **Pagination**: Not implemented yet (future enhancement)
- **Data Caching**: Firestore offline caching enabled
- **Query Limits**: Using `.limit(1)` for authentication queries

### 2. Widget Optimization
- **StreamBuilder**: Only rebuilds when data changes
- **const Constructors**: Used throughout for performance
- **Split Widgets**: Each screen is its own StatefulWidget

### 3. Memory Management
- **Dispose**: All TextEditingControllers properly disposed
- **mounted Check**: Always check before setState in callbacks
- **Stream Cleanup**: StreamBuilder automatically unsubscribes

## Firestore Query Examples

### Authenticate Admin
```dart
final snapshot = await _firestore
    .collection('masjids')
    .where('username', isEqualTo: username)
    .where('password', isEqualTo: password)
    .limit(1)  // Optimization: stop after first match
    .get();
```

### Check Username Availability
```dart
final existing = await _firestore
    .collection('masjids')
    .where('username', isEqualTo: newUsername)
    .limit(1)
    .get();
    
if (existing.docs.isNotEmpty) {
  throw Exception('Username already exists');
}
```

### Listen to Masjid Updates
```dart
_firestore
    .collection('masjids')
    .doc(masjidId)
    .snapshots()  // Real-time listener
    .listen((snapshot) {
      final masjid = Masjid.fromFirestore(
          snapshot.data() ?? {}, 
          snapshot.id
      );
      // Update UI
    });
```

## Testing Strategy

### Unit Tests (Models)
```dart
test('PrayerTime serialization', () {
  final prayer = PrayerTime(name: 'Fajr', time: '5:30 AM');
  final json = prayer.toJson();
  expect(json['name'], 'Fajr');
});
```

### Mock Services
```dart
class MockFirebaseService implements FirebaseService {
  @override
  Future<Masjid?> authenticateAdmin(String username, String password) async {
    // Return mock data
    return testMasjid;
  }
}
```

### Widget Tests
```dart
testWidgets('HomeScreen displays prayer times', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('Fajr'), findsOneWidget);
});
```

## Future Architecture Improvements

### 1. State Management
Replace SetState with:
- **Provider**: Lightweight, recommended
- **Riverpod**: Type-safe, more powerful
- **GetX**: Complete solution with services

### 2. Dependency Injection
```dart
final firebaseService = GetIt.instance.get<FirebaseService>();
```

### 3. Clean Architecture
Separate into:
- **Data Layer**: Firestore, shared_preferences
- **Domain Layer**: Use cases, repositories
- **Presentation Layer**: Screens, widgets

### 4. MVVM or BLoC Pattern
```
UI → ViewModel → Service → Firestore
```

### 5. Repository Pattern Enhancement
```dart
abstract class MasjidRepository {
  Future<List<Masjid>> getAllMasjids();
  Stream<List<Masjid>> getMasjidsStream();
  // ...
}

class FirestoreMasjidRepository implements MasjidRepository {
  // Implementation
}
```

## Security & Best Practices

### Currently Implemented
✅ Password validation (minimum 6 characters)
✅ Null safety throughout
✅ Error handling
✅ Proper resource cleanup
✅ Firestore offline persistence

### Recommended for Production
- [ ] Firebase Authentication (not just username/password)
- [ ] Password hashing (bcrypt)
- [ ] Rate limiting on login attempts
- [ ] Two-factor authentication
- [ ] Audit logging
- [ ] Encryption at rest
- [ ] Input sanitization/validation
- [ ] HTTPS enforcement

## Code Organization Principles

### Single Responsibility
Each class has one reason to change:
- `FirebaseService`: Only Firebase operations
- `StorageService`: Only local storage
- `HomeScreen`: Only rendering prayer times
- `AdminPanelScreen`: Only editing times

### DRY (Don't Repeat Yourself)
Common patterns extracted:
- TextEditingController initialization
- Firestore error handling
- UI message display

### Testability
Services are mockable:
```dart
final firebaseService = MockFirebaseService();
final result = await firebaseService.authenticateAdmin('admin1', 'pass123');
```

### Maintainability
- Clear naming conventions
- Comprehensive comments
- Type-safe code
- Null safety enabled

---

This architecture provides a solid foundation for scaling the app while maintaining code quality and performance.
