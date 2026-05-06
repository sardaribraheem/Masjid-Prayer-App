import 'package:flutter/material.dart';
import '../models/app_data.dart';
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
  late List<Question> _questions;
  String _filterType = 'all'; // 'all', 'unanswered', 'answered'

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    setState(() {
      if (_filterType == 'unanswered') {
        _questions = AppData.getUnansweredQuestions(
          AppData.selectedMasjid?.id ?? '',
        );
      } else if (_filterType == 'answered') {
        _questions = AppData.getQuestionsByMasjid(
          AppData.selectedMasjid?.id ?? '',
        ).where((q) => q.isAnswered).toList();
      } else {
        _questions = AppData.getQuestionsByMasjid(
          AppData.selectedMasjid?.id ?? '',
        );
      }
    });
  }

  void _changeFilter(String type) {
    setState(() => _filterType = type);
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
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
            child: _questions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          appLocalization.t(AppStrings.noQuestionsYet),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? ColorPalette.darkTextSecondary
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _questions.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      return _QuestionCard(
                        question: _questions[index],
                        onAnswerTap: () {
                          _showAnswerDialog(context, _questions[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to answer a question
  void _showAnswerDialog(BuildContext context, Question question) {
    final answerController = TextEditingController(text: question.answer ?? '');

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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? ColorPalette.darkTextSecondary
                            : Colors.grey,
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
            onPressed: () {
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

              // Save the answer
              AppData.answerQuestion(question.id, answerController.text.trim());

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(appLocalization.t(AppStrings.answerSaved)),
                  backgroundColor: ColorPalette.success,
                ),
              );

              Navigator.pop(context);
              _loadQuestions(); // Refresh the list
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
          color: isSelected ? ColorPalette.primary : 
            (Theme.of(context).brightness == Brightness.dark
              ? ColorPalette.darkCardBg
              : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ColorPalette.primary : 
              (Theme.of(context).brightness == Brightness.dark
                ? ColorPalette.darkBorder
                : Colors.grey[300]!),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : 
                  (Theme.of(context).brightness == Brightness.dark
                    ? ColorPalette.darkText
                    : Colors.grey[600]),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                        ? Colors.green[100]
                        : Colors.red[100],
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
                        color: question.isAnswered ? Colors.green : Colors.red,
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
                              ? Colors.green
                              : Colors.red,
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
                      color: Colors.grey[600],
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
                        color: Colors.grey[600],
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
