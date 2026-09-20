import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'muqtaddi_register_screen.dart';

/// Login screen for normal Muqtaddis (`latesttodo.md` §2, §10).
///
/// Uses the AuthProvider's Firestore-backed role flow: after Firebase Auth
/// sign-in, `hydrateUser` loads the authoritative `users/{uid}` document so
/// the user is shown with their real role (muqtaddi / verified / imam / admin).
class MuqtaddiLoginScreen extends StatefulWidget {
  const MuqtaddiLoginScreen({super.key});

  @override
  State<MuqtaddiLoginScreen> createState() => _MuqtaddiLoginScreenState();
}

class _MuqtaddiLoginScreenState extends State<MuqtaddiLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(appLocalization.t(AppStrings.fieldRequired));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithEmail(email, password);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      _showError(
        authProvider.error ?? appLocalization.t(AppStrings.invalidUsernameOrPassword),
      );
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
        title: Text(appLocalization.t(AppStrings.muqtaddiLoginTitle)),
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
              appLocalization.t(AppStrings.loginSubtitle),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ColorPalette.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 28),

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
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                labelText: appLocalization.t(AppStrings.password),
                hintText: appLocalization.t(AppStrings.enterYourPassword),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login button
            ElevatedButton(
              onPressed: authProvider.isLoading ? null : _handleLogin,
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      appLocalization.t(AppStrings.signInButton),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Link to register
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  appLocalization.t(AppStrings.dontHaveAccount),
                  style: const TextStyle(fontSize: 14),
                ),
                TextButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MuqtaddiRegisterScreen(),
                            ),
                          );
                        },
                  child: Text(
                    appLocalization.t(AppStrings.createAccount),
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