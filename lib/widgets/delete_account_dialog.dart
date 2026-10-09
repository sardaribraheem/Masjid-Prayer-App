import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localization.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});
  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_saving) return;
    final provider = context.read<AuthProvider>();
    setState(() {
      _saving = true;
      _error = null;
    });
    final success = await provider.deleteAccount(password: _password.text);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _error = provider.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final passwordAccount =
        firebase.FirebaseAuth.instance.currentUser?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ??
        false;
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(appLocalization.t('delete_account_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(appLocalization.t('delete_account_explanation')),
              if (passwordAccount)
                TextField(
                  controller: _password,
                  enabled: !_saving,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: appLocalization.t('current_password'),
                  ),
                ),
              if (_saving) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: Text(appLocalization.t('cancel')),
          ),
          TextButton(
            onPressed: _saving ? null : _delete,
            child: Text(
              appLocalization.t(
                _saving ? 'deleting_account' : 'delete_account_title',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
