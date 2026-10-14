import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/auth_provider.dart';
import '../providers/question_provider.dart';
import '../widgets/shared/empty_state.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Screen for imams/admins to view and answer questions
class AdminQAScreen extends StatefulWidget {
  const AdminQAScreen({super.key});

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
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isSuperAdmin &&
        authProvider.currentUser?.canManageMasjid(AppData.selectedMasjid?.id) !=
            true) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appLocalization.t(AppStrings.qnaManagementTitle)),
        ),
        body: Center(
          child: Text(appLocalization.t('manager_approval_required')),
        ),
      );
    }
    final questions = _getFilteredQuestions();

    return Scaffold(
      bottomNavigationBar: context.watch<QuestionProvider>().hasMore
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton(
                  onPressed: context.watch<QuestionProvider>().loadingMore
                      ? null
                      : context.read<QuestionProvider>().loadMore,
                  child: Text(appLocalization.t('load_more')),
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.qnaManagementTitle)),
        actions: [
          IconButton(
            tooltip: appLocalization.t(AppStrings.refresh),
            onPressed: _loadQuestions,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
            child: context.watch<QuestionProvider>().error != null
                ? EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: appLocalization.t('feed_error'),
                    actionLabel: appLocalization.t(AppStrings.refresh),
                    onAction: _loadQuestions,
                  )
                : context.watch<QuestionProvider>().isLoading
                ? const Center(child: CircularProgressIndicator())
                : questions.isEmpty
                ? EmptyState(
                    icon: Icons.inbox_outlined,
                    title: appLocalization.t(AppStrings.noQuestionsYet),
                    subtitle: appLocalization.t(
                      AppStrings.questionsWillAppearHereAdmin,
                    ),
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

  /// Save before closing so failed writes preserve the answer draft.
  Future<void> _showAnswerDialog(
    BuildContext context,
    Question question,
  ) async {
    final controller = TextEditingController(text: question.answer ?? '');
    final provider = context.read<QuestionProvider>();
    final masjidId = question.masjidId;
    bool saving = false;
    String? error;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: Text(appLocalization.t(AppStrings.answerQuestion)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.questionText),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    enabled: !saving,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 4000,
                    decoration: InputDecoration(
                      labelText: appLocalization.t(AppStrings.yourAnswer),
                    ),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                child: Text(appLocalization.t(AppStrings.cancel)),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final text = controller.text.trim();
                        if (text.isEmpty) {
                          update(
                            () => error = appLocalization.t(
                              AppStrings.pleaseEnterAnAnswer,
                            ),
                          );
                          return;
                        }
                        update(() {
                          saving = true;
                          error = null;
                        });
                        final success = await provider.answerQuestion(
                          masjidId,
                          question.id,
                          text,
                        );
                        if (!context.mounted) return;
                        if (success) {
                          Navigator.pop(context, true);
                        } else {
                          update(() {
                            saving = false;
                            error = appLocalization.t('feed_error');
                          });
                        }
                      },
                child: Text(
                  appLocalization.t(
                    saving ? 'submitting' : AppStrings.saveAnswer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Route disposal is asynchronous; release the controller after its fields
    // leave the tree rather than during the dismissal transition.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
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
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: isSelected,
      onSelected: (_) => onTap(),
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
                        question.displayName,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalization.t(AppStrings.question),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLocalization.t(AppStrings.answerText),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
