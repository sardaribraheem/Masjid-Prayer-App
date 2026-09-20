import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'muqtaddi_login_screen.dart';

/// Register screen for normal Muqtaddis (`latesttodo.md` §2).
///
/// Creates a Firebase Auth account AND a Firestore `users/{uid}` document
/// with role = `muqtaddi`. Verification/permissions are never self-assigned
/// here — an admin/imam grants them via the `users/{uid}` doc (§9).
class MuqtaddiRegisterScreen extends StatefulWidget {
  const MuqtaddiRegisterScreen({super.key});

  @override
  State<MuqtaddiRegisterScreen> createState() => _MuqtaddiRegisterScreenState();
}

class _MuqtaddiRegisterScreenState extends State<MuqtaddiRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty) {
      _showError(appLocalization.t(AppStrings.pleaseEnterYourName));
      return;
    }
    if (email.isEmpty) {
      _showError(appLocalization.t(AppStrings.fieldRequired));
      return;
    }
    if (password.length < 6) {
      _showError(appLocalization.t(AppStrings.passwordTooShort));
      return;
    }
    if (password != confirm) {
      _showError(appLocalization.t(AppStrings.passwordsDoNotMatch));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.registerWithEmail(
      email: email,
      password: password,
      displayName: name,
      masjidId: AppData.selectedMasjidId,
      masjidName: AppData.selectedMasjid?.name,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalization.t(AppStrings.registerSuccessMsg)),
          backgroundColor: ColorPalette.success,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      _showError(authProvider.error ?? appLocalization.t(AppStrings.registrationFailed));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorPalette.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.muqtaddiRegisterTitle)),
        backgroundColor: ColorPalette.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Subtitle
            Text(
              appLocalization.t(AppStrings.registerSubtitle),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ColorPalette.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // Full name
            TextField(
              controller: _nameController,
              enabled: !authProvider.isLoading,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: appLocalization.t(AppStrings.fullName),
                hintText: appLocalization.t(AppStrings.enterFullName),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Email
            TextField(
              controller: _emailController,
              enabled: !authProvider.isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'email@example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Password
            TextField(
              controller: _passwordController,
              enabled: !authProvider.isLoading,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: appLocalization.t(AppStrings.password),
                hintText: appLocalization.t(AppStrings.enterYourPassword),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm password
            TextField(
              controller: _confirmController,
              enabled: !authProvider.isLoading,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleRegister(),
              decoration: InputDecoration(
                labelText: appLocalization.t(AppStrings.confirmPassword),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Register button
            ElevatedButton(
              onPressed: authProvider.isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: ColorPalette.lightBorder,
              ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      appLocalization.t(AppStrings.createAccount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Link to login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  appLocalization.t(AppStrings.alreadyHaveAccount),
                  style: const TextStyle(fontSize: 14),
                ),
                TextButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const MuqtaddiLoginScreen(),
                            ),
                          );
                        },
                  child: Text(
                    appLocalization.t(AppStrings.signInButton),
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorPalette.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}