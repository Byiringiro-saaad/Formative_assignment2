import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Authentication.
///
/// Converts Firebase error codes into messages that can be shown to users.
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  /// Fires on sign-in, sign-out and profile changes such as a reload after
  /// the user verifies their email.
  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(name.trim());
      // A failed send isn't fatal: the verify screen offers to resend.
      try {
        await cred.user!.sendEmailVerification();
      } on FirebaseAuthException catch (_) {}
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  /// Sends the verification link again to the signed-in user.
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  /// Reloads the signed-in user from Firebase and refreshes their ID token,
  /// so a newly verified email reaches the security rules straight away.
  /// Returns whether the email is now verified.
  Future<bool> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      final fresh = _auth.currentUser ?? user;
      if (fresh.emailVerified) await fresh.getIdToken(true);
      return fresh.emailVerified;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();
}

/// A login problem with a message safe to show in the UI.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  factory AuthFailure.fromCode(String code) => AuthFailure(switch (code) {
    'invalid-email' => 'That email address is not valid.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Incorrect email or password.',
    'email-already-in-use' => 'An account already exists for that email.',
    'weak-password' => 'Choose a stronger password (at least 6 characters).',
    'too-many-requests' => 'Too many attempts. Please wait and try again.',
    'network-request-failed' => 'No internet connection. Check your network.',
    _ => 'Something went wrong. Please try again.',
  });

  @override
  String toString() => message;
}
