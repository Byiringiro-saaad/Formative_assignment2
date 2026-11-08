/// Public client configuration for the backend services.
///
/// These values are safe to ship in the app: the Supabase publishable key
/// only grants what the storage policies in `supabase/storage.sql` allow,
/// and Firebase client keys are protected by Firestore security rules.
class AppConfig {
  const AppConfig._();

  static const firebaseProjectId = 'campus-incidents-saad-b5923';

  static const supabaseUrl = 'https://wkjdfzafkuwigelkxiir.supabase.co';
  static const supabasePublishableKey =
      'sb_publishable_wTRNK6e8gRmLinjpxOlkvg_EJWLBzcS';

  /// Supabase Storage bucket that holds incident photos.
  static const photoBucket = 'incident-photos';

  /// Largest photo we upload, after compression on the device.
  static const maxPhotoBytes = 5 * 1024 * 1024;

  /// Only ALU accounts may use the app: students and staff.
  /// The Firestore rules and storage policies check the same list.
  static const allowedEmailDomains = ['alustudent.com', 'alueducation.com'];

  /// True when [email] ends in one of [allowedEmailDomains].
  static bool isAllowedEmail(String? email) {
    final e = (email ?? '').trim().toLowerCase();
    return allowedEmailDomains.any((d) => e.endsWith('@$d'));
  }
}
