import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';

/// Reads and writes user profiles in the `users` collection.
class UserRepository {
  UserRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Live profile for [uid]; emits null until the profile document exists.
  Stream<AppUser?> watchUser(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null);

  /// Saves the profile chosen at sign-up.
  ///
  /// Runs in a transaction because the app may also be repairing a missing
  /// profile at the same moment (see [ensureProfile]). Whichever write lands
  /// second just updates the editable fields, so neither fails.
  Future<void> createProfile(AppUser user) => _db.runTransaction((tx) async {
    final ref = _users.doc(user.uid);
    final existing = await tx.get(ref);
    if (existing.exists) {
      tx.update(ref, {
        'name': user.name,
        'department': user.department,
        'campus': user.campus,
      });
    } else {
      tx.set(ref, user.toCreateMap());
    }
  });

  /// Creates a student profile if [uid] has none yet, e.g. when sign-up was
  /// interrupted after the account was created but before the profile was.
  /// Never overwrites an existing profile.
  Future<void> ensureProfile({
    required String uid,
    required String email,
    String? displayName,
  }) => _db.runTransaction((tx) async {
    final ref = _users.doc(uid);
    if ((await tx.get(ref)).exists) return;
    tx.set(
      ref,
      AppUser(
        uid: uid,
        name: fallbackName(displayName: displayName, email: email),
        email: email,
        role: UserRole.student,
      ).toCreateMap(),
    );
  });

  /// A name that always passes the 2–60 character rule.
  static String fallbackName({String? displayName, required String email}) {
    final raw = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : email.split('@').first;
    final padded = raw.length < 2 ? 'Student $raw'.trim() : raw;
    return padded.length > 60 ? padded.substring(0, 60) : padded;
  }

  /// Updates the editable profile fields. The role can't be changed here.
  Future<void> updateProfile(
    String uid, {
    required String name,
    required String department,
    required String campus,
  }) => _users.doc(uid).update({
    'name': name.trim(),
    'department': department.trim(),
    'campus': campus.trim(),
  });
}
