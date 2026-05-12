import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visionscreen/db/database_helper.dart';
import 'package:visionscreen/repositories/auth_repository.dart';
import 'package:visionscreen/services/sync/mongo_workspace_remote.dart';
import 'package:visionscreen/services/sync/sync_service.dart';
import 'package:visionscreen/utils/app_constants.dart';
import 'package:visionscreen/utils/id_utils.dart';
import 'package:visionscreen/utils/security_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences? prefs;
  try {
    if (!SyncService.instance.isConfigured) {
      throw StateError(
        'MongoDB sync is not configured. Provide the VS_MONGODB_* dart defines.',
      );
    }

    final db = DatabaseHelper.instance;
    prefs = await SharedPreferences.getInstance();
    await _resetLocalState(db, prefs);

    final runId = DateTime.now().toUtc().millisecondsSinceEpoch;
    final chwEmail = 'smoke-$runId@visionscreen.test';
    final chwName = 'Smoke Test CHW';
    final chwPhone = '700${(runId % 1000000).toString().padLeft(6, '0')}';
    final center = 'Smoke Health Centre $runId';
    final district = 'Kampala';
    final facilityId = IdUtils.facilityId(center: center, district: district);
    final now = DateTime.now().toUtc().toIso8601String();

    final profile = <String, dynamic>{
      'chw_id': IdUtils.generate('chw'),
      'facility_id': facilityId,
      'name': chwName,
      'center': center,
      'district': district,
      'email': chwEmail,
      'phone': chwPhone,
      'password': SecurityUtils.hashPassword('SmokePass123!'),
      'role': 'chw',
      'created_at': now,
      'updated_at': now,
      'sync_state': AppStrings.syncPendingUpsert,
      'version': 1,
    };

    await _seedSession(
      prefs,
      name: chwName,
      center: center,
      district: district,
      email: chwEmail,
      phone: chwPhone,
      chwId: profile['chw_id'] as String,
      facilityId: facilityId,
      now: now,
    );

    await db.insertChwProfile(profile);
    await SyncService.instance.mirrorProfile(profile);

    final campaignId = await db.insertCampaign({
      'id': IdUtils.generate('campaign'),
      'name': 'Smoke Campaign $runId',
      'location': 'Kampala',
      'target_group': 'Children',
      'created_at': now,
      'updated_at': now,
    });

    final patientOneId = IdUtils.generate('patient');
    final patientTwoId = IdUtils.generate('patient');

    await db.insertPatient({
      'id': patientOneId,
      'name': 'Patient Pass $runId',
      'age': 9,
      'gender': 'Female',
      'village': 'Nakasero',
      'phone': '701111111',
      'conditions': '',
      'campaign_id': campaignId,
      'created_at': now,
      'updated_at': now,
    });
    await db.insertPatient({
      'id': patientTwoId,
      'name': 'Patient Refer $runId',
      'age': 11,
      'gender': 'Male',
      'village': 'Kololo',
      'phone': '702222222',
      'conditions': '',
      'campaign_id': campaignId,
      'created_at': now,
      'updated_at': now,
    });

    await db.insertScreening({
      'patient_id': patientOneId,
      'screening_date': now,
      'od_logmar': '0.2',
      'os_logmar': '0.2',
      'ou_near_logmar': '0.2',
      'od_snellen': '6/9',
      'os_snellen': '6/9',
      'ou_near_snellen': 'N6',
      'outcome': AppStrings.outcomePass,
      'chw_name': chwName,
      'created_at': now,
      'updated_at': now,
    });
    await db.insertScreening({
      'patient_id': patientTwoId,
      'screening_date': now,
      'od_logmar': '0.7',
      'os_logmar': '0.8',
      'ou_near_logmar': '0.6',
      'od_snellen': '6/30',
      'os_snellen': '6/38',
      'ou_near_snellen': 'N12',
      'outcome': AppStrings.outcomeRefer,
      'referral_facility': 'Mulago',
      'referral_status': AppStrings.statusPending,
      'chw_name': chwName,
      'created_at': now,
      'updated_at': now,
    });

    final pendingBefore = await db.getPendingSyncOperations();
    if (pendingBefore.length < 4) {
      throw StateError(
        'Expected queued sync operations before sync, found ${pendingBefore.length}.',
      );
    }

    final sync = await SyncService.instance.syncNow();
    if (!sync.success) {
      throw StateError('Sync failed: ${sync.errorMessage}');
    }

    final backup = await SyncService.instance.createBackup();
    if (!backup.success || (backup.backupId?.isEmpty ?? true)) {
      throw StateError('Backup failed: ${backup.errorMessage}');
    }

    final remoteBackup = await MongoWorkspaceRemote.instance
        .fetchLatestWorkspaceBackup(facilityId: facilityId);
    if (remoteBackup == null) {
      throw StateError('Remote backup lookup returned no result.');
    }

    await db.clearRestorableData();
    final clearedPatients = await db.getAllPatients();
    final clearedCampaigns = await db.getAllCampaigns();
    final clearedScreenings = await db.getAllScreenings();
    if (clearedPatients.isNotEmpty ||
        clearedCampaigns.isNotEmpty ||
        clearedScreenings.isNotEmpty) {
      throw StateError('Local workspace was not cleared before restore.');
    }

    final restore = await SyncService.instance.restoreLatestBackup();
    if (!restore.success) {
      throw StateError('Restore failed: ${restore.errorMessage}');
    }

    final restoredCampaigns = await db.getAllCampaigns();
    final restoredPatients = await db.getAllPatients();
    final restoredScreenings = await db.getAllScreenings();
    final unsyncedAfterRestore = await db.getUnsyncedCount();

    if (restoredCampaigns.length != 1 ||
        restoredPatients.length != 2 ||
        restoredScreenings.length != 2) {
      throw StateError(
        'Restore verification failed. campaigns=${restoredCampaigns.length}, patients=${restoredPatients.length}, screenings=${restoredScreenings.length}',
      );
    }
    if (unsyncedAfterRestore != 0) {
      throw StateError(
        'Expected 0 unsynced records after restore, found $unsyncedAfterRestore.',
      );
    }

    await _resetLocalState(db, prefs);

    final relogin = await AuthRepository.instance.login(
      chwEmail,
      'SmokePass123!',
    );
    if (!relogin.success) {
      throw StateError(
        'Remote login recovery failed: ${relogin.errorMessage ?? 'unknown error'}.',
      );
    }

    final recoveredProfile = await db.getChwProfileByEmail(chwEmail);
    final recoveredCampaigns = await db.getAllCampaigns();
    final recoveredPatients = await db.getAllPatients();
    final recoveredScreenings = await db.getAllScreenings();
    final unsyncedAfterRelogin = await db.getUnsyncedCount();

    if (recoveredProfile == null) {
      throw StateError('Remote login did not restore the local account row.');
    }
    if (recoveredCampaigns.length != 1 ||
        recoveredPatients.length != 2 ||
        recoveredScreenings.length != 2) {
      throw StateError(
        'Remote login recovery failed. campaigns=${recoveredCampaigns.length}, patients=${recoveredPatients.length}, screenings=${recoveredScreenings.length}',
      );
    }
    if (unsyncedAfterRelogin != 0) {
      throw StateError(
        'Expected 0 unsynced records after remote login recovery, found $unsyncedAfterRelogin.',
      );
    }

    final summary =
        'facility_id=$facilityId backup_id=${backup.backupId} '
        'sync_applied=${sync.appliedChanges} restored=${sync.restoredRecords} '
        'local_counts campaigns=${restoredCampaigns.length} patients=${restoredPatients.length} screenings=${restoredScreenings.length} '
        'relogin_counts campaigns=${recoveredCampaigns.length} patients=${recoveredPatients.length} screenings=${recoveredScreenings.length}';
    await _recordSmokeStatus(prefs, status: 'pass', message: summary);
    debugPrint('LIVE_SYNC_SMOKE PASS');
    debugPrint('facility_id=$facilityId');
    debugPrint('backup_id=${backup.backupId}');
    debugPrint(
      'sync_applied=${sync.appliedChanges} restored=${sync.restoredRecords}',
    );
    debugPrint(
      'local_counts campaigns=${restoredCampaigns.length} patients=${restoredPatients.length} screenings=${restoredScreenings.length}',
    );
    debugPrint(
      'relogin_counts campaigns=${recoveredCampaigns.length} patients=${recoveredPatients.length} screenings=${recoveredScreenings.length}',
    );
    exit(0);
  } catch (error, stackTrace) {
    if (prefs != null) {
      await _recordSmokeStatus(
        prefs,
        status: 'fail',
        message: '$error\n$stackTrace',
      );
    }
    debugPrint('LIVE_SYNC_SMOKE FAIL');
    debugPrint('$error');
    debugPrint('$stackTrace');
    exit(1);
  }
}

