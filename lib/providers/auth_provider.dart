import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart' as google;
import '../models/app_data.dart' as app;
import '../services/account_deletion_service.dart';

/// Provides authentication state and operations using Firebase Auth.
///
/// Email/password is the PRIMARY path for normal Muqtaddis (`latesttodo.md`
/// §2, §10). There is NO anonymous fallback: a signed-out user is a guest who
/// can read public data but must register/log in to write.
///
/// Roles (`role`, `verificationStatus`, `eventPermission`) are read from the
/// Firestore `users/{uid}` document. A newly registered user is a plain
/// `muqtaddi` — verification and permissions can only be granted by an
/// admin/imam, not self-assigned (`§9`).
class AuthProvider extends ChangeNotifier {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  // Lazily created: on the web, GoogleSignIn() without a web client ID throws
  // at construction time (assertion in google_sign_in_web). Email/password is
  // the primary auth path for this MVP, so only build GoogleSignIn when the
  // (admin) Google sign-in is actually requested.
  google.GoogleSignIn? _googleSignIn;
  google.GoogleSignIn get _signIn {
    return _googleSignIn ??= google.GoogleSignIn();
  }

  StreamSubscription<auth.User?>? _authSubscription;
  StreamSubscription<firestore.DocumentSnapshot<Map<String, dynamic>>>?
  _userSubscription;
  int _authGeneration = 0;
  int _profileRevision = 0;
  bool _isSuperAdmin = false;
  bool get isSuperAdmin => isLoggedIn && _isSuperAdmin;
  app.User? _currentUser;
  bool _isLoading = false;
  String? _error;

  app.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && _currentUser!.isLoggedIn;

  AuthProvider() {
    // Listen to Firebase Auth state changes
    _authSubscription = _firebaseAuth.authStateChanges().listen(
      _onAuthStateChanged,
    );
  }

  /// Handle Firebase Auth state changes.
  ///
  /// Always maps to a client-side `app.User`. The authoritative role data is
  /// loaded from the `users/{uid}` Firestore doc (via [hydrateUser]); until
  /// that resolves, the user is shown as a plain `muqtaddi` so they can never
  /// appear with elevated permissions spuriously.
  void _onAuthStateChanged(auth.User? firebaseUser) {
    final generation = ++_authGeneration;
    _profileRevision = 0;
    _userSubscription?.cancel();
    _userSubscription = null;
    _isSuperAdmin = false;
    if (firebaseUser == null) {
      app.AppData.currentUser = app.User(
        id: '',
        username: 'Guest',
        role: app.UserRole.guest,
      );
      _currentUser = app.AppData.currentUser;
      notifyListeners();
    } else {
      _currentUser = app.User(
        id: firebaseUser.uid,
        username: firebaseUser.displayName ?? firebaseUser.email ?? 'User',
        email: firebaseUser.email ?? '',
        role: app.UserRole.muqtaddi,
        isLoggedIn: true,
        lastLogin: DateTime.now(),
      );
      app.AppData.currentUser = _currentUser!;
      notifyListeners();
      // Best-effort: hydrate authoritative role info from Firestore.
      hydrateUser(firebaseUser.uid);
      _userSubscription = _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .listen(
            (doc) {
              if (generation != _authGeneration) return;
              _profileRevision++;
              if (doc.exists) {
                _applyUserData(firebaseUser.uid, doc.data()!);
              } else {
                _currentUser = app.User(
                  id: firebaseUser.uid,
                  username: firebaseUser.displayName ?? 'User',
                  email: firebaseUser.email ?? '',
                  role: app.UserRole.muqtaddi,
                  isLoggedIn: true,
                );
                app.AppData.currentUser = _currentUser!;
                notifyListeners();
              }
            },
            onError: (Object error) {
              if (generation != _authGeneration) return;
              _error = 'Could not refresh your account permissions.';
              notifyListeners();
            },
          );
    }
  }

