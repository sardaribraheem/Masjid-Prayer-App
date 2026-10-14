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
  int _generation = 0;
  String? _masjidId;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

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
    final generation = ++_generation;
    _masjidId = masjidId;
    _streamSub?.cancel();
    _loadingMore = false;
    _questions = [];
    _hasMore = false;
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final page = await _repository.getQuestions(masjidId);
      if (generation != _generation) return;
      _hasMore = page.length > 30;
      _questions = page.take(30).toList();
      _error = null;
    } catch (e) {
      if (generation != _generation) return;
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Listen to real-time updates for questions. Cancels any prior subscription
  /// (tab switching recreates pages) and returns the new subscription so the
  /// caller can cancel it in dispose().
  StreamSubscription<List<Question>> subscribeToQuestions(String masjidId) {
    final generation = ++_generation;
    _masjidId = masjidId;
    _questions = [];
    _hasMore = false;
    _loadingMore = false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    _streamSub?.cancel();
    final sub = _repository
        .getQuestionsStream(masjidId)
        .listen(
          (questions) {
            if (generation != _generation) return;
            _questions = questions.take(30).toList();
            _hasMore = questions.length > 30;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            if (generation != _generation) return;
            _isLoading = false;
            _error = error.toString();
            notifyListeners();
          },
        );
    _streamSub = sub;
    return sub;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _masjidId == null || _questions.isEmpty) {
      return;
    }
    // Older pages are a point-in-time view. Stop the head listener while
    // browsing them so a new head snapshot cannot silently discard pages.
    _streamSub?.cancel();
    final generation = _generation;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _repository.getQuestions(
        _masjidId!,
        after: _questions.last,
      );
      if (generation != _generation) return;
      _hasMore = page.length > 30;
      final ids = _questions.map((item) => item.id).toSet();
      _questions.addAll(page.take(30).where((item) => !ids.contains(item.id)));
      _error = null;
    } catch (error) {
      if (generation == _generation) _error = error.toString();
    } finally {
      if (generation == _generation) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _streamSub?.cancel();
    super.dispose();
  }

  /// Add a new question
  Future<bool> addQuestion({
    required String userName,
    required String questionText,
    required String masjidId,
    String? createdByUid,
    bool isAnonymous = false,
  }) async {
    if (masjidId.isEmpty ||
        createdByUid == null ||
        questionText.trim().isEmpty ||
        questionText.length > 4000) {
      return false;
    }
    final question = Question(
      id: '',
      userName: isAnonymous ? 'Anonymous' : userName,
      questionText: questionText,
      masjidId: masjidId,
      timestamp: DateTime.now(),
      isAnonymous: isAnonymous,
      createdByUid: createdByUid,
    );

    final success = await _repository.addQuestion(question);
    if (success) {
      // The stream listener will update the list automatically
      // Also sync to AppData for backward compatibility
      AppData.addQuestion(
        userName,
        questionText,
        masjidId,
        createdByUid: createdByUid,
        isAnonymous: isAnonymous,
      );
    }
    return success;
  }

  Future<bool> deleteQuestion(String masjidId, String questionId) async {
    final success = await _repository.deleteQuestion(masjidId, questionId);
    if (success) {
      _questions.removeWhere((q) => q.id == questionId);
      notifyListeners();
    }
    return success;
  }

  /// Answer a question
  Future<bool> answerQuestion(
    String masjidId,
    String questionId,
    String answer,
  ) async {
    final success = await _repository.answerQuestion(
      masjidId,
      questionId,
      answer,
    );
    if (success) {
      // Also update AppData for backward compatibility
      AppData.answerQuestion(questionId, answer);
      final index = _questions.indexWhere(
        (question) =>
            question.id == questionId && question.masjidId == masjidId,
      );
      if (index != -1) {
        _questions[index] = Question.fromJson({
          ..._questions[index].toJson(),
          'answer': answer,
          'isAnswered': true,
        });
        notifyListeners();
      }
    }
    return success;
  }
}
