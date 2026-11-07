import 'package:campus_incidents/data/models/app_user.dart';
import 'package:campus_incidents/data/models/incident_category.dart';
import 'package:campus_incidents/data/models/incident_status.dart';
import 'package:campus_incidents/data/models/user_role.dart';
import 'package:campus_incidents/data/repositories/auth_repository.dart';
import 'package:campus_incidents/data/repositories/incident_repository.dart';
import 'package:campus_incidents/data/repositories/user_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  const amina = AppUser(
    uid: 'amina',
    name: 'Amina Hassan',
    email: 'amina@alu.edu',
    role: UserRole.student,
  );
  const staff = AppUser(
    uid: 'staff1',
    name: 'Campus Staff',
    email: 'staff@alu.edu',
    role: UserRole.staff,
  );

  group('IncidentRepository', () {
    late FakeFirebaseFirestore db;
    late IncidentRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = IncidentRepository(db);
    });

    Future<void> createSample(String id, DateTime at, {AppUser by = amina}) =>
        repo.create(
          id: id,
          reporter: by,
          title: '  Broken projector  ',
          description: 'The projector in room 204 does not turn on.',
          category: IncidentCategory.facilities,
          location: 'Block B',
          now: at,
        );

    test('create stores a submitted report with one history entry', () async {
      await createSample('i1', DateTime(2026, 11, 1));

      final saved = await repo.watchById('i1').first;
      expect(saved, isNotNull);
      expect(saved!.title, 'Broken projector');
      expect(saved.status, IncidentStatus.submitted);
      expect(saved.reporterId, 'amina');
      expect(saved.history.single.status, IncidentStatus.submitted);
    });

    test('watchAll lists newest first', () async {
      await createSample('old', DateTime(2026, 11, 1));
      await createSample('new', DateTime(2026, 11, 5));

      final all = await repo.watchAll().first;
      expect(all.map((i) => i.id), ['new', 'old']);
    });

    test('watchByReporter only returns that user\'s reports', () async {
      await createSample('mine', DateTime(2026, 11, 1));
      await createSample(
        'theirs',
        DateTime(2026, 11, 2),
        by: const AppUser(
          uid: 'brian',
          name: 'Brian',
          email: 'b@alu.edu',
          role: UserRole.student,
        ),
      );

      final mine = await repo.watchByReporter('amina').first;
      expect(mine.map((i) => i.id), ['mine']);
    });

    test('updateStatus changes status and appends to the timeline', () async {
      await createSample('i1', DateTime(2026, 11, 1));
      final incident = (await repo.watchById('i1').first)!;

      await repo.updateStatus(
        incident: incident,
        status: IncidentStatus.inProgress,
        staff: staff,
        note: ' Technician assigned ',
        now: DateTime(2026, 11, 2),
      );

      final updated = (await repo.watchById('i1').first)!;
      expect(updated.status, IncidentStatus.inProgress);
      expect(updated.history, hasLength(2));
      expect(updated.history.last.changedByName, 'Campus Staff');
      expect(updated.history.last.note, 'Technician assigned');
      expect(
        updated.reachedAt(IncidentStatus.inProgress),
        DateTime(2026, 11, 2),
      );
    });

    test('delete removes the report', () async {
      await createSample('i1', DateTime(2026, 11, 1));
      await repo.delete('i1');
      expect(await repo.watchById('i1').first, isNull);
    });

    test('newId returns unique ids', () {
      expect(repo.newId(), isNot(repo.newId()));
    });
  });

  group('UserRepository', () {
    test('creates a student profile and streams it', () async {
      final repo = UserRepository(FakeFirebaseFirestore());
      expect(await repo.watchUser('amina').first, isNull);

      await repo.createProfile(amina);
      final user = await repo.watchUser('amina').first;
      expect(user!.name, 'Amina Hassan');
      expect(user.role, UserRole.student);
    });

    test('updateProfile trims the editable fields', () async {
      final repo = UserRepository(FakeFirebaseFirestore());
      await repo.createProfile(amina);
      await repo.updateProfile(
        'amina',
        name: ' Amina H ',
        department: ' CS ',
        campus: ' Kigali ',
      );

      final user = await repo.watchUser('amina').first;
      expect(user!.name, 'Amina H');
      expect(user.department, 'CS');
      expect(user.campus, 'Kigali');
    });
  });

  group('AuthRepository', () {
    test('signs up, signs out and signs back in', () async {
      final auth = MockFirebaseAuth();
      final repo = AuthRepository(auth);

      final user = await repo.signUp(
        name: ' Amina ',
        email: 'amina@alu.edu ',
        password: 'secret123',
      );
      expect(user.email, 'amina@alu.edu');
      expect(repo.currentUser, isNotNull);

      await repo.signOut();
      expect(repo.currentUser, isNull);

      await repo.signIn(email: 'amina@alu.edu', password: 'secret123');
      expect(repo.currentUser, isNotNull);
    });

    test('maps Firebase errors to friendly messages', () async {
      final auth = MockFirebaseAuth();
      whenCalling(
        Invocation.method(#signInWithEmailAndPassword, null),
      ).on(auth).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      final repo = AuthRepository(auth);

      await expectLater(
        repo.signIn(email: 'a@b.c', password: 'x'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'Incorrect email or password.',
          ),
        ),
      );
    });

    test('unknown error codes get a generic message', () {
      expect(
        AuthFailure.fromCode('weird').message,
        'Something went wrong. Please try again.',
      );
    });
  });
}
