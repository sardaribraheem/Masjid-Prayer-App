import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localization.dart';

/// Uses the login email without revealing whether an account exists.
class PasswordResetButton extends StatefulWidget {
  final TextEditingController emailController;
  final bool disabled;
  const PasswordResetButton({
    super.key,
    required this.emailController,
    this.disabled = false,
  });
  @override
  State<PasswordResetButton> createState() => _PasswordResetButtonState();
}

class _PasswordResetButtonState extends State<PasswordResetButton> {
  bool _sending = false;
  Future<void> _send() async {
    if (_sending) return;
    final email = widget.emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      messenger.showSnackBar(
        SnackBar(content: Text(appLocalization.t('reset_enter_email'))),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(appLocalization.t('reset_sent'))),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              appLocalization.t(
                error.code == 'user-not-found' ? 'reset_sent' : 'reset_failed',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: widget.disabled || _sending ? null : _send,
    child: Text(appLocalization.t(_sending ? 'submitting' : 'forgot_password')),
  );
}
