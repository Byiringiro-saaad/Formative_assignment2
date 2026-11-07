import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Profile stored at `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.department = '',
    this.campus = '',
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String campus;
  final DateTime? createdAt;

  bool get isStaff => role == UserRole.staff;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    name: map['name'] as String? ?? '',
    email: map['email'] as String? ?? '',
    role: UserRole.fromName(map['role'] as String?),
    department: map['department'] as String? ?? '',
    campus: map['campus'] as String? ?? '',
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
  );

  /// Fields written when the profile is first created. The role is always
  /// `student`; the security rules reject anything else.
  Map<String, dynamic> toCreateMap() => {
    'name': name,
    'email': email,
    'role': UserRole.student.name,
    'department': department,
    'campus': campus,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
