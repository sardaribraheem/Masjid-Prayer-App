import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'admin_login_screen.dart';
import 'edit_profile_screen.dart';
import 'masjid_selection_screen.dart';

/// Settings Page - Account, profile, preferences
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _firebaseAuth.currentUser;
    final isLoggedIn = currentUser != null;
    final displayName =
        currentUser?.displayName ?? currentUser?.email ?? 'Guest';
    final email = currentUser?.email ?? '';

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
                            color:
                                ColorPalette.primary.withValues(alpha: 0.2),
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
                                    : appLocalization
                                        .t(AppStrings.guest),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorPalette.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (!isLoggedIn)
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AdminLoginScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorPalette.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                  ),
                                  child: Text(
                                    appLocalization.t(AppStrings.login),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const EditProfileScreen(),
                                          ),
                                        );
                                        if (mounted) setState(() {});
                                      },
                                      icon: const Icon(Icons.edit, size: 14),
                                      label: Text(
                                        appLocalization.t(
                                            AppStrings.editProfile),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: ColorPalette.primary,
                                        side: BorderSide(
                                            color: ColorPalette.primary),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await _firebaseAuth.signOut();
                                        if (mounted) setState(() {});
                                      },
                                      icon: const Icon(Icons.logout, size: 14),
                                      label: const Text(
                                        'Logout',
                                        style: TextStyle(fontSize: 12),
                                      ),
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
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
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
                              appLocalization
                                  .t(AppStrings.selectMasjid),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppData.selectedMasjid?.location ??
                              appLocalization
                                  .t(AppStrings.selectMasjid),
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
                                  builder: (_) =>
                                      const MasjidSelectionScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.location_on),
                            label: Text(
                              appLocalization
                                  .t(AppStrings.changeMasjid),
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
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
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
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? ColorPalette.darkBorder
                                : ColorPalette.lightBorder,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.dark_mode,
                              title: appLocalization
                                  .t(AppStrings.darkMode),
                              trailing: Switch(
                                value: settings.isDarkMode,
                                onChanged: (_) =>
                                    settings.toggleDarkMode(),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? ColorPalette.darkBorder
                                  : ColorPalette.lightBorder,
                            ),
                            _SettingsTile(
                              icon: Icons.notifications,
                              title: appLocalization
                                  .t(AppStrings.notifications),
                              trailing: Switch(
                                value: settings.notificationsEnabled,
                                onChanged: (_) =>
                                    settings.toggleNotifications(),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? ColorPalette.darkBorder
                                  : ColorPalette.lightBorder,
                            ),
                            _LanguageTile(
                              icon: Icons.language,
                              title: appLocalization
                                  .t(AppStrings.language),
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
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
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
                      label:
                          Text(appLocalization.t(AppStrings.adminPanel)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalette.tertiary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
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
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          onTap: () {},
                        ),
                        Divider(
                          height: 1,
                          color: ColorPalette.lightBorder,
                        ),
                        _SettingsTile(
                          icon: Icons.help,
                          title: appLocalization.t(AppStrings.help),
                          onTap: () {},
                        ),
                        Divider(
                          height: 1,
                          color: ColorPalette.lightBorder,
                        ),
                        _SettingsTile(
                          icon: Icons.privacy_tip,
                          title: appLocalization
                              .t(AppStrings.privacyPolicy),
                          onTap: () {},
                        ),
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
      trailing: trailing ??
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
                    title:
                        Text(appLocalization.t(AppStrings.english)),
                    onTap: () => Navigator.pop(context, 'en'),
                    selected: settings.locale == 'en',
                    selectedTileColor: ColorPalette.primary
                        .withValues(alpha: 0.2),
                  ),
                  ListTile(
                    title:
                        Text(appLocalization.t(AppStrings.urdu)),
                    onTap: () => Navigator.pop(context, 'ur'),
                    selected: settings.locale == 'ur',
                    selectedTileColor: ColorPalette.primary
                        .withValues(alpha: 0.2),
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
