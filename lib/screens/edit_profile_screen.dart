import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Lightweight screen for editing the current user's display name and
/// password. The user must be signed in (we redirect otherwise).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _displayNameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      _showError(appLocalization.t(AppStrings.loginRequired));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Update display name if it changed.
      final newName = _displayNameController.text.trim();
      if (newName.isNotEmpty && newName != user.displayName) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'username': newName});
        await user.updateDisplayName(newName);
      }

      // 2. Update password if a new one was provided.
      final newPassword = _newPasswordController.text;
      if (newPassword.isNotEmpty) {
        // Re-authenticate first — Firebase requires recent login for sensitive ops.
        final credential = EmailAuthProvider.credential(
          email: user.email ?? '',
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      }

      // Reload the user to ensure cached profile is fresh.
      await user.reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalization.t(AppStrings.passwordChanged)),
          backgroundColor: ColorPalette.success,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_mapFirebaseError(e));
    } catch (e) {
      if (!mounted) return;
      _showError('${appLocalization.t(AppStrings.error)}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: ColorPalette.error),
    );
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return appLocalization.t(AppStrings.invalidPassword);
      case 'weak-password':
        return appLocalization.t(AppStrings.passwordMismatch);
      case 'requires-recent-login':
        return appLocalization.t(AppStrings.loginRequired);
      default:
        return '${appLocalization.t(AppStrings.error)}: ${e.message ?? e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appLocalization.t(AppStrings.editProfile)),
          backgroundColor: ColorPalette.primary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  appLocalization.t(AppStrings.loginRequired),
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.editProfile)),
        backgroundColor: ColorPalette.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Read-only account info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorPalette.primary.withValues(alpha: 0.08),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.email ?? appLocalization.t(AppStrings.guest),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Display name field
              Text(
                appLocalization.t(AppStrings.yourName),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _displayNameController,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: appLocalization.t(AppStrings.enterYourName),
                  prefixIcon: Icon(Icons.person, color: ColorPalette.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Password section
              Text(
                appLocalization.t(AppStrings.changePassword),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                appLocalization.t(AppStrings.passwordOptional),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: appLocalization.t(AppStrings.oldPassword),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: ColorPalette.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (_newPasswordController.text.isNotEmpty &&
                      (value == null || value.isEmpty)) {
                    return appLocalization.t(
                      AppStrings.pleaseEnterUsernameAndPassword,
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: appLocalization.t(AppStrings.newPassword),
                  prefixIcon: Icon(Icons.lock, color: ColorPalette.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return appLocalization.t(AppStrings.invalidPassword);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: appLocalization.t(AppStrings.confirmPassword),
                  prefixIcon: Icon(Icons.lock, color: ColorPalette.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  final newPassword = _newPasswordController.text;
                  if (newPassword.isNotEmpty && value != newPassword) {
                    return appLocalization.t(AppStrings.passwordMismatch);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving
                        ? appLocalization.t(AppStrings.submitting)
                        : appLocalization.t(AppStrings.save),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
