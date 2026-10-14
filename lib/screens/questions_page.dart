import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/masjid_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/question_provider.dart';
import '../widgets/shared/empty_state.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'muqtaddi_login_screen.dart';
import '../widgets/post_comments.dart';
import '../widgets/app_icon.dart';

/// Questions Page - Users can ask questions and see answered questions
///
/// Only signed-in Muqtaddis can post (`Firestore rules` requires auth); guests
/// see a login prompt instead of the form. Questions are attributed to the
/// logged-in user's `users/{uid}` username — no manual name field.
class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  final TextEditingController _questionController = TextEditingController();
  String _filterType = 'all'; // 'all', 'answered', 'unanswered'
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  StreamSubscription<List<Question>>? _questionSub;

  String? _listeningMasjidId;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id =
        (context.watch<MasjidProvider>().selectedMasjid ??
                AppData.selectedMasjid)
            ?.id;
    if (id != _listeningMasjidId) {
      _listeningMasjidId = id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && id == _listeningMasjidId) _loadQuestions();
      });
    }
  }

  Future<void> _loadQuestions() async {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    if (masjidId.isNotEmpty) {
      _questionSub?.cancel();
      _questionSub = context.read<QuestionProvider>().subscribeToQuestions(
        masjidId,
      );
    }
  }

  @override
  void dispose() {
    _questionSub?.cancel();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      // Guests cannot post per Firestore rules — route them to login.
      await _promptLogin();
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

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final postedAsAnonymous = _isAnonymous;
    final success = await context.read<QuestionProvider>().addQuestion(
      userName: authProvider.currentUser?.username ?? 'Muqtaddi',
      questionText: _questionController.text.trim(),
      masjidId: AppData.selectedMasjid?.id ?? 'unknown',
      createdByUid: authProvider.currentUser?.id,
      isAnonymous: postedAsAnonymous,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalization.t(AppStrings.questionSubmitted)),
          backgroundColor: ColorPalette.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalization.t(AppStrings.errorOccurred)),
          backgroundColor: ColorPalette.error,
        ),
      );
    }

    if (!success) return;
    _questionController.clear();
    setState(() {
      _isAnonymous = false;
    });
  }

  /// Send guests to the Muqtaddi login screen before posting.
  Future<void> _promptLogin() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appLocalization.t(AppStrings.guestCanReadLoginToParticipate),
        ),
      ),
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MuqtaddiLoginScreen()),
    );
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: appLocalization,
    builder: (context, _) => _buildLocalized(context),
  );

  Widget _buildLocalized(BuildContext context) {
    final filteredQuestions = _getFilteredQuestions();

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(16),
          child: AppIcon('book', color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(appLocalization.t(AppStrings.communityQA)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: appLocalization.t(AppStrings.refresh),
            onPressed: _loadQuestions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Ask Question Card
          if (context.watch<AuthProvider>().isLoggedIn)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalization.t(AppStrings.community),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionController,
                    enabled: !_isSubmitting,
                    maxLines: 3,
                    maxLength: 4000,
                    decoration: InputDecoration(
                      hintText: appLocalization.t(AppStrings.yourQuestion),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(top: 8, left: 8),
                        child: Icon(
                          Icons.help_outline,
                          color: Theme.of(context).colorScheme.primary,
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
                  Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(appLocalization.t('post_anonymously')),
                      subtitle: Text(
                        appLocalization.t('anonymous_display_note'),
                      ),
                      value: _isAnonymous,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _isAnonymous = value);
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitQuestion,
                      icon: const Icon(Icons.send),
                      label: Text(
                        appLocalization.t(
                          _isSubmitting
                              ? AppStrings.submitting
                              : AppStrings.submitQuestion,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Guests read public data but must log in to post (§2).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalization.t(AppStrings.community),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appLocalization.t(
                      AppStrings.guestCanReadLoginToParticipate,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: ColorPalette.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MuqtaddiLoginScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.login),
                    label: Text(appLocalization.t(AppStrings.login)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
          ),

          if (context.watch<QuestionProvider>().isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (context.watch<QuestionProvider>().error != null)
            EmptyState(
              icon: Icons.cloud_off_outlined,
              title: appLocalization.t('feed_error'),
              actionLabel: appLocalization.t(AppStrings.refresh),
              onAction: _loadQuestions,
            )
          else if (filteredQuestions.isEmpty)
            EmptyState(
              icon: Icons.chat_bubble_outline,
              title: appLocalization.t(AppStrings.noQuestions),
              subtitle: appLocalization.t(AppStrings.questionsWillAppearHere),
            )
          else
            ...filteredQuestions.map(
              (question) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _QuestionCard(
                  key: ValueKey(question.id),
                  question: question,
                ),
              ),
            ),
          if (context.watch<QuestionProvider>().hasMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: context.watch<QuestionProvider>().loadingMore
                    ? null
                    : context.read<QuestionProvider>().loadMore,
                child: Text(appLocalization.t('load_more')),
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
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: isSelected,
    onSelected: (_) => onTap(),
    visualDensity: VisualDensity.standard,
  );
}

/// Question card widget
class _QuestionCard extends StatelessWidget {
  final Question question;

  const _QuestionCard({super.key, required this.question});

  Future<void> _delete(BuildContext context) async {
    final provider = context.read<QuestionProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalization.t('delete_post_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appLocalization.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(appLocalization.t('delete_content')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await provider.deleteQuestion(
      question.masjidId,
      question.id,
    );
    if (!success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appLocalization.t('feed_error'))));
    }
  }

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
    final auth = context.watch<AuthProvider>();
    final canDelete =
        auth.isLoggedIn &&
        (auth.currentUser?.id == question.createdByUid ||
            auth.currentUser?.canManageMasjid(question.masjidId) == true ||
            auth.isSuperAdmin);
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
                        question.displayName,
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
                        : appLocalization.t('open_discussion'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: question.isAnswered
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
                    question.questionText,
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
            if (canDelete)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  tooltip: appLocalization.t('delete_content'),
                  onPressed: () => _delete(context),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            PostComments(masjidId: question.masjidId, postId: question.id),
          ],
        ),
      ),
    );
  }
}
