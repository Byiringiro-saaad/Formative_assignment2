import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_providers.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/incidents/incident_details_screen.dart';
import '../../features/incidents/reports_screen.dart';
import '../../features/notifications/activity_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/report/report_form_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../config/app_config.dart';
import 'routes.dart';

/// Decides where to send the user for the current auth state.
///
/// Kept as a pure function so it can be unit tested without a widget tree.
String? resolveRedirect({
  required String location,
  required bool authLoading,
  required bool signedIn,
  required bool profileReady,
  bool emailAllowed = true,
  bool emailVerified = true,
}) {
  final onPublic = Routes.public.contains(location);
  if (authLoading) return location == Routes.splash ? null : Routes.splash;
  if (!signedIn) return onPublic ? null : Routes.login;
  // Only verified ALU accounts get past this point.
  if (!emailAllowed || !emailVerified) {
    return location == Routes.verifyEmail ? null : Routes.verifyEmail;
  }
  if (!profileReady) return location == Routes.splash ? null : Routes.splash;
  if (onPublic || location == Routes.splash || location == Routes.verifyEmail) {
    return Routes.signedInHome;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  // Re-run the redirect whenever the auth state or profile changes.
  final refresh = ValueNotifier(0);
  ref
    ..listen(authStateProvider, (_, _) => refresh.value++)
    ..listen(currentUserProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final profile = ref.read(currentUserProvider);
      final user = auth.value;
      return resolveRedirect(
        location: state.matchedLocation,
        authLoading: auth.isLoading && !auth.hasValue,
        signedIn: user != null,
        profileReady: profile.value != null,
        emailAllowed: AppConfig.isAllowedEmail(user?.email),
        emailVerified: user?.emailVerified ?? false,
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
      GoRoute(
        path: Routes.verifyEmail,
        builder: (_, _) => const VerifyEmailScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.reports,
                builder: (_, _) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.report,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const ReportFormScreen(),
      ),
      GoRoute(
        path: Routes.activity,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/incidents/:id',
        parentNavigatorKey: rootKey,
        builder: (_, state) =>
            IncidentDetailsScreen(incidentId: state.pathParameters['id']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
