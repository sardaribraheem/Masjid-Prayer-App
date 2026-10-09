import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'admin_panel_screen.dart';
import 'admin_register_screen.dart';

/// Admin login screen using Firebase Auth (Email/Password)
/// Admins/Imams can log in here to manage their masjid
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  String? errorMessage;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Authenticate an imam/admin using the real Firestore user record rather than
  /// the legacy masjid.username == auth email lookup. This avoids the login trap
  /// where a normal user account can never become a masjid manager unless their
  /// UID is linked to the correct masjid.
  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = appLocalization.t(
          AppStrings.pleaseEnterUsernameAndPassword,
        );
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        setState(() {
          errorMessage = appLocalization.t(
            AppStrings.invalidUsernameOrPassword,
          );
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      final userData = userDoc.data() ?? const <String, dynamic>{};
      final role = UserRole.fromValue(userData['role'] as String?);
      final masjidId = userData['masjidId'] as String?;

      if (role != UserRole.imam && role != UserRole.admin) {
        setState(() {
          errorMessage =
              'This account is not linked to a masjid as an imam/admin.';
        });
        return;
      }

      if (masjidId == null || masjidId.isEmpty) {
        setState(() {
          errorMessage =
              'This masjid manager account is not assigned to a masjid yet.';
        });
        return;
      }

      final masjid = await _firebaseService.getMasjidById(masjidId);
      if (masjid == null) {
        setState(() {
          errorMessage = 'The assigned masjid could not be found.';
        });
        return;
      }

      await _storageService.saveAdminLoginStatus(masjid.id, email);
      AppData.selectedMasjid = masjid;
      AppData.selectedMasjidId = masjid.id;

      if (mounted) {
        await context.read<AuthProvider>().hydrateUser(firebaseUser.uid);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
        );
      }
    } on auth.FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          errorMessage = appLocalization.t(
            AppStrings.invalidUsernameOrPassword,
          );
        } else if (e.code == 'wrong-password') {
          errorMessage = appLocalization.t(
            AppStrings.invalidUsernameOrPassword,
          );
        } else {
          errorMessage = e.message ?? 'Login failed';
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Login error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.adminLogin)),
        backgroundColor: ColorPalette.tertiary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Title
              Text(
                appLocalization.t(AppStrings.adminLogin),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in with your email and password',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              // Email field
              TextField(
                controller: emailController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'admin@masjid.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: passwordController,
                enabled: !isLoading,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: appLocalization.t(AppStrings.password),
                  hintText: appLocalization.t(AppStrings.enterYourPassword),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 12),

              // Error message (if any)
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorPalette.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ColorPalette.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: ColorPalette.error, fontSize: 14),
                    ),
                  ),
                ),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.tertiary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: ColorPalette.lightBorder,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          appLocalization.t(AppStrings.login),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Google Sign-In button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final authProvider = context.read<AuthProvider>();
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final navigator = Navigator.of(context);
                          final success = await authProvider.signInWithGoogle();
                          if (!mounted) return;
                          if (success) {
                            final user = authProvider.currentUser;
                            if (user == null ||
                                !user.isAdminOrImam ||
                                user.masjidId == null) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    appLocalization.t(
                                      'manager_approval_required',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }
                            final masjid = await _firebaseService.getMasjidById(
                              user.masjidId!,
                            );
                            if (!mounted || masjid == null) return;
                            AppData.selectedMasjid = masjid;
                            AppData.selectedMasjidId = masjid.id;
                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) => const AdminPanelScreen(),
                              ),
                            );
                          } else if (authProvider.error != null) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(authProvider.error!),
                                backgroundColor: ColorPalette.error,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.login, color: Colors.black54),
                  label: const Text('Sign in with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Register Masjid button
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminRegisterScreen(),
                          ),
                        );
                      },
                child: Text(
                  appLocalization.t(AppStrings.registerNewMasjid),
                  style: TextStyle(fontSize: 14, color: ColorPalette.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
