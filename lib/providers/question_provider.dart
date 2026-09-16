import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../repositories/question_repository.dart';

/// ChangeNotifier provider for questions data.
/// Wraps QuestionRepository and provides reactive state for the UI.
class QuestionProvider extends ChangeNotifier {
  final QuestionRepository _repository = QuestionRepository();

  StreamSubscription<List<Question>>? _streamSub;

  List<Question> _questions = [];
  bool _isLoading = false;
  String? _error;

  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get questions filtered by masjid ID
  List<Question> getQuestionsByMasjid(String masjidId) {
    return _questions.where((q) => q.masjidId == masjidId).toList();
  }

  /// Get unanswered questions for a masjid
  List<Question> getUnansweredQuestions(String masjidId) {
    return _questions
        .where((q) => q.masjidId == masjidId && !q.isAnswered)
        .toList();
  }

  /// Load questions from Firestore for a specific masjid
  Future<void> loadQuestions(String masjidId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _questions = await _repository.getQuestions(masjidId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Listen to real-time updates for questions. Cancels any prior subscription
  /// (tab switching recreates pages) and returns the new subscription so the
  /// caller can cancel it in dispose().
  StreamSubscription<List<Question>> subscribeToQuestions(String masjidId) {
    _streamSub?.cancel();
    final sub = _repository.getQuestionsStream(masjidId).listen((questions) {
      _questions = questions;
      _error = null;
      notifyListeners();
    });
    _streamSub = sub;
    return sub;
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  /// Add a new question
  Future<bool> addQuestion({
    required String userName,
    required String questionText,
    required String masjidId,
  }) async {
    final question = Question(
      id: '',
      userName: userName,
      questionText: questionText,
      masjidId: masjidId,
      timestamp: DateTime.now(),
    );

    final success = await _repository.addQuestion(question);
    if (success) {
      // The stream listener will update the list automatically
      // Also sync to AppData for backward compatibility
      AppData.addQuestion(userName, questionText, masjidId);
    }
    return success;
  }

  /// Answer a question
  Future<bool> answerQuestion(
    String masjidId,
    String questionId,
    String answer,
  ) async {
    final success = await _repository.answerQuestion(masjidId, questionId, answer);
    if (success) {
      // Also update AppData for backward compatibility
      AppData.answerQuestion(questionId, answer);
    }
    return success;
  }
}
