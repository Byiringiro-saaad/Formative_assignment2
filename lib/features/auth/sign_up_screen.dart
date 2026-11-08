import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/labeled_field.dart';
import '../../shared/widgets/password_field.dart';
import '../../shared/widgets/primary_button.dart';
import 'auth_header.dart';
import 'auth_providers.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _department = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _department, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .signUp(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          department: _department.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError) {
        showMessage(context, next.error.toString(), error: true);
      }
    });
    final loading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    title: 'Create account',
                    subtitle:
                        'Join your campus community and help keep it safe.',
                  ),
                  const SizedBox(height: 32),
                  LabeledField(
                    label: 'Full name',
                    hint: 'Amina Hassan',
                    controller: _name,
                    validator: Validators.name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: Icons.person_outline_rounded,
                    autofillHints: const [AutofillHints.name],
                  ),
                  const SizedBox(height: 20),
                  LabeledField(
                    label: 'ALU email',
                    hint: 'you@alustudent.com',
                    controller: _email,
                    validator: Validators.aluEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.mail_outline_rounded,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 20),
                  LabeledField(
                    label: 'Department (optional)',
                    hint: 'e.g. Computer Science',
                    controller: _department,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 20),
                  PasswordField(
                    controller: _password,
                    validator: Validators.password,
                    hint: 'At least 8 characters, letters and numbers',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 20),
                  PasswordField(
                    controller: _confirm,
                    label: 'Confirm password',
                    hint: 'Re-enter your password',
                    validator: Validators.confirmPassword(() => _password.text),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Create Account',
                    loading: loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () => context.go(Routes.login),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
