import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_providers.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import 'routes.dart';

/// Decides where to send the user for the current auth state.
///
/// Kept as a pure function so it can be unit tested without a widget tree.
String? resolveRedirect({
  required String location,
  required bool authLoading,
  required bool signedIn,
  required bool profileReady,
}) {
  final onPublic = Routes.public.contains(location);
  if (authLoading) return location == Routes.splash ? null : Routes.splash;
  if (!signedIn) return onPublic ? null : Routes.login;
  if (!profileReady) return location == Routes.splash ? null : Routes.splash;
  if (onPublic || location == Routes.splash) return Routes.signedInHome;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever the auth state or profile changes.
  final refresh = ValueNotifier(0);
  ref
    ..listen(authStateProvider, (_, _) => refresh.value++)
    ..listen(currentUserProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final profile = ref.read(currentUserProvider);
      return resolveRedirect(
        location: state.matchedLocation,
        authLoading: auth.isLoading && !auth.hasValue,
        signedIn: auth.value != null,
        profileReady: profile.value != null,
      );
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
