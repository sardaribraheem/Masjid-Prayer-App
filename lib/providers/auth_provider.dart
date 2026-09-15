import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart' as google;
import '../models/app_data.dart' as app;

/// Provides authentication state and operations using Firebase Auth.
/// Wraps Firebase Auth to expose a ChangeNotifier interface for the UI.
class AuthProvider extends ChangeNotifier {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final google.GoogleSignIn _googleSignIn = google.GoogleSignIn();

  app.User? _currentUser;
  bool _isLoading = false;
  String? _error;

  app.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && _currentUser!.isLoggedIn;

  AuthProvider() {
    // Listen to Firebase Auth state changes
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Handle Firebase Auth state changes
  void _onAuthStateChanged(auth.User? firebaseUser) {
    if (firebaseUser == null) {
      // User signed out — create a guest user
      _currentUser = app.User(
        id: '',
        username: 'Guest',
        role: app.UserRole.guest,
      );
    } else {
      // User is signed in
      _currentUser = app.User(
        id: firebaseUser.uid,
        username: firebaseUser.displayName ?? firebaseUser.email ?? 'User',
        role: app.UserRole.verifiedUser,
        isLoggedIn: true,
        lastLogin: DateTime.now(),
      );
    }
    notifyListeners();
  }

  /// Sign in anonymously (default for new users)
  Future<bool> signInAnonymously() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseAuth.signInAnonymously();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register a new account with email and password
  Future<bool> registerWithEmail(String email, String password, String displayName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google.
  ///
  /// This is gated to admin users only. After Firebase Auth accepts the
  /// credential we re-check the ID token's custom claims and refuse to keep
  /// the session open if the user is not an admin. The super-admin role
  /// (email match) is also accepted.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final google.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final google.GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        _error = 'Sign-in failed: no user returned';
        await _firebaseAuth.signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Force a fresh token so we read the latest custom claims.
      final idTokenResult = await firebaseUser.getIdTokenResult(true);
      final claims = idTokenResult.claims ?? const <String, dynamic>{};

      final isAdmin = claims['admin'] == true || claims['imam'] == true;
      final isSuperAdmin = claims['superadmin'] == true ||
          firebaseUser.email == 'superadmin@masjid-app.com';

      if (!isAdmin && !isSuperAdmin) {
        // Reject — sign the user back out so the session never sticks.
        await _firebaseAuth.signOut();
        _error =
            'This account is not registered as a masjid admin. Contact the super admin.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      // Best-effort: drop any partial session.
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
      return false;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Clear any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
