import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_reminder_provider.dart';
import '../l10n/app_localization.dart';

class PrayerReminderSettings extends StatelessWidget {
  const PrayerReminderSettings({super.key});
  String _t(String key) => appLocalization.t(key);
  String _lead(int minutes) =>
      _t('reminder_lead_value').replaceAll('{minutes}', '$minutes');
  Future<void> _chooseLead(
    BuildContext context,
    PrayerReminderProvider provider,
  ) async {
    final controller = TextEditingController(text: '${provider.leadMinutes}');
    final form = GlobalKey<FormState>();
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('reminder_lead_title')),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final minutes in [5, 10, 15, 20, 30, 60])
                      ChoiceChip(
                        label: Text(
                          _t(
                            'reminder_minutes',
                          ).replaceAll('{minutes}', '$minutes'),
                        ),
                        selected: minutes == provider.leadMinutes,
                        onSelected: (_) => Navigator.pop(context, minutes),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  decoration: InputDecoration(labelText: _t('reminder_custom')),
                  validator: (value) {
                    final minutes = int.tryParse(value?.trim() ?? '');
                    return minutes == null || minutes < 1 || minutes > 60
                        ? _t('reminder_range')
                        : null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, int.parse(controller.text.trim()));
              }
            },
            child: Text(_t('save')),
          ),
        ],
      ),
    );
    if (value != null) await provider.setLeadMinutes(value);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<PrayerReminderProvider>();
    final scheme = Theme.of(context).colorScheme;
    final status = switch (reminders.status) {
      PrayerReminderStatus.off => 'reminder_off',
      PrayerReminderStatus.scheduled => 'reminder_on',
      PrayerReminderStatus.permissionsNeeded => 'reminder_permissions',
      PrayerReminderStatus.noMasjid => 'reminder_no_masjid',
      PrayerReminderStatus.noTimes => 'reminder_no_times',
      PrayerReminderStatus.unsupported => 'reminder_android_only',
      PrayerReminderStatus.error => reminders.errorKey ?? 'reminder_failed',
    };
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            secondary: Icon(
              Icons.notifications_outlined,
              color: scheme.primary,
            ),
            title: Text(_t('prayer_reminders')),
            subtitle: Semantics(
              liveRegion: true,
              child: Text(
                reminders.busy ? _t('reminder_updating') : _t(status),
              ),
            ),
            value: reminders.supported && reminders.enabled,
            onChanged: reminders.supported && !reminders.busy
                ? reminders.setEnabled
                : null,
          ),
          ListTile(
            title: Text(_t('reminder_lead_title')),
            subtitle: Text(_lead(reminders.leadMinutes)),
            trailing: const Icon(Icons.chevron_right),
            onTap: reminders.busy
                ? null
                : () => _chooseLead(context, reminders),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              _t('reminder_timetable_note'),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
          if (reminders.masjidName != null && reminders.enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(reminders.masjidName!),
            ),
          if (reminders.errorKey != null &&
              reminders.status != PrayerReminderStatus.error)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _t(reminders.errorKey!),
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ),
          if (reminders.supported &&
              reminders.status == PrayerReminderStatus.permissionsNeeded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                children: [
                  TextButton(
                    onPressed: reminders.busy
                        ? null
                        : () => reminders.setEnabled(true),
                    child: Text(_t('reminder_allow')),
                  ),
                  TextButton(
                    onPressed: reminders.busy
                        ? null
                        : reminders.openNotificationSettings,
                    child: Text(_t('reminder_open_settings')),
                  ),
                ],
              ),
            ),
          if (reminders.supported &&
              reminders.status == PrayerReminderStatus.error)
            TextButton(
              onPressed: reminders.busy ? null : reminders.refresh,
              child: Text(_t('refresh')),
            ),
          if (reminders.supported && reminders.enabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.notifications_active_outlined),
                onPressed: reminders.busy
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (await reminders.testReminder()) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(_t('reminder_test_sent'))),
                          );
                        }
                      },
                label: Text(_t('reminder_test')),
              ),
            ),
        ],
      ),
    );
  }
}
