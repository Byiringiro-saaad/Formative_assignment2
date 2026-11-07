import 'package:campus_incidents/core/router/app_router.dart';
import 'package:campus_incidents/core/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? go(
    String location, {
    bool loading = false,
    bool signedIn = false,
    bool profile = false,
  }) => resolveRedirect(
    location: location,
    authLoading: loading,
    signedIn: signedIn,
    profileReady: profile,
  );

  test('shows the splash while auth is loading', () {
    expect(go(Routes.login, loading: true), Routes.splash);
    expect(go(Routes.splash, loading: true), isNull);
  });

  test('signed-out users can only see public screens', () {
    expect(go(Routes.splash), Routes.login);
    expect(go(Routes.profile), Routes.login);
    expect(go(Routes.login), isNull);
    expect(go(Routes.signUp), isNull);
    expect(go(Routes.forgotPassword), isNull);
  });

  test('waits on the splash until the profile has loaded', () {
    expect(go(Routes.login, signedIn: true), Routes.splash);
    expect(go(Routes.splash, signedIn: true), isNull);
  });

  test('signed-in users leave the auth screens', () {
    expect(
      go(Routes.login, signedIn: true, profile: true),
      Routes.signedInHome,
    );
    expect(
      go(Routes.splash, signedIn: true, profile: true),
      Routes.signedInHome,
    );
    expect(go(Routes.profile, signedIn: true, profile: true), isNull);
  });
}
