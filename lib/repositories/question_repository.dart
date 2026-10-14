import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_data.dart';

/// Repository for Question CRUD operations in Firestore.
/// Questions are stored as a subcollection under each masjid document.
class QuestionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a stream of questions for a specific masjid
  Stream<List<Question>> getQuestionsStream(String masjidId) {
    return _firestore
        .collection('masjids')
        .doc(masjidId)
        .collection('questions')
        .orderBy('timestamp', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(31)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Question.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  /// Fetch questions once (for static display or admin panel)
  Future<List<Question>> getQuestions(
    String masjidId, {
    Question? after,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('masjids')
          .doc(masjidId)
          .collection('questions')
          .orderBy('timestamp', descending: true)
          .orderBy(FieldPath.documentId, descending: true);
      if (after != null) {
        query = query.startAfter([after.timestamp.toIso8601String(), after.id]);
      }
      final snapshot = await query.limit(31).get();
      return snapshot.docs
          .map((doc) => Question.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      rethrow;
    }
  }

  /// Add a new question to a masjid's subcollection
  Future<bool> addQuestion(Question question) async {
    try {
      final doc = _firestore
          .collection('masjids')
          .doc(question.masjidId)
          .collection('questions')
          .doc();
      await doc.set({...question.toJson(), 'id': doc.id});
      return true;
    } catch (e) {
      debugPrint('Error adding question: $e');
      return false;
    }
  }

  /// Update an answer for a question
  Future<bool> answerQuestion(
    String masjidId,
    String questionId,
    String answer,
  ) async {
    try {
      await _firestore
          .collection('masjids')
          .doc(masjidId)
          .collection('questions')
          .doc(questionId)
          .update({'answer': answer, 'isAnswered': true});
      return true;
    } catch (e) {
      debugPrint('Error answering question: $e');
      return false;
    }
  }

  /// Delete a question
  Future<bool> deleteQuestion(String masjidId, String questionId) async {
    try {
      final post = _firestore
          .collection('masjids')
          .doc(masjidId)
          .collection('questions')
          .doc(questionId);
      await post.update({'isDeleting': true});
      while (true) {
        final comments = await post.collection('comments').limit(100).get();
        if (comments.docs.isEmpty) break;
        final batch = _firestore.batch();
        for (final comment in comments.docs) {
          batch.delete(comment.reference);
        }
        await batch.commit();
      }
      await post.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting question: $e');
      return false;
    }
  }
}
