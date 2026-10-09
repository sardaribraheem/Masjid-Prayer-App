import 'package:flutter_test/flutter_test.dart';
import 'package:masjid_app/models/app_data.dart';

void main() {
  group('masjid management access', () {
    test('imam linked to the selected masjid can manage it', () {
      final user = User(
        id: 'uid-1',
        username: 'Imam User',
        email: 'imam@example.com',
        role: UserRole.imam,
        masjidId: 'masjid-1',
        isLoggedIn: true,
      );

      expect(user.canManageMasjid('masjid-1'), isTrue);
    });

    test('plain muqtaddi cannot manage a masjid without imam linkage', () {
      final user = User(
        id: 'uid-2',
        username: 'Normal User',
        email: 'user@example.com',
        role: UserRole.muqtaddi,
        masjidId: null,
        isLoggedIn: true,
      );

      expect(user.canManageMasjid('masjid-1'), isFalse);
    });
  });

  group('question posting rules', () {
    test('anonymous question records hidden author metadata and display label', () {
      final question = Question(
        id: 'question-1',
        userName: 'Anonymous',
        questionText: 'Is the class tomorrow?',
        masjidId: 'masjid-1',
        timestamp: DateTime(2026, 9, 29),
        createdByUid: 'uid-123',
        isAnonymous: true,
      );

      final json = question.toJson();
      expect(json['isAnonymous'], isTrue);
      expect(json['createdByUid'], 'uid-123');
      expect(question.displayName, 'Anonymous');

      final restored = Question.fromJson(json);
      expect(restored.isAnonymous, isTrue);
      expect(restored.createdByUid, 'uid-123');
    });
  });

  group('event approval pipeline', () {
    test('newly submitted events default to pending and are not public until approved', () {
      final event = Event(
        id: 'event-1',
        title: 'Community Talk',
        description: 'Talk about Ramadan',
        masjidId: 'masjid-1',
        masjidName: 'Hassan Masjid',
        eventDate: DateTime(2026, 10, 1),
        startTime: '7:00 PM',
        endTime: '8:00 PM',
      );

      expect(event.status, EventStatus.pending);
      expect(event.isApproved, isFalse);
    });

    test('legacy question media is excluded from writes while event media remains compatible', () {
      final question = Question(
        id: 'question-2',
        userName: 'User One',
        questionText: 'Can we share the Qurani lecture poster?',
        masjidId: 'masjid-1',
        timestamp: DateTime(2026, 9, 29),
        mediaUrl: 'https://example.com/poster.jpg',
        mediaType: 'image',
      );

      final event = Event(
        id: 'event-2',
        title: 'Lecture Poster',
        description: 'Poster for the youth lecture',
        masjidId: 'masjid-1',
        masjidName: 'Hassan Masjid',
        eventDate: DateTime(2026, 10, 2),
        startTime: '6:30 PM',
        endTime: '8:00 PM',
        mediaUrl: 'https://example.com/lecture.mp4',
        mediaType: 'video',
      );

      expect(question.hasMedia, isTrue);
      expect(question.mediaType, 'image');
      expect(event.hasMedia, isTrue);
      expect(event.mediaType, 'video');

      final restoredQuestion = Question.fromJson(question.toJson());
      final restoredEvent = Event.fromJson(event.toJson());
      expect(question.toJson().containsKey('mediaUrl'), isFalse);
      expect(restoredQuestion.mediaUrl, isNull);
      expect(restoredEvent.mediaUrl, 'https://example.com/lecture.mp4');
    });
  });

  group('verification request lifecycle', () {
    test('a regular muqtaddi can request verification and the status updates to pending', () {
      final user = User(
        id: 'uid-3',
        username: 'New Member',
        email: 'member@example.com',
        role: UserRole.muqtaddi,
        verificationStatus: VerificationStatus.none,
        masjidId: 'masjid-1',
      );

      final requested = user.requestVerification();
      expect(requested.verificationStatus, VerificationStatus.pending);
      expect(requested.role, UserRole.muqtaddi);
      expect(requested.canSubmitEvents, isFalse);

      final approved = requested.updateVerificationStatus(VerificationStatus.approved);
      expect(approved.verificationStatus, VerificationStatus.approved);
      expect(approved.role, UserRole.verifiedMuqtaddi);
      expect(approved.canSubmitEvents, isTrue);
    });
  });
}
