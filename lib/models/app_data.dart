/// User role enumeration for role-based access control
enum UserRole {
  guest,        // No authentication, read-only access
  verifiedUser, // Can post questions, basic access
  imam,         // Can edit prayer times, answer questions, manage events
  admin,        // Full system access
}

/// Represents an app user with role and authentication info
class User {
  String id;
  String username;
  String? password;
  UserRole role;
  String? masjidId;    // Admin/Imam users are associated with a masjid
  String? masjidName;
  bool isLoggedIn;
  DateTime? lastLogin;
  DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    this.password,
    required this.role,
    this.masjidId,
    this.masjidName,
    this.isLoggedIn = false,
    this.lastLogin,
    this.createdAt,
  });

  /// Check if user has permission to edit content
  bool get canEdit => role == UserRole.admin || role == UserRole.imam;

  /// Check if user has permission to post questions
  bool get canPostQuestion => role != UserRole.guest;

  /// Check if user has permission to answer questions
  bool get canAnswerQuestion => role == UserRole.imam || role == UserRole.admin;

  /// Check if user has permission to manage events
  bool get canManageEvents => role == UserRole.imam || role == UserRole.admin;

  /// Check if user has permission to manage prayer times
  bool get canEditPrayerTimes => role == UserRole.imam || role == UserRole.admin;

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role.toString().split('.').last,
      'masjidId': masjidId,
      'masjidName': masjidName,
      'isLoggedIn': isLoggedIn,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    final roleString = json['role'] as String? ?? 'guest';
    return User(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == roleString,
        orElse: () => UserRole.guest,
      ),
      masjidId: json['masjidId'] as String?,
      masjidName: json['masjidName'] as String?,
      isLoggedIn: json['isLoggedIn'] as bool? ?? false,
      lastLogin: json['lastLogin'] is String
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

/// Represents a single prayer (like Fajr) and its time
class PrayerTime {
  String name;
  String time;

  PrayerTime({required this.name, required this.time});

  /// Convert PrayerTime to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'time': time,
    };
  }

  /// Create PrayerTime from JSON
  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      name: json['name'] as String? ?? '',
      time: json['time'] as String? ?? '',
    );
  }
}

/// Represents a Masjid document in Firestore
class Masjid {
  String id; // Firestore document ID
  String name;
  String location;
  String username; // For admin login
  String password; // For admin login
  List<PrayerTime> prayerTimes;
  String? jummahTime; // Optional Jummah time
  DateTime? lastUpdated;
  double? latitude; // For location-based features
  double? longitude; // For location-based features
  double? distanceFromUser; // Calculated at runtime, not stored

  Masjid({
    this.id = '',
    required this.name,
    required this.location,
    required this.username,
    required this.password,
    required this.prayerTimes,
    this.jummahTime,
    this.lastUpdated,
    this.latitude,
    this.longitude,
    this.distanceFromUser,
  });

  /// Convert Masjid to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'username': username,
      'password': password,
      'prayerTimes': prayerTimes.map((p) => p.toJson()).toList(),
      'jummah': jummahTime,
      'lastUpdated': lastUpdated ?? DateTime.now(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Create Masjid from Firestore document
  factory Masjid.fromFirestore(Map<String, dynamic> data, String docId) {
    final prayerTimesData = data['prayerTimes'] as List? ?? [];
    final prayerTimes = prayerTimesData
        .map((p) => PrayerTime.fromJson(p as Map<String, dynamic>))
        .toList();

    return Masjid(
      id: docId,
      name: data['name'] as String? ?? '',
      location: data['location'] as String? ?? '',
      username: data['username'] as String? ?? '',
      password: data['password'] as String? ?? '',
      prayerTimes: prayerTimes,
      jummahTime: data['jummah'] as String?,
      lastUpdated: data['lastUpdated'] is DateTime
          ? data['lastUpdated'] as DateTime
          : DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Represents a Question posted by a user
class Question {
  String id;
  String userName;
  String questionText;
  String? answer; // Imam's answer (optional, null if not answered yet)
  String masjidId;
  DateTime timestamp;
  bool isAnswered;

  Question({
    required this.id,
    required this.userName,
    required this.questionText,
    required this.masjidId,
    required this.timestamp,
    this.answer,
    this.isAnswered = false,
  });

  /// Convert Question to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'questionText': questionText,
      'answer': answer,
      'masjidId': masjidId,
      'timestamp': timestamp.toIso8601String(),
      'isAnswered': isAnswered,
    };
  }

  /// Create Question from JSON
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Anonymous',
      questionText: json['questionText'] as String? ?? '',
      masjidId: json['masjidId'] as String? ?? '',
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : (json['timestamp'] as DateTime? ?? DateTime.now()),
      answer: json['answer'] as String?,
      isAnswered: json['isAnswered'] as bool? ?? false,
    );
  }
}

