import 'package:flutter_test/flutter_test.dart';
import 'package:visionscreen/utils/patient_validators.dart';

void main() {
  group('PatientValidators.validateName', () {
    test('accepts a well-formed name', () {
      expect(PatientValidators.validateName('Mary Atim'), isNull);
      expect(PatientValidators.validateName("O'Brien-Mukasa"), isNull);
    });

    test('rejects empty, too-short and too-long names', () {
      expect(PatientValidators.validateName('   '),
          'Patient name is required');
      expect(PatientValidators.validateName('A'),
          'Name must be at least 2 characters');
      expect(PatientValidators.validateName('a' * 101),
          'Name is too long (max 100 characters)');
    });

    test('rejects names containing digits or symbols', () {
      expect(PatientValidators.validateName('John99'),
          'Name should contain letters only');
    });
  });

  group('PatientValidators.validatePhone', () {
    test('treats an empty phone as valid (optional field)', () {
      expect(PatientValidators.validatePhone(''), isNull);
    });

    test('accepts Ugandan local, international and generic formats', () {
      expect(PatientValidators.validatePhone('0701234567'), isNull);
      expect(PatientValidators.validatePhone('0312345678'), isNull);
      expect(PatientValidators.validatePhone('+256701234567'), isNull);
      expect(PatientValidators.validatePhone('256701234567'), isNull);
      expect(PatientValidators.validatePhone('070 123 4567'), isNull);
    });

    test('rejects clearly invalid numbers', () {
      expect(PatientValidators.validatePhone('12345'),
          'Enter a valid phone number (e.g. 0701234567)');
      expect(PatientValidators.validatePhone('phone'),
          'Enter a valid phone number (e.g. 0701234567)');
    });
  });

  group('PatientValidators.validateAge', () {
    test('accepts ages within 1-120', () {
      expect(PatientValidators.validateAge(1), isNull);
      expect(PatientValidators.validateAge(45), isNull);
      expect(PatientValidators.validateAge(120), isNull);
    });

    test('rejects ages outside the supported range', () {
      expect(PatientValidators.validateAge(0), 'Age must be at least 1');
      expect(PatientValidators.validateAge(121), 'Age cannot exceed 120');
    });
  });

  group('PatientValidators.validateVillage', () {
    test('accepts a valid location', () {
      expect(PatientValidators.validateVillage('Bukoto'), isNull);
    });

    test('rejects empty or too-short locations', () {
      expect(PatientValidators.validateVillage(''),
          'Village or area is required');
      expect(PatientValidators.validateVillage('B'),
          'Please enter a valid location');
    });
  });

  group('PatientValidators.validateDob', () {
    test('requires a date of birth', () {
      expect(PatientValidators.validateDob(null),
          'Date of birth is required');
    });

    test('rejects a future date of birth', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(PatientValidators.validateDob(future),
          'Date of birth cannot be in the future');
    });

    test('rejects an unrealistic age', () {
      final tooOld = DateTime(DateTime.now().year - 130);
      expect(PatientValidators.validateDob(tooOld),
          'Date of birth gives an unrealistic age');
    });

    test('accepts a realistic past date of birth', () {
      final dob = DateTime(DateTime.now().year - 25, 6, 15);
      expect(PatientValidators.validateDob(dob), isNull);
    });
  });
}
