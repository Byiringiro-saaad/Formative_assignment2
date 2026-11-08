import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final amina = MockUser(
    uid: 'amina',
    email: 'amina@alustudent.com',
    displayName: 'Amina Hassan',
  );

  testWidgets('signed-out users start on the login screen', (tester) async {
    await tester.pumpApp(TestBackend());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('login form validates before submitting', (tester) async {
    await tester.pumpApp(TestBackend());

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('signing in opens the profile with the user\'s role', (
    tester,
  ) async {
    final backend = TestBackend(user: amina);
    await backend.addUser('amina');
    await tester.pumpApp(backend);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'amina@alustudent.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret12');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Hello, Amina', findRichText: true),
      findsOneWidget,
    );

    await tester.openTab('Profile');
    expect(find.text('Amina Hassan'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Computer Science'), findsOneWidget);
  });

  testWidgets('staff accounts are labelled as staff', (tester) async {
    final backend = TestBackend(user: amina, signedIn: true);
    await backend.addUser('amina', role: 'staff');
    await tester.pumpApp(backend);
    await tester.openTab('Profile');

    expect(find.text('Staff'), findsOneWidget);
    expect(find.textContaining('update their status'), findsOneWidget);
  });

  testWidgets('sign up creates a student profile', (tester) async {
    final backend = TestBackend(
      user: MockUser(uid: 'brian', email: 'brian@alustudent.com'),
    );
    await tester.pumpApp(backend);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Brian Kamau');
    await tester.enterText(fields.at(1), 'brian@alustudent.com');
    await tester.enterText(fields.at(2), 'Engineering');
    await tester.enterText(fields.at(3), 'secret12');
    await tester.enterText(fields.at(4), 'secret99');
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);

    await tester.enterText(fields.at(4), 'secret12');
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    final profiles = await backend.db.collection('users').get();
    final doc = profiles.docs.single;
    expect(doc['name'], 'Brian Kamau');
    expect(doc['role'], 'student');
    expect(doc['department'], 'Engineering');
    expect(
      find.textContaining('Hello, Brian', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('sign up only accepts ALU email addresses', (tester) async {
    await tester.pumpApp(TestBackend());
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'brian@gmail.com');
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(
      find.text('Use your ALU email (@alustudent.com or @alueducation.com).'),
      findsOneWidget,
    );
  });

  testWidgets('a new account must verify its email before using the app', (
    tester,
  ) async {
    final backend = TestBackend(verifyEmailAutomatically: false);
    await tester.pumpApp(backend);
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Brian Kamau');
    await tester.enterText(fields.at(1), 'brian@alustudent.com');
    await tester.enterText(fields.at(3), 'secret12');
    await tester.enterText(fields.at(4), 'secret12');
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('brian@alustudent.com'), findsWidgets);
    // The profile is saved at sign-up, so nothing is lost while verifying.
    expect((await backend.db.collection('users').get()).docs, hasLength(1));

    await tester.tap(find.text("I've Verified My Email"));
    await tester.pumpAndSettle();
    expect(
      find.text('Not verified yet. Open the link in the email first.'),
      findsOneWidget,
    );
    expect(find.text('Verify your email'), findsOneWidget);

    await tester.tap(find.text('Resend Email'));
    await tester.pumpAndSettle();
    expect(
      find.text('Verification email sent to brian@alustudent.com.'),
      findsOneWidget,
    );
  });

  testWidgets('an unverified user can only sign out', (tester) async {
    final backend = TestBackend(
      user: MockUser(
        uid: 'amina',
        email: 'amina@alustudent.com',
        isEmailVerified: false,
      ),
      signedIn: true,
    );
    await backend.addUser('amina');
    await tester.pumpApp(backend);

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('Report'), findsNothing);

    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('accounts outside ALU are turned away', (tester) async {
    final backend = TestBackend(
      user: MockUser(uid: 'eve', email: 'eve@gmail.com'),
      signedIn: true,
    );
    await tester.pumpApp(backend);

    expect(find.text('ALU email required'), findsOneWidget);
    expect(find.text("I've Verified My Email"), findsNothing);
    expect((await backend.db.collection('users').get()).docs, isEmpty);
  });

  testWidgets('signing out returns to the login screen', (tester) async {
    final backend = TestBackend(user: amina, signedIn: true);
    await backend.addUser('amina');
    await tester.pumpApp(backend);
    await tester.openTab('Profile');

    await tester.ensureVisible(find.text('Sign Out'));
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('forgot password confirms the email was sent', (tester) async {
    await tester.pumpApp(TestBackend());

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'amina@alustudent.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(
      find.text('Check amina@alustudent.com for a reset link.'),
      findsOneWidget,
    );
  });
}
