/// Access level of a signed-in user.
///
/// Everyone signs up as a [student]. The [staff] role can only be granted by
/// an administrator (see `tool/make_staff.mjs`); Firestore rules stop users
/// from promoting themselves.
enum UserRole {
  student('Student'),
  staff('Staff');

  const UserRole(this.label);

  final String label;

  static UserRole fromName(String? name) =>
      name == UserRole.staff.name ? UserRole.staff : UserRole.student;
}
