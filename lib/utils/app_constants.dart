// ── App Strings ───────────────────────────────────────────────────────────────
class AppStrings {
  AppStrings._();

  static const appName = 'VisionScreen';
  static const appVersion = 'v1.0.0';
  static const appTagline = 'Made for Community Health Workers · Uganda';

  // Outcomes
  static const outcomePass = 'pass';
  static const outcomeRefer = 'refer';
  static const outcomePending = 'pending';

  // Referral statuses
  static const statusPending = 'pending';
  static const statusNotified = 'notified';
  static const statusCompleted = 'completed';
  static const statusRescheduled = 'rescheduled';
  static const statusOverdue = 'overdue';

  // SharedPreferences keys
  static const prefChwName = 'chw_name';
  static const prefChwCenter = 'chw_center';
  static const prefChwDistrict = 'chw_district';
  static const prefChwEmail = 'chw_email';
  static const prefChwPhone = 'chw_phone';
  static const prefChwId = 'chw_id';
  static const prefChwPhoto = 'chw_photo';
  static const prefLastLoginTime = 'last_login_time';
  static const prefLastLoginRole = 'last_login_role';
  static const prefRememberMe = 'remember_me';
  static const prefRememberedEmail = 'remembered_email';
  static const prefBrightnessLock = 'brightness_lock';
  static const prefHapticFeedback = 'haptic_feedback';
  static const prefReferralLanguage = 'referral_language';
  static const prefFirstLaunch = 'first_launch';
  static const prefFacilityId = 'facility_id';
  static const prefLastSyncAt = 'last_sync_at';
  static const prefLastSyncError = 'last_sync_error';
  static const prefLastBackupId = 'last_backup_id';
  static const prefLastBackupAt = 'last_backup_at';

  // Sync state
  static const syncPendingUpsert = 'pending_upsert';
  static const syncPendingDelete = 'pending_delete';
  static const syncSynced = 'synced';
  static const syncConflict = 'conflict';

  // Sync entities
  static const entityPatient = 'patient';
  static const entityCampaign = 'campaign';
  static const entityScreening = 'screening';
  static const entityChwProfile = 'chw_profile';
  static const entityFacility = 'facility';
  static const entityMembership = 'membership';
}

// ── Pagination ────────────────────────────────────────────────────────────────
class AppPagination {
  AppPagination._();

  static const patientPageSize = 25;
  static const screeningPageSize = 20;
  static const recentLimit = 10;
}
