// Renders the main screens to PNG files in docs/screenshots for the report.
//
//   flutter test tool/screenshots --update-goldens
//
// Lives outside test/ so the normal `flutter test` run never compares these
// images (font rendering differs between machines).
import 'package:campus_incidents/data/models/incident_category.dart';
import 'package:campus_incidents/data/models/incident_status.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers.dart';

void main() {
  final amina = MockUser(
    uid: 'amina',
    email: 'amina@alustudent.com',
    displayName: 'Amina Hassan',
  );
  final grace = MockUser(
    uid: 'grace',
    email: 'grace@alueducation.com',
    displayName: 'Grace Uwase',
  );

  Future<TestBackend> demo(MockUser user, {bool signedIn = true}) async {
    final b = TestBackend(user: user, signedIn: signedIn);
    await b.addUser('amina');
    await b.addUser('brian', name: 'Brian Kamau');
    await b.addUser('grace', name: 'Grace Uwase', role: 'staff');
    await b.addIncident(
      'i1',
      title: 'Water shortage',
      reporter: 'amina',
      category: IncidentCategory.water,
      location: 'Student Residence',
      hoursAgo: 2,
    );
    await b.addIncident(
      'i2',
      title: 'Broken classroom projector',
      reporter: 'amina',
      status: IncidentStatus.inProgress,
      location: 'Block B',
      hoursAgo: 26,
    );
    await b.advance(
      'i2',
      IncidentStatus.inProgress,
      note: 'A technician has been assigned.',
    );
    await b.addIncident(
      'i3',
      title: 'Overflowing bin',
      reporter: 'amina',
      category: IncidentCategory.sanitation,
      status: IncidentStatus.resolved,
      location: 'Cafeteria',
      hoursAgo: 72,
    );
    await b.addIncident(
      'i4',
      title: 'Flickering lights in the library',
      reporter: 'brian',
      category: IncidentCategory.electricity,
      location: 'Library',
      hoursAgo: 5,
    );
    await b.addIncident(
      'i5',
      title: 'Main gate light not working',
      reporter: 'brian',
      category: IncidentCategory.safety,
      location: 'Main Gate',
      hoursAgo: 50,
      anonymous: true,
    );
    return b;
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/$name.png'),
    );
  }

  Future<void> phone(WidgetTester tester, TestBackend backend) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpApp(backend);
    await tester.binding.setSurfaceSize(null);
    await tester.pumpAndSettle();
  }

  testWidgets('01 login', (tester) async {
    await phone(tester, await demo(amina, signedIn: false));
    await shot(tester, '01_login');
  });

  testWidgets('02 home', (tester) async {
    await phone(tester, await demo(amina));
    await shot(tester, '02_home_student');
  });

  testWidgets('03 report form', (tester) async {
    await phone(tester, await demo(amina));
    await tester.tap(find.bySemanticsLabel('Report an incident'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Water'));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Leaking tap in bathroom',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'The tap in the 1st floor bathroom keeps running and water is pooling on the floor.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await shot(tester, '03_report_form');
  });

  testWidgets('04 reports filtered', (tester) async {
    await phone(tester, await demo(amina));
    await tester.openTab('Reports');
    await tester.tap(find.text('Submitted').first);
    await shot(tester, '04_reports_filtered');
  });

  testWidgets('05 details', (tester) async {
    await phone(tester, await demo(amina));
    await tester.openTab('Reports');
    await tester.tap(find.text('Broken classroom projector'));
    await shot(tester, '05_incident_details');
  });

  testWidgets('06 profile', (tester) async {
    await phone(tester, await demo(amina));
    await tester.openTab('Profile');
    await shot(tester, '06_profile');
  });

  testWidgets('07 staff home', (tester) async {
    await phone(tester, await demo(grace));
    await shot(tester, '07_home_staff');
  });

  testWidgets('08 staff update sheet', (tester) async {
    await phone(tester, await demo(grace));
    await tester.tap(find.text('Water shortage'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as In Progress'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Plumber assigned, arriving at 2pm.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await shot(tester, '08_staff_update_status');
  });

  testWidgets('09 updates feed', (tester) async {
    await phone(tester, await demo(amina));
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await shot(tester, '09_updates_feed');
  });

  testWidgets('10 verify email', (tester) async {
    final unverified = MockUser(
      uid: 'amina',
      email: 'amina@alustudent.com',
      displayName: 'Amina Hassan',
      isEmailVerified: false,
    );
    await phone(tester, await demo(unverified));
    await shot(tester, '10_verify_email');
  });

  testWidgets('11 anonymous report option', (tester) async {
    await phone(tester, await demo(amina));
    await tester.tap(find.bySemanticsLabel('Report an incident'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide my name from other students'));
    await shot(tester, '11_report_anonymous');
  });

  testWidgets('12 staff view of an anonymous report', (tester) async {
    await phone(tester, await demo(grace));
    await tester.openTab('Reports');
    await tester.tap(find.text('Main gate light not working'));
    await shot(tester, '12_anonymous_staff_view');
  });
}
