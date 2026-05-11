import '../db/database_helper.dart';

/// Repository for campaign CRUD operations.
/// Fixes the N+1 query problem in getAllCampaigns by batching stat updates.
class CampaignRepository {
  CampaignRepository._();
  static final CampaignRepository instance = CampaignRepository._();

  final _db = DatabaseHelper.instance;

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Returns all campaigns with up-to-date stats.
  ///
  /// Fixes the original N+1 pattern: instead of updating each campaign
  /// individually and re-querying, we do a single bulk UPDATE via a
  /// subquery, then fetch all campaigns in one query.
  Future<List<Map<String, dynamic>>> getAllCampaigns() async {
    final database = await _db.db;

    // Single bulk UPDATE: recalculate stats for all campaigns at once
    await database.execute('''
      UPDATE campaigns
      SET
        total = (
          SELECT COUNT(DISTINCT p.id)
          FROM patients p
          WHERE p.campaign_id = campaigns.id
            AND p.deleted_at IS NULL
        ),
        passed = (
          SELECT COUNT(DISTINCT p.id)
          FROM patients p
          INNER JOIN (
            SELECT patient_id, outcome
            FROM screenings
            WHERE id IN (
              SELECT MAX(id)
              FROM screenings
              WHERE deleted_at IS NULL
              GROUP BY patient_id
            )
          ) latest ON latest.patient_id = p.id
          WHERE p.campaign_id = campaigns.id
            AND p.deleted_at IS NULL
            AND latest.outcome = 'pass'
        ),
        referred = (
          SELECT COUNT(DISTINCT p.id)
          FROM patients p
          INNER JOIN (
            SELECT patient_id, outcome
            FROM screenings
            WHERE id IN (
              SELECT MAX(id)
              FROM screenings
              WHERE deleted_at IS NULL
              GROUP BY patient_id
            )
          ) latest ON latest.patient_id = p.id
          WHERE p.campaign_id = campaigns.id
            AND p.deleted_at IS NULL
            AND latest.outcome = 'refer'
        )
      WHERE deleted_at IS NULL
    ''');

    return database.query(
      'campaigns',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getCampaign(String id) => _db.getCampaign(id);

  Future<List<Map<String, dynamic>>> getPatientsForCampaign(
    String campaignId,
  ) => _db.getPatientsForCampaign(campaignId);

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<String> insertCampaign(Map<String, dynamic> campaign) =>
      _db.insertCampaign(campaign);

  Future<void> deleteCampaign(String campaignId) =>
      _db.deleteCampaign(campaignId);

  /// Recalculate stats for a single campaign (used after individual patient changes).
  Future<void> updateCampaignStats(String campaignId) =>
      _db.updateCampaignStats(campaignId);
}