  /// Load the authoritative `users/{uid}` document and merge its role,
  /// verification and permission fields into the current user.
  ///
  /// Errors are silent here on purpose — the guest/muqtaddi default shown
  /// until the document loads is a safe (never elevated) state, and this is
  /// called on every auth-state change.
  Future<void> hydrateUser(String uid) async {
    final generation = _authGeneration;
    final profileRevision = _profileRevision;
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null || firebaseUser.uid != uid) return;
    try {
      final token = await firebaseUser.getIdTokenResult();
      final doc = await _firestore.collection('users').doc(uid).get();
      if (generation != _authGeneration ||
          _firebaseAuth.currentUser?.uid != uid) {
        return;
      }
      _isSuperAdmin = token.claims?['superAdmin'] == true;
      if (doc.exists && profileRevision == _profileRevision) {
        _applyUserData(uid, doc.data()!);
      } else {
        notifyListeners();
      }
    } catch (_) {
      // A failed lookup never grants management or super-admin access.
    }
  }

  void _applyUserData(String uid, Map<String, dynamic> data) {
    if (_firebaseAuth.currentUser?.uid != uid) return;
    final stored = app.User.fromJson({...data, 'id': uid});
    _currentUser = app.User(
      id: uid,
      username: stored.username,
      email: stored.email,
      role: stored.role,
      verificationStatus: stored.verificationStatus,
      eventPermission: stored.eventPermission,
      masjidId: stored.masjidId,
      masjidName: stored.masjidName,
      isLoggedIn: true,
      createdAt: stored.createdAt,
    );
    app.AppData.currentUser = _currentUser!;
    notifyListeners();
  }

  @override
  void dispose() {
    _authGeneration++;
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  /// Auth-state listener that also (re)hydrates role data when AuthProvider is
  /// created or the user's Firestore doc changes. Used by the UI via
  /// `context.watch<AuthProvider>()`.
  void refreshUser() {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      _onAuthStateChanged(firebaseUser);
    }
  }

  /// Register a new normal Muqtaddi account with email and password
  /// (`latesttodo.md` §2). Creates the Firebase Auth user AND a Firestore
  /// `users/{uid}` document with role = muqtaddi (never anything higher).
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? masjidId,
    String? masjidName,
  }) async {
    if (displayName.trim().isEmpty || displayName.trim().length > 100) {
      _error = 'Name must contain between 1 and 100 characters.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Firestore users/{uid} — role is always 'muqtaddi' at registration.
      // This doc is the authoritative source for role/permissions and can
      // only be elevated by an admin/imam (enforced by Firestore rules).
      final uid = credential.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'username': displayName.trim(),
        'email': credential.user!.email,
        'role': app.UserRole.muqtaddi.value,
        'verificationStatus': app.VerificationStatus.none.value,
        'eventPermission': app.EventPermission.none.value,
        'masjidId': masjidId,
        'masjidName': masjidName,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await hydrateUser(_firebaseAuth.currentUser!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _readableAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password (`latesttodo.md` §2, §10).
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await hydrateUser(_firebaseAuth.currentUser!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _readableAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request verification as a muqtaddi for the selected masjid.
  /// The request is stored on the authoritative Firestore user doc and keeps
  /// the user's role as `muqtaddi` until an imam/admin approves it.
  Future<bool> requestVerification() async {
    final currentUser = _currentUser;
    if (currentUser == null || currentUser.id.isEmpty) {
      _error = 'Please log in to request verification.';
      notifyListeners();
      return false;
    }

    if (currentUser.role != app.UserRole.muqtaddi ||
        ![
          app.VerificationStatus.none,
          app.VerificationStatus.rejected,
        ].contains(currentUser.verificationStatus)) {
      _error = 'Only muqtaddis can request verification.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final masjid = app.AppData.selectedMasjid;
      if (masjid == null || masjid.id.isEmpty) {
        throw StateError('Select a masjid first.');
      }
      final updatedUser = app.User.fromJson({
        ...currentUser.toJson(),
        'id': currentUser.id,
        'isLoggedIn': true,
        'masjidId': masjid.id,
        'masjidName': masjid.name,
        'verificationStatus': 'pending',
      });
      await _firestore.collection('users').doc(currentUser.id).update({
        'verificationStatus': updatedUser.verificationStatus.value,
        'masjidId': masjid.id,
        'masjidName': masjid.name,
      });

      _currentUser = updatedUser;
      app.AppData.currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _readableAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google.
  ///
  /// Google login is NOT automatically elevated to admin (`§10`): the Firestore
  /// `users/{uid}` document decides the role for every non-superadmin user.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final google.GoogleSignInAccount? googleUser = await _signIn.signIn();
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

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _error = 'Sign-in failed: no user returned';
        await _firebaseAuth.signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Ensure a Firestore user doc exists so the account can be assigned a
      // role by an admin (mirrors email registration).
      final uid = firebaseUser.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(uid).set({
          'username': firebaseUser.displayName ?? 'User',
          'email': firebaseUser.email ?? '',
          'role': app.UserRole.muqtaddi.value,
          'verificationStatus': app.VerificationStatus.none.value,
          'eventPermission': app.EventPermission.none.value,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      await hydrateUser(uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _readableAuthError(e);
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
    app.AppData.logout();
    _currentUser = app.AppData.currentUser;
    notifyListeners();
  }

  /// Delete the current user's account (Firebase Auth + Firestore user doc cleanup).
  Future<bool> deleteAccount({String? password}) async {
    if (_isLoading) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw StateError('Please sign in before deleting your account.');
      }
      if (user.providerData.any(
        (provider) => provider.providerId == 'password',
      )) {
        if (password == null || password.isEmpty) {
          throw StateError('Enter your current password.');
        }
        await user.reauthenticateWithCredential(
          auth.EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          ),
        );
      } else if (user.providerData.any(
        (provider) => provider.providerId == 'google.com',
      )) {
        final googleUser = await _signIn.signIn();
        if (googleUser == null) {
          throw StateError('Reauthentication was cancelled.');
        }
        final googleAuth = await googleUser.authentication;
        await user.reauthenticateWithCredential(
          auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          ),
        );
      } else {
        throw StateError(
          'Sign in with a supported account provider to delete your account.',
        );
      }
      await AccountDeletionService().removeFirestoreData(user);
      await user.delete();
      await signOut();
      return true;
    } catch (error) {
      _error = _readableAuthError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Map common Firebase Auth exceptions to human-readable messages.
  String _readableAuthError(Object e) {
    final message = e.toString();
    if (message.contains('email-already-in-use')) {
      return 'An account with this email already exists. Try logging in.';
    }
    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('user-not-found')) {
      return 'No account found with this email. Please register first.';
    }
    if (message.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return message.replaceAll('PlatformException(', '');
  }
}
