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
      version: 3,
      onCreate: (db, _) async {
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
    await database.delete('screenings', where: 'patient_id = ?', whereArgs: [patientId]);
    await database.delete('patients', where: 'id = ?', whereArgs: [patientId]);
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
    return database.query('campaigns', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getCampaign(String id) async {
    final database = await db;
    final rows = await database.query('campaigns', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> updateCampaignStats(String campaignId) async {
    final database = await db;
    final result = await database.rawQuery('''
      SELECT
        COUNT(DISTINCT p.id) as total,
        SUM(CASE WHEN s.outcome = 'pass' THEN 1 ELSE 0 END) as passed,
        SUM(CASE WHEN s.outcome = 'refer' THEN 1 ELSE 0 END) as referred
      FROM patients p
      LEFT JOIN screenings s ON s.patient_id = p.id
      WHERE p.campaign_id = ?
    ''', [campaignId]);
    if (result.isNotEmpty) {
      await database.update('campaigns', {
        'total': result.first['total'] ?? 0,
        'passed': result.first['passed'] ?? 0,
        'referred': result.first['referred'] ?? 0,
      }, where: 'id = ?', whereArgs: [campaignId]);
    }
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
      {'referral_status': status},
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
    if (status != null) data['referral_status'] = status;
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

  Future<Map<String, int>> getOutcomeCounts() async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT outcome, COUNT(*) as count FROM screenings GROUP BY outcome',
    );
    final map = <String, int>{};
    for (final row in rows) {
      map[row['outcome'] as String] = (row['count'] as int?) ?? 0;
    }
    return map;
  }

  Future<Map<String, int>> getAgeGroupCounts() async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT
        CASE
          WHEN age BETWEEN 0 AND 17 THEN '0-17'
          WHEN age BETWEEN 18 AND 40 THEN '18-40'
          WHEN age BETWEEN 41 AND 60 THEN '41-60'
          ELSE '60+'
        END as age_group,
        COUNT(*) as count
      FROM patients
      GROUP BY age_group
    ''');
    final map = <String, int>{};
    for (final row in rows) {
      map[row['age_group'] as String] = (row['count'] as int?) ?? 0;
    }
    return map;
  }

  Future<Map<String, int>> getGenderCounts() async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT gender, COUNT(*) as count FROM patients GROUP BY gender',
    );
    final map = <String, int>{};
    for (final row in rows) {
      map[row['gender'] as String] = (row['count'] as int?) ?? 0;
    }
    return map;
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
