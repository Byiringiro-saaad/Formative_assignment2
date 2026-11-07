import 'package:campus_incidents/data/models/incident_status.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final grace = MockUser(
    uid: 'grace',
    email: 'grace@alu.edu',
    displayName: 'Grace Uwase',
  );
  final amina = MockUser(
    uid: 'amina',
    email: 'amina@alu.edu',
    displayName: 'Amina Hassan',
  );

  Future<TestBackend> backendFor(MockUser user, {required String role}) async {
    final backend = TestBackend(user: user, signedIn: true);
    await backend.addUser('amina');
    await backend.addUser('grace', name: 'Grace Uwase', role: 'staff');
    if (user.uid == 'amina') await backend.addUser('amina', role: role);
    await backend.addIncident(
      'i1',
      title: 'Water shortage',
      reporter: 'amina',
      location: 'Student Residence',
    );
    return backend;
  }

  Future<void> openIncident(WidgetTester tester, String title) async {
    await tester.tap(find.text(title).first);
    await tester.pumpAndSettle();
  }

  Future<void> scrollDown(WidgetTester tester) async {
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
  }

  testWidgets('staff move a report to In Progress with a note', (tester) async {
    final backend = await backendFor(grace, role: 'staff');
    await tester.pumpApp(backend);
    await openIncident(tester, 'Water shortage');
    await scrollDown(tester);

    expect(find.text('Staff actions'), findsOneWidget);
    await tester.tap(find.text('Mark as In Progress'));
    await tester.pumpAndSettle();

    expect(find.text('Mark as In Progress?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Plumber on the way');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    final doc = await backend.db.doc('incidents/i1').get();
    expect(doc['status'], IncidentStatus.inProgress.name);
    final history = (doc['history'] as List).cast<Map<String, dynamic>>();
    expect(history, hasLength(2));
    expect(history.last['changedBy'], 'grace');
    expect(history.last['changedByName'], 'Grace Uwase');
    expect(history.last['note'], 'Plumber on the way');

    expect(find.text('Status updated to In Progress.'), findsOneWidget);
    expect(find.text('Plumber on the way'), findsOneWidget);
  });

  testWidgets('staff can resolve straight away, then see who resolved it', (
    tester,
  ) async {
    final backend = await backendFor(grace, role: 'staff');
    await tester.pumpApp(backend);
    await openIncident(tester, 'Water shortage');
    await scrollDown(tester);

    await tester.tap(find.text('Mark as Resolved'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await scrollDown(tester);

    expect((await backend.db.doc('incidents/i1').get())['status'], 'resolved');
    expect(find.text('Staff actions'), findsNothing);
    expect(find.textContaining('Resolved by Grace Uwase'), findsOneWidget);
  });

  testWidgets('cancelling the sheet leaves the status unchanged', (
    tester,
  ) async {
    final backend = await backendFor(grace, role: 'staff');
    await tester.pumpApp(backend);
    await openIncident(tester, 'Water shortage');
    await scrollDown(tester);

    await tester.tap(find.text('Mark as In Progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect((await backend.db.doc('incidents/i1').get())['status'], 'submitted');
  });

  testWidgets('students never see staff actions', (tester) async {
    final backend = await backendFor(amina, role: 'student');
    await tester.pumpApp(backend);
    await openIncident(tester, 'Water shortage');
    await scrollDown(tester);

    expect(find.text('Staff actions'), findsNothing);
    expect(find.text('Mark as In Progress'), findsNothing);
  });

  testWidgets('the student sees the staff update in their activity feed', (
    tester,
  ) async {
    final backend = await backendFor(amina, role: 'student');
    await backend.advance(
      'i1',
      IncidentStatus.inProgress,
      note: 'Plumber on the way',
    );
    await tester.pumpApp(backend);

    expect(find.byTooltip('1 new update'), findsOneWidget);
    await tester.tap(find.byTooltip('1 new update'));
    await tester.pumpAndSettle();

    expect(find.text('"Water shortage" is now in progress'), findsOneWidget);
    expect(find.textContaining('Plumber on the way'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Updates'), findsOneWidget);
  });

  testWidgets('staff home links straight to submitted reports', (tester) async {
    final backend = await backendFor(grace, role: 'staff');
    await backend.addIncident(
      'i2',
      title: 'Fixed light',
      reporter: 'amina',
      status: IncidentStatus.resolved,
    );
    await tester.pumpApp(backend);

    await tester.tap(find.text('Review Reports'));
    await tester.pumpAndSettle();

    expect(find.text('All Reports'), findsOneWidget);
    expect(find.text('1 report'), findsOneWidget);
    expect(find.text('Water shortage'), findsOneWidget);
    expect(find.text('Fixed light'), findsNothing);
  });
}
