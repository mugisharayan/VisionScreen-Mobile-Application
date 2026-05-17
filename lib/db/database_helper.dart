import 'dart:convert';

import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/app_constants.dart';
import '../utils/id_utils.dart';

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
      version: 6,
      onCreate: (db, _) async {
        await _createBaseTables(db);
        await _createSyncTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE screenings ADD COLUMN appointment_date TEXT',
          );
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
        if (oldVersion < 5) {
          await _createSyncTables(db);
          await _ensureColumn(
            db,
            'chw_profiles',
            'chw_id',
            "TEXT NOT NULL DEFAULT ''",
          );
          await _ensureColumn(
            db,
            'chw_profiles',
            'facility_id',
            "TEXT NOT NULL DEFAULT ''",
          );
          await _ensureColumn(
            db,
            'chw_profiles',
            'updated_at',
            "TEXT NOT NULL DEFAULT ''",
          );
          await _ensureColumn(db, 'chw_profiles', 'last_synced_at', 'TEXT');
          await _ensureColumn(
            db,
            'chw_profiles',
            'sync_state',
            "TEXT NOT NULL DEFAULT '${AppStrings.syncPendingUpsert}'",
          );
          await _ensureColumn(
            db,
            'chw_profiles',
            'version',
            'INTEGER NOT NULL DEFAULT 1',
          );

          await _ensureSyncColumns(db, 'campaigns', idColumn: 'id');
          await _ensureSyncColumns(db, 'patients', idColumn: 'id');
          await _ensureColumn(
            db,
            'screenings',
            'record_id',
            "TEXT NOT NULL DEFAULT ''",
          );
          await _ensureSyncColumns(db, 'screenings', idColumn: 'record_id');
          await _backfillScreeningRecordIds(db);
          await _backfillOwnership(db);
        }
        if (oldVersion < 6) {
          // Fix: empty-string deleted_at values cause WHERE deleted_at IS NULL
          // to exclude rows that should be visible. Normalise them to NULL.
          for (final table in const ['patients', 'campaigns', 'screenings']) {
            await db.execute(
              "UPDATE $table SET deleted_at = NULL WHERE deleted_at = ''",
            );
          }
        }
      },
    );
  }

  Future<void> _createBaseTables(Database db) async {
    await db.execute('''
      CREATE TABLE chw_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chw_id TEXT NOT NULL,
        facility_id TEXT NOT NULL,
        name TEXT NOT NULL,
        center TEXT NOT NULL,
        district TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'chw',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT,
        sync_state TEXT NOT NULL DEFAULT '${AppStrings.syncPendingUpsert}',
        version INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE campaigns (
        id TEXT PRIMARY KEY,
        facility_id TEXT NOT NULL,
        created_by TEXT NOT NULL,
        updated_by TEXT NOT NULL,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        target_group TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        last_synced_at TEXT,
        sync_state TEXT NOT NULL DEFAULT '${AppStrings.syncPendingUpsert}',
        version INTEGER NOT NULL DEFAULT 1,
        total INTEGER DEFAULT 0,
        passed INTEGER DEFAULT 0,
        referred INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        facility_id TEXT NOT NULL,
        created_by TEXT NOT NULL,
        updated_by TEXT NOT NULL,
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
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        last_synced_at TEXT,
        sync_state TEXT NOT NULL DEFAULT '${AppStrings.syncPendingUpsert}',
        version INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (campaign_id) REFERENCES campaigns(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE screenings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id TEXT NOT NULL UNIQUE,
        facility_id TEXT NOT NULL,
        created_by TEXT NOT NULL,
        updated_by TEXT NOT NULL,
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
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        last_synced_at TEXT,
        sync_state TEXT NOT NULL DEFAULT '${AppStrings.syncPendingUpsert}',
        version INTEGER NOT NULL DEFAULT 1,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');
  }

  Future<void> _createSyncTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workspace_facilities (
        id TEXT PRIMARY KEY,
        center TEXT NOT NULL,
        district TEXT NOT NULL,
        display_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS facility_memberships (
        id TEXT PRIMARY KEY,
        facility_id TEXT NOT NULL,
        user_email TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        synced_at TEXT
      )
    ''');
  }

  Future<void> _ensureSyncColumns(
    Database db,
    String table, {
    required String idColumn,
  }) async {
    await _ensureColumn(db, table, 'facility_id', "TEXT NOT NULL DEFAULT ''");
    await _ensureColumn(db, table, 'created_by', "TEXT NOT NULL DEFAULT ''");
    await _ensureColumn(db, table, 'updated_by', "TEXT NOT NULL DEFAULT ''");
    await _ensureColumn(db, table, 'updated_at', "TEXT NOT NULL DEFAULT ''");
    await _ensureColumn(db, table, 'deleted_at', 'TEXT');
    await _ensureColumn(db, table, 'last_synced_at', 'TEXT');
    await _ensureColumn(
      db,
      table,
      'sync_state',
      "TEXT NOT NULL DEFAULT '${AppStrings.syncPendingUpsert}'",
    );
    await _ensureColumn(db, table, 'version', 'INTEGER NOT NULL DEFAULT 1');
    if (idColumn == 'record_id') {
      final existing = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_screenings_record_id'",
      );
      if (existing.isEmpty) {
        await db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_screenings_record_id ON screenings(record_id)',
        );
      }
    }
  }

  Future<void> _ensureColumn(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final rows = await db.rawQuery("PRAGMA table_info($table)");
    final exists = rows.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _backfillScreeningRecordIds(Database db) async {
    final rows = await db.query('screenings', columns: ['id', 'record_id']);
    for (final row in rows) {
      final existing = (row['record_id'] as String?) ?? '';
      if (existing.isNotEmpty) continue;
      await db.update(
        'screenings',
        {'record_id': IdUtils.generate('screening')},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<void> _backfillOwnership(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(AppStrings.prefChwEmail) ?? '';
    final center = prefs.getString(AppStrings.prefChwCenter) ?? '';
    final district = prefs.getString(AppStrings.prefChwDistrict) ?? '';
    final facilityId =
        prefs.getString(AppStrings.prefFacilityId) ??
        IdUtils.facilityId(center: center, district: district);
    final now = DateTime.now().toUtc().toIso8601String();

    for (final table in const ['campaigns', 'patients', 'screenings']) {
      await db.update(table, {
        'facility_id': facilityId,
        'created_by': email,
        'updated_by': email,
        'updated_at': now,
        'sync_state': AppStrings.syncPendingUpsert,
      }, where: "facility_id = '' OR updated_at = ''");
    }
    await db.update('chw_profiles', {
      'facility_id': facilityId,
      'updated_at': now,
      'sync_state': AppStrings.syncPendingUpsert,
    }, where: "facility_id = '' OR updated_at = ''");
  }

  Future<({String email, String facilityId})> _currentActorContext() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(AppStrings.prefChwEmail) ?? '';
    final facilityId = prefs.getString(AppStrings.prefFacilityId) ?? '';
    return (email: email, facilityId: facilityId);
  }

  String _isoNow() => DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> _decorateSyncableRow(
    Map<String, dynamic> row, {
    required String facilityId,
    required String actorEmail,
    required String createdAtFallback,
  }) {
    final createdAt = (row['created_at'] as String?)?.isNotEmpty == true
        ? row['created_at'] as String
        : createdAtFallback;
    final updatedAt = (row['updated_at'] as String?)?.isNotEmpty == true
        ? row['updated_at'] as String
        : createdAtFallback;

    return {
      ...row,
      'facility_id': (row['facility_id'] as String?)?.isNotEmpty == true
          ? row['facility_id']
          : facilityId,
      'created_by': (row['created_by'] as String?)?.isNotEmpty == true
          ? row['created_by']
          : actorEmail,
      'updated_by': actorEmail,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': row['deleted_at'],
      'last_synced_at': row['last_synced_at'],
      'sync_state': AppStrings.syncPendingUpsert,
      'version': (row['version'] as int?) ?? 1,
    };
  }

  Future<void> _queueOperation(
    DatabaseExecutor database, {
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await database.insert('sync_queue', {
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'created_at': _isoNow(),
      'attempts': 0,
      'last_error': null,
      'synced_at': null,
    });
  }

  // ── PATIENTS ──────────────────────────────────────────────

  Future<void> insertPatient(Map<String, dynamic> patient) async {
    final database = await db;
    final ctx = await _currentActorContext();
    final now = _isoNow();
    final row = _decorateSyncableRow(
      patient,
      facilityId: ctx.facilityId,
      actorEmail: ctx.email,
      createdAtFallback: now,
    );
    await database.insert(
      'patients',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _queueOperation(
      database,
      entityType: AppStrings.entityPatient,
      entityId: row['id'] as String,
      operation: AppStrings.syncPendingUpsert,
      payload: row,
    );
    final campaignId = row['campaign_id'] as String?;
    if (campaignId != null && campaignId.isNotEmpty) {
      await updateCampaignStats(campaignId);
    }
  }

  Future<void> deletePatient(String patientId) async {
    final database = await db;
    final patient = await getPatient(patientId);
    if (patient == null) return;
    final campaignId = patient['campaign_id'] as String?;
    final screenings = await getScreeningsForPatient(patientId);
    for (final screening in screenings) {
      await _queueOperation(
        database,
        entityType: AppStrings.entityScreening,
        entityId:
            screening['record_id'] as String? ??
            IdUtils.generate('screening-delete'),
        operation: AppStrings.syncPendingDelete,
        payload: {
          'record_id': screening['record_id'],
          'facility_id': screening['facility_id'],
          'updated_at': _isoNow(),
          'deleted_at': _isoNow(),
        },
      );
    }
    await _queueOperation(
      database,
      entityType: AppStrings.entityPatient,
      entityId: patientId,
      operation: AppStrings.syncPendingDelete,
      payload: {
        'id': patientId,
        'facility_id': patient['facility_id'],
        'updated_at': _isoNow(),
        'deleted_at': _isoNow(),
      },
    );
    await database.delete(
      'screenings',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
    await database.delete('patients', where: 'id = ?', whereArgs: [patientId]);
    if (campaignId != null && campaignId.isNotEmpty) {
      await updateCampaignStats(campaignId);
    }
  }

  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final database = await db;
    return database.rawQuery(
      "SELECT * FROM patients WHERE (deleted_at IS NULL OR deleted_at = '') ORDER BY created_at DESC",
    );
  }

  Future<Map<String, dynamic>?> getPatient(String id) async {
    final database = await db;
    final rows = await database.rawQuery(
      "SELECT * FROM patients WHERE id = ? AND (deleted_at IS NULL OR deleted_at = '') LIMIT 1",
      [id],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<bool> hasWorkspaceData() async {
    final database = await db;
    const tables = <String>[
      'campaigns',
      'patients',
      'screenings',
      'workspace_facilities',
      'facility_memberships',
    ];
    for (final table in tables) {
      final rows = await database.query(table, limit: 1);
      if (rows.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    final database = await db;
    final q = '%${query.toLowerCase()}%';
    return database.rawQuery(
      "SELECT * FROM patients WHERE (deleted_at IS NULL OR deleted_at = '') AND (LOWER(name) LIKE ? OR LOWER(id) LIKE ? OR LOWER(village) LIKE ?) ORDER BY created_at DESC",
      [q, q, q],
    );
  }

  // ── CAMPAIGNS ─────────────────────────────────────────────

  Future<String> insertCampaign(Map<String, dynamic> campaign) async {
    final database = await db;
    final ctx = await _currentActorContext();
    final now = _isoNow();
    final row = _decorateSyncableRow(
      campaign,
      facilityId: ctx.facilityId,
      actorEmail: ctx.email,
      createdAtFallback: now,
    );
    await database.insert(
      'campaigns',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _queueOperation(
      database,
      entityType: AppStrings.entityCampaign,
      entityId: row['id'] as String,
      operation: AppStrings.syncPendingUpsert,
      payload: row,
    );
    return row['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAllCampaigns() async {
    final database = await db;
    return database.rawQuery(
      "SELECT * FROM campaigns WHERE (deleted_at IS NULL OR deleted_at = '') ORDER BY created_at DESC",
    );
  }

  Future<Map<String, dynamic>?> getCampaign(String id) async {
    final database = await db;
    final rows = await database.rawQuery(
      "SELECT * FROM campaigns WHERE id = ? AND (deleted_at IS NULL OR deleted_at = '') LIMIT 1",
      [id],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> updateCampaignStats(
    String campaignId, {
    bool queueSync = true,
  }) async {
    final database = await db;
    // Count distinct patients, and their latest screening outcome
    final result = await database.rawQuery(
      '''
      SELECT
        COUNT(DISTINCT p.id) AS total,
        SUM(CASE WHEN latest.outcome = 'pass'  THEN 1 ELSE 0 END) AS passed,
        SUM(CASE WHEN latest.outcome = 'refer' THEN 1 ELSE 0 END) AS referred
      FROM patients p
      LEFT JOIN (
        SELECT patient_id, outcome
        FROM screenings
        WHERE id IN (
          SELECT MAX(id)
          FROM screenings
          WHERE deleted_at IS NULL
          GROUP BY patient_id
        )
      ) latest ON latest.patient_id = p.id
      WHERE p.campaign_id = ?
        AND p.deleted_at IS NULL
    ''',
      [campaignId],
    );
    if (result.isNotEmpty) {
      final current = await getCampaign(campaignId);
      if (current == null) {
        return;
      }

      final total = (result.first['total'] as int?) ?? 0;
      final passed = (result.first['passed'] as num?)?.toInt() ?? 0;
      final referred = (result.first['referred'] as num?)?.toInt() ?? 0;
      final currentTotal = (current['total'] as int?) ?? 0;
      final currentPassed = (current['passed'] as int?) ?? 0;
      final currentReferred = (current['referred'] as int?) ?? 0;
      if (currentTotal == total &&
          currentPassed == passed &&
          currentReferred == referred) {
        return;
      }

      final data = <String, dynamic>{
        'total': total,
        'passed': passed,
        'referred': referred,
      };
      if (queueSync) {
        final ctx = await _currentActorContext();
        final now = _isoNow();
        final nextVersion = ((current['version'] as int?) ?? 0) + 1;
        data.addAll({
          'updated_at': now,
          'updated_by': ctx.email,
          'sync_state': AppStrings.syncPendingUpsert,
          'version': nextVersion,
        });
      }

      await database.update(
        'campaigns',
        data,
        where: 'id = ?',
        whereArgs: [campaignId],
      );

      if (queueSync) {
        final updated = await getCampaign(campaignId);
        if (updated != null) {
          await _queueOperation(
            database,
            entityType: AppStrings.entityCampaign,
            entityId: campaignId,
            operation: AppStrings.syncPendingUpsert,
            payload: updated,
          );
        }
      }
    }
  }

  Future<void> deleteCampaign(String campaignId) async {
    final database = await db;
    final campaign = await getCampaign(campaignId);
    if (campaign == null) return;
    final patients = await database.query(
      'patients',
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
    );
    for (final p in patients) {
      final patientId = p['id'] as String;
      final screenings = await getScreeningsForPatient(patientId);
      for (final screening in screenings) {
        await _queueOperation(
          database,
          entityType: AppStrings.entityScreening,
          entityId: screening['record_id'] as String,
          operation: AppStrings.syncPendingDelete,
          payload: {
            'record_id': screening['record_id'],
            'facility_id': screening['facility_id'],
            'updated_at': _isoNow(),
            'deleted_at': _isoNow(),
          },
        );
      }
      await _queueOperation(
        database,
        entityType: AppStrings.entityPatient,
        entityId: patientId,
        operation: AppStrings.syncPendingDelete,
        payload: {
          'id': patientId,
          'facility_id': p['facility_id'],
          'updated_at': _isoNow(),
          'deleted_at': _isoNow(),
        },
      );
      await database.delete(
        'screenings',
        where: 'patient_id = ?',
        whereArgs: [patientId],
      );
    }
    await database.delete(
      'patients',
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
    );
    await _queueOperation(
      database,
      entityType: AppStrings.entityCampaign,
      entityId: campaignId,
      operation: AppStrings.syncPendingDelete,
      payload: {
        'id': campaignId,
        'facility_id': campaign['facility_id'],
        'updated_at': _isoNow(),
        'deleted_at': _isoNow(),
      },
    );
    await database.delete(
      'campaigns',
      where: 'id = ?',
      whereArgs: [campaignId],
    );
  }

  Future<List<Map<String, dynamic>>> getPatientsForCampaign(
    String campaignId,
  ) async {
    final database = await db;
    return database.rawQuery(
      '''
      SELECT p.*, s.outcome, s.od_snellen, s.os_snellen, s.ou_near_snellen,
             s.referral_facility, s.referral_status, s.screening_date
      FROM patients p
      LEFT JOIN screenings s ON s.id = (
        SELECT id FROM screenings WHERE patient_id = p.id AND deleted_at IS NULL ORDER BY screening_date DESC LIMIT 1
      )
      WHERE p.campaign_id = ? AND p.deleted_at IS NULL
      ORDER BY p.created_at ASC
    ''',
      [campaignId],
    );
  }

  // ── SCREENINGS ────────────────────────────────────────────

  Future<int> insertScreening(Map<String, dynamic> screening) async {
    final database = await db;
    final ctx = await _currentActorContext();
    final now = _isoNow();
    final row = _decorateSyncableRow(
      {
        ...screening,
        'record_id': (screening['record_id'] as String?)?.isNotEmpty == true
            ? screening['record_id']
            : IdUtils.generate('screening'),
        'synced': 0,
      },
      facilityId: ctx.facilityId,
      actorEmail: ctx.email,
      createdAtFallback: now,
    );
    final id = await database.insert('screenings', row);
    await _queueOperation(
      database,
      entityType: AppStrings.entityScreening,
      entityId: row['record_id'] as String,
      operation: AppStrings.syncPendingUpsert,
      payload: row,
    );
    final patient = await getPatient(row['patient_id'] as String);
    final campaignId = patient?['campaign_id'] as String?;
    if (campaignId != null && campaignId.isNotEmpty) {
      await updateCampaignStats(campaignId);
    }
    return id;
  }

  Future<List<Map<String, dynamic>>> getScreeningsForPatient(
    String patientId,
  ) async {
    final database = await db;
    return database.query(
      'screenings',
      where: 'patient_id = ? AND deleted_at IS NULL',
      whereArgs: [patientId],
      orderBy: 'screening_date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllScreenings() async {
    final database = await db;
    return database.query(
      'screenings',
      where: 'deleted_at IS NULL',
      orderBy: 'screening_date DESC',
    );
  }

  Future<Map<String, dynamic>?> getLatestScreening(String patientId) async {
    final database = await db;
    final rows = await database.query(
      'screenings',
      where: 'patient_id = ? AND deleted_at IS NULL',
      whereArgs: [patientId],
      orderBy: 'screening_date DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> updateReferralStatus(int screeningId, String status) async {
    final database = await db;
    final ctx = await _currentActorContext();
    final current = await database.query(
      'screenings',
      where: 'id = ?',
      whereArgs: [screeningId],
      limit: 1,
    );
    if (current.isEmpty) return;
    final row = current.first;
    await database.update(
      'screenings',
      {
        'referral_status': status.toLowerCase().trim(),
        'updated_at': _isoNow(),
        'updated_by': ctx.email,
        'sync_state': AppStrings.syncPendingUpsert,
        'version': ((row['version'] as int?) ?? 0) + 1,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [screeningId],
    );
    final updated = await database.query(
      'screenings',
      where: 'id = ?',
      whereArgs: [screeningId],
      limit: 1,
    );
    if (updated.isNotEmpty) {
      await _queueOperation(
        database,
        entityType: AppStrings.entityScreening,
        entityId: updated.first['record_id'] as String,
        operation: AppStrings.syncPendingUpsert,
        payload: updated.first,
      );
    }
  }

  Future<void> updateReferralDetails(
    int screeningId, {
    String? facility,
    String? appointmentDate,
    String? status,
  }) async {
    final database = await db;
    final ctx = await _currentActorContext();
    final current = await database.query(
      'screenings',
      where: 'id = ?',
      whereArgs: [screeningId],
      limit: 1,
    );
    if (current.isEmpty) return;
    final row = current.first;
    final data = <String, dynamic>{};
    if (facility != null) data['referral_facility'] = facility;
    if (appointmentDate != null) data['appointment_date'] = appointmentDate;
    if (status != null) data['referral_status'] = status.toLowerCase().trim();
    if (data.isEmpty) return;
    data['updated_at'] = _isoNow();
    data['updated_by'] = ctx.email;
    data['sync_state'] = AppStrings.syncPendingUpsert;
    data['version'] = ((row['version'] as int?) ?? 0) + 1;
    data['synced'] = 0;
    await database.update(
      'screenings',
      data,
      where: 'id = ?',
      whereArgs: [screeningId],
    );
    final updated = await database.query(
      'screenings',
      where: 'id = ?',
      whereArgs: [screeningId],
      limit: 1,
    );
    if (updated.isNotEmpty) {
      await _queueOperation(
        database,
        entityType: AppStrings.entityScreening,
        entityId: updated.first['record_id'] as String,
        operation: AppStrings.syncPendingUpsert,
        payload: updated.first,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getReferredPatients() async {
    final database = await db;
    return database.rawQuery('''
      SELECT s.id as screening_id, s.patient_id, s.od_snellen, s.os_snellen,
             s.referral_facility, s.referral_status, s.appointment_date,
             p.name, p.age, p.gender, p.photo_path
      FROM screenings s
      JOIN patients p ON s.patient_id = p.id
      WHERE s.outcome = 'refer' AND s.deleted_at IS NULL
      ORDER BY s.appointment_date ASC
    ''');
  }

  /// Patients registered but not yet screened (no row in screenings table)
  Future<int> getPendingCount() async {
    final database = await db;
    final result = await database.rawQuery('''
      SELECT COUNT(*) as count FROM patients p
      WHERE NOT EXISTS (
        SELECT 1 FROM screenings s WHERE s.patient_id = p.id AND s.deleted_at IS NULL
      )
      AND p.deleted_at IS NULL
    ''');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getUnsyncedCount() async {
    final database = await db;
    final result = await database.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE synced_at IS NULL",
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> markSynced(int screeningId) async {
    final database = await db;
    await database.update(
      'screenings',
      {
        'synced': 1,
        'sync_state': AppStrings.syncSynced,
        'last_synced_at': _isoNow(),
      },
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
        groupExpr = "strftime('%H:00', screening_date)";
        whereClause = "DATE(screening_date) = DATE('now')";
        break;
      case 'Month':
        groupExpr = "DATE(screening_date)";
        whereClause = "screening_date >= DATE('now', '-29 days')";
        break;
      case 'Year':
        groupExpr = "strftime('%Y-%m', screening_date)";
        whereClause = "screening_date >= DATE('now', '-364 days')";
        break;
      default: // Week
        groupExpr = "DATE(screening_date)";
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
        .map(
          (r) => {
            'label': r['label'] as String? ?? '',
            'pass_count': (r['pass_count'] as num?)?.toInt() ?? 0,
            'refer_count': (r['refer_count'] as num?)?.toInt() ?? 0,
          },
        )
        .toList();

    // Append a period-total summary so the chart headline shows
    // the overall rate for the whole period, not just the last bucket.
    final totalPass = points.fold(0, (s, r) => s + (r['pass_count'] as int));
    final totalRefer = points.fold(0, (s, r) => s + (r['refer_count'] as int));
    points.add({
      'label': '__total__',
      'pass_count': totalPass,
      'refer_count': totalRefer,
    });
    return points;
  }

  /// Buckets worst-eye Snellen per patient into 5 acuity levels.
  Future<Map<String, int>> getVisualAcuityDistribution({
    String period = 'All',
  }) async {
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
      'Normal': 0,
      'Near Normal': 0,
      'Moderate': 0,
      'Severe': 0,
      'Blind Range': 0,
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
            "SELECT conditions FROM patients WHERE conditions IS NOT NULL AND conditions != ''",
          )
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
  Future<Map<String, int>> getSeverityClassification({
    String period = 'All',
  }) async {
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
      'Normal': 0,
      'Mild': 0,
      'Moderate': 0,
      'Severe': 0,
      'Critical': 0,
    };

    for (final row in rows) {
      final odLogmar = double.tryParse((row['od_logmar'] as String?) ?? '');
      final osLogmar = double.tryParse((row['os_logmar'] as String?) ?? '');
      final odCantTell = (row['od_cant_tell'] as int?) ?? 0;
      final osCantTell = (row['os_cant_tell'] as int?) ?? 0;

      // Both eyes unable to assess
      if (odLogmar == null && osLogmar == null) {
        if (odCantTell > 0 || osCantTell > 0) {
          counts['Critical'] = counts['Critical']! + 1;
        }
        // No data at all — skip
        continue;
      }

      // Use the worse (higher logMAR) of the two recorded eyes
      final worst = [
        odLogmar,
        osLogmar,
      ].whereType<double>().fold<double>(-1, (m, v) => v > m ? v : m);

      if (worst <= 0.3) {
        counts['Normal'] = counts['Normal']! + 1;
      } else if (worst <= 0.5) {
        counts['Mild'] = counts['Mild']! + 1;
      } else if (worst <= 1.0) {
        counts['Moderate'] = counts['Moderate']! + 1;
      } else if (worst <= 2.0) {
        counts['Severe'] = counts['Severe']! + 1;
      } else {
        counts['Critical'] = counts['Critical']! + 1;
      }
    }
    return counts;
  }

  /// Referral status breakdown for all referred screenings.
  Future<Map<String, int>> getReferralStatusCounts({
    String period = 'All',
  }) async {
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
  Future<Map<String, int>> getFollowUpCompliance({
    String period = 'All',
  }) async {
    final statuses = await getReferralStatusCounts(period: period);
    return {
      'Attended': statuses['completed'] ?? 0,
      'Rescheduled': statuses['rescheduled'] ?? 0,
      'Pending': (statuses['pending'] ?? 0) + (statuses['notified'] ?? 0),
      'Missed': statuses['overdue'] ?? 0,
    };
  }

  /// Conditions broken down by age group.
  Future<Map<String, Map<String, int>>> getConditionsByAgeGroup({
    String period = 'All',
  }) async {
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
      final raw = row['conditions'] as String? ?? '';
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
  Future<List<Map<String, dynamic>>> getVillageBreakdown({
    String period = 'All',
  }) async {
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
      sql =
          '''
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
        .map(
          (r) => {
            'village': r['village'] as String? ?? 'Unknown',
            'total': (r['total'] as int?) ?? 0,
            'referred': (r['referred'] as num?)?.toInt() ?? 0,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRecentScreeningsWithPatient({
    int limit = 10,
  }) async {
    final database = await db;
    return database.rawQuery(
      '''
      SELECT s.*, p.name, p.age, p.gender, p.village, p.photo_path, p.conditions
      FROM screenings s
      JOIN patients p ON s.patient_id = p.id
      WHERE s.deleted_at IS NULL AND p.deleted_at IS NULL
      ORDER BY s.screening_date DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────

  // ── CHW PROFILES ──────────────────────────────────────────

  Future<void> insertChwProfile(Map<String, dynamic> profile) async {
    final database = await db;
    final now = _isoNow();
    final facilityId = (profile['facility_id'] as String?)?.isNotEmpty == true
        ? profile['facility_id'] as String
        : IdUtils.facilityId(
            center: profile['center'] as String? ?? '',
            district: profile['district'] as String? ?? '',
          );
    final row = {
      ...profile,
      'chw_id': (profile['chw_id'] as String?)?.isNotEmpty == true
          ? profile['chw_id']
          : IdUtils.generate('chw'),
      'facility_id': facilityId,
      'created_at': (profile['created_at'] as String?)?.isNotEmpty == true
          ? profile['created_at']
          : now,
      'updated_at': now,
      'last_synced_at': profile['last_synced_at'],
      'sync_state': profile['sync_state'] ?? AppStrings.syncPendingUpsert,
      'version': (profile['version'] as int?) ?? 1,
    };
    await database.insert(
      'chw_profiles',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _queueOperation(
      database,
      entityType: AppStrings.entityChwProfile,
      entityId: row['email'] as String,
      operation: AppStrings.syncPendingUpsert,
      payload: row,
    );
  }

  Future<void> cacheSyncedChwProfile(Map<String, dynamic> profile) async {
    final database = await db;
    final row = Map<String, dynamic>.from(profile)
      ..remove('remote_id')
      ..['last_synced_at'] = profile['last_synced_at'] ?? _isoNow()
      ..['sync_state'] = AppStrings.syncSynced;
    await database.insert(
      'chw_profiles',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  Future<void> updateChwProfile(
    String email,
    Map<String, dynamic> updates,
  ) async {
    final database = await db;
    final normalised = email.trim().toLowerCase();
    final existing = await getChwProfileByEmail(normalised);
    if (existing == null) return;

    final ctx = await _currentActorContext();
    final center =
        (updates['center'] as String?)?.trim() ??
        existing['center'] as String? ??
        '';
    final district =
        (updates['district'] as String?)?.trim() ??
        existing['district'] as String? ??
        '';
    final nextVersion = ((existing['version'] as int?) ?? 0) + 1;
    final data = <String, dynamic>{
      ...updates,
      'center': center,
      'district': district,
      'facility_id': IdUtils.facilityId(center: center, district: district),
      'updated_at': _isoNow(),
      'updated_by': ctx.email,
      'sync_state': AppStrings.syncPendingUpsert,
      'version': nextVersion,
    };

    await database.update(
      'chw_profiles',
      data,
      where: 'email = ?',
      whereArgs: [normalised],
    );

    final updated = await getChwProfileByEmail(normalised);
    if (updated != null) {
      await _queueOperation(
        database,
        entityType: AppStrings.entityChwProfile,
        entityId: updated['email'] as String,
        operation: AppStrings.syncPendingUpsert,
        payload: updated,
      );
    }
  }

  Future<void> updateChwPassword(String email, String newHashedPassword) async {
    final database = await db;
    final existing = await getChwProfileByEmail(email);
    final nextVersion = ((existing?['version'] as int?) ?? 0) + 1;
    final ctx = await _currentActorContext();
    await database.update(
      'chw_profiles',
      {
        'password': newHashedPassword,
        'updated_at': _isoNow(),
        'updated_by': ctx.email,
        'sync_state': AppStrings.syncPendingUpsert,
        'version': nextVersion,
      },
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    final updated = await getChwProfileByEmail(email);
    if (updated != null) {
      await _queueOperation(
        database,
        entityType: AppStrings.entityChwProfile,
        entityId: updated['email'] as String,
        operation: AppStrings.syncPendingUpsert,
        payload: updated,
      );
    }
  }

  Future<void> clearRestorableData({DatabaseExecutor? database}) async {
    final target = database ?? await db;
    await target.delete('sync_queue');
    await target.delete('screenings');
    await target.delete('patients');
    await target.delete('campaigns');
    await target.delete('facility_memberships');
    await target.delete('workspace_facilities');
    await target.delete('chw_profiles');
  }

  Future<void> clearWorkspaceData({DatabaseExecutor? database}) async {
    final target = database ?? await db;
    await target.delete('sync_queue');
    await target.delete('screenings');
    await target.delete('patients');
    await target.delete('campaigns');
    await target.delete('facility_memberships');
    await target.delete('workspace_facilities');
  }

  Future<void> upsertWorkspaceFacility(Map<String, dynamic> facility) async {
    final database = await db;
    await database.insert('workspace_facilities', {
      'id': facility['id'],
      'center': facility['center'],
      'district': facility['district'],
      'display_name': facility['display_name'],
      'created_at': facility['created_at'],
      'updated_at': facility['updated_at'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertFacilityMembership(Map<String, dynamic> membership) async {
    final database = await db;
    await database.insert('facility_memberships', {
      'id': membership['id'],
      'facility_id': membership['facility_id'],
      'user_email': membership['user_email'],
      'role': membership['role'],
      'created_at': membership['created_at'],
      'updated_at': membership['updated_at'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingSyncOperations({
    int limit = 100,
  }) async {
    final database = await db;
    return database.query(
      'sync_queue',
      where: 'synced_at IS NULL',
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  Future<void> markSyncOperationSucceeded(
    int queueId, {
    required String entityType,
    required String entityId,
    String? screeningRecordId,
  }) async {
    final database = await db;
    final syncedAt = _isoNow();
    await database.update(
      'sync_queue',
      {'synced_at': syncedAt, 'last_error': null},
      where: 'id = ?',
      whereArgs: [queueId],
    );
    await _markEntitySynced(
      database,
      entityType: entityType,
      entityId: entityId,
      screeningRecordId: screeningRecordId,
      syncedAt: syncedAt,
    );
  }

  Future<void> markSyncOperationFailed(int queueId, String error) async {
    final database = await db;
    await database.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      [error, queueId],
    );
  }

  Future<void> markEntitySyncedFromRemote(
    String entityType,
    String entityId, {
    String? screeningRecordId,
  }) async {
    final database = await db;
    await _markEntitySynced(
      database,
      entityType: entityType,
      entityId: entityId,
      screeningRecordId: screeningRecordId,
      syncedAt: _isoNow(),
    );
  }

  Future<void> _markEntitySynced(
    DatabaseExecutor database, {
    required String entityType,
    required String entityId,
    required String syncedAt,
    String? screeningRecordId,
  }) async {
    switch (entityType) {
      case AppStrings.entityPatient:
        await database.update(
          'patients',
          {'sync_state': AppStrings.syncSynced, 'last_synced_at': syncedAt},
          where: 'id = ?',
          whereArgs: [entityId],
        );
        break;
      case AppStrings.entityCampaign:
        await database.update(
          'campaigns',
          {'sync_state': AppStrings.syncSynced, 'last_synced_at': syncedAt},
          where: 'id = ?',
          whereArgs: [entityId],
        );
        break;
      case AppStrings.entityScreening:
        await database.update(
          'screenings',
          {
            'sync_state': AppStrings.syncSynced,
            'last_synced_at': syncedAt,
            'synced': 1,
          },
          where: 'record_id = ?',
          whereArgs: [screeningRecordId ?? entityId],
        );
        break;
      case AppStrings.entityChwProfile:
        await database.update(
          'chw_profiles',
          {'sync_state': AppStrings.syncSynced, 'last_synced_at': syncedAt},
          where: 'email = ?',
          whereArgs: [entityId],
        );
        break;
    }
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
        'id': 'overdue_${r['id']}',
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
        'id': 'upcoming_${r['id']}',
        'icon': 'reminder',
        'color': 0xFF8B5CF6,
        'title': 'Appointment Reminder',
        'body':
            '${r['name']} — ${r['referral_facility']} on ${r['appointment_date']}.',
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
        'id': 'screening_${r['id']}',
        'icon': passed ? 'check' : 'assignment',
        'color': passed ? 0xFF22C55E : 0xFFF59E0B,
        'title': passed ? 'Screening Passed' : 'Referral Generated',
        'body': passed
            ? '${r['name']} passed. OD ${r['od_snellen']}, OS ${r['os_snellen']}.'
            : 'Referral created for ${r['name']}.',
        'time': r['screening_date'],
        'read': false,
        'tag': passed ? 'RESULT' : 'REFERRAL',
      });
    }

    // 4. Unsynced records
    final unsynced = await getUnsyncedCount();
    if (unsynced > 0) {
      notifications.add({
        'id': 'sync_pending',
        'icon': 'sync',
        'color': 0xFF38BDF8,
        'title': 'Sync Pending',
        'body': '$unsynced record${unsynced == 1 ? '' : 's'} waiting to sync.',
        'time': DateTime.now().toIso8601String(),
        'read': false,
        'tag': 'SYNC',
      });
    }

    return notifications;
  }
}
