import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/question_provider.dart';
import '../widgets/shared/empty_state.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Questions Page - Users can ask questions and see answered questions
class QuestionsPage extends StatefulWidget {
  const QuestionsPage({Key? key}) : super(key: key);

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  String _filterType = 'all'; // 'all', 'answered', 'unanswered'

  StreamSubscription<List<Question>>? _questionSub;

  @override
  void initState() {
    super.initState();
    // Defer past the first frame: loadQuestions()/subscribeToQuestions() notify
    // synchronously, which would otherwise trigger "setState() called during
    // build". Subscribing here (not in build) also avoids creating a new
    // Firestore listener on every rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadQuestions();
      final masjidId = AppData.selectedMasjid?.id ?? '';
      if (masjidId.isNotEmpty) {
        _questionSub =
            context.read<QuestionProvider>().subscribeToQuestions(masjidId);
      }
    });
  }

  Future<void> _loadQuestions() async {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    if (masjidId.isNotEmpty) {
      await context.read<QuestionProvider>().loadQuestions(masjidId);
    }
  }

  @override
  void dispose() {
    _questionSub?.cancel();
    _nameController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalization.t(AppStrings.pleaseEnterYourName)),
        ),
      );
      return;
    }

    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalization.t(AppStrings.pleaseEnterYourQuestion)),
        ),
      );
      return;
    }

    final success = await context.read<QuestionProvider>().addQuestion(
          userName: _nameController.text.trim(),
          questionText: _questionController.text.trim(),
          masjidId: AppData.selectedMasjid?.id ?? 'unknown',
        );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalization.t(AppStrings.questionSubmitted)),
          backgroundColor: ColorPalette.success,
        ),
      );
    }

    _nameController.clear();
    _questionController.clear();
  }

  List<Question> _getFilteredQuestions() {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    final provider = context.watch<QuestionProvider>();
    final questions = provider.getQuestionsByMasjid(masjidId);

    if (_filterType == 'answered') {
      return questions.where((q) => q.isAnswered).toList();
    } else if (_filterType == 'unanswered') {
      return questions.where((q) => !q.isAnswered).toList();
    }
    return questions;
  }

  @override
  Widget build(BuildContext context) {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    if (masjidId.isNotEmpty) {
      // Ensure we're subscribed to real-time updates
      context.read<QuestionProvider>().subscribeToQuestions(masjidId);
    }

    final filteredQuestions = _getFilteredQuestions();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.communityQA)),
        backgroundColor: ColorPalette.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Ask Question Card
          Container(
            padding: const EdgeInsets.all(16),
            color: ColorPalette.primary.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalization.t(AppStrings.askTheImam),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ColorPalette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: appLocalization.t(AppStrings.yourName),
                    prefixIcon: Icon(Icons.person, color: ColorPalette.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _questionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: appLocalization.t(AppStrings.yourQuestion),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8),
                      child: Icon(
                        Icons.help_outline,
                        color: ColorPalette.primary,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitQuestion,
                    icon: const Icon(Icons.send),
                    label: Text(appLocalization.t(AppStrings.submitQuestion)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _FilterButton(
                  label: appLocalization.t(AppStrings.allCategories),
                  isSelected: _filterType == 'all',
                  onTap: () => setState(() => _filterType = 'all'),
                ),
                const SizedBox(width: 10),
                _FilterButton(
                  label: appLocalization.t(AppStrings.answered),
                  isSelected: _filterType == 'answered',
                  onTap: () => setState(() => _filterType = 'answered'),
                ),
                const SizedBox(width: 10),
                _FilterButton(
                  label: appLocalization.t(AppStrings.unanswered),
                  isSelected: _filterType == 'unanswered',
                  onTap: () => setState(() => _filterType = 'unanswered'),
                ),
              ],
            ),
          ),

          // Questions List
          Expanded(
            child: context.watch<QuestionProvider>().isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredQuestions.isEmpty
                    ? EmptyState(
                        icon: Icons.inbox_outlined,
                        title: appLocalization.t(AppStrings.noQuestions),
                        subtitle: appLocalization.t(AppStrings.questionsWillAppearHere),
                        actionLabel: appLocalization.t(AppStrings.refresh),
                        onAction: _loadQuestions,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadQuestions,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: filteredQuestions.length,
                          itemBuilder: (context, index) {
                            final question = filteredQuestions[index];
                            return _QuestionCard(question: question);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Filter button widget
class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.primary : ColorPalette.lightBorder,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Question card widget
class _QuestionCard extends StatelessWidget {
  final Question question;

  const _QuestionCard({required this.question});

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return appLocalization.t(AppStrings.justNow);
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${appLocalization.t(AppStrings.minutesAgo)}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${appLocalization.t(AppStrings.hoursAgo)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${appLocalization.t(AppStrings.daysAgo)}';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(question.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: question.isAnswered
                        ? ColorPalette.success.withValues(alpha: 0.15)
                        : ColorPalette.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    question.isAnswered
                        ? appLocalization.t(AppStrings.answered)
                        : appLocalization.t(AppStrings.pending),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: question.isAnswered
                          ? ColorPalette.success
                          : ColorPalette.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorPalette.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${appLocalization.t(AppStrings.question)} ${question.questionText}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            if (question.isAnswered && question.answer != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorPalette.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appLocalization.t(AppStrings.answerText)} ${question.answer!}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
