# Masjid Prayer App - Quick Guide

## 📱 How the App Works

### **Startup Flow:**
1. App starts → **Masjid Selection Screen**
2. User picks a masjid → **Home Screen** (shows prayer times)
3. OR User taps "Admin / Imam?" → **Admin Login Screen**

---

## 🗂️ File Structure (What Each File Does)

### **`lib/main.dart`** - App Entry Point
- Where the app starts
- Sets up the MaterialApp and initializes data
- Simple 5 lines - just loads everything

### **`lib/models/app_data.dart`** - Data Container
- `PrayerTime` class: Stores prayer name and time
- `Masjid` class: Stores masjid info, admin credentials, and prayer times
- `AppData` class: Global storage for selected masjid and all masjids (like a shared "memory")
- Has 3 hardcoded masjids (Central Masjid, New Mosque, Green Valley Mosque)

### **`lib/screens/masjid_selection_screen.dart`** - First Screen
- Shows list of 3 masjids
- User taps a masjid → saves it to AppData → goes to Home Screen
- "Admin / Imam?" button at bottom → goes to Admin Login

### **`lib/screens/home_screen.dart`** - Prayer Times Display
- Shows selected masjid name and location
- Displays all 5 prayer times in a card layout
- Clean, simple UI - no editing here (read-only)

### **`lib/screens/admin_login_screen.dart`** - Admin Login
- Username + Password fields
- Checks credentials against all masjids in AppData
- If correct → saves selected masjid → goes to Admin Panel
- If wrong → shows error message
- Link to Register screen

### **`lib/screens/admin_register_screen.dart`** - Register New Masjid
- 4 text fields: Masjid Name, Location, Username, Password
- Checks if username already exists (simple validation)
- Creates new Masjid and adds it to AppData.allMasjids
- After success, goes back to login screen

### **`lib/screens/admin_panel_screen.dart`** - Edit Prayer Times
- Shows editable text fields for each prayer time
- Admin can change times like "5:30 AM" → "5:45 AM"
- "Save Changes" button updates the times in AppData
- Shows success message

---

## 🔑 Test Credentials (Already Hardcoded)

| Masjid | Username | Password |
|--------|----------|----------|
| Central Masjid | admin1 | pass123 |
| New Mosque | admin2 | pass456 |
| Green Valley Mosque | admin3 | pass789 |

---

## 🚀 How to Use the App

### **As a Regular User:**
1. Tap a masjid name
2. See the prayer times
3. That's it!

### **As an Admin:**
1. Tap "Admin / Imam?" button
2. Login with credentials above
3. Edit prayer times
4. Tap "Save Changes"
5. Changes are saved (in memory - will reset if you close the app)

---

## 💾 Important: Data Storage

- All data is stored in **memory only** (in the `AppData` class)
- If you close the app, changes are **lost**
- Next version can use a real database (SQLite, Firebase, etc.)

---

## 🎨 UI Design

- **Blue theme** for user screens
- **Orange theme** for admin screens
- Uses Material Design 3
- Simple cards for each prayer time
- Easy to read on any phone size

---

## 📝 Code Style

Each file has **comments** explaining what each section does. Good for learning!

Example comment style:
```dart
// This is what happens when user taps the button
Navigator.push(...);
```

---

## ✨ What's Next? (Future Enhancements)

- [ ] Add real database (SQLite or Firebase)
- [ ] Add real prayer time calculation based on location
- [ ] Add notifications for prayer times
- [ ] Add user accounts (save favorite masjids)
- [ ] Add dark mode
- [ ] Add multiple languages

---

## 🐛 Common Issues

**Q: App crashes when I tap a masjid?**
A: Check that AppData.initialize() is called in main.dart

**Q: Admin login not working?**
A: Use the exact username/password from the table above

**Q: Changes don't save?**
A: They DO save - but only while the app is running. Close and reopen = reset.

---

## 🎓 Learning Points

This app teaches you:
- Navigation with Navigator.push()
- StatelessWidget vs StatefulWidget
- TextEditingController for form inputs
- ListView.builder for lists
- Card widgets for UI design
- Simple app state management (AppData class)
- Material Design basics

Enjoy! 🎉
