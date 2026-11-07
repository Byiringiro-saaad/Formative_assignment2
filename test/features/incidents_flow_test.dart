import 'package:campus_incidents/core/utils/time_ago.dart';
import 'package:campus_incidents/data/models/incident.dart';
import 'package:campus_incidents/data/models/incident_category.dart';
import 'package:campus_incidents/data/models/incident_status.dart';
import 'package:campus_incidents/features/incidents/incident_providers.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final amina = MockUser(
    uid: 'amina',
    email: 'amina@alu.edu',
    displayName: 'Amina Hassan',
  );

  Future<TestBackend> signedInStudent() async {
    final backend = TestBackend(user: amina, signedIn: true);
    await backend.addUser('amina');
    await backend.addUser('brian', name: 'Brian Kamau');
    await backend.addIncident(
      'i1',
      title: 'Water shortage',
      reporter: 'amina',
      category: IncidentCategory.water,
      location: 'Student Residence',
      hoursAgo: 2,
    );
    await backend.addIncident(
      'i2',
      title: 'Broken classroom projector',
      reporter: 'amina',
      status: IncidentStatus.inProgress,
      location: 'Block B',
      hoursAgo: 26,
    );
    await backend.addIncident(
      'i3',
      title: 'Overflowing bin',
      reporter: 'amina',
      category: IncidentCategory.sanitation,
      status: IncidentStatus.resolved,
      location: 'Cafeteria',
      hoursAgo: 72,
    );
    await backend.addIncident(
      'i4',
      title: 'Flickering lights',
      reporter: 'brian',
      category: IncidentCategory.electricity,
      location: 'Library',
      hoursAgo: 5,
    );
    return backend;
  }

  group('home', () {
    testWidgets('greets the student and summarises their own reports', (
      tester,
    ) async {
      await tester.pumpApp(await signedInStudent());

      expect(find.text('Hello, Amina 👋'), findsOneWidget);
      expect(find.text('Report an Issue'), findsOneWidget);
      // 3 of Amina's reports: one per status. Brian's report is not counted.
      expect(find.widgetWithText(Column, 'My Reports'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Water shortage'), findsOneWidget);
      expect(find.text('Flickering lights'), findsNothing);
    });

    testWidgets('staff see campus-wide numbers', (tester) async {
      final backend = await signedInStudent();
      await backend.addUser('amina', role: 'staff');
      await tester.pumpApp(backend);

      expect(find.text('Campus Summary'), findsOneWidget);
      expect(find.text('Review Reports'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });
  });

  group('reports list', () {
    Future<void> openReports(WidgetTester tester) async {
      await tester.pumpApp(await signedInStudent());
      await tester.openTab('Reports');
    }

    testWidgets('lists every report on campus', (tester) async {
      await openReports(tester);

      expect(find.text('4 reports'), findsOneWidget);
      expect(find.text('Flickering lights'), findsOneWidget);
    });

    testWidgets('search narrows the list', (tester) async {
      await openReports(tester);

      await tester.enterText(find.byType(TextField).first, 'projector');
      await tester.pumpAndSettle();

      expect(find.text('1 report'), findsOneWidget);
      expect(find.text('Broken classroom projector'), findsOneWidget);
      expect(find.text('Water shortage'), findsNothing);
    });

    testWidgets('status and category filters combine', (tester) async {
      await openReports(tester);

      await tester.tap(find.text('Submitted').first);
      await tester.pumpAndSettle();
      expect(find.text('2 reports'), findsOneWidget);

      await tester.tap(find.text('Electricity'));
      await tester.pumpAndSettle();
      expect(find.text('1 report'), findsOneWidget);
      expect(find.text('Flickering lights'), findsOneWidget);
    });

    testWidgets('"My reports" hides other students\' reports', (tester) async {
      await openReports(tester);

      await tester.tap(find.text('My reports'));
      await tester.pumpAndSettle();

      expect(find.text('3 reports'), findsOneWidget);
      expect(find.text('Flickering lights'), findsNothing);
    });

    testWidgets('shows a helpful empty state', (tester) async {
      await openReports(tester);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No matching reports'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('4 reports'), findsOneWidget);
    });
  });

  group('details', () {
    testWidgets('shows the timeline, description and staff notes', (
      tester,
    ) async {
      final backend = await signedInStudent();
      await backend.advance(
        'i2',
        IncidentStatus.inProgress,
        note: 'Technician booked for 2pm',
      );
      await tester.pumpApp(backend);

      await tester.tap(find.text('Broken classroom projector'));
      await tester.pumpAndSettle();

      expect(find.text('Incident Details'), findsOneWidget);
      expect(find.text('Status Timeline'), findsOneWidget);
      expect(find.text('Reported by Amina Hassan'), findsOneWidget);
      expect(find.text('Technician booked for 2pm'), findsOneWidget);
      expect(find.textContaining('Submitted on'), findsOneWidget);
    });

    testWidgets('the reporter can withdraw a submitted report', (tester) async {
      final backend = await signedInStudent();
      await tester.pumpApp(backend);

      await tester.tap(find.text('Water shortage'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Withdraw report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Withdraw'));
      await tester.pumpAndSettle();

      expect((await backend.db.doc('incidents/i1').get()).exists, isFalse);
      expect(find.text('Report withdrawn.'), findsOneWidget);
    });
  });

  group('report form', () {
    Future<void> openForm(WidgetTester tester, TestBackend backend) async {
      await tester.pumpApp(backend);
      await tester.tap(find.bySemanticsLabel('Report an incident'));
      await tester.pumpAndSettle();
    }

    testWidgets('validates every required field', (tester) async {
      await openForm(tester, await signedInStudent());

      await tester.scrollForm(find.text('Submit Report'));
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();

      expect(
        find.text('Choose the category that best fits the issue.'),
        findsOneWidget,
      );
      expect(find.text('Title is required.'), findsOneWidget);
      expect(find.text('Description is required.'), findsOneWidget);
      expect(find.text('Choose a location.'), findsOneWidget);
    });

    testWidgets('submits a report with a photo and opens it', (tester) async {
      final backend = await signedInStudent();
      await openForm(tester, backend);

      await tester.tap(find.text('Furniture'));
      await tester.enterText(find.byType(TextFormField).at(0), 'Broken chair');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'The chair in the front row has a cracked leg.',
      );
      await tester.scrollForm(find.text('Where is the issue?'));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Library').last);
      await tester.pumpAndSettle();

      await tester.scrollForm(find.text('Tap to add photos'));
      await tester.tap(find.text('Tap to add photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove photo'), findsOneWidget);

      await tester.scrollForm(find.text('Submit Report'));
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();

      final saved =
          (await backend.db
                  .collection('incidents')
                  .where('title', isEqualTo: 'Broken chair')
                  .get())
              .docs
              .single;
      expect(saved['category'], 'furniture');
      expect(saved['location'], 'Library');
      expect(saved['status'], 'submitted');
      expect(saved['reporterId'], 'amina');
      expect(saved['photoUrl'], startsWith('https://photos.test/amina/'));
      expect(backend.photos.uploads, hasLength(1));

      expect(find.text('Incident Details'), findsOneWidget);
      expect(find.text('Broken chair'), findsOneWidget);
    });

    testWidgets('a failed upload keeps the form and shows the error', (
      tester,
    ) async {
      final backend = await signedInStudent();
      backend.photos.failNextUpload = true;
      await openForm(tester, backend);

      await tester.tap(find.text('Water'));
      await tester.enterText(find.byType(TextFormField).at(0), 'Leaking tap');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Tap in the bathroom keeps running.',
      );
      await tester.scrollForm(find.text('Where is the issue?'));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block A').last);
      await tester.pumpAndSettle();
      await tester.scrollForm(find.text('Tap to add photos'));
      await tester.tap(find.text('Tap to add photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      await tester.scrollForm(find.text('Submit Report'));
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();

      expect(find.text('Photo upload failed: network down'), findsOneWidget);
      expect(find.text('Report an Incident'), findsOneWidget);
      final saved = await backend.db
          .collection('incidents')
          .where('title', isEqualTo: 'Leaking tap')
          .get();
      expect(saved.docs, isEmpty);
    });
  });

  group('filter and summary logic', () {
    test('IncidentSummary counts by status', () async {
      final backend = await signedInStudent();
      final docs = (await backend.db.collection('incidents').get()).docs;
      final summary = IncidentSummary.of(docs.map(Incident.fromDoc).toList());

      expect(summary.total, 4);
      expect(summary.submitted, 2);
      expect(summary.inProgress, 1);
      expect(summary.resolved, 1);
    });

    test('timeAgo formats recent and older times', () {
      final now = DateTime(2026, 11, 7, 12);
      expect(
        timeAgo(now.subtract(const Duration(seconds: 10)), now: now),
        'Just now',
      );
      expect(
        timeAgo(now.subtract(const Duration(minutes: 1)), now: now),
        '1 minute ago',
      );
      expect(
        timeAgo(now.subtract(const Duration(hours: 2)), now: now),
        '2 hours ago',
      );
      expect(
        timeAgo(now.subtract(const Duration(days: 1)), now: now),
        '1 day ago',
      );
      expect(timeAgo(DateTime(2026, 10, 1), now: now), 'Oct 1, 2026');
    });

    test('IncidentFilter.isActive ignores the mine-only toggle', () {
      expect(const IncidentFilter(mineOnly: true).isActive, isFalse);
      expect(const IncidentFilter(query: 'x').isActive, isTrue);
      expect(
        const IncidentFilter(status: IncidentStatus.resolved).isActive,
        isTrue,
      );
    });
  });
}

extension on WidgetTester {
  /// Scrolls the report form until [finder] is comfortably on screen.
  Future<void> scrollForm(Finder finder) async {
    await ensureVisible(finder);
    await drag(find.byType(SingleChildScrollView).last, const Offset(0, -120));
    await pumpAndSettle();
  }
}
