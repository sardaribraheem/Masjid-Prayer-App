import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/firebase_service.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Screen for registering a new masjid
/// Admins/Imams can create a new masjid account here
class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  // Controllers for form fields
  final masjidNameController = TextEditingController();
  final locationController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  String? errorMessage;
  String? successMessage;
  bool isLoading = false;

  @override
  void dispose() {
    masjidNameController.dispose();
    locationController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handle the registration of a new masjid
  Future<void> handleRegister() async {
    final masjidName = masjidNameController.text.trim();
    final location = locationController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Simple validation
    if (masjidName.isEmpty ||
        location.isEmpty ||
        username.isEmpty ||
        password.isEmpty) {
      setState(() {
        errorMessage = appLocalization.t(AppStrings.allFieldsRequired);
        successMessage = null;
      });
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

    try {
      // Default prayer times for new masjid
      final defaultPrayerTimes = [
        PrayerTime(name: 'Fajr', time: '5:30 AM'),
        PrayerTime(name: 'Dhuhr', time: '12:45 PM'),
        PrayerTime(name: 'Asr', time: '3:30 PM'),
        PrayerTime(name: 'Maghrib', time: '6:15 PM'),
        PrayerTime(name: 'Isha', time: '7:45 PM'),
      ];

      // Create new masjid object
      final newMasjid = Masjid(
        name: masjidName,
        location: location,
        username: username,
        password: password,
        prayerTimes: defaultPrayerTimes,
        jummahTime: '1:00 PM',
      );

      // Try to register in Firestore
      final success = await _firebaseService.registerMasjid(newMasjid);

      if (success) {
        // Also add to local list
        AppData.allMasjids.add(newMasjid);

        if (mounted) {
          setState(() {
            successMessage = appLocalization.t(AppStrings.registrationSuccess);
            errorMessage = null;
          });

          // Clear the form
          masjidNameController.clear();
          locationController.clear();
          usernameController.clear();
          passwordController.clear();
          confirmPasswordController.clear();

          // Go back after 2 seconds
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        setState(() {
          errorMessage = appLocalization.t(AppStrings.registrationFailed);
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            '${appLocalization.t(AppStrings.registrationFailed)}: $e';
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

              // Username field
              TextField(
                controller: usernameController,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: appLocalization.t(AppStrings.username),
                  hintText: appLocalization.t(AppStrings.mustBeUnique),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
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
