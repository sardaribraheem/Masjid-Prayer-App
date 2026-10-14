import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_data.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/masjid_provider.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/prayer_reminder_settings.dart';
import 'admin_login_screen.dart';
import 'admin_panel_screen.dart';
import 'edit_profile_screen.dart';
import 'masjid_selection_screen.dart';
import 'muqtaddi_login_screen.dart';
import 'privacy_policy_screen.dart';
import 'super_admin_dashboard.dart';
import 'claim_masjid_screen.dart';
import 'member_verification_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  String _role(User? user) => appLocalization.t(switch (user?.role) {
    UserRole.muqtaddi => AppStrings.muqtaddi,
    UserRole.verifiedMuqtaddi => AppStrings.verifiedUser,
    UserRole.imam || UserRole.admin => AppStrings.imam,
    _ => AppStrings.guest,
  });
  void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(4, 24, 4, 12),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
  Future<void> _language(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final locale = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(appLocalization.t(AppStrings.language)),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'en'),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('English'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'ur'),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('اردو'),
            ),
          ),
        ],
      ),
    );
    if (locale != null) await settings.setLanguage(locale);
  }

  Future<void> _support(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      Uri(scheme: 'mailto', path: 'sardaribraheem277@gmail.com'),
    );
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('sardaribraheem277@gmail.com')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: appLocalization,
    builder: (context, _) {
      final auth = context.watch<AuthProvider>();
      final settings = context.watch<SettingsProvider>();
      final masjid =
          context.watch<MasjidProvider>().selectedMasjid ??
          AppData.selectedMasjid;
      final user = auth.currentUser;
      final scheme = Theme.of(context).colorScheme;
      final manage = user?.canManageMasjid(masjid?.id) == true;
      return Scaffold(
        appBar: AppBar(title: Text(appLocalization.t(AppStrings.settings))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person_outline, color: scheme.primary, size: 28),
                    const SizedBox(height: 12),
                    Text(
                      auth.isLoggedIn
                          ? user!.username
                          : appLocalization.t(AppStrings.guest),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (auth.isLoggedIn) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.email,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(_role(user), style: TextStyle(color: scheme.primary)),
                    const SizedBox(height: 16),
                    if (!auth.isLoggedIn)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _open(context, const MuqtaddiLoginScreen()),
                          icon: const Icon(Icons.login),
                          label: Text(appLocalization.t(AppStrings.login)),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () =>
                            _open(context, const EditProfileScreen()),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(appLocalization.t(AppStrings.editProfile)),
                      ),
                    if (user?.verificationStatus == VerificationStatus.pending)
                      Text(appLocalization.t('verification_pending')),
                    if (auth.isLoggedIn &&
                        user?.role == UserRole.muqtaddi &&
                        [
                          VerificationStatus.none,
                          VerificationStatus.rejected,
                        ].contains(user?.verificationStatus))
                      TextButton.icon(
                        onPressed: auth.isLoading || masjid == null
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final success = await auth
                                    .requestVerification();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      appLocalization.t(
                                        success
                                            ? 'verification_submitted'
                                            : 'feed_error',
                                      ),
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.verified_user_outlined),
                        label: Text(appLocalization.t('verification_request')),
                      ),
                  ],
                ),
              ),
            ),
            _heading(context, appLocalization.t(AppStrings.selectedMasjid)),
            Card(
              child: ListTile(
                leading: Icon(Icons.mosque_outlined, color: scheme.primary),
                title: Text(
                  masjid == null
                      ? appLocalization.t(AppStrings.selectMasjid)
                      : appLocalization.isRTL && masjid.nameUrdu.isNotEmpty
                      ? masjid.nameUrdu
                      : masjid.name,
                ),
                subtitle: Text(
                  masjid?.location ??
                      appLocalization.t('choose_masjid_subtitle'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _open(context, const MasjidSelectionScreen(isPicker: true)),
              ),
            ),
            _heading(context, appLocalization.t('settings_preferences')),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      Icons.dark_mode_outlined,
                      color: scheme.primary,
                    ),
                    title: Text(appLocalization.t(AppStrings.darkMode)),
                    value: settings.isDarkMode,
                    onChanged: (_) => settings.toggleDarkMode(),
                  ),
                  ListTile(
                    leading: Icon(Icons.language, color: scheme.primary),
                    title: Text(appLocalization.t(AppStrings.language)),
                    subtitle: Text(appLocalization.isRTL ? 'اردو' : 'English'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _language(context),
                  ),
                ],
              ),
            ),
            _heading(context, appLocalization.t('prayer_reminders')),
            const PrayerReminderSettings(),
            _heading(context, appLocalization.t('settings_management')),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: scheme.primary,
                    ),
                    title: Text(appLocalization.t(AppStrings.adminPanel)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(
                      context,
                      manage
                          ? const AdminPanelScreen()
                          : const AdminLoginScreen(),
                    ),
                  ),
                  if (manage)
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(appLocalization.t('review_members')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(
                        context,
                        MemberVerificationScreen(masjidId: masjid!.id),
                      ),
                    ),
                  if (auth.isSuperAdmin)
                    ListTile(
                      leading: const Icon(Icons.fact_check_outlined),
                      title: Text(appLocalization.t('super_admin_dashboard')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(context, const SuperAdminDashboard()),
                    ),
                  if (auth.isLoggedIn && user?.isAdminOrImam != true)
                    ListTile(
                      leading: const Icon(Icons.mosque_outlined),
                      title: Text(appLocalization.t('claim_masjid_action')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(context, const ClaimMasjidScreen()),
                    ),
                ],
              ),
            ),
            _heading(context, appLocalization.t('settings_support')),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(appLocalization.t('settings_support')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _support(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(appLocalization.t(AppStrings.privacyPolicy)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const PrivacyPolicyScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(appLocalization.t('icon_attribution')),
                    onTap: () => launchUrl(
                      Uri.parse(
                        'https://www.streamlinehq.com/icons/nova-line-free',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ),
            if (auth.isLoggedIn) ...[
              _heading(context, appLocalization.t('settings_account')),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(appLocalization.t('sign_out')),
                      onTap: auth.isLoading ? null : auth.signOut,
                    ),
                    ListTile(
                      leading: Icon(Icons.delete_outline, color: scheme.error),
                      title: Text(
                        appLocalization.t('delete_account_title'),
                        style: TextStyle(color: scheme.error),
                      ),
                      onTap: auth.isLoading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final deleted = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const DeleteAccountDialog(),
                              );
                              if (deleted == true) {
                                messenger.showSnackBar(
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
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
