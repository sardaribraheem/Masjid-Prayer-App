/// User role enumeration for role-based access control.
///
/// Mirrors `latesttodo.md` §3 — there are two separate tracks:
///   Normal Muqtaddi → Verification Request → Verified Muqtaddi
///        (event approval-required OR full event permission)
/// and separately: Imam / Admin.
/// `superadmin` lives in Firebase Auth custom claims, not in the Firestore
/// `users/{uid}` document.
enum UserRole {
  guest,
  muqtaddi,
  verifiedMuqtaddi,
  imam,
  admin;

  String get value => switch (this) {
        UserRole.guest => 'guest',
        UserRole.muqtaddi => 'muqtaddi',
        UserRole.verifiedMuqtaddi => 'verified_muqtaddi',
        UserRole.imam => 'imam',
        UserRole.admin => 'admin',
      };

  static UserRole fromValue(String? v) {
    for (final role in UserRole.values) {
      if (role.value == v) return role;
    }
    return UserRole.guest;
  }
}

/// Verification status of a muqtaddi (`latesttodo.md` §2).
/// `none`      — not applied (default for new accounts)
/// `pending`   — verification requested, awaiting admin/imam review
/// `approved`  — verified muqtaddi
/// `rejected`  — request denied (may re-apply)
enum VerificationStatus {
  none,
  pending,
  approved,
  rejected;

  String get value => switch (this) {
        VerificationStatus.none => 'none',
        VerificationStatus.pending => 'pending',
        VerificationStatus.approved => 'approved',
        VerificationStatus.rejected => 'rejected',
      };

  static VerificationStatus fromValue(String? v) {
    for (final s in VerificationStatus.values) {
      if (s.value == v) return s;
    }
    return VerificationStatus.none;
  }
}

/// Event-posting permission for a verified muqtaddi (`latesttodo.md` §3).
/// Kept separate from verification: being verified does NOT grant any of
/// these automatically.
enum EventPermission {
  none,
  approvalRequired,
  full;

  String get value => switch (this) {
        EventPermission.none => 'none',
        EventPermission.approvalRequired => 'approval_required',
        EventPermission.full => 'full',
      };

  static EventPermission fromValue(String? v) {
    for (final p in EventPermission.values) {
      if (p.value == v) return p;
    }
    return EventPermission.none;
  }
}

/// Represents an app user with role, verification and authentication info.
///
/// The Firestore document for a user lives at `users/{uid}` and is the
/// source of truth for `role`, `verificationStatus` and `eventPermission`.
/// `password` is NEVER stored — Firebase Auth owns credentials (`§10`).
class User {
  String id; // Firebase Auth UID
  String username; // Display name
  String email;
  UserRole role;
  VerificationStatus verificationStatus;
  EventPermission eventPermission;
  String? masjidId; // Associated masjid (if any)
  String? masjidName;
  bool isLoggedIn;
  DateTime? lastLogin;
  DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    this.email = '',
    required this.role,
    this.verificationStatus = VerificationStatus.none,
    this.eventPermission = EventPermission.none,
    this.masjidId,
    this.masjidName,
    this.isLoggedIn = false,
    this.lastLogin,
    this.createdAt,
  });

  /// Is this user an admin/imam (management track)?
  bool get isAdminOrImam =>
      role == UserRole.admin || role == UserRole.imam;

  /// Validates whether this user is the authorized manager of the selected
  /// masjid. We do not trust client-side role strings alone; the `users/{uid}`
  /// doc must also point to the matching masjid ID.
  bool canManageMasjid(String? masjidId) {
    if (masjidId == null || masjidId.isEmpty) return false;
    if (!isAdminOrImam) return false;
    return masjidId == this.masjidId;
  }

  /// Is this user verified?
  bool get isVerified => verificationStatus == VerificationStatus.approved;

  /// Request verification for this user. Verification status changes from
  /// `none` to `pending`; the user remains a plain muqtaddi until an imam/admin
  /// approves the request.
  User requestVerification() {
    if (role == UserRole.guest || role == UserRole.imam || role == UserRole.admin) {
      return this;
    }

    return User(
      id: id,
      username: username,
      email: email,
      role: UserRole.muqtaddi,
      verificationStatus: VerificationStatus.pending,
      eventPermission: eventPermission,
      masjidId: masjidId,
      masjidName: masjidName,
      isLoggedIn: isLoggedIn,
      lastLogin: lastLogin,
      createdAt: createdAt,
    );
  }

  /// Update verification status after imam/admin review.
  User updateVerificationStatus(VerificationStatus status) {
    if (role == UserRole.guest || role == UserRole.imam || role == UserRole.admin) {
      return this;
    }

    final nextRole = status == VerificationStatus.approved
        ? UserRole.verifiedMuqtaddi
        : UserRole.muqtaddi;

    return User(
      id: id,
      username: username,
      email: email,
      role: nextRole,
      verificationStatus: status,
      eventPermission: status == VerificationStatus.approved
          ? EventPermission.approvalRequired
          : EventPermission.none,
      masjidId: masjidId,
      masjidName: masjidName,
      isLoggedIn: isLoggedIn,
      lastLogin: lastLogin,
      createdAt: createdAt,
    );
  }

  /// Check if user has permission to post questions
  bool get canPostQuestion => role != UserRole.guest;

  /// Check if user has permission to answer questions
  bool get canAnswerQuestion => isAdminOrImam;

  /// Check if user has permission to manage (create/edit/delete) any event
  bool get canManageEvents => isAdminOrImam;

  /// Check if user has permission to edit prayer times
  bool get canEditPrayerTimes => isAdminOrImam;

  /// Can submit events at all (never public for plain muqtaddis/guests).
  bool get canSubmitEvents =>
      isAdminOrImam || (role == UserRole.verifiedMuqtaddi && isVerified);

  /// Can publish an event directly without individual approval.
  /// Verified muqtaddis need `EventPermission.full` (granted by admin).
  bool get canPublishEventsDirectly =>
      isAdminOrImam ||
      (role == UserRole.verifiedMuqtaddi &&
          isVerified &&
          eventPermission == EventPermission.full);

  /// Convert User to a Firestore `users/{uid}` document.
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'role': role.value,
      'verificationStatus': verificationStatus.value,
      'eventPermission': eventPermission.value,
      'masjidId': masjidId,
      'masjidName': masjidName,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Create User from a Firestore `users/{uid}` document.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromValue(json['role'] as String?),
      verificationStatus: VerificationStatus.fromValue(
        json['verificationStatus'] as String?,
      ),
      eventPermission: EventPermission.fromValue(
        json['eventPermission'] as String?,
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

/// Represents a single prayer (like Fajr) and its time.
class PrayerTime {
  String name; // English name, e.g. "Fajr"
  String nameUrdu; // Urdu name, e.g. "فجر"
  String time; // e.g. "5:30 AM"

  PrayerTime({required this.name, required this.time, this.nameUrdu = ''});

  /// Convert PrayerTime to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameUrdu': nameUrdu,
      'time': time,
    };
  }

  /// Create PrayerTime from JSON
  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      name: json['name'] as String? ?? '',
      nameUrdu: json['nameUrdu'] as String? ?? '',
      time: json['time'] as String? ?? '',
    );
  }
}