/// Represents a Masjid Event (classes, talks, gatherings, etc.)
class Event {
  String id;
  String title;
  String description;
  String masjidId;
  String masjidName;
  DateTime eventDate;
  String startTime; // Format: "2:00 PM"
  String endTime; // Format: "3:30 PM"
  String? location; // Event location (e.g., "Main Hall", "Basement")
  String? category; // Event category (e.g., "Class", "Talk", "Gathering")

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.masjidId,
    required this.masjidName,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    this.location,
    this.category,
  });

  /// Convert Event to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'masjidId': masjidId,
      'masjidName': masjidName,
      'eventDate': eventDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'category': category,
    };
  }

  /// Create Event from JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      masjidId: json['masjidId'] as String? ?? '',
      masjidName: json['masjidName'] as String? ?? '',
      eventDate: json['eventDate'] is String
          ? DateTime.parse(json['eventDate'] as String)
          : (json['eventDate'] as DateTime? ?? DateTime.now()),
      startTime: json['startTime'] as String? ?? '00:00 AM',
      endTime: json['endTime'] as String? ?? '00:00 AM',
      location: json['location'] as String?,
      category: json['category'] as String?,
    );
  }
}

/// Global app state - stores data we need everywhere
class AppData {
  static Masjid? selectedMasjid; // Which masjid the user selected
  static List<Masjid> allMasjids = []; // List of all masjids in the system
  static String? selectedMasjidId; // ID of selected masjid for persistence
  static List<Question> allQuestions = []; // All questions posted by users
  static List<Event> allEvents = []; // All events from all masjids
  
  // User/Role Management
  static User currentUser = User(
    id: 'user_guest',
    username: 'Guest',
    role: UserRole.guest,
    isLoggedIn: false,
  ); // Current logged-in user (default: guest)
  static List<User> allUsers = []; // All app users (admin/imam accounts)

  /// Initialize with 3 hardcoded masjids (for testing without Firebase)
  static void initialize() {
    allMasjids = [
      Masjid(
        id: 'masjid_1',
        name: 'Central Masjid',
        location: 'Downtown',
        username: 'admin1',
        password: 'pass123',
        prayerTimes: [
          PrayerTime(name: 'Fajr', time: '5:30 AM'),
          PrayerTime(name: 'Dhuhr', time: '12:45 PM'),
          PrayerTime(name: 'Asr', time: '3:30 PM'),
          PrayerTime(name: 'Maghrib', time: '6:15 PM'),
          PrayerTime(name: 'Isha', time: '7:45 PM'),
        ],
        jummahTime: '1:00 PM',
      ),
      Masjid(
        id: 'masjid_2',
        name: 'New Mosque',
        location: 'Uptown',
        username: 'admin2',
        password: 'pass456',
        prayerTimes: [
          PrayerTime(name: 'Fajr', time: '5:25 AM'),
          PrayerTime(name: 'Dhuhr', time: '12:50 PM'),
          PrayerTime(name: 'Asr', time: '3:35 PM'),
          PrayerTime(name: 'Maghrib', time: '6:20 PM'),
          PrayerTime(name: 'Isha', time: '7:50 PM'),
        ],
        jummahTime: '1:15 PM',
      ),
      Masjid(
        id: 'masjid_3',
        name: 'Green Valley Mosque',
        location: 'Eastside',
        username: 'admin3',
        password: 'pass789',
        prayerTimes: [
          PrayerTime(name: 'Fajr', time: '5:35 AM'),
          PrayerTime(name: 'Dhuhr', time: '12:40 PM'),
          PrayerTime(name: 'Asr', time: '3:25 PM'),
          PrayerTime(name: 'Maghrib', time: '6:10 PM'),
          PrayerTime(name: 'Isha', time: '7:40 PM'),
        ],
        jummahTime: '12:45 PM',
      ),
    ];

    /// Add sample events for demonstration
    allEvents = [
      Event(
        id: 'evt_1',
        title: 'Qur\'an Recitation Class',
        description: 'Weekly Qur\'an recitation and tajweed class for adults',
        masjidId: 'masjid_1',
        masjidName: 'Central Masjid',
        eventDate: DateTime.now().add(const Duration(days: 2)),
        startTime: '7:00 PM',
        endTime: '8:30 PM',
        location: 'Main Hall',
        category: 'Class',
      ),
      Event(
        id: 'evt_2',
        title: 'Islamic Finance Workshop',
        description: 'Understanding halal investments and Islamic banking',
        masjidId: 'masjid_1',
        masjidName: 'Central Masjid',
        eventDate: DateTime.now().add(const Duration(days: 5)),
        startTime: '2:00 PM',
        endTime: '4:00 PM',
        location: 'Conference Room',
        category: 'Talk',
      ),
      Event(
        id: 'evt_3',
        title: 'Youth Gathering',
        description: 'Social and spiritual gathering for young adults',
        masjidId: 'masjid_2',
        masjidName: 'New Mosque',
        eventDate: DateTime.now().add(const Duration(days: 3)),
        startTime: '6:00 PM',
        endTime: '8:00 PM',
        location: 'Basement',
        category: 'Gathering',
      ),
      Event(
        id: 'evt_4',
        title: 'Hadith Study Circle',
        description: 'Daily Hadith explanation and discussion',
        masjidId: 'masjid_3',
        masjidName: 'Green Valley Mosque',
        eventDate: DateTime.now().add(const Duration(days: 1)),
        startTime: '8:00 PM',
        endTime: '9:00 PM',
        location: 'Prayer Hall',
        category: 'Class',
      ),
    ];
  }

