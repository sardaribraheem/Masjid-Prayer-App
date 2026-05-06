import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Screen where users can post questions to the imam
class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({Key? key}) : super(key: key);

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  /// Validate and submit the question
  void _submitQuestion() {
    // Validation
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

    // Submit the question
    setState(() => _isSubmitting = true);

    try {
      AppData.addQuestion(
        _nameController.text.trim(),
        _questionController.text.trim(),
        AppData.selectedMasjid?.id ?? 'unknown',
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalization.t(AppStrings.questionSubmitted)),
          backgroundColor: ColorPalette.success,
        ),
      );

      // Clear the form
      _nameController.clear();
      _questionController.clear();

      // Go back
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appLocalization.t(AppStrings.error)}: ${e.toString()}',
          ),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.askTheImam)),
        backgroundColor: ColorPalette.primary,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                '📝 ${appLocalization.t(AppStrings.submitQuestion)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ColorPalette.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                appLocalization.t(AppStrings.imamWillReview),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorPalette.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 30),

              // Selected Masjid Info
              if (AppData.selectedMasjid != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPalette.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ColorPalette.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLocalization.t(AppStrings.postingTo),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppData.selectedMasjid!.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 25),

              // Name Field
              Text(
                appLocalization.t(AppStrings.yourName),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: appLocalization.t(AppStrings.enterYourName),
                  prefixIcon: Icon(Icons.person, color: ColorPalette.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ColorPalette.lightBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: ColorPalette.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Question Field
              Text(
                appLocalization.t(AppStrings.yourQuestion),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _questionController,
                enabled: !_isSubmitting,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: appLocalization.t(AppStrings.writeYourQuestion),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(top: 8, left: 8),
                    child: Icon(
                      Icons.help_outline,
                      color: ColorPalette.primary,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ColorPalette.lightBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: ColorPalette.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitQuestion,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorPalette.primary,
                            ),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSubmitting
                        ? appLocalization.t(AppStrings.submitting)
                        : appLocalization.t(AppStrings.submitQuestion),
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorPalette.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ColorPalette.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: ColorPalette.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        appLocalization.t(AppStrings.questionAnonymous),
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorPalette.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
