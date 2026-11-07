import 'package:campus_incidents/app.dart';
import 'package:campus_incidents/core/providers/firebase_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Test doubles shared by the widget tests.
class TestBackend {
  TestBackend({MockUser? user, bool signedIn = false})
    : db = FakeFirebaseFirestore(),
      auth = MockFirebaseAuth(mockUser: user, signedIn: signedIn);

  final FakeFirebaseFirestore db;
  final MockFirebaseAuth auth;

  List<Override> get overrides => [
    firebaseAuthProvider.overrideWithValue(auth),
    firestoreProvider.overrideWithValue(db),
  ];

  Future<void> addUser(
    String uid, {
    String name = 'Amina Hassan',
    String role = 'student',
  }) => db.doc('users/$uid').set({
    'name': name,
    'email': '$uid@alu.edu',
    'role': role,
    'department': 'Computer Science',
    'campus': 'Kigali, Rwanda',
  });
}

extension PumpApp on WidgetTester {
  /// Pumps the whole app against [backend] and lets streams settle.
  Future<void> pumpApp(TestBackend backend) async {
    await binding.setSurfaceSize(const Size(400, 860));
    addTearDown(() => binding.setSurfaceSize(null));
    await pumpWidget(
      ProviderScope(overrides: backend.overrides, child: const CampusApp()),
    );
    await pumpAndSettle();
  }
}
