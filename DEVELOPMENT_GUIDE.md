# Masjid App - Developer Instructions & Maintenance Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Project Structure](#project-structure)
3. [Common Tasks](#common-tasks)
4. [Adding Features](#adding-features)
5. [Managing Translations](#managing-translations)
6. [Debugging & Troubleshooting](#debugging--troubleshooting)
7. [Building & Deployment](#building--deployment)
8. [Best Practices](#best-practices)

---

## Getting Started

### Prerequisites
- Flutter SDK: `^3.9.0`
- Dart SDK: `^3.9.0`
- IDE: VS Code or Android Studio with Flutter extension
- Git for version control

### Initial Setup
```bash
# Clone the repository
git clone [repo-url] masjid_app
cd masjid_app

# Install dependencies
flutter pub get

# Generate localization (if needed)
flutter pub run intl_utils:generate

# Run the app
flutter run -d chrome      # For web development
flutter run -d android     # For Android device
flutter run -d ios         # For iOS device
```

### Quick Test
```bash
# Run on Chrome (recommended for development)
flutter run -d chrome

# Run analysis
flutter analyze

# Format code
dart format lib/
```

---

## Project Structure Explained

### `/lib` Directory Organization

```
lib/
├── main.dart                     # App entry point, initialization
│                                 # - Locale initialization
│                                 # - Service initialization
│                                 # - Theme/Localization setup
│
├── l10n/                         # Localization files
│   ├── app_translations.dart     # Translation strings (English/Urdu)
│   └── app_localization.dart     # Locale manager & provider
│
├── theme/                        # Theme management
│   ├── app_theme.dart            # Light/Dark theme definitions
│   └── app_state.dart            # Theme state (ChangeNotifier)
│
├── models/                       # Data models
│   └── app_data.dart             # All data models & sample data
│
├── services/                     # Business logic & external APIs
│   ├── firebase_service.dart     # Firebase/Firestore operations
│   ├── storage_service.dart      # SharedPreferences wrapper
│   ├── location_service.dart     # GPS/geolocator wrapper
│   └── prayer_time_service.dart  # Prayer time calculations
│
├── screens/                      # Page/Screen widgets
│   ├── masjid_selection_screen.dart
│   ├── main_navigation_screen.dart
│   ├── prayer_page.dart          # Currently: shows prayer times + countdown
│   ├── community_page.dart       # Currently: search + categories + events
│   ├── questions_page.dart
│   ├── settings_page.dart        # Currently: language switching + dark mode
│   ├── admin_login_screen.dart
│   ├── admin_register_screen.dart
│   ├── admin_panel_screen.dart
│   └── ask_question_screen.dart
│
└── widgets/                      # Reusable UI components
    ├── event_search_bar.dart     # Search bar for events
    ├── category_slider.dart      # Horizontal category selector
    └── enhanced_event_card.dart  # Improved event card display
```

### Key Directories

| Directory | Purpose | Files Modified |
|-----------|---------|-----------------|
| `lib/l10n/` | Language support | Add new translations here |
| `lib/theme/` | Visual styling | Update colors/fonts here |
| `lib/models/` | Data classes | Add new models in app_data.dart |
| `lib/screens/` | Full-page widgets | Add new pages here |
| `lib/widgets/` | Reusable components | Add new components here |

---

## Common Tasks

### 1. Add a New Translation

**Location**: `lib/l10n/app_translations.dart`

**Steps**:
```dart
// In the _translations map, find the 'en' dictionary
static const Map<String, Map<String, String>> _translations = {
  'en': {
    // ... existing translations ...
    'my_new_key': 'My English Text',      // Add here
  },
  'ur': {
    // ... existing Urdu translations ...
    'my_new_key': 'میرا اردو متن',        // Add corresponding Urdu
  },
};
```

**Usage in code**:
```dart
// Get the translated string
final translated = appLocalization.t('my_new_key');

// Or in a widget
Text(appLocalization.translations.t('my_new_key'))
```

### 2. Change App Colors

**Location**: `lib/theme/app_theme.dart`

**Steps**:
```dart
class AppTheme {
  // Update these constants
  static const Color deepEmerald = Color(0xFF1B5E47);    // Primary
  static const Color softCream = Color(0xFFFAF7F2);      // Background
  static const Color brushGold = Color(0xFFD4A574);      // Accent

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: deepEmerald,        // Change primary color
      // ... other color schemes
    ),
  );
}
```

### 3. Add a New Screen

**Steps**:
1. Create file: `lib/screens/my_new_screen.dart`
2. Create StatefulWidget or StatelessWidget
3. Import in `main_navigation_screen.dart` or appropriate parent
4. Add navigation route

**Example template**:
```dart
import 'package:flutter/material.dart';
import '../l10n/app_localization.dart';

class MyNewScreen extends StatefulWidget {
  const MyNewScreen({Key? key}) : super(key: key);

  @override
  State<MyNewScreen> createState() => _MyNewScreenState();
}

class _MyNewScreenState extends State<MyNewScreen> {
  @override
  Widget build(BuildContext context) {
    final translations = appLocalization.translations;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(translations.t('screen_title')),
      ),
      body: Center(
        child: Text('Content here'),
      ),
    );
  }
}
```

### 4. Add a New Data Model

**Location**: `lib/models/app_data.dart`

**Steps**:
```dart
// Add your class to app_data.dart
class MyModel {
  String id;
  String name;
  DateTime createdAt;

  MyModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  // Add toJson() for Firebase serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Add fromJson() for deserialization
  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

// Add to AppData class
class AppData {
  static List<MyModel> allMyModels = [];

  static void initialize() {
    // Initialize sample data
    allMyModels = [
      MyModel(id: '1', name: 'Sample', createdAt: DateTime.now()),
    ];
  }
}
```

### 5. Use Dark Mode & Language in Widgets

```dart
// Dark Mode Check
if (appStateProvider.isDarkMode) {
  // Dark mode UI
} else {
  // Light mode UI
}

// Language Check & Translation
Text(appLocalization.t('key_name'))

// Check if RTL (Right-to-Left for Urdu)
if (appLocalization.isRTL) {
  // RTL layout
} else {
  // LTR layout
}
```

### 6. Add Firebase Integration

**Location**: `lib/services/firebase_service.dart`

**Prerequisite**: Firebase project setup and `google-services.json`/`GoogleService-Info.plist`

**Example**:
```dart
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<List<MyModel>> getMyModels() async {
    try {
      final snapshot = await _firestore.collection('my_collection').get();
      return snapshot.docs
          .map((doc) => MyModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching: $e');
      return [];
    }
  }
}
```

---

## Adding Features

### Example: Add Event Filtering by Date Range

**File**: `lib/screens/community_page.dart`

```dart
class _CommunityPageState extends State<CommunityPage> {
  String _filterType = 'upcoming';
  String _selectedCategory = 'all';
  String _searchQuery = '';
  DateTimeRange? _dateRange;  // Add date filter

  List<Event> _getFilteredEvents() {
    // ... existing filters ...

    // Add date range filter
    if (_dateRange != null) {
      events = events.where((event) {
        return event.eventDate.isAfter(_dateRange!.start) &&
               event.eventDate.isBefore(_dateRange!.end);
      }).toList();
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... existing code ...
      body: Column(
        children: [
          // Add date picker button
          ElevatedButton(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _dateRange = picked);
              }
            },
            child: Text('Filter by Date'),
          ),
          // ... rest of UI ...
        ],
      ),
    );
  }
}
```

---

## Managing Translations

### Workflow for Adding Languages

1. **Edit `app_translations.dart`**:
   - Add new language code to `_translations` map
   - Translate all keys from English

2. **Update `app_localization.dart`** (if needed):
   - Add language validation logic

3. **Update UI for language selection**:
   - Edit `settings_page.dart` `_LanguageTile`

4. **Test**:
   - Switch language in Settings
   - Verify all UI updates

### Current Languages
- **'en'**: English (LTR - Left to Right)
- **'ur'**: اردو (RTL - Right to Left)

### Adding Urdu (Example)
```dart
'ur': {
  'select_masjid': 'مسجد منتخب کریں',
  'prayer_times': 'نماز کے اوقات',
  'community': 'کمیونٹی',
  // ... all keys translated to Urdu
}
```

---

## Debugging & Troubleshooting

### Common Issues & Solutions

#### Issue 1: "Language not changing"
**Cause**: Language provider not rebuilding UI
**Solution**:
```dart
// Ensure widget is listening to appLocalization changes
ListenableBuilder(
  listenable: appLocalization,
  builder: (context, child) {
    return MyWidget();  // Will rebuild on language change
  },
)
```

#### Issue 2: "Theme not persisting"
**Cause**: SharedPreferences not initialized
**Solution**: Ensure `appStateProvider` initialization in `main()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize theme provider
  await appStateProvider.initialize();  // Add this
  runApp(MyApp());
}
```

#### Issue 3: "Firebase not connecting"
**Cause**: Google services not configured
**Solution**:
- Download `google-services.json` from Firebase Console
- Place in `android/app/`
- Add to `android/app/build.gradle`

#### Issue 4: "GPS not working"
**Cause**: Permissions not granted
**Solution**: Test with `geolocator` permissions:
```dart
LocationPermission permission = await Geolocator.requestPermission();
if (permission == LocationPermission.denied) {
  // Handle denied
}
```

#### Issue 5: "Events not showing in search"
**Cause**: Search query formatting
**Solution**: Check search filter logic in `_getFilteredEvents()`

### Debug Commands

```bash
# Run with verbose logging
flutter run -v

# Clear all build artifacts
flutter clean

# Rebuild with no cache
flutter clean && flutter pub get && flutter run -d chrome

# Check for lint issues
flutter analyze

# Format code
dart format lib/

# Profile app performance
flutter run --profile
```

---

## Building & Deployment

### Web Build
```bash
# Build for web
flutter build web

# Serve locally
flutter run -d chrome

# Release build
flutter build web --release
```

### Android Build
```bash
# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build AAB (for Play Store)
flutter build appbundle --release
```

### iOS Build
```bash
# Build for iOS
flutter build ios --release

# Create IPA
cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release
```

### Push to Play Store/App Store
1. Prepare release files (APK/AAB or IPA)
2. Create app store accounts
3. Upload via respective console
4. Follow platform-specific guidelines

---

## Best Practices

### Code Style
✅ **DO**:
- Use meaningful variable names: `userLocation` not `ul`
- Add comments for complex logic
- Use const constructors: `const Text('Label')`
- Keep functions focused on single responsibility
- Use `final` for immutable variables

❌ **DON'T**:
- Use single-letter variables: `x`, `i` (except in loops)
- Add redundant comments
- Hard-code strings (use translations)
- Create deep widget nesting (extract to separate methods)

### Performance
✅ **DO**:
- Use `const` widgets where possible
- Implement `shouldRebuild` in custom notifiers
- Cache expensive computations
- Use `ListView.builder()` for long lists
- Lazy-load images and data

❌ **DON'T**:
- Rebuild entire screen on minor state change
- Load all data at once (paginate)
- Keep Large objects in memory
- Perform network calls in `build()`

### Organization
✅ **DO**:
- Group related classes in same file
- Keep screen files focused
- Put reusable widgets in `widgets/` folder
- Use meaningful folder structure
- Document complex functions

❌ **DON'T**:
- Mix models, screens, widgets in one file
- Create unnecessary abstraction layers
- Forget to add comments for non-obvious logic
- Leave dead/unused code

### Testing
✅ **DO**:
- Write unit tests for business logic
- Test state management changes
- Test widget renders correctly
- Verify translations work

❌ **DON'T**:
- Skip testing complex screens
- Hardcode test data
- Leave debugPrint() statements
- Test implementation details

---

## Maintenance Schedule

### Daily
- Check logs for errors
- Monitor user feedback

### Weekly
- Run `flutter analyze`
- Review code quality
- Update dependencies if patches available

### Monthly
- Backup Firebase data
- Review analytics
- Plan next features
- Update documentation

### Quarterly
- Major dependency updates
- Security audit
- Performance optimization
- User feedback review

---

## Quick Reference - Key Exports

```dart
// Language & Translation
import 'package:app/l10n/app_localization.dart';
appLocalization.t('key')              // Get translation
appLocalization.locale               // Current language
appLocalization.isRTL                // Check if RTL

// Theme
import 'package:app/theme/app_state.dart';
appStateProvider.isDarkMode           // Check dark mode
appStateProvider.toggleDarkMode()    // Toggle theme

// Data
import 'package:app/models/app_data.dart';
AppData.selectedMasjid               // Get selected masjid
AppData.allEvents                    // Get all events

// Firebase
import 'package:app/services/firebase_service.dart';
FirebaseService().getMasjids()       // Get masjids from Firebase
FirebaseService().getMasjidStream()  // Real-time updates
```

---

## Contact & Support

For issues, questions, or feature requests:
- Create GitHub issues
- Comment code with questions
- Document any custom modifications
- Keep this guide updated

---

**Last Updated**: May 4, 2026  
**Version**: 1.0  
**Maintained By**: Development Team