/// Represents a Masjid document in Firestore.
class Masjid {
  String id; // Firestore document ID
  String name; // English name
  String nameUrdu; // Urdu name (§7)
  String location;
  String username; // Legacy admin-login identifier (not a credential)
  List<PrayerTime> prayerTimes;
  String? jummahTime; // Optional Jummah time
  DateTime? lastUpdated;
  String? creatorUid;
  List<String> authorizedImamUids;
  bool isVerified;
  double? latitude; // For location-based features
  double? longitude; // For location-based features
  double? distanceFromUser; // Calculated at runtime, not stored

  Masjid({
    this.id = '',
    required this.name,
    this.nameUrdu = '',
    required this.location,
    this.username = '',
    required this.prayerTimes,
    this.jummahTime,
    this.lastUpdated,
    this.creatorUid,
    this.authorizedImamUids = const [],
    this.isVerified = false,
    this.latitude,
    this.longitude,
    this.distanceFromUser,
  });

  /// Convert Masjid to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameUrdu': nameUrdu,
      'location': location,
      'username': username,
      'prayerTimes': prayerTimes.map((p) => p.toJson()).toList(),
      'jummah': jummahTime,
      'lastUpdated': lastUpdated ?? DateTime.now(),
      'creatorUid': creatorUid,
      'authorizedImamUids': authorizedImamUids,
      'isVerified': isVerified,
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
      nameUrdu: data['nameUrdu'] as String? ?? '',
      location: data['location'] as String? ?? '',
      username: data['username'] as String? ?? '',
      prayerTimes: prayerTimes,
      jummahTime: data['jummah'] as String?,
      lastUpdated: data['lastUpdated'] is DateTime
          ? data['lastUpdated'] as DateTime
          : DateTime.now(),
      creatorUid: data['creatorUid'] as String?,
      authorizedImamUids: ((data['authorizedImamUids'] as List?) ?? [])
          .map((item) => item.toString())
          .toList(),
      isVerified: data['isVerified'] as bool? ?? false,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Represents a Question posted by a user.
class Question {
  String id;
  String userName;
  String questionText;
  String? answer; // Imam's answer (optional, null if not answered yet)
  String masjidId;
  DateTime timestamp;
  bool isAnswered;
  bool isAnonymous;
  String? createdByUid;
  String? mediaUrl;
  String? mediaType;

