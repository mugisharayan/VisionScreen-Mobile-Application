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
      version: 1,
      onCreate: (db, _) async {
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
            created_at TEXT NOT NULL
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
            chw_name TEXT,
            synced INTEGER DEFAULT 0,
            FOREIGN KEY (patient_id) REFERENCES patients(id)
          )
        ''');
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
}
