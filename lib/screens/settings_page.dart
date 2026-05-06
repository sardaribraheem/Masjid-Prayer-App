import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../theme/app_state.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'admin_login_screen.dart';
import 'masjid_selection_screen.dart';

/// Settings Page - Account, profile, preferences
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
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
                      '👤 ${appLocalization.t(AppStrings.userProfile)}',
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
                                appLocalization.t(AppStrings.userProfile),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appLocalization.t(AppStrings.settings),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorPalette.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // Edit profile
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorPalette.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                                child: Text(
                                  appLocalization.t(AppStrings.editProfile),
                                  style: const TextStyle(fontSize: 12),
                                ),
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
                    '🕌 ${appLocalization.t(AppStrings.masjidSettings)}',
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
                    '⚙️ ${appLocalization.t(AppStrings.preferences)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
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
                            value: appStateProvider.isDarkMode,
                            onChanged: (value) {
                              appStateProvider.toggleDarkMode();
                            },
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? ColorPalette.darkBorder
                              : ColorPalette.lightBorder,
                        ),
                        _SettingsTile(
                          icon: Icons.notifications,
                          title: appLocalization.t(AppStrings.notifications),
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() => _notificationsEnabled = value);
                            },
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).brightness == Brightness.dark
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
                    '🔐 ${appLocalization.t(AppStrings.adminPanel)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    'ℹ️ ${appLocalization.t(AppStrings.about)}',
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
                          onTap: () {},
                        ),
                        Divider(height: 1, color: ColorPalette.lightBorder),
                        _SettingsTile(
                          icon: Icons.help,
                          title: appLocalization.t(AppStrings.help),
                          onTap: () {},
                        ),
                        Divider(height: 1, color: ColorPalette.lightBorder),
                        _SettingsTile(
                          icon: Icons.privacy_tip,
                          title: appLocalization.t(AppStrings.privacyPolicy),
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
    final currentLanguage = appLocalization.locale == 'en'
        ? appLocalization.t(AppStrings.english)
        : appLocalization.t(AppStrings.urdu);

    return ListTile(
      leading: Icon(icon, color: ColorPalette.primary),
      title: Text(title),
      subtitle: Text(currentLanguage),
      trailing: GestureDetector(
        onTap: () async {
          // Show language selection dialog
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
                    selected: appLocalization.locale == 'en',
                    selectedTileColor: ColorPalette.primary.withValues(
                      alpha: 0.2,
                    ),
                  ),
                  ListTile(
                    title: Text(appLocalization.t(AppStrings.urdu)),
                    onTap: () => Navigator.pop(context, 'ur'),
                    selected: appLocalization.locale == 'ur',
                    selectedTileColor: ColorPalette.primary.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );

          if (selected != null && selected != appLocalization.locale) {
            await appLocalization.setLanguage(selected);
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