  /// Add a new question posted by a user
  static void addQuestion(String userName, String questionText, String masjidId) {
    final newQuestion = Question(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      userName: userName,
      questionText: questionText,
      masjidId: masjidId,
      timestamp: DateTime.now(),
    );
    allQuestions.add(newQuestion);
  }

  /// Get all questions for a specific masjid
  static List<Question> getQuestionsByMasjid(String masjidId) {
    return allQuestions
        .where((q) => q.masjidId == masjidId)
        .toList()
        .reversed
        .toList(); // Most recent first
  }

  /// Get unanswered questions for a masjid
  static List<Question> getUnansweredQuestions(String masjidId) {
    return allQuestions
        .where((q) => q.masjidId == masjidId && !q.isAnswered)
        .toList()
        .reversed
        .toList(); // Most recent first
  }

  /// Post an answer to a question
  static void answerQuestion(String questionId, String answer) {
    final index = allQuestions.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      allQuestions[index].answer = answer;
      allQuestions[index].isAnswered = true;
    }
  }

  /// Get a question by ID
  static Question? getQuestionById(String questionId) {
    try {
      return allQuestions.firstWhere((q) => q.id == questionId);
    } catch (e) {
      return null;
    }
  }

  /// Add a new event
  static void addEvent(Event event) {
    allEvents.add(event);
  }

  /// Get all events for a specific masjid
  static List<Event> getEventsByMasjid(String masjidId) {
    return allEvents
        .where((e) => e.masjidId == masjidId)
        .toList()
        .reversed
        .toList(); // Most recent first
  }

  /// Get all upcoming events sorted by date
  static List<Event> getUpcomingEvents() {
    final now = DateTime.now();
    return allEvents
        .where((e) => e.eventDate.isAfter(now))
        .toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  /// Get events sorted by distance from selected masjid
  static List<Event> getEventsSortedByDistance() {
    if (selectedMasjid == null) return getUpcomingEvents();
    return getUpcomingEvents();  // Can be enhanced with actual distance calculation later
  }

  // ============ User/Role Management Methods ============

  /// Initialize admin/imam users for each masjid
  static void initializeUsers() {
    allUsers = [
      User(
        id: 'admin_masjid_1',
        username: 'admin1',
        password: 'pass123',
        role: UserRole.imam,
        masjidId: 'masjid_1',
        masjidName: 'Central Masjid',
        createdAt: DateTime.now(),
      ),
      User(
        id: 'admin_masjid_2',
        username: 'admin2',
        password: 'pass456',
        role: UserRole.imam,
        masjidId: 'masjid_2',
        masjidName: 'New Mosque',
        createdAt: DateTime.now(),
      ),
      User(
        id: 'admin_masjid_3',
        username: 'admin3',
        password: 'pass789',
        role: UserRole.imam,
        masjidId: 'masjid_3',
        masjidName: 'Green Valley Mosque',
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// Login user - return true if credentials are valid
  static bool login(String username, String password) {
    try {
      final user = allUsers.firstWhere(
        (u) => u.username == username && u.password == password,
      );
      currentUser = user;
      currentUser.isLoggedIn = true;
      currentUser.lastLogin = DateTime.now();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout current user
  static void logout() {
    currentUser = User(
      id: 'user_guest',
      username: 'Guest',
      role: UserRole.guest,
      isLoggedIn: false,
    );
  }

  /// Change password for a user
  static bool changePassword(String username, String oldPassword, String newPassword) {
    try {
      final userIndex = allUsers.indexWhere(
        (u) => u.username == username && u.password == oldPassword,
      );
      if (userIndex != -1) {
        allUsers[userIndex].password = newPassword;
        // If this is the current user, update their password too
        if (currentUser.username == username) {
          currentUser.password = newPassword;
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get user by username
  static User? getUserByUsername(String username) {
    try {
      return allUsers.firstWhere((u) => u.username == username);
    } catch (e) {
      return null;
    }
  }

  /// Get all users for a specific masjid
  static List<User> getUsersByMasjid(String masjidId) {
    return allUsers.where((u) => u.masjidId == masjidId).toList();
  }
}
