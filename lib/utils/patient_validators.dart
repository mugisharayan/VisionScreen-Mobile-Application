// ─────────────────────────────────────────────────────────────
// Patient form validation utilities
// Used by new_screening_screen.dart and bulk_mode_screen.dart
// ─────────────────────────────────────────────────────────────

class PatientValidators {
  PatientValidators._();

  /// Validates full name — must be 2+ chars, letters/spaces/hyphens only
  static String? validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Patient name is required';
    if (trimmed.length < 2) return 'Name must be at least 2 characters';
    if (trimmed.length > 100) return 'Name is too long (max 100 characters)';
    if (!RegExp(r"^[a-zA-Z\s\-'\.]+$").hasMatch(trimmed)) {
      return 'Name should contain letters only';
    }
    return null;
  }

  /// Validates Uganda phone number — optional but if provided must be valid
  /// Accepts: 07XXXXXXXX, 03XXXXXXXX, +2567XXXXXXXX, 2567XXXXXXXX
  static String? validatePhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return null; // optional field

    // Strip spaces and dashes
    final cleaned = trimmed.replaceAll(RegExp(r'[\s\-]'), '');

    // Uganda formats
    final ugandaLocal    = RegExp(r'^0[37]\d{8}$');           // 07/03 + 8 digits
    final ugandaIntl     = RegExp(r'^\+?256[37]\d{8}$');      // +256 or 256 prefix
    final genericMobile  = RegExp(r'^\+?\d{9,15}$');          // any 9-15 digit number

    if (!ugandaLocal.hasMatch(cleaned) &&
        !ugandaIntl.hasMatch(cleaned) &&
        !genericMobile.hasMatch(cleaned)) {
      return 'Enter a valid phone number (e.g. 0701234567)';
    }
    return null;
  }

  /// Validates age — must be 1–120
  static String? validateAge(int age) {
    if (age < 1) return 'Age must be at least 1';
    if (age > 120) return 'Age cannot exceed 120';
    return null;
  }

  /// Validates village/area — required, 2+ chars
  static String? validateVillage(String village) {
    final trimmed = village.trim();
    if (trimmed.isEmpty) return 'Village or area is required';
    if (trimmed.length < 2) return 'Please enter a valid location';
    return null;
  }

  /// Validates date of birth — must not be in the future, must give age 1–120
  static String? validateDob(DateTime? dob) {
    if (dob == null) return 'Date of birth is required';
    final now = DateTime.now();
    if (dob.isAfter(now)) return 'Date of birth cannot be in the future';
    final age = now.year - dob.year -
        ((now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day))
            ? 1
            : 0);
    if (age < 0) return 'Invalid date of birth';
    if (age > 120) return 'Date of birth gives an unrealistic age';
    return null;
  }
}
