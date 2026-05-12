import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../db/database_helper.dart';
import '../../utils/app_constants.dart';
import '../../utils/id_utils.dart';
import '../backup_service.dart';
import 'mongo_workspace_remote.dart';

class SyncResult {
  const SyncResult({
    required this.success,
    required this.appliedChanges,
    this.errorMessage,
    this.restoredRecords = 0,
  });

  final bool success;
  final int appliedChanges;
  final int restoredRecords;
  final String? errorMessage;
}

class BackupResult {
  const BackupResult({
    required this.success,
    required this.rowsCaptured,
    this.backupId,
    this.createdAt,
    this.errorMessage,
  });

  final bool success;
  final int rowsCaptured;
  final String? backupId;
  final String? createdAt;
  final String? errorMessage;
}

class RestoreBackupResult {
  const RestoreBackupResult({
    required this.success,
    required this.rowsRestored,
    required this.tablesRestored,
    this.backupId,
    this.createdAt,
    this.errorMessage,
  });

  final bool success;
  final int rowsRestored;
  final int tablesRestored;
  final String? backupId;
  final String? createdAt;
  final String? errorMessage;
}

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final MongoWorkspaceRemote _remote = MongoWorkspaceRemote.instance;
  final BackupService _backup = BackupService.instance;

  bool get isConfigured => _remote.isConfigured;

  Future<void> mirrorProfile(Map<String, dynamic> profile) async {
    if (!isConfigured) {
      return;
    }
    await _remote.ensureConnected();

    final facility = _facilityFromProfile(profile);
    final membership = _membershipFromProfile(
      profile,
      facilityId: facility['id'] as String,
    );

    await _remote.upsertFacility(facility);
    await _remote.upsertMembership(membership);
    await _remote.upsertUser(profile);

    await _db.upsertWorkspaceFacility(facility);
    await _db.upsertFacilityMembership(membership);
  }

  Future<Map<String, dynamic>?> fetchRemoteProfile(String email) async {
    if (!isConfigured) {
      return null;
    }
    await _remote.ensureConnected();
    return _remote.fetchUserByEmail(email);
  }

  Future<SyncResult> syncNow() async {
    if (!isConfigured) {
      return const SyncResult(
        success: false,
        appliedChanges: 0,
        errorMessage: 'Cloud workspace is not configured.',
      );
    }

    await _remote.ensureConnected();
    final prefs = await SharedPreferences.getInstance();
    final facilityId = prefs.getString(AppStrings.prefFacilityId) ?? '';
    if (facilityId.isEmpty) {
      return const SyncResult(
        success: false,
        appliedChanges: 0,
        errorMessage: 'Missing facility context for sync.',
      );
    }

    var applied = 0;
    try {
      final operations = await _db.getPendingSyncOperations();
      for (final op in operations) {
        try {
          final payload =
              jsonDecode(op['payload'] as String) as Map<String, dynamic>;
          final result = await _remote.pushQueuedChange(
            entityType: op['entity_type'] as String,
            entityId: op['entity_id'] as String,
            operation: op['operation'] as String,
            payload: payload,
          );
          if (result['conflict'] == true) {
            final remoteDoc = result['remote'] as Map<String, dynamic>?;
            if (remoteDoc != null) {
              await _applyRemoteRecord(op['entity_type'] as String, remoteDoc);
            }
            await _db.markSyncOperationSucceeded(
              op['id'] as int,
              entityType: op['entity_type'] as String,
              entityId: op['entity_id'] as String,
              screeningRecordId: payload['record_id'] as String?,
            );
            continue;
          }

          await _db.markSyncOperationSucceeded(
            op['id'] as int,
            entityType: op['entity_type'] as String,
            entityId: op['entity_id'] as String,
            screeningRecordId: payload['record_id'] as String?,
          );
          applied++;
        } catch (error) {
          await _db.markSyncOperationFailed(op['id'] as int, error.toString());
          rethrow;
        }
      }

      final workspace = await _remote.fetchWorkspaceData(
        facilityId: facilityId,
      );
      var restored = 0;
      for (final entry in workspace.entries) {
        switch (entry.key) {
          case 'facilities':
            for (final facility in entry.value) {
              await _db.upsertWorkspaceFacility(facility);
              restored++;
            }
            break;
          case 'memberships':
            for (final membership in entry.value) {
              await _db.upsertFacilityMembership(membership);
              restored++;
            }
            break;
          case 'patients':
            for (final record in entry.value) {
              await _applyRemoteRecord(AppStrings.entityPatient, record);
              restored++;
            }
            break;
          case 'campaigns':
            for (final record in entry.value) {
              await _applyRemoteRecord(AppStrings.entityCampaign, record);
              restored++;
            }
            break;
          case 'screenings':
            for (final record in entry.value) {
              await _applyRemoteRecord(AppStrings.entityScreening, record);
              restored++;
            }
            break;
        }
      }

      await prefs.setString(
        AppStrings.prefLastSyncAt,
        DateTime.now().toUtc().toIso8601String(),
      );
      await prefs.remove(AppStrings.prefLastSyncError);

      return SyncResult(
        success: true,
        appliedChanges: applied,
        restoredRecords: restored,
      );
    } catch (error) {
      await prefs.setString(AppStrings.prefLastSyncError, error.toString());
      return SyncResult(
        success: false,
        appliedChanges: applied,
        errorMessage: error.toString(),
      );
    }
  }

  Future<BackupResult> createBackup() async {
    if (!isConfigured) {
      return const BackupResult(
        success: false,
        rowsCaptured: 0,
        errorMessage: 'Cloud workspace is not configured.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final facilityId = prefs.getString(AppStrings.prefFacilityId) ?? '';
    final email = prefs.getString(AppStrings.prefChwEmail) ?? '';
    if (facilityId.isEmpty || email.isEmpty) {
      return const BackupResult(
        success: false,
        rowsCaptured: 0,
        errorMessage: 'Missing account context for backup.',
      );
    }

    try {
      await _remote.ensureConnected();
      final snapshot = await _backup.createWorkspaceSnapshot();
      final saved = await _remote.saveWorkspaceBackup(
        facilityId: facilityId,
        createdBy: email,
        snapshot: snapshot.toMap(),
      );
      final createdAt = saved['created_at'] as String? ?? snapshot.createdAt;
      final backupId =
          saved['remote_id'] as String? ?? saved['id'] as String? ?? '';
      await prefs.setString(AppStrings.prefLastBackupId, backupId);
      await prefs.setString(AppStrings.prefLastBackupAt, createdAt);
      return BackupResult(
        success: true,
        rowsCaptured: snapshot.totalRows,
        backupId: backupId,
        createdAt: createdAt,
      );
    } catch (error) {
      return BackupResult(
        success: false,
        rowsCaptured: 0,
        errorMessage: error.toString(),
      );
    }
  }

  Future<RestoreBackupResult> restoreLatestBackup() async {
    if (!isConfigured) {
      return const RestoreBackupResult(
        success: false,
        rowsRestored: 0,
        tablesRestored: 0,
        errorMessage: 'Cloud workspace is not configured.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final facilityId = prefs.getString(AppStrings.prefFacilityId) ?? '';
    if (facilityId.isEmpty) {
      return const RestoreBackupResult(
        success: false,
        rowsRestored: 0,
        tablesRestored: 0,
        errorMessage: 'Missing facility context for restore.',
      );
    }

    try {
      await _remote.ensureConnected();
      final backup = await _remote.fetchLatestWorkspaceBackup(
        facilityId: facilityId,
      );
      if (backup == null) {
        return const RestoreBackupResult(
          success: false,
          rowsRestored: 0,
          tablesRestored: 0,
          errorMessage: 'No cloud backup is available for this facility yet.',
        );
      }

      final summary = await _backup.restoreWorkspaceSnapshot(backup);
      final createdAt = backup['created_at'] as String? ?? '';
      final backupId =
          backup['remote_id'] as String? ?? backup['id'] as String? ?? '';
      await prefs.setString(AppStrings.prefLastBackupId, backupId);
      await prefs.setString(AppStrings.prefLastBackupAt, createdAt);

      return RestoreBackupResult(
        success: true,
        rowsRestored: summary.rowsRestored,
        tablesRestored: summary.tablesRestored,
        backupId: backupId,
        createdAt: createdAt,
      );
    } catch (error) {
      return RestoreBackupResult(
        success: false,
        rowsRestored: 0,
        tablesRestored: 0,
        errorMessage: error.toString(),
      );
    }
  }

  Map<String, dynamic> _facilityFromProfile(Map<String, dynamic> profile) {
    final now = DateTime.now().toUtc().toIso8601String();
    final center = profile['center'] as String? ?? '';
    final district = profile['district'] as String? ?? '';
    final facilityId = (profile['facility_id'] as String?)?.isNotEmpty == true
        ? profile['facility_id'] as String
        : IdUtils.facilityId(center: center, district: district);
    return {
      'id': facilityId,
      'center': center,
      'district': district,
      'display_name': center.isEmpty ? district : '$center, $district',
      'created_at': profile['created_at'] ?? now,
      'updated_at': profile['updated_at'] ?? now,
    };
  }

  Map<String, dynamic> _membershipFromProfile(
    Map<String, dynamic> profile, {
    required String facilityId,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    final email = profile['email'] as String;
    return {
      'id': '$facilityId::$email',
      'facility_id': facilityId,
      'user_email': email,
      'role': (profile['role'] as String?) ?? 'chw',
      'created_at': profile['created_at'] ?? now,
      'updated_at': profile['updated_at'] ?? now,
    };
  }

  Future<void> _applyRemoteRecord(
    String entityType,
    Map<String, dynamic> record,
  ) async {
    final database = await _db.db;
    switch (entityType) {
      case AppStrings.entityPatient:
        final patientRow = _localRow(record);
        if ((record['deleted_at'] as String?)?.isNotEmpty == true) {
          await database.delete(
            'patients',
            where: 'id = ?',
            whereArgs: [record['id']],
          );
        } else {
          await database.insert(
            'patients',
            patientRow,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _db.markEntitySyncedFromRemote(
            entityType,
            record['id'] as String,
          );
        }
        break;
      case AppStrings.entityCampaign:
        final campaignRow = _localRow(record);
        if ((record['deleted_at'] as String?)?.isNotEmpty == true) {
          await database.delete(
            'campaigns',
            where: 'id = ?',
            whereArgs: [record['id']],
          );
        } else {
          await database.insert(
            'campaigns',
            campaignRow,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _db.markEntitySyncedFromRemote(
            entityType,
            record['id'] as String,
          );
        }
        break;
      case AppStrings.entityScreening:
        final recordId = (record['record_id'] as String?)?.isNotEmpty == true
            ? record['record_id'] as String
            : record['remote_id'] as String;
        if ((record['deleted_at'] as String?)?.isNotEmpty == true) {
          await database.delete(
            'screenings',
            where: 'record_id = ?',
            whereArgs: [recordId],
          );
        } else {
          final existing = await database.query(
            'screenings',
            where: 'record_id = ?',
            whereArgs: [recordId],
            limit: 1,
          );
          final row = _localRow(record)..['record_id'] = recordId;
          if (existing.isNotEmpty) {
            row['id'] = existing.first['id'];
          } else {
            row.remove('id');
          }
          await database.insert(
            'screenings',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _db.markEntitySyncedFromRemote(
            entityType,
            recordId,
            screeningRecordId: recordId,
          );
        }
        break;
    }
  }

  Map<String, dynamic> _localRow(Map<String, dynamic> record) {
    final row = Map<String, dynamic>.from(record);
    row.remove('remote_id');
    return row;
  }
}