  Question({
    required this.id,
    required this.userName,
    required this.questionText,
    required this.masjidId,
    required this.timestamp,
    this.answer,
    this.isAnswered = false,
    this.isAnonymous = false,
    this.createdByUid,
    this.mediaUrl,
    this.mediaType,
  });

  /// Public display label shown in the UI. Anonymous posts are hidden from
  /// public viewers but still stored with the creator UID for moderation.
  String get displayName => isAnonymous ? 'Anonymous' : userName;

  bool get hasMedia => mediaUrl != null && mediaUrl!.trim().isNotEmpty;

  bool get isImageMedia {
    if (mediaType == 'image') return true;
    final normalized = (mediaUrl ?? '').toLowerCase();
    return normalized.endsWith('.png') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.gif') ||
        normalized.endsWith('.webp');
  }

  bool get isVideoMedia {
    if (mediaType == 'video') return true;
    final normalized = (mediaUrl ?? '').toLowerCase();
    return normalized.endsWith('.mp4') ||
        normalized.endsWith('.mov') ||
        normalized.endsWith('.avi') ||
        normalized.endsWith('.webm');
  }

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
      'isAnonymous': isAnonymous,
      'createdByUid': createdByUid,
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
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      createdByUid: json['createdByUid'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
    );
  }
}

/// Publication status of an event (`latesttodo.md` §3/§8).
/// Only `approved` events are publicly visible.
enum EventStatus {
  pending,
  approved,
  rejected;

  String get value => switch (this) {
        EventStatus.pending => 'pending',
        EventStatus.approved => 'approved',
        EventStatus.rejected => 'rejected',
      };

  static EventStatus fromValue(String? v) {
    for (final s in EventStatus.values) {
      if (s.value == v) return s;
    }
    return EventStatus.approved; // Backwards-compatible default for old docs
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
  String? category; // Event category (e.g., "Class", "Talk", "Jammat")
  String? mediaUrl;
  String? mediaType;
  EventStatus status; // pending/approved/rejected — only approved is public
  String? createdByUid;
  String? createdByName;

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
    this.mediaUrl,
    this.mediaType,
    this.status = EventStatus.pending,
    this.createdByUid,
    this.createdByName,
  });

  bool get isApproved => status == EventStatus.approved;

  bool get hasMedia => mediaUrl != null && mediaUrl!.trim().isNotEmpty;

  bool get isImageMedia {
    if (mediaType == 'image') return true;
    final normalized = (mediaUrl ?? '').toLowerCase();
    return normalized.endsWith('.png') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.gif') ||
        normalized.endsWith('.webp');
  }

  bool get isVideoMedia {
    if (mediaType == 'video') return true;
    final normalized = (mediaUrl ?? '').toLowerCase();
    return normalized.endsWith('.mp4') ||
        normalized.endsWith('.mov') ||
        normalized.endsWith('.avi') ||
        normalized.endsWith('.webm');
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? masjidId,
    String? masjidName,
    DateTime? eventDate,
    String? startTime,
    String? endTime,
    String? location,
    String? category,
    String? mediaUrl,
    String? mediaType,
    EventStatus? status,
    String? createdByUid,
    String? createdByName,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      masjidId: masjidId ?? this.masjidId,
      masjidName: masjidName ?? this.masjidName,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      category: category ?? this.category,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByName: createdByName ?? this.createdByName,
    );
  }

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
      'mediaUrl': mediaUrl,
      'mediaType': mediaType ?? (isImageMedia ? 'image' : (isVideoMedia ? 'video' : null)),
      'status': status.value,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
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
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      status: EventStatus.fromValue(json['status'] as String?),
      createdByUid: json['createdByUid'] as String?,
      createdByName: json['createdByName'] as String?,
    );
  }
}

/// Global app state - stores data we need everywhere.
///
/// NOTE: `AppData` is a static cache. Firebase is the single source of truth;
/// these lists are hydrated from Firestore and must NOT contain hardcoded
/// sample data (`latesttodo.md` §1).
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

  /// Add a new question posted by a user
  static void addQuestion(
    String userName,
    String questionText,
    String masjidId, {
    String? createdByUid,
    bool isAnonymous = false,
    String? mediaUrl,
    String? mediaType,
  }) {
    final newQuestion = Question(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      userName: isAnonymous ? 'Anonymous' : userName,
      questionText: questionText,
      masjidId: masjidId,
      timestamp: DateTime.now(),
      isAnonymous: isAnonymous,
      createdByUid: createdByUid,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
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
    return getUpcomingEvents(); // Can be enhanced with actual distance calculation later
  }

  /// Reset the current user to the guest default (used on logout).
  static void logout() {
    currentUser = User(
      id: 'user_guest',
      username: 'Guest',
      role: UserRole.guest,
      isLoggedIn: false,
    );
  }
}