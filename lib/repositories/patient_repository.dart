import '../db/database_helper.dart';
import '../utils/app_constants.dart';

/// Repository for patient CRUD operations.
/// Screens should use this instead of calling DatabaseHelper directly.
class PatientRepository {
  PatientRepository._();
  static final PatientRepository instance = PatientRepository._();

  final _db = DatabaseHelper.instance;

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Returns a paginated list of patients ordered by creation date (newest first).
  Future<List<Map<String, dynamic>>> getPatients({
    int page = 0,
    int pageSize = AppPagination.patientPageSize,
  }) async {
    final database = await _db.db;
    return database.query(
      'patients',
      orderBy: 'created_at DESC',
      limit: pageSize,
      offset: page * pageSize,
    );
  }

  /// Returns the total number of patients (for pagination UI).
  Future<int> getPatientCount() async {
    final database = await _db.db;
    final result = await database.rawQuery('SELECT COUNT(*) as count FROM patients');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<Map<String, dynamic>?> getPatient(String id) => _db.getPatient(id);

  /// Search patients by name, ID, or village with pagination.
  Future<List<Map<String, dynamic>>> searchPatients(
    String query, {
    int page = 0,
    int pageSize = AppPagination.patientPageSize,
  }) async {
    if (query.trim().isEmpty) return getPatients(page: page, pageSize: pageSize);
    final database = await _db.db;
    final q = '%${query.toLowerCase()}%';
    return database.rawQuery(
      '''SELECT * FROM patients
         WHERE LOWER(name) LIKE ? OR LOWER(id) LIKE ? OR LOWER(village) LIKE ?
         ORDER BY created_at DESC
         LIMIT ? OFFSET ?''',
      [q, q, q, pageSize, page * pageSize],
    );
  }

  /// Count search results (for pagination UI).
  Future<int> searchPatientCount(String query) async {
    if (query.trim().isEmpty) return getPatientCount();
    final database = await _db.db;
    final q = '%${query.toLowerCase()}%';
    final result = await database.rawQuery(
      '''SELECT COUNT(*) as count FROM patients
         WHERE LOWER(name) LIKE ? OR LOWER(id) LIKE ? OR LOWER(village) LIKE ?''',
      [q, q, q],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> insertPatient(Map<String, dynamic> patient) =>
      _db.insertPatient(patient);

  /// Check for potential duplicate patients by name similarity + age.
  /// Returns list of existing patients that may be duplicates.
  Future<List<Map<String, dynamic>>> findPotentialDuplicates({
    required String name,
    required int age,
    String village = '',
  }) async {
    final database = await _db.db;
    final nameParts = name.trim().toLowerCase().split(' ');
    // Match on first name + last name (if available) + similar age (±2 years)
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName  = nameParts.length > 1 ? nameParts.last : '';

    final results = await database.rawQuery(
      '''SELECT * FROM patients
         WHERE (
           LOWER(name) LIKE ? OR
           (? != '' AND LOWER(name) LIKE ?)
         )
         AND ABS(age - ?) <= 2
         ORDER BY created_at DESC
         LIMIT 5''',
      [
        '%$firstName%',
        lastName,
        '%$lastName%',
        age,
      ],
    );
    return results;
  }

  Future<void> deletePatient(String patientId) => _db.deletePatient(patientId);
}
