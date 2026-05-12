import '../db/database_helper.dart';
import '../utils/app_constants.dart';

/// Repository for screening CRUD plus summary and reporting reads.
class ScreeningRepository {
  ScreeningRepository._();
  static final ScreeningRepository instance = ScreeningRepository._();

  final _db = DatabaseHelper.instance;

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Returns paginated screenings for a patient, newest first.
  Future<List<Map<String, dynamic>>> getScreeningsForPatient(
    String patientId, {
    int page = 0,
    int pageSize = AppPagination.screeningPageSize,
  }) async {
    final database = await _db.db;
    return database.query(
      'screenings',
      where: 'patient_id = ? AND deleted_at IS NULL',
      whereArgs: [patientId],
      orderBy: 'screening_date DESC',
      limit: pageSize,
      offset: page * pageSize,
    );
  }

  /// Total screening count for a patient (for pagination UI).
  Future<int> getScreeningCountForPatient(String patientId) async {
    final database = await _db.db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM screenings WHERE patient_id = ? AND deleted_at IS NULL',
      [patientId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<Map<String, dynamic>?> getLatestScreening(String patientId) =>
      _db.getLatestScreening(patientId);

  Future<Map<String, Map<String, dynamic>>> getLatestScreeningsForPatients(
    Iterable<String> patientIds,
  ) async {
    final ids = patientIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) {
      return <String, Map<String, dynamic>>{};
    }

    final database = await _db.db;
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await database.rawQuery('''
      SELECT s.*
      FROM screenings s
      JOIN (
        SELECT patient_id, MAX(screening_date) AS latest_screening_date
        FROM screenings
        WHERE deleted_at IS NULL AND patient_id IN ($placeholders)
        GROUP BY patient_id
      ) latest
        ON latest.patient_id = s.patient_id
       AND latest.latest_screening_date = s.screening_date
      WHERE s.deleted_at IS NULL
      ORDER BY s.patient_id ASC, s.id DESC
      ''', ids);

    final latestByPatient = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final patientId = row['patient_id'] as String? ?? '';
      if (patientId.isEmpty || latestByPatient.containsKey(patientId)) {
        continue;
      }
      latestByPatient[patientId] = row;
    }
    return latestByPatient;
  }

  Future<List<Map<String, dynamic>>> getRecentScreeningsWithPatient({
    int limit = AppPagination.recentLimit,
  }) => _db.getRecentScreeningsWithPatient(limit: limit);

  Future<List<Map<String, dynamic>>> getReferredPatients() =>
      _db.getReferredPatients();

  Future<int> getUnsyncedCount() => _db.getUnsyncedCount();

  Future<int> getPendingCount() => _db.getPendingCount();

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<int> insertScreening(Map<String, dynamic> screening) =>
      _db.insertScreening(screening);

  Future<void> updateReferralStatus(int screeningId, String status) =>
      _db.updateReferralStatus(screeningId, status);

  Future<void> updateReferralDetails(
    int screeningId, {
    String? facility,
    String? appointmentDate,
    String? status,
  }) => _db.updateReferralDetails(
    screeningId,
    facility: facility,
    appointmentDate: appointmentDate,
    status: status,
  );

  Future<void> markSynced(int screeningId) => _db.markSynced(screeningId);

  // ── Summary and reporting reads ───────────────────────────────────────────

  Future<Map<String, int>> getOutcomeCounts({String period = 'All'}) =>
      _db.getOutcomeCounts(period: period);

  Future<Map<String, int>> getAgeGroupCounts({String period = 'All'}) =>
      _db.getAgeGroupCounts(period: period);

  Future<Map<String, int>> getGenderCounts({String period = 'All'}) =>
      _db.getGenderCounts(period: period);

  Future<List<Map<String, dynamic>>> getPassRateTrend(String period) =>
      _db.getPassRateTrend(period);

  Future<Map<String, int>> getVisualAcuityDistribution({
    String period = 'All',
  }) => _db.getVisualAcuityDistribution(period: period);

  Future<Map<String, int>> getConditionCounts({String period = 'All'}) =>
      _db.getConditionCounts(period: period);

  Future<Map<String, int>> getSeverityClassification({String period = 'All'}) =>
      _db.getSeverityClassification(period: period);

  Future<Map<String, int>> getReferralStatusCounts({String period = 'All'}) =>
      _db.getReferralStatusCounts(period: period);

  Future<Map<String, int>> getFollowUpCompliance({String period = 'All'}) =>
      _db.getFollowUpCompliance(period: period);

  Future<Map<String, Map<String, int>>> getConditionsByAgeGroup({
    String period = 'All',
  }) => _db.getConditionsByAgeGroup(period: period);

  Future<List<Map<String, dynamic>>> getVillageBreakdown({
    String period = 'All',
  }) => _db.getVillageBreakdown(period: period);

  Future<List<Map<String, dynamic>>> getNotifications() =>
      _db.getNotifications();
}
