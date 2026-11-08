import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/firebase_providers.dart';
import '../../data/models/app_user.dart';
import '../../data/models/user_role.dart';

/// The signed-in Firebase user, or null when signed out.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);

/// The signed-in user's profile (name, role, ...), or null when signed out.
///
/// If the account exists but its profile doesn't, the profile is created so
/// the user is never stuck on the loading screen.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  // Non-ALU accounts never get a profile; the router shows them a notice.
  if (user == null || !AppConfig.isAllowedEmail(user.email)) {
    return Stream.value(null);
  }

  final users = ref.watch(userRepositoryProvider);
  var repaired = false;
  return users.watchUser(user.uid).map((profile) {
    if (profile == null && !repaired) {
      repaired = true;
      // A transaction, so it can't clash with sign-up writing the profile.
      unawaited(
        users
            .ensureProfile(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName,
            )
            .catchError((Object _) => repaired = false),
      );
    }
    return profile;
  });
});

/// Runs sign-in, sign-up and password reset, exposing loading and errors to
/// the UI as an [AsyncValue].
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> signIn(String email, String password) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password),
  );

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String department = '',
    String campus = '',
  }) => _run(() async {
    final user = await ref
        .read(authRepositoryProvider)
        .signUp(name: name, email: email, password: password);
    await ref
        .read(userRepositoryProvider)
        .createProfile(
          AppUser(
            uid: user.uid,
            name: name.trim(),
            email: user.email ?? email.trim(),
            role: UserRole.student,
            department: department.trim(),
            campus: campus.trim(),
          ),
        );
  });

  Future<bool> sendPasswordReset(String email) =>
      _run(() => ref.read(authRepositoryProvider).sendPasswordReset(email));

  Future<bool> resendVerification() =>
      _run(() => ref.read(authRepositoryProvider).sendEmailVerification());

  /// Checks with Firebase whether the user has opened the verification link.
  /// Returns true once verified; the router then opens the app.
  Future<bool> checkVerified() async {
    state = const AsyncLoading();
    try {
      final verified = await ref.read(authRepositoryProvider).reloadUser();
      if (!ref.mounted) return verified;
      state = const AsyncData(null);
      if (verified) ref.invalidate(authStateProvider);
      return verified;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  /// Returns true on success; on failure the error is left in [state].
  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
