import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/question_provider.dart';
import '../widgets/shared/empty_state.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Screen for imams/admins to view and answer questions
class AdminQAScreen extends StatefulWidget {
  const AdminQAScreen({Key? key}) : super(key: key);

  @override
  State<AdminQAScreen> createState() => _AdminQAScreenState();
}

class _AdminQAScreenState extends State<AdminQAScreen> {
  String _filterType = 'all'; // 'all', 'unanswered', 'answered'

  @override
  void initState() {
    super.initState();
    // Defer past the first frame: loadQuestions() notifies synchronously, which
    // would otherwise trigger "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadQuestions();
    });
  }

  Future<void> _loadQuestions() async {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    if (masjidId.isNotEmpty) {
      await context.read<QuestionProvider>().loadQuestions(masjidId);
    }
  }

  void _changeFilter(String type) {
    setState(() => _filterType = type);
  }

  List<Question> _getFilteredQuestions() {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    final provider = context.watch<QuestionProvider>();
    final questions = provider.getQuestionsByMasjid(masjidId);

    if (_filterType == 'unanswered') {
      return questions.where((q) => !q.isAnswered).toList();
    } else if (_filterType == 'answered') {
      return questions.where((q) => q.isAnswered).toList();
    }
    return questions;
  }

  @override
  Widget build(BuildContext context) {
    final questions = _getFilteredQuestions();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.qnaManagementTitle)),
        backgroundColor: ColorPalette.primary,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _FilterChip(
                    label: appLocalization.t(AppStrings.allQuestions),
                    isSelected: _filterType == 'all',
                    onTap: () => _changeFilter('all'),
                    icon: Icons.quiz,
                  ),
                  const SizedBox(width: 12),
                  _FilterChip(
                    label: appLocalization.t(AppStrings.unanswered),
                    isSelected: _filterType == 'unanswered',
                    onTap: () => _changeFilter('unanswered'),
                    icon: Icons.pending_actions,
                  ),
                  const SizedBox(width: 12),
                  _FilterChip(
                    label: appLocalization.t(AppStrings.answered),
                    isSelected: _filterType == 'answered',
                    onTap: () => _changeFilter('answered'),
                    icon: Icons.check_circle,
                  ),
                ],
              ),
            ),
          ),

          // Questions List
          Expanded(
            child: context.watch<QuestionProvider>().isLoading
                ? const Center(child: CircularProgressIndicator())
                : questions.isEmpty
                    ? EmptyState(
                        icon: Icons.inbox_outlined,
                        title: appLocalization.t(AppStrings.noQuestionsYet),
                        subtitle: appLocalization.t(AppStrings.questionsWillAppearHereAdmin),
                        actionLabel: appLocalization.t(AppStrings.refresh),
                        onAction: _loadQuestions,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadQuestions,
                        child: ListView.builder(
                          itemCount: questions.length,
                          padding: const EdgeInsets.all(12),
                          itemBuilder: (context, index) {
                            return _QuestionCard(
                              question: questions[index],
                              onAnswerTap: () {
                                _showAnswerDialog(context, questions[index]);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to answer a question
  void _showAnswerDialog(BuildContext context, Question question) {
    final answerController =
        TextEditingController(text: question.answer ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalization.t(AppStrings.answerQuestion)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorPalette.info,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appLocalization.t(AppStrings.questionFrom)} ${question.userName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.questionText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Answer field
              Text(
                appLocalization.t(AppStrings.yourAnswer),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: answerController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: appLocalization.t(AppStrings.typeYourAnswerHere),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocalization.t(AppStrings.cancel)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (answerController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      appLocalization.t(AppStrings.pleaseEnterAnAnswer),
                    ),
                  ),
                );
                return;
              }

              // Save the answer via provider
              await context.read<QuestionProvider>().answerQuestion(
                    AppData.selectedMasjid?.id ?? '',
                    question.id,
                    answerController.text.trim(),
                  );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(appLocalization.t(AppStrings.answerSaved)),
                  backgroundColor: ColorPalette.success,
                ),
              );

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primary,
            ),
            child: Text(appLocalization.t(AppStrings.saveAnswer)),
          ),
        ],
      ),
    );
  }
}

/// Custom filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorPalette.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ColorPalette.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Question card widget for displaying questions and answers
class _QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onAnswerTap;

  const _QuestionCard({required this.question, required this.onAnswerTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
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
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(question.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: question.isAnswered
                        ? ColorPalette.success.withValues(alpha: 0.15)
                        : ColorPalette.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        question.isAnswered
                            ? Icons.check_circle
                            : Icons.pending_actions,
                        size: 16,
                        color: question.isAnswered
                            ? ColorPalette.success
                            : ColorPalette.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        question.isAnswered
                            ? appLocalization.t(AppStrings.answered)
                            : appLocalization.t(AppStrings.pending),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: question.isAnswered
                              ? ColorPalette.success
                              : ColorPalette.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorPalette.info,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalization.t(AppStrings.question),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.questionText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Answer (if exists)
            if (question.isAnswered && question.answer != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorPalette.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLocalization.t(AppStrings.answerText),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.answer!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAnswerTap,
                icon: Icon(question.isAnswered ? Icons.edit : Icons.reply),
                label: Text(
                  question.isAnswered
                      ? appLocalization.t(AppStrings.editAnswer)
                      : appLocalization.t(AppStrings.answerQuestion),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format timestamp for display
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
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
