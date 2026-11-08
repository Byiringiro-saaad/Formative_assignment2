import '../config/app_config.dart';

/// Form validators shared by every screen. Each returns an error message, or
/// null when the value is valid (the contract `TextFormField` expects).
class Validators {
  const Validators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  /// Sign-up only accepts ALU addresses (see [AppConfig.allowedEmailDomains]).
  static String? aluEmail(String? value) {
    final error = email(value);
    if (error != null) return error;
    if (!AppConfig.isAllowedEmail(value)) {
      return 'Use your ALU email (@alustudent.com or @alueducation.com).';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password.';
    if (v.length < 8) return 'Use at least 8 characters.';
    if (!v.contains(RegExp(r'[A-Za-z]')) || !v.contains(RegExp(r'[0-9]'))) {
      return 'Use both letters and numbers.';
    }
    return null;
  }

  /// Sign-in only checks presence: older accounts may predate the rules above.
  static String? loginPassword(String? value) =>
      (value ?? '').isEmpty ? 'Enter your password.' : null;

  static String? Function(String?) confirmPassword(
    String Function() original,
  ) =>
      (value) => value != original() ? 'Passwords do not match.' : null;

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your full name.';
    if (v.length < 2) return 'Name is too short.';
    if (v.length > 60) return 'Name must be 60 characters or fewer.';
    return null;
  }

  /// Required text between [min] and [max] characters, after trimming.
  static String? Function(String?) text({
    required String field,
    int min = 1,
    int max = 1000,
  }) => (value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$field is required.';
    if (v.length < min) return '$field must be at least $min characters.';
    if (v.length > max) return '$field must be $max characters or fewer.';
    return null;
  };
}
