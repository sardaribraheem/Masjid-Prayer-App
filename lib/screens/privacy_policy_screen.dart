import 'package:flutter/material.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(appLocalization.t(AppStrings.privacyPolicy))),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          appLocalization.t('privacy_updated'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        for (final section in [
          'account',
          'community',
          'location',
          'retention',
          'deletion',
          'contact',
        ]) ...[
          Text(
            appLocalization.t('privacy_${section}_title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(appLocalization.t('privacy_${section}_body')),
          const SizedBox(height: 24),
        ],
      ],
    ),
  );
}
