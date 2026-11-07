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

  Future<void> createProfile(AppUser user) =>
      _users.doc(user.uid).set(user.toCreateMap());

  /// Creates a student profile if [uid] has none yet, e.g. when sign-up was
  /// interrupted after the account was created but before the profile was.
  Future<void> ensureProfile({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    final doc = await _users.doc(uid).get();
    if (doc.exists) return;
    final fallbackName = email.split('@').first;
    await createProfile(
      AppUser(
        uid: uid,
        name: (displayName?.trim().isNotEmpty ?? false)
            ? displayName!.trim()
            : fallbackName,
        email: email,
        role: UserRole.student,
      ),
    );
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
