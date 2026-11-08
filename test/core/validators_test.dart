import 'package:campus_incidents/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('accepts valid addresses', () {
      expect(Validators.email('amina@alu.edu'), isNull);
      expect(Validators.email('  a.b+c@uni.ac.rw  '), isNull);
    });
    test('rejects empty and malformed addresses', () {
      expect(Validators.email(''), 'Enter your email address.');
      expect(Validators.email(null), 'Enter your email address.');
      expect(Validators.email('amina'), 'Enter a valid email address.');
      expect(Validators.email('amina@alu'), 'Enter a valid email address.');
      expect(
        Validators.email('a mina@alu.edu'),
        'Enter a valid email address.',
      );
    });
  });

  group('ALU email', () {
    test('accepts student and staff addresses, in any case', () {
      expect(Validators.aluEmail('a.mina@alustudent.com'), isNull);
      expect(Validators.aluEmail(' G.Uwase@ALUEducation.com '), isNull);
    });
    test('rejects other domains, including look-alikes', () {
      const message =
          'Use your ALU email (@alustudent.com or @alueducation.com).';
      expect(Validators.aluEmail('amina@gmail.com'), message);
      expect(Validators.aluEmail('amina@alustudent.com.evil.io'), message);
      expect(Validators.aluEmail('amina@notalustudent.com'), message);
    });
    test('still reports malformed addresses first', () {
      expect(Validators.aluEmail(''), 'Enter your email address.');
    });
  });

  group('password', () {
    test('needs 8+ characters with letters and numbers', () {
      expect(Validators.password('secret12'), isNull);
      expect(Validators.password(''), 'Enter a password.');
      expect(Validators.password('abc12'), 'Use at least 8 characters.');
      expect(Validators.password('abcdefgh'), 'Use both letters and numbers.');
      expect(Validators.password('12345678'), 'Use both letters and numbers.');
    });
    test('sign-in only checks that a password was entered', () {
      expect(Validators.loginPassword('x'), isNull);
      expect(Validators.loginPassword(''), 'Enter your password.');
    });
    test('confirmation must match', () {
      final check = Validators.confirmPassword(() => 'secret12');
      expect(check('secret12'), isNull);
      expect(check('secret13'), 'Passwords do not match.');
    });
  });

  group('name', () {
    test('validates length', () {
      expect(Validators.name('Amina Hassan'), isNull);
      expect(Validators.name(' '), 'Enter your full name.');
      expect(Validators.name('A'), 'Name is too short.');
      expect(Validators.name('x' * 61), 'Name must be 60 characters or fewer.');
    });
  });

  group('text', () {
    final title = Validators.text(field: 'Title', min: 3, max: 10);
    test('trims and checks bounds', () {
      expect(title('  Leak  '), isNull);
      expect(title(''), 'Title is required.');
      expect(title(' ab '), 'Title must be at least 3 characters.');
      expect(title('x' * 11), 'Title must be 10 characters or fewer.');
    });
  });
}
