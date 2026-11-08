import 'package:campus_incidents/app.dart';
import 'package:campus_incidents/core/providers/firebase_providers.dart';
import 'package:campus_incidents/data/models/incident_category.dart';
import 'package:campus_incidents/data/models/incident_status.dart';
import 'package:campus_incidents/features/report/report_form_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Test doubles shared by the widget tests.
class TestBackend {
  TestBackend({
    MockUser? user,
    bool signedIn = false,
    bool verifyEmailAutomatically = true,
  }) : db = FakeFirebaseFirestore(),
       auth = MockFirebaseAuth(
         mockUser: user,
         signedIn: signedIn,
         verifyEmailAutomatically: verifyEmailAutomatically,
       );

  final FakeFirebaseFirestore db;
  final MockFirebaseAuth auth;
  final photos = FakePhotoRepository();
  final _names = <String, String>{};

  List<Override> get overrides => [
    firebaseAuthProvider.overrideWithValue(auth),
    firestoreProvider.overrideWithValue(db),
    photoRepositoryProvider.overrideWithValue(photos),
    imagePickerProvider.overrideWithValue(FakeImagePicker()),
  ];

  Future<void> addUser(
    String uid, {
    String name = 'Amina Hassan',
    String role = 'student',
  }) {
    _names[uid] = name;
    return db.doc('users/$uid').set({
      'name': name,
      'email': '$uid@alustudent.com',
      'role': role,
      'department': 'Computer Science',
      'campus': 'Kigali, Rwanda',
    });
  }

  /// Adds a report, moving it through the statuses up to [status].
  Future<void> addIncident(
    String id, {
    required String title,
    required String reporter,
    IncidentCategory category = IncidentCategory.facilities,
    IncidentStatus status = IncidentStatus.submitted,
    String location = 'Block A',
    int hoursAgo = 1,
  }) async {
    final at = DateTime.now().subtract(Duration(hours: hoursAgo));
    final name = _names[reporter] ?? reporter;
    final history = [
      _change(IncidentStatus.submitted, at, reporter, name),
      for (final s in IncidentStatus.values.where(
        (s) => s.index > 0 && s.index <= status.index,
      ))
        _change(
          s,
          at.add(Duration(minutes: 30 * s.index)),
          'staff1',
          'Campus Staff',
        ),
    ];
    await db.doc('incidents/$id').set({
      'title': title,
      'description': 'Details about $title, reported for testing.',
      'category': category.name,
      'location': location,
      'status': status.name,
      'reporterId': reporter,
      'reporterName': name,
      'createdAt': Timestamp.fromDate(at),
      'updatedAt': Timestamp.fromDate(at),
      'photoUrl': null,
      'photoPath': null,
      'history': history,
    });
  }

  /// Records a staff status change (with a note) on an existing report.
  Future<void> advance(String id, IncidentStatus status, {String note = ''}) =>
      db.doc('incidents/$id').update({
        'status': status.name,
        'history': FieldValue.arrayUnion([
          {
            ..._change(status, DateTime.now(), 'staff1', 'Campus Staff'),
            'note': note,
          },
        ]),
      });

  Map<String, dynamic> _change(
    IncidentStatus s,
    DateTime at,
    String by,
    String name,
  ) => {
    'status': s.name,
    'changedAt': Timestamp.fromDate(at),
    'changedBy': by,
    'changedByName': name,
    'note': '',
  };
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

  /// Taps a bottom-navigation tab by its label.
  Future<void> openTab(String label) async {
    await tap(find.bySemanticsLabel(label).last);
    await pumpAndSettle();
  }
}
