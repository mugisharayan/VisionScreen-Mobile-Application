import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'visionscreen.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE chw_profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            center TEXT NOT NULL,
            district TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            phone TEXT NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'chw',
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE campaigns (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            location TEXT NOT NULL,
            target_group TEXT NOT NULL,
            created_at TEXT NOT NULL,
            total INTEGER DEFAULT 0,
            passed INTEGER DEFAULT 0,
            referred INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE patients (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            dob TEXT,
            gender TEXT NOT NULL,
            village TEXT NOT NULL,
            phone TEXT,
            conditions TEXT,
            photo_path TEXT,
            campaign_id TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (campaign_id) REFERENCES campaigns(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE screenings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_id TEXT NOT NULL,
            screening_date TEXT NOT NULL,
            od_logmar TEXT,
            os_logmar TEXT,
            ou_near_logmar TEXT,
            od_snellen TEXT,
            os_snellen TEXT,
            ou_near_snellen TEXT,
            od_cant_tell INTEGER DEFAULT 0,
            os_cant_tell INTEGER DEFAULT 0,
            near_cant_tell INTEGER DEFAULT 0,
            od_duration TEXT,
            os_duration TEXT,
            near_duration TEXT,
            outcome TEXT NOT NULL,
            referral_facility TEXT,
            referral_status TEXT,
            appointment_date TEXT,
            chw_name TEXT,
            synced INTEGER DEFAULT 0,
            FOREIGN KEY (patient_id) REFERENCES patients(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE screenings ADD COLUMN appointment_date TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS chw_profiles (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              center TEXT NOT NULL,
              district TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              phone TEXT NOT NULL,
              password TEXT NOT NULL,
              role TEXT NOT NULL DEFAULT 'chw',
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS campaigns (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              location TEXT NOT NULL,
              target_group TEXT NOT NULL,
              created_at TEXT NOT NULL,
              total INTEGER DEFAULT 0,
              passed INTEGER DEFAULT 0,
            referred INTEGER DEFAULT 0
            )
          ''');
          await db.execute('ALTER TABLE patients ADD COLUMN campaign_id TEXT');
        }
      },
    );
  }

  // ── PATIENTS ──────────────────────────────────────────────

  Future<void> insertPatient(Map<String, dynamic> patient) async {
    final database = await db;
    await database.insert(
      'patients',
      patient,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePatient(String patientId) async {
    final database = await db;
    // Get campaign_id before deleting
    final patient = await getPatient(patientId);
    final campaignId = patient?['campaign_id'] as String?;
    await database.delete('screenings', where: 'patient_id = ?', whereArgs: [patientId]);
    await database.delete('patients', where: 'id = ?', whereArgs: [patientId]);
    // Update campaign stats if this patient belonged to a campaign
    if (campaignId != null && campaignId.isNotEmpty) {
      await updateCampaignStats(campaignId);
    }
  }

  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final database = await db;
    return database.query('patients', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getPatient(String id) async {
    final database = await db;
    final rows = await database.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    final database = await db;
    final q = '%${query.toLowerCase()}%';
    return database.rawQuery(
      'SELECT * FROM patients WHERE LOWER(name) LIKE ? OR LOWER(id) LIKE ? OR LOWER(village) LIKE ? ORDER BY created_at DESC',
      [q, q, q],
    );
  }

  // ── CAMPAIGNS ─────────────────────────────────────────────

  Future<String> insertCampaign(Map<String, dynamic> campaign) async {
    final database = await db;
    await database.insert('campaigns', campaign, conflictAlgorithm: ConflictAlgorithm.replace);
    return campaign['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAllCampaigns() async {
    final database = await db;
    final campaigns = await database.query('campaigns', orderBy: 'created_at DESC');
    // Recalculate stats for each campaign fresh
    final result = <Map<String, dynamic>>[];
    for (final c in campaigns) {
      await updateCampaignStats(c['id'] as String);
      final updated = await database.query('campaigns', where: 'id = ?', whereArgs: [c['id']], limit: 1);
      if (updated.isNotEmpty) result.add(updated.first);
    }
    return result;
  }

  Future<Map<String, dynamic>?> getCampaign(String id) async {
    final database = await db;
    final rows = await database.query('campaigns', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> updateCampaignStats(String campaignId) async {
    final database = await db;
    // Count distinct patients, and their latest screening outcome
    final result = await database.rawQuery('''
      SELECT
        COUNT(DISTINCT p.id) AS total,
        SUM(CASE WHEN latest.outcome = 'pass'  THEN 1 ELSE 0 END) AS passed,
        SUM(CASE WHEN latest.outcome = 'refer' THEN 1 ELSE 0 END) AS referred
      FROM patients p
      LEFT JOIN (
        SELECT patient_id, outcome
        FROM screenings
        WHERE id IN (
          SELECT MAX(id) FROM screenings GROUP BY patient_id
        )
      ) latest ON latest.patient_id = p.id
      WHERE p.campaign_id = ?
    ''', [campaignId]);
    if (result.isNotEmpty) {
      await database.update('campaigns', {
        'total':    (result.first['total']    as int?) ?? 0,
        'passed':   (result.first['passed']   as num?)?.toInt() ?? 0,
        'referred': (result.first['referred'] as num?)?.toInt() ?? 0,
      }, where: 'id = ?', whereArgs: [campaignId]);
    }
  }

  Future<void> deleteCampaign(String campaignId) async {
    final database = await db;
    // Delete all screenings for patients in this campaign
    final patients = await database.query('patients', where: 'campaign_id = ?', whereArgs: [campaignId]);
    for (final p in patients) {
      await database.delete('screenings', where: 'patient_id = ?', whereArgs: [p['id']]);
    }
    // Delete all patients in this campaign
    await database.delete('patients', where: 'campaign_id = ?', whereArgs: [campaignId]);
    // Delete the campaign
    await database.delete('campaigns', where: 'id = ?', whereArgs: [campaignId]);
  }

  Future<List<Map<String, dynamic>>> getPatientsForCampaign(String campaignId) async {
    final database = await db;
    return database.rawQuery('''
      SELECT p.*, s.outcome, s.od_snellen, s.os_snellen, s.ou_near_snellen,
             s.referral_facility, s.referral_status, s.screening_date
      FROM patients p
      LEFT JOIN screenings s ON s.id = (
        SELECT id FROM screenings WHERE patient_id = p.id ORDER BY screening_date DESC LIMIT 1
      )
      WHERE p.campaign_id = ?
      ORDER BY p.created_at ASC
    ''', [campaignId]);
  }

  // ── SCREENINGS ────────────────────────────────────────────

  Future<int> insertScreening(Map<String, dynamic> screening) async {
    final database = await db;
    return database.insert('screenings', screening);
  }

  Future<List<Map<String, dynamic>>> getScreeningsForPatient(
      String patientId) async {
    final database = await db;
    return database.query(
      'screenings',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'screening_date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllScreenings() async {
    final database = await db;
    return database.query('screenings', orderBy: 'screening_date DESC');
  }

  Future<Map<String, dynamic>?> getLatestScreening(String patientId) async {
    final database = await db;
    final rows = await database.query(
      'screenings',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'screening_date DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> updateReferralStatus(int screeningId, String status) async {
    final database = await db;
    await database.update(
      'screenings',
      {'referral_status': status.toLowerCase().trim()},
      where: 'id = ?',
      whereArgs: [screeningId],
    );
  }

  Future<void> updateReferralDetails(int screeningId, {
    String? facility,
    String? appointmentDate,
    String? status,
  }) async {
    final database = await db;
    final data = <String, dynamic>{};
    if (facility != null) data['referral_facility'] = facility;
    if (appointmentDate != null) data['appointment_date'] = appointmentDate;
    if (status != null) data['referral_status'] = status.toLowerCase().trim();
    if (data.isEmpty) return;
    await database.update('screenings', data, where: 'id = ?', whereArgs: [screeningId]);
  }

  Future<List<Map<String, dynamic>>> getReferredPatients() async {
    final database = await db;
    return database.rawQuery('''
      SELECT s.id as screening_id, s.patient_id, s.od_snellen, s.os_snellen,
             s.referral_facility, s.referral_status, s.appointment_date,
             p.name, p.age, p.gender, p.photo_path
      FROM screenings s
      JOIN patients p ON s.patient_id = p.id
      WHERE s.outcome = 'refer'
      ORDER BY s.appointment_date ASC
    ''');
  }

  /// Patients registered but not yet screened (no row in screenings table)
  Future<int> getPendingCount() async {
    final database = await this.db;
    final result = await database.rawQuery('''
      SELECT COUNT(*) as count FROM patients p
      WHERE NOT EXISTS (
        SELECT 1 FROM screenings s WHERE s.patient_id = p.id
      )
    ''');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getUnsyncedCount() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM screenings WHERE synced = 0',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> markSynced(int screeningId) async {
    final database = await db;
    await database.update(
      'screenings',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [screeningId],
    );
  }

  // ── ANALYTICS ─────────────────────────────────────────────

  Future<Map<String, int>> getOutcomeCounts({String period = 'All'}) async {
    final database = await db;
    final where = _periodWhere(period);
    final rows = await database.rawQuery(
      'SELECT outcome, COUNT(*) as count FROM screenings ${where.isEmpty ? '' : 'WHERE $where'} GROUP BY outcome',
    );
    final map = <String, int>{};
    for (final row in rows) {
      map[row['outcome'] as String] = (row['count'] as int?) ?? 0;
    }
    // Add pending: patients with no screening record at all
    final pendingResult = await database.rawQuery('''
      SELECT COUNT(*) as count FROM patients p
      WHERE NOT EXISTS (SELECT 1 FROM screenings s WHERE s.patient_id = p.id)
    ''');
    map['pending'] = (pendingResult.first['count'] as int?) ?? 0;
    return map;
  }

  Future<Map<String, int>> getAgeGroupCounts({String period = 'All'}) async {
    final database = await db;
    final where = _periodWhere(period);
    final whereClause = where.isEmpty ? '' : 'WHERE $where';
    final rows = await database.rawQuery('''
      SELECT
        CASE
          WHEN p.age BETWEEN 0  AND 17 THEN '0-17'
          WHEN p.age BETWEEN 18 AND 40 THEN '18-40'
          WHEN p.age BETWEEN 41 AND 60 THEN '41-60'
          ELSE '60+'
        END as age_group,
        COUNT(DISTINCT p.id) as count
      FROM patients p
      INNER JOIN screenings s ON s.patient_id = p.id
      $whereClause
      GROUP BY age_group
    ''');
    final map = <String, int>{};
    for (final row in rows) {
      map[row['age_group'] as String] = (row['count'] as int?) ?? 0;
    }
    return map;
  }

  Future<Map<String, int>> getGenderCounts({String period = 'All'}) async {
    final database = await db;
    final where = _periodWhere(period);
    final whereClause = where.isEmpty ? '' : 'WHERE $where';
    final rows = await database.rawQuery('''
      SELECT p.gender, COUNT(DISTINCT p.id) as count
      FROM patients p
      INNER JOIN screenings s ON s.patient_id = p.id
      $whereClause
      GROUP BY p.gender
    ''');
    final map = <String, int>{};
    for (final row in rows) {
      map[row['gender'] as String] = (row['count'] as int?) ?? 0;
    }
    return map;
  }

  /// Returns a WHERE clause fragment (no leading WHERE) for the given period.
  String _periodWhere(String period) {
    switch (period) {
      case 'Today':
        return "DATE(screening_date) = DATE('now')";
      case 'Week':
        return "screening_date >= DATE('now', '-6 days')";
      case 'Month':
        return "screening_date >= DATE('now', '-29 days')";
      case 'Year':
        return "screening_date >= DATE('now', '-364 days')";
      default:
        return '';
    }
  }

  /// Pass-rate trend: returns one row per day/hour depending on period.
  /// Each row: { label, pass_count, refer_count }
  /// Also returns a 'total' summary row as the last element with label '__total__'.
  Future<List<Map<String, dynamic>>> getPassRateTrend(String period) async {
    final database = await db;
    String groupExpr;
    String whereClause;
    switch (period) {
      case 'Today':
        groupExpr   = "strftime('%H:00', screening_date)";
        whereClause = "DATE(screening_date) = DATE('now')";
        break;
      case 'Month':
        groupExpr   = "DATE(screening_date)";
        whereClause = "screening_date >= DATE('now', '-29 days')";
        break;
      case 'Year':
        groupExpr   = "strftime('%Y-%m', screening_date)";
        whereClause = "screening_date >= DATE('now', '-364 days')";
        break;
      default: // Week
        groupExpr   = "DATE(screening_date)";
        whereClause = "screening_date >= DATE('now', '-6 days')";
    }
    final rows = await database.rawQuery('''
      SELECT
        $groupExpr AS label,
        SUM(CASE WHEN outcome = 'pass'  THEN 1 ELSE 0 END) AS pass_count,
        SUM(CASE WHEN outcome = 'refer' THEN 1 ELSE 0 END) AS refer_count
      FROM screenings
      WHERE $whereClause
      GROUP BY $groupExpr
      ORDER BY $groupExpr ASC
    ''');
    final points = rows
        .map((r) => {
              'label':       r['label'] as String? ?? '',
              'pass_count':  (r['pass_count']  as num?)?.toInt() ?? 0,
              'refer_count': (r['refer_count'] as num?)?.toInt() ?? 0,
            })
        .toList();

    // Append a period-total summary so the chart headline shows
    // the overall rate for the whole period, not just the last bucket.
    final totalPass  = points.fold(0, (s, r) => s + (r['pass_count']  as int));
    final totalRefer = points.fold(0, (s, r) => s + (r['refer_count'] as int));
    points.add({
      'label':       '__total__',
      'pass_count':  totalPass,
      'refer_count': totalRefer,
    });
    return points;
  }

  /// Buckets worst-eye Snellen per patient into 5 acuity levels.
  Future<Map<String, int>> getVisualAcuityDistribution({String period = 'All'}) async {
    final database = await db;
    final where = _periodWhere(period);
    final periodFilter = where.isEmpty ? '' : 'AND $where';
    final rows = await database.rawQuery('''
      SELECT od_snellen, os_snellen
      FROM screenings
      WHERE id IN (
        SELECT MAX(id)
        FROM screenings
        WHERE 1=1 $periodFilter
        GROUP BY patient_id
      )
      AND (od_snellen IS NOT NULL OR os_snellen IS NOT NULL)
    ''');
    final counts = <String, int>{
      'Normal': 0, 'Near Normal': 0, 'Moderate': 0, 'Severe': 0, 'Blind Range': 0,
    };
    for (final row in rows) {
      final od = row['od_snellen'] as String?;
      final os = row['os_snellen'] as String?;
      final bucket = _worstAcuityBucket(od, os);
      if (bucket != null) counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns the acuity bucket for the worse of two eyes.
  /// Returns null if both values are null/empty (unrecorded).
  String? _worstAcuityBucket(String? od, String? os) {
    int rank(String? s) {
      if (s == null || s.trim().isEmpty) return -1; // unrecorded
      if (s.contains('6/6') && !s.contains('6/60')) return 0;
      if (s.contains('6/9') || s.contains('6/12')) return 1;
      if (s.contains('6/18') || s.contains('6/24')) return 2;
      if (s.contains('6/36') || s.contains('6/60')) return 3;
      return 4; // CF / HM / PL / <6/60
    }
    final rOd = rank(od);
    final rOs = rank(os);
    // Both unrecorded — skip this row
    if (rOd == -1 && rOs == -1) return null;
    final worst = rOd >= rOs ? rOd : rOs;
    if (worst <= 0) return 'Normal';
    if (worst == 1) return 'Near Normal';
    if (worst == 2) return 'Moderate';
    if (worst == 3) return 'Severe';
    return 'Blind Range';
  }

  /// Counts occurrences of each condition tag stored in patients.conditions.
  Future<Map<String, int>> getConditionCounts({String period = 'All'}) async {
    final database = await db;
    final where = _periodWhere(period);
    final rows = where.isEmpty
        ? await database.rawQuery(
            "SELECT conditions FROM patients WHERE conditions IS NOT NULL AND conditions != ''")
        : await database.rawQuery('''
            SELECT p.conditions
            FROM patients p
            INNER JOIN screenings s ON s.patient_id = p.id
            WHERE $where
              AND p.conditions IS NOT NULL AND p.conditions != ''
          ''');
    final counts = <String, int>{};
    for (final row in rows) {
      final raw = row['conditions'] as String? ?? '';
      for (final tag in raw.split(',')) {
        final t = tag.trim();
        if (t.isNotEmpty) counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Derives severity from worst-eye logMAR per patient.
  /// Uses the same thresholds as the screening app's _needsReferral logic.
  /// Normal: logMAR <= 0.3 (6/12 or better)
  /// Mild:   logMAR 0.4–0.5
  /// Moderate: logMAR 0.6–1.0
  /// Severe: logMAR > 1.0
  /// Critical: cant_tell on both eyes (unable to assess)
  Future<Map<String, int>> getSeverityClassification({String period = 'All'}) async {
    final database = await db;
    final where = _periodWhere(period);
    final periodFilter = where.isEmpty ? '' : 'AND $where';
    // Get latest screening per patient within the period
    final rows = await database.rawQuery('''
      SELECT od_logmar, os_logmar, od_cant_tell, os_cant_tell
      FROM screenings
      WHERE id IN (
        SELECT MAX(id)
        FROM screenings
        WHERE 1=1 $periodFilter
        GROUP BY patient_id
      )
    ''');

    final counts = <String, int>{
      'Normal': 0, 'Mild': 0, 'Moderate': 0, 'Severe': 0, 'Critical': 0,
    };

    for (final row in rows) {
      final odLogmar    = double.tryParse((row['od_logmar'] as String?) ?? '');
      final osLogmar    = double.tryParse((row['os_logmar'] as String?) ?? '');
      final odCantTell  = (row['od_cant_tell'] as int?) ?? 0;
      final osCantTell  = (row['os_cant_tell'] as int?) ?? 0;

      // Both eyes unable to assess
      if (odLogmar == null && osLogmar == null) {
        if (odCantTell > 0 || osCantTell > 0) {
          counts['Critical'] = counts['Critical']! + 1;
        }
        // No data at all — skip
        continue;
      }

      // Use the worse (higher logMAR) of the two recorded eyes
      final worst = [odLogmar, osLogmar]
          .whereType<double>()
          .fold<double>(-1, (m, v) => v > m ? v : m);

      if (worst <= 0.3)      counts['Normal']   = counts['Normal']!   + 1;
      else if (worst <= 0.5) counts['Mild']     = counts['Mild']!     + 1;
      else if (worst <= 1.0) counts['Moderate'] = counts['Moderate']! + 1;
      else if (worst <= 2.0) counts['Severe']   = counts['Severe']!   + 1;
      else                   counts['Critical'] = counts['Critical']! + 1;
    }
    return counts;
  }

  /// Referral status breakdown for all referred screenings.
  Future<Map<String, int>> getReferralStatusCounts({String period = 'All'}) async {
    final database = await db;
    final where = _periodWhere(period);
    final periodFilter = where.isEmpty ? '' : 'AND $where';
    final rows = await database.rawQuery('''
      SELECT
        CASE
          WHEN referral_status IS NULL OR TRIM(referral_status) = '' THEN 'pending'
          ELSE LOWER(TRIM(referral_status))
        END AS status,
        COUNT(*) AS count
      FROM screenings
      WHERE outcome = 'refer' $periodFilter
      GROUP BY status
    ''');
    final map = <String, int>{};
    for (final row in rows) {
      final key = row['status'] as String;
      map[key] = ((map[key] ?? 0) + ((row['count'] as int?) ?? 0));
    }
    return map;
  }

  /// Follow-up compliance: maps referral_status to attendance buckets.
  Future<Map<String, int>> getFollowUpCompliance({String period = 'All'}) async {
    final statuses = await getReferralStatusCounts(period: period);
    return {
      'Attended':    statuses['completed']   ?? 0,
      'Rescheduled': statuses['rescheduled'] ?? 0,
      'Pending':     (statuses['pending'] ?? 0) + (statuses['notified'] ?? 0),
      'Missed':      statuses['overdue']     ?? 0,
    };
  }

  /// Conditions broken down by age group.
  Future<Map<String, Map<String, int>>> getConditionsByAgeGroup({String period = 'All'}) async {
    final database = await db;
    final where = _periodWhere(period);
    final periodFilter = where.isEmpty ? '' : 'AND $where';
    final rows = await database.rawQuery('''
      SELECT
        p.conditions,
        CASE
          WHEN p.age BETWEEN 0  AND 17 THEN '0-17'
          WHEN p.age BETWEEN 18 AND 60 THEN '18-60'
          ELSE '60+'
        END AS age_group
      FROM patients p
      WHERE p.conditions IS NOT NULL
        AND p.conditions != ''
        AND EXISTS (
          SELECT 1 FROM screenings s
          WHERE s.patient_id = p.id $periodFilter
        )
    ''');
    final result = <String, Map<String, int>>{};
    for (final row in rows) {
      final ageGroup = row['age_group'] as String;
      final raw      = row['conditions'] as String? ?? '';
      for (final tag in raw.split(',')) {
        final t = tag.trim();
        if (t.isEmpty) continue;
        result.putIfAbsent(t, () => {'0-17': 0, '18-60': 0, '60+': 0});
        result[t]![ageGroup] = (result[t]![ageGroup] ?? 0) + 1;
      }
    }
    return result;
  }

  /// Village breakdown: total patients + referred count per village.
  Future<List<Map<String, dynamic>>> getVillageBreakdown({String period = 'All'}) async {
    final database = await db;
    final where = _periodWhere(period);

    // When a period is set, only count patients who had a screening in that period.
    // Use a subquery to get per-patient stats within the period, then group by village.
    String sql;
    if (where.isEmpty) {
      sql = '''
        SELECT
          p.village,
          COUNT(DISTINCT p.id) AS total,
          SUM(CASE WHEN latest.outcome = 'refer' THEN 1 ELSE 0 END) AS referred
        FROM patients p
        LEFT JOIN (
          SELECT patient_id, outcome
          FROM screenings
          WHERE id IN (SELECT MAX(id) FROM screenings GROUP BY patient_id)
        ) latest ON latest.patient_id = p.id
        GROUP BY p.village
        ORDER BY total DESC
      ''';
    } else {
      sql = '''
        SELECT
          p.village,
          COUNT(DISTINCT p.id) AS total,
          SUM(CASE WHEN s.outcome = 'refer' THEN 1 ELSE 0 END) AS referred
        FROM patients p
        INNER JOIN screenings s ON s.patient_id = p.id AND $where
        GROUP BY p.village
        ORDER BY total DESC
      ''';
    }

    final rows = await database.rawQuery(sql);
    return rows
        .map((r) => {
              'village':  r['village']  as String? ?? 'Unknown',
              'total':    (r['total']   as int?)          ?? 0,
              'referred': (r['referred'] as num?)?.toInt() ?? 0,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRecentScreeningsWithPatient(
      {int limit = 10}) async {
    final database = await db;
    return database.rawQuery('''
      SELECT s.*, p.name, p.age, p.gender, p.village, p.photo_path, p.conditions
      FROM screenings s
      JOIN patients p ON s.patient_id = p.id
      ORDER BY s.screening_date DESC
      LIMIT ?
    ''', [limit]);
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────

  // ── CHW PROFILES ──────────────────────────────────────────

  Future<void> insertChwProfile(Map<String, dynamic> profile) async {
    final database = await db;
    await database.insert('chw_profiles', profile, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getChwProfileByEmail(String email) async {
    final database = await db;
    final rows = await database.query(
      'chw_profiles',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final List<Map<String, dynamic>> notifications = [];

    // 1. Overdue referrals (appointment_date passed, status still pending/notified)
    final overdueRows = await (await db).rawQuery('''
      SELECT s.id, p.name, s.referral_facility, s.appointment_date
      FROM screenings s JOIN patients p ON s.patient_id = p.id
      WHERE s.outcome = 'refer'
        AND s.referral_status IN ('pending','notified')
        AND s.appointment_date IS NOT NULL
        AND s.appointment_date < datetime('now')
      ORDER BY s.appointment_date ASC
    ''');
    for (final r in overdueRows) {
      notifications.add({
        'icon': 'warning',
        'color': 0xFFEF4444,
        'title': 'Referral Overdue',
        'body': '${r['name']} has not attended ${r['referral_facility']}.',
        'time': r['appointment_date'],
        'read': false,
        'tag': 'URGENT',
      });
    }

    // 2. Upcoming appointments (within next 3 days)
    final upcomingRows = await (await db).rawQuery('''
      SELECT s.id, p.name, s.referral_facility, s.appointment_date
      FROM screenings s JOIN patients p ON s.patient_id = p.id
      WHERE s.outcome = 'refer'
        AND s.referral_status IN ('pending','notified')
        AND s.appointment_date >= datetime('now')
        AND s.appointment_date <= datetime('now', '+3 days')
      ORDER BY s.appointment_date ASC
    ''');
    for (final r in upcomingRows) {
      notifications.add({
        'icon': 'reminder',
        'color': 0xFF8B5CF6,
        'title': 'Appointment Reminder',
        'body': '${r['name']} — ${r['referral_facility']} on ${r['appointment_date']}.',
        'time': r['appointment_date'],
        'read': false,
        'tag': 'REMINDER',
      });
    }

    // 3. Recent screenings (last 24 hours)
    final recentRows = await (await db).rawQuery('''
      SELECT s.id, p.name, s.outcome, s.od_snellen, s.os_snellen, s.screening_date
      FROM screenings s JOIN patients p ON s.patient_id = p.id
      WHERE s.screening_date >= datetime('now', '-1 day')
      ORDER BY s.screening_date DESC
      LIMIT 5
    ''');
    for (final r in recentRows) {
      final passed = r['outcome'] == 'pass';
      notifications.add({
        'icon': passed ? 'check' : 'assignment',
        'color': passed ? 0xFF22C55E : 0xFFF59E0B,
        'title': passed ? 'Screening Passed' : 'Referral Generated',
        'body': passed
            ? '${r['name']} passed. OD ${r['od_snellen']}, OS ${r['os_snellen']}.'
            : 'Referral created for ${r['name']}.',
        'time': r['screening_date'],
        'read': true,
        'tag': passed ? 'RESULT' : 'REFERRAL',
      });
    }

    // 4. Unsynced records
    final unsynced = await getUnsyncedCount();
    if (unsynced > 0) {
      notifications.add({
        'icon': 'sync',
        'color': 0xFF38BDF8,
        'title': 'Sync Pending',
        'body': '$unsynced record${unsynced == 1 ? '' : 's'} waiting to sync.',
        'time': DateTime.now().toIso8601String(),
        'read': unsynced < 3,
        'tag': 'SYNC',
      });
    }

    return notifications;
  }
}
