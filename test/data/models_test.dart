import 'package:campus_incidents/data/models/app_user.dart';
import 'package:campus_incidents/data/models/incident.dart';
import 'package:campus_incidents/data/models/incident_category.dart';
import 'package:campus_incidents/data/models/incident_status.dart';
import 'package:campus_incidents/data/models/status_change.dart';
import 'package:campus_incidents/data/models/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 10, 15, 10, 24);
  final t1 = DateTime(2026, 10, 16, 14, 30);

  Incident sample() => Incident(
    id: 'i1',
    title: 'Water shortage',
    description: 'No water supply in the residence since this morning.',
    category: IncidentCategory.water,
    location: 'Student Residence',
    status: IncidentStatus.inProgress,
    reporterId: 'amina',
    reporterName: 'Amina Hassan',
    createdAt: t0,
    updatedAt: t1,
    photoUrl: 'https://example.com/a.jpg',
    photoPath: 'amina/i1/a.jpg',
    history: [
      StatusChange(
        status: IncidentStatus.submitted,
        changedAt: t0,
        changedBy: 'amina',
        changedByName: 'Amina Hassan',
      ),
      StatusChange(
        status: IncidentStatus.inProgress,
        changedAt: t1,
        changedBy: 'staff1',
        changedByName: 'Campus Staff',
        note: 'Plumber assigned',
      ),
    ],
  );

  group('Incident', () {
    test('round-trips through a Firestore map', () {
      final original = sample();
      final copy = Incident.fromMap('i1', original.toMap());

      expect(copy.title, original.title);
      expect(copy.category, IncidentCategory.water);
      expect(copy.status, IncidentStatus.inProgress);
      expect(copy.createdAt, t0);
      expect(copy.photoPath, 'amina/i1/a.jpg');
      expect(copy.history, hasLength(2));
      expect(copy.history.last.note, 'Plumber assigned');
    });

    test('reachedAt returns when each status was reached', () {
      final i = sample();
      expect(i.reachedAt(IncidentStatus.submitted), t0);
      expect(i.reachedAt(IncidentStatus.inProgress), t1);
      expect(i.reachedAt(IncidentStatus.resolved), isNull);
    });

    test('matches searches title, description, location and category', () {
      final i = sample();
      expect(i.matches(''), isTrue);
      expect(i.matches('WATER'), isTrue);
      expect(i.matches('residence'), isTrue);
      expect(i.matches('morning'), isTrue);
      expect(i.matches('projector'), isFalse);
    });

    test('tolerates missing and unknown fields', () {
      final i = Incident.fromMap('x', {
        'category': 'parking',
        'status': 'archived',
        'createdAt': Timestamp.fromDate(t0),
      });
      expect(i.category, IncidentCategory.facilities);
      expect(i.status, IncidentStatus.submitted);
      expect(i.updatedAt, t0);
      expect(i.hasPhoto, isFalse);
      expect(i.history, isEmpty);
    });
  });

  group('IncidentStatus', () {
    test('only allows moving forward', () {
      expect(IncidentStatus.submitted.nextOptions, [
        IncidentStatus.inProgress,
        IncidentStatus.resolved,
      ]);
      expect(IncidentStatus.inProgress.nextOptions, [IncidentStatus.resolved]);
      expect(IncidentStatus.resolved.nextOptions, isEmpty);
      expect(IncidentStatus.resolved.isFinal, isTrue);
    });
  });

  group('AppUser', () {
    test('derives first name and initials', () {
      const u = AppUser(
        uid: 'u',
        name: 'Amina  Hassan',
        email: 'a@b.c',
        role: UserRole.student,
      );
      expect(u.firstName, 'Amina');
      expect(u.initials, 'AH');
      expect(u.isStaff, isFalse);
    });

    test('create map always uses the student role', () {
      const u = AppUser(
        uid: 'u',
        name: 'Sneaky',
        email: 'a@b.c',
        role: UserRole.staff,
      );
      expect(u.toCreateMap()['role'], 'student');
    });

    test('unknown roles are treated as student', () {
      final u = AppUser.fromMap('u', {'name': 'X', 'role': 'admin'});
      expect(u.role, UserRole.student);
    });
  });
}
