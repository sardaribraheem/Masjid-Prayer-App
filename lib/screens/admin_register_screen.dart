import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/app_data.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Screen for registering a new masjid with Firebase Auth
/// Creates a member account and a pending masjid approval request.
class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final masjidNameController = TextEditingController();
  final locationController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  String? errorMessage;
  String? successMessage;
  bool isLoading = false;

  @override
  void dispose() {
    masjidNameController.dispose();
    locationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handle the registration of a new masjid using Firebase Auth
  Future<void> handleRegister() async {
    if (isLoading) return;
    final masjidName = masjidNameController.text.trim();
    final location = locationController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Simple validation
    if (masjidName.isEmpty ||
        location.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      setState(() {
        errorMessage = appLocalization.t(AppStrings.allFieldsRequired);
        successMessage = null;
      });
      return;
    }

    if (masjidName.length > 100 || location.length > 500) {
      setState(
        () => errorMessage = appLocalization.t('masjid_request_too_long'),
      );
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = appLocalization.t(AppStrings.passwordsDoNotMatch);
        successMessage = null;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage = appLocalization.t(AppStrings.passwordMustBeAtLeast);
        successMessage = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    auth.User? applicant;
    bool requestSaved = false;
    try {
      // Step 1: Create Firebase Auth account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Failed to create account';
        });
        return;
      }

      applicant = credential.user;
      // Step 2: Update display name
      await credential.user!.updateDisplayName(masjidName);

      // Register the applicant and request together. Only trusted approval
      // creates a masjid and grants imam access.
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.set(firestore.collection('users').doc(applicant!.uid), {
        'username': masjidName,
        'email': applicant.email,
        'role': UserRole.muqtaddi.value,
        'verificationStatus': VerificationStatus.none.value,
        'eventPermission': EventPermission.none.value,
        'masjidId': null,
        'masjidName': null,
        'createdAt': DateTime.now().toIso8601String(),
      });
      batch.set(firestore.collection('claimRequests').doc(), {
        'masjidId': null,
        'imamUid': applicant.uid,
        'imamName': masjidName,
        'imamEmail': applicant.email,
        'masjidName': masjidName,
        'masjidLocation': location,
        'status': 'pending',
        'type': 'new_masjid',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      requestSaved = true;
      if (mounted) {
        await context.read<AuthProvider>().hydrateUser(applicant.uid);
      }

      if (mounted) {
        setState(() {
          successMessage = appLocalization.t('masjid_request_submitted');
          errorMessage = null;
        });

        masjidNameController.clear();
        locationController.clear();
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } on auth.FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'email-already-in-use') {
          errorMessage = 'An account with this email already exists';
        } else if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak';
        } else {
          errorMessage = e.message ?? 'Registration failed';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage =
            '${appLocalization.t(AppStrings.registrationFailed)}: $e';
      });
    } finally {
      // No Firestore documents were committed if request submission failed.
      // Roll back the just-created Auth account when possible.
      if (!requestSaved && applicant != null) {
        try {
          await applicant.delete();
        } catch (_) {
          if (mounted) {
            setState(() {
              errorMessage = appLocalization.t('masjid_request_retry_login');
            });
          }
        }
      }
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
        title: Text(appLocalization.t(AppStrings.registerNewMasjid)),
        backgroundColor: ColorPalette.tertiary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Title
              Text(
                appLocalization.t(AppStrings.registerNewMasjid),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appLocalization.t(AppStrings.createAdminAccount),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Masjid Name field
              TextField(
                controller: masjidNameController,
                maxLength: 100,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: appLocalization.t(AppStrings.masjidName),
                  hintText: appLocalization.t(AppStrings.enterMasjidName),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.mosque),
                ),
              ),
              const SizedBox(height: 16),

              // Location field
              TextField(
                controller: locationController,
                maxLength: 500,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: appLocalization.t(AppStrings.location),
                  hintText: appLocalization.t(AppStrings.enterLocation),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

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
                  hintText: appLocalization.t(AppStrings.atLeast6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password field
              TextField(
                controller: confirmPasswordController,
                enabled: !isLoading,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: appLocalization.t(AppStrings.confirmPassword),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
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

              // Success message
              if (successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorPalette.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ColorPalette.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      successMessage!,
                      style: TextStyle(
                        color: ColorPalette.success,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              // Register button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.grey,
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
                      : const Text(
                          'Register Masjid',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
