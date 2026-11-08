import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/primary_button.dart';
import 'auth_header.dart';
import 'auth_providers.dart';

/// Holds signed-in users here until their ALU email is verified.
///
/// Accounts outside the ALU domains can only sign out. The Firestore rules
/// and storage policies enforce the same checks, so skipping this screen
/// in a modified app gains nothing.
class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError) {
        showMessage(context, next.error.toString(), error: true);
      }
    });
    final user = ref.watch(authStateProvider).value;
    final email = user?.email ?? '';
    final allowed = AppConfig.isAllowedEmail(email);
    final loading = ref.watch(authControllerProvider).isLoading;
    final auth = ref.read(authControllerProvider.notifier);

    Future<void> check() async {
      final verified = await auth.checkVerified();
      if (!verified && context.mounted) {
        showMessage(
          context,
          'Not verified yet. Open the link in the email first.',
          error: true,
        );
      }
    }

    Future<void> resend() async {
      if (await auth.resendVerification() && context.mounted) {
        showMessage(context, 'Verification email sent to $email.');
      }
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: allowed ? 'Verify your email' : 'ALU email required',
                subtitle: allowed
                    ? 'We sent a verification link to $email. Open it, '
                          'then come back and tap the button below.'
                    : 'Campus Incidents is only for ALU accounts. You signed '
                          'in as $email. Sign out and use your '
                          '@alustudent.com or @alueducation.com email.',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: allowed ? AppColors.primaryLight : AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      allowed
                          ? Icons.mark_email_unread_outlined
                          : Icons.block_rounded,
                      color: allowed ? AppColors.primary : AppColors.danger,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        allowed
                            ? "Can't find it? Check your spam folder, or "
                                  'send the email again.'
                            : 'Reports can only be read and written by '
                                  'verified ALU accounts.',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              if (allowed) ...[
                PrimaryButton(
                  label: "I've Verified My Email",
                  loading: loading,
                  onPressed: check,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: loading ? null : resend,
                  child: const Text('Resend Email'),
                ),
                const SizedBox(height: 4),
              ],
              TextButton(
                onPressed: auth.signOut,
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
