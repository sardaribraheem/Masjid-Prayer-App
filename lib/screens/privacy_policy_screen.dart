import 'package:flutter/material.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Privacy Policy Screen detailing data collection, verification, community posts,
/// event registration, and account deletion.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.privacyPolicy)),
        backgroundColor: ColorPalette.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Masjid Prayer App',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorPalette.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: September 2026',
              style: TextStyle(
                fontSize: 12,
                color: ColorPalette.lightTextSecondary,
              ),
            ),
            const Divider(height: 24),
            _buildSection(
              '1. Information We Collect',
              'We collect information you provide directly when creating an account, registering as a muqtaddi or imam, submitting verification requests, proposing community events, registering for events, or asking questions. This includes your name, email address, selected masjid linkage, and role-based permissions.',
              textColor,
            ),
            _buildSection(
              '2. Verification & Role Management',
              'Verification requests and role assignments (Muqtaddi, Verified Muqtaddi, Imam, Admin) are managed securely through Firebase Firestore and authenticated user claims. Self-promotion and self-verification are strictly prevented by security rules.',
              textColor,
            ),
            _buildSection(
              '3. Community Posts & Questions',
              'Questions asked to the Imam and community posts are stored securely to facilitate communication within your selected masjid community. Public identity settings determine how your name is displayed.',
              textColor,
            ),
            _buildSection(
              '4. Event Registration',
              'When you register for community events, your name and participation status are recorded for masjid administrators and organizers to manage attendance effectively.',
              textColor,
            ),
            _buildSection(
              '5. Data Security & Retention',
              'We use Firebase Authentication and Firestore security rules to protect your personal information. Content lifecycle policies automatically archive or remove expired posts according to community guidelines.',
              textColor,
            ),
            _buildSection(
              '6. Account Deletion',
              'You have the right to delete your account at any time via the Settings page. Deleting your account permanently removes your authentication credentials and associated user profile data from our databases.',
              textColor,
            ),
            _buildSection(
              '7. Contact Us',
              'If you have any questions or concerns regarding this Privacy Policy or your personal data, please contact support at sardaribraheem277@gmail.com.',
              textColor,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ColorPalette.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
