/// Every route path in the app, in one place.
class Routes {
  const Routes._();

  static const splash = '/splash';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';

  // Bottom-navigation tabs.
  static const home = '/';
  static const reports = '/reports';
  static const profile = '/profile';

  // Screens opened on top of the tabs.
  static const report = '/report';
  static const activity = '/activity';
  static String incident(String id) => '/incidents/$id';

  /// Screens anyone may see while signed out.
  static const public = {login, signUp, forgotPassword};

  /// Where a user lands after signing in.
  static const signedInHome = home;
}
