/// Every route path in the app, in one place.
class Routes {
  const Routes._();

  static const splash = '/splash';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';

  static const profile = '/profile';

  /// Screens anyone may see while signed out.
  static const public = {login, signUp, forgotPassword};

  /// Where a user lands after signing in.
  static const signedInHome = profile;
}