Future<void> _resetLocalState(
  DatabaseHelper db,
  SharedPreferences prefs,
) async {
  final database = await db.db;
  await db.clearRestorableData(database: database);
  await database.delete('chw_profiles');
  await prefs.clear();
}

Future<void> _seedSession(
  SharedPreferences prefs, {
  required String name,
  required String center,
  required String district,
  required String email,
  required String phone,
  required String chwId,
  required String facilityId,
  required String now,
}) async {
  await prefs.setString(AppStrings.prefChwName, name);
  await prefs.setString(AppStrings.prefChwCenter, center);
  await prefs.setString(AppStrings.prefChwDistrict, district);
  await prefs.setString(AppStrings.prefChwEmail, email);
  await prefs.setString(AppStrings.prefChwPhone, phone);
  await prefs.setString(AppStrings.prefChwId, chwId);
  await prefs.setString(AppStrings.prefFacilityId, facilityId);
  await prefs.setString(AppStrings.prefLastLoginTime, now);
  await prefs.setString(AppStrings.prefLastLoginRole, 'CHW');
  await prefs.setBool(AppStrings.prefFirstLaunch, false);
}

Future<void> _recordSmokeStatus(
  SharedPreferences prefs, {
  required String status,
  required String message,
}) async {
  await prefs.setString('smoke_status', status);
  await prefs.setString('smoke_message', message);
}
