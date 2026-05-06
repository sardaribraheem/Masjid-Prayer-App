import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'admin_panel_screen.dart';
import 'admin_register_screen.dart';

/// Admin login screen
/// Admins/Imams can log in here to edit prayer times
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  // Controllers to get text from input fields
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();
  String? errorMessage; // Show error if login fails
  bool isLoading = false; // Show loading indicator

  @override
  void dispose() {
    // Clean up when we're done with this screen
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Authenticate admin against Firestore
  Future<void> handleLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
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
      // Try to authenticate against Firestore
      final masjid = await _firebaseService.authenticateAdmin(
        username,
        password,
      );

      if (masjid != null) {
        // Login successful! Save the login state and go to Admin Panel
        await _storageService.saveAdminLoginStatus(masjid.id, username);
        AppData.selectedMasjid = masjid;
        AppData.selectedMasjidId = masjid.id;

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
          );
        }
      } else {
        // Try fallback to local data for testing
        Masjid? foundMasjid;
        for (var masjid in AppData.allMasjids) {
          if (masjid.username == username && masjid.password == password) {
            foundMasjid = masjid;
            break;
          }
        }

        if (foundMasjid != null) {
          await _storageService.saveAdminLoginStatus(foundMasjid.id, username);
          AppData.selectedMasjid = foundMasjid;
          AppData.selectedMasjidId = foundMasjid.id;

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
            );
          }
        } else {
          setState(() {
            errorMessage = appLocalization.t(
              AppStrings.invalidUsernameOrPassword,
            );
          });
        }
      }
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
              const SizedBox(height: 30),

              // Username field
              TextField(
                controller: usernameController,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: appLocalization.t(AppStrings.username),
                  hintText: appLocalization.t(AppStrings.enterYourUsername),
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
                obscureText: true, // Hide the password
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
