import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_data.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'admin_login_screen.dart';
import 'edit_profile_screen.dart';
import 'masjid_selection_screen.dart';
import 'muqtaddi_login_screen.dart';
import 'privacy_policy_screen.dart';
import 'super_admin_dashboard.dart';
import 'claim_masjid_screen.dart';
import '../widgets/delete_account_dialog.dart';
import 'member_verification_screen.dart';

/// Settings Page - Account, profile, preferences
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Human-readable role label for the profile card. Admins/imams and verified
  /// muqtaddis get their elevated label; a plain muqtaddi is shown as-is.
  String _roleLabel(User? user) {
    if (user == null) return appLocalization.t(AppStrings.guest);
    return switch (user.role) {
      UserRole.guest => appLocalization.t(AppStrings.guest),
      UserRole.muqtaddi =>
        user.isVerified
            ? appLocalization.t(AppStrings.verifiedUser)
            : appLocalization.t(AppStrings.muqtaddi),
      UserRole.verifiedMuqtaddi => appLocalization.t(AppStrings.verifiedUser),
      UserRole.imam || UserRole.admin => appLocalization.t(AppStrings.imam),
    };
  }

  /// True for management-track or verified users (used for role label color).
  bool _isElevated(User? user) =>
      user != null && (user.isAdminOrImam || user.isVerified);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final displayName = authProvider.currentUser?.username ?? 'Guest';
    final email = authProvider.currentUser?.email ?? '';
    final currentUser = authProvider.currentUser;
    final verificationStatus =
        currentUser?.verificationStatus ?? VerificationStatus.none;

    final Widget profileActions;
    if (!isLoggedIn) {
      profileActions = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MuqtaddiLoginScreen()),
              );
              if (mounted) setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              appLocalization.t(AppStrings.login),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appLocalization.t(AppStrings.guestCanReadLoginToParticipate),
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: ColorPalette.lightTextSecondary,
            ),
          ),
        ],
      );
    } else {
      profileActions = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currentUser != null && currentUser.role == UserRole.muqtaddi) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: verificationStatus == VerificationStatus.approved
                    ? ColorPalette.success.withValues(alpha: 0.12)
                    : verificationStatus == VerificationStatus.pending
                    ? ColorPalette.warning.withValues(alpha: 0.12)
                    : ColorPalette.lightBorder,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                verificationStatus == VerificationStatus.approved
                    ? 'Verified'
                    : verificationStatus == VerificationStatus.pending
                    ? 'Verification pending'
                    : 'Not verified',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: verificationStatus == VerificationStatus.approved
                      ? ColorPalette.success
                      : verificationStatus == VerificationStatus.pending
                      ? ColorPalette.warning
                      : ColorPalette.lightTextSecondary,
                ),
              ),
            ),
            if (verificationStatus != VerificationStatus.approved &&
                verificationStatus != VerificationStatus.pending) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await authProvider.requestVerification();

                    if (!mounted) return;
                    if (success) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Verification request sent.'),
                          backgroundColor: ColorPalette.success,
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            authProvider.error ??
                                'Unable to request verification.',
                          ),
                          backgroundColor: ColorPalette.error,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.verified_user, size: 14),
                  label: const Text(
                    'Request Verification',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ],
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.edit, size: 14),
                label: Text(
                  appLocalization.t(AppStrings.editProfile),
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorPalette.primary,
                  side: BorderSide(color: ColorPalette.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().signOut();
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.logout, size: 14),
                label: const Text('Logout', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.settings)),
        backgroundColor: ColorPalette.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorPalette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorPalette.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLocalization.t(AppStrings.userProfile),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ColorPalette.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorPalette.primary.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: ColorPalette.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLoggedIn
                                    ? email
                                    : appLocalization.t(AppStrings.guest),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorPalette.lightTextSecondary,
                                ),
                              ),
                              if (isLoggedIn)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _roleLabel(authProvider.currentUser),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          _isElevated(authProvider.currentUser)
                                          ? ColorPalette.success
                                          : ColorPalette.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              profileActions,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Masjid Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalization.t(AppStrings.masjidSettings),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? ColorPalette.darkBorder
                            : ColorPalette.lightBorder,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appLocalization.t(AppStrings.selectedMasjid),
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorPalette.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppData.selectedMasjid?.name ??
                              appLocalization.t(AppStrings.selectMasjid),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppData.selectedMasjid?.location ??
                              appLocalization.t(AppStrings.selectMasjid),
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorPalette.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MasjidSelectionScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.location_on),
                            label: Text(
                              appLocalization.t(AppStrings.changeMasjid),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPalette.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preferences
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalization.t(AppStrings.preferences),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final settings = context.watch<SettingsProvider>();
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? ColorPalette.darkBorder
                                : ColorPalette.lightBorder,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.dark_mode,
                              title: appLocalization.t(AppStrings.darkMode),
                              trailing: Switch(
                                value: settings.isDarkMode,
                                onChanged: (_) => settings.toggleDarkMode(),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? ColorPalette.darkBorder
                                  : ColorPalette.lightBorder,
                            ),
                            _SettingsTile(
                              icon: Icons.notifications,
                              title: appLocalization.t(
                                AppStrings.notifications,
                              ),
                              trailing: Switch(
                                value: settings.notificationsEnabled,
                                onChanged: (_) =>
                                    settings.toggleNotifications(),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? ColorPalette.darkBorder
                                  : ColorPalette.lightBorder,
                            ),
                            _LanguageTile(
                              icon: Icons.language,
                              title: appLocalization.t(AppStrings.language),
                              onLanguageChanged: () {
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Admin Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalization.t(AppStrings.adminPanel),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (currentUser?.isAdminOrImam == true &&
                      currentUser?.masjidId != null)
                    TextButton.icon(
                      icon: const Icon(Icons.verified_user_outlined),
                      label: Text(appLocalization.t('review_members')),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemberVerificationScreen(
                            masjidId: currentUser!.masjidId!,
                          ),
                        ),
                      ),
                    ),
                  if (authProvider.isSuperAdmin)
                    TextButton.icon(
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(appLocalization.t('super_admin_dashboard')),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuperAdminDashboard(),
                        ),
                      ),
                    ),
                  if (isLoggedIn && currentUser?.isAdminOrImam != true)
                    TextButton.icon(
                      icon: const Icon(Icons.mosque_outlined),
                      label: Text(appLocalization.t('claim_masjid_action')),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClaimMasjidScreen(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.admin_panel_settings),
                      label: Text(appLocalization.t(AppStrings.adminPanel)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalette.tertiary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About & Support
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocalization.t(AppStrings.about),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorPalette.lightBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.info,
                          title: appLocalization.t(AppStrings.about),
                          subtitle: 'v1.0.0',
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Masjid Prayer App',
                              applicationVersion: '1.0.0',
                              applicationLegalese:
                                  '© 2026 Hassan Masjid Community',
                            );
                          },
                        ),
                        Divider(height: 1, color: ColorPalette.lightBorder),
                        _SettingsTile(
                          icon: Icons.help,
                          title: appLocalization.t(AppStrings.help),
                          onTap: () async {
                            final uri = Uri.parse(
                              'mailto:sardaribraheem277@gmail.com',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not launch mail client to sardaribraheem277@gmail.com',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        Divider(height: 1, color: ColorPalette.lightBorder),
                        _SettingsTile(
                          icon: Icons.privacy_tip,
                          title: appLocalization.t(AppStrings.privacyPolicy),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                        ),
                        if (isLoggedIn) ...[
                          Divider(height: 1, color: ColorPalette.lightBorder),
                          _SettingsTile(
                            icon: Icons.delete_forever,
                            title: appLocalization.t('delete_account_title'),
                            onTap: () async {
                              final deleted = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const DeleteAccountDialog(),
                              );
                              if (deleted == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      appLocalization.t('account_deleted'),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Settings Tile Widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: ColorPalette.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing:
          trailing ??
          Icon(Icons.chevron_right, color: ColorPalette.lightTextSecondary),
      onTap: onTap,
    );
  }
}

/// Language Switcher Tile Widget
class _LanguageTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onLanguageChanged;

  const _LanguageTile({
    required this.icon,
    required this.title,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currentLanguage = settings.locale == 'en'
        ? appLocalization.t(AppStrings.english)
        : appLocalization.t(AppStrings.urdu);

    return ListTile(
      leading: Icon(icon, color: ColorPalette.primary),
      title: Text(title),
      subtitle: Text(currentLanguage),
      trailing: GestureDetector(
        onTap: () async {
          final selected = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(appLocalization.t(AppStrings.language)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(appLocalization.t(AppStrings.english)),
                    onTap: () => Navigator.pop(context, 'en'),
                    selected: settings.locale == 'en',
                    selectedTileColor: ColorPalette.primary.withValues(
                      alpha: 0.2,
                    ),
                  ),
                  ListTile(
                    title: Text(appLocalization.t(AppStrings.urdu)),
                    onTap: () => Navigator.pop(context, 'ur'),
                    selected: settings.locale == 'ur',
                    selectedTileColor: ColorPalette.primary.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );

          if (selected != null && selected != settings.locale) {
            await settings.setLanguage(selected);
            onLanguageChanged?.call();
          }
        },
        child: Icon(
          Icons.chevron_right,
          color: ColorPalette.lightTextSecondary,
        ),
      ),
    );
  }
}
