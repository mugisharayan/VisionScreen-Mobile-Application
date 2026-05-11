import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../services/sync/sync_service.dart';
import '../utils/app_constants.dart';
import '../utils/id_utils.dart';
import '../utils/security_utils.dart';

/// Result of a login or sign-up attempt.
class AuthResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? profile;

  const AuthResult.success(this.profile) : success = true, errorMessage = null;

  const AuthResult.failure(this.errorMessage) : success = false, profile = null;
}

/// Repository for authentication operations.
/// Centralises all auth logic (login, sign-up, password change, session).
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final _db = DatabaseHelper.instance;

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<AuthResult> login(String email, String password) async {
    final normalised = email.trim().toLowerCase();
    var profile = await _db.getChwProfileByEmail(normalised);

    if (profile == null && SyncService.instance.isConfigured) {
      final remoteProfile = await SyncService.instance.fetchRemoteProfile(
        normalised,
      );
      if (remoteProfile != null) {
        final storedRemote = remoteProfile['password'] as String? ?? '';
        if (!SecurityUtils.verifyPassword(password, storedRemote)) {
          return const AuthResult.failure('Invalid email or password');
        }
        await _db.cacheSyncedChwProfile(remoteProfile);
        profile = await _db.getChwProfileByEmail(normalised);
      }
    }

    if (profile == null) {
      return const AuthResult.failure('Invalid email or password');
    }

    final stored = profile['password'] as String;

    // Verify password (supports both legacy SHA-256 and new salted format)
    if (!SecurityUtils.verifyPassword(password, stored)) {
      return const AuthResult.failure('Invalid email or password');
    }

    // Migrate legacy hash to salted hash on successful login
    if (SecurityUtils.needsRehash(stored)) {
      final newHash = SecurityUtils.hashPassword(password);
      await _db.updateChwPassword(normalised, newHash);
    }

    await _persistSession(profile);
    if (SyncService.instance.isConfigured) {
      await SyncService.instance.mirrorProfile(profile);
      await SyncService.instance.syncNow();
    }
    return AuthResult.success(profile);
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────

  Future<AuthResult> signUp({
    required String name,
    required String center,
    required String district,
    required String email,
    required String phone,
    required String password,
    String role = 'chw',
  }) async {
    final normalised = email.trim().toLowerCase();
    final existing = await _db.getChwProfileByEmail(normalised);
    if (existing != null) {
      return const AuthResult.failure(
        'An account with this email already exists',
      );
    }

    if (SyncService.instance.isConfigured) {
      final remoteExisting = await SyncService.instance.fetchRemoteProfile(
        normalised,
      );
      if (remoteExisting != null) {
        return const AuthResult.failure(
          'An account with this email already exists',
        );
      }
    }

    final facilityId = IdUtils.facilityId(
      center: center.trim(),
      district: district.trim(),
    );
    final now = DateTime.now().toUtc().toIso8601String();

    final profile = {
      'chw_id': IdUtils.generate('chw'),
      'facility_id': facilityId,
      'name': name.trim(),
      'center': center.trim(),
      'district': district.trim(),
      'email': normalised,
      'phone': phone.replaceAll(RegExp(r'\s'), ''),
      'password': SecurityUtils.hashPassword(password),
      'role': role,
      'created_at': now,
      'updated_at': now,
      'sync_state': AppStrings.syncPendingUpsert,
    };

    await _db.insertChwProfile(profile);
    if (SyncService.instance.isConfigured) {
      await SyncService.instance.mirrorProfile(profile);
      await SyncService.instance.syncNow();
    }
    await _persistSession(profile);
    return AuthResult.success(profile);
  }

  // ── Password Change ────────────────────────────────────────────────────────

  /// Verifies [currentPassword] then updates to [newPassword].
  /// Returns an error message on failure, null on success.
  Future<String?> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final normalised = email.trim().toLowerCase();
    final profile = await _db.getChwProfileByEmail(normalised);
    if (profile == null) return 'Account not found';

    final stored = profile['password'] as String;
    if (!SecurityUtils.verifyPassword(currentPassword, stored)) {
      return 'Current password is incorrect';
    }

    final newHash = SecurityUtils.hashPassword(newPassword);
    await _db.updateChwPassword(normalised, newHash);
    if (SyncService.instance.isConfigured) {
      final updated = await _db.getChwProfileByEmail(normalised);
      if (updated != null) {
        await SyncService.instance.mirrorProfile(updated);
        await SyncService.instance.syncNow();
      }
    }
    return null; // success
  }

  /// Reset password without verifying the old one (used in forgot-password flow
  /// after email verification).
  Future<void> resetPassword(String email, String newPassword) async {
    final newHash = SecurityUtils.hashPassword(newPassword);
    final normalised = email.trim().toLowerCase();
    await _db.updateChwPassword(normalised, newHash);
    if (SyncService.instance.isConfigured) {
      final updated = await _db.getChwProfileByEmail(normalised);
      if (updated != null) {
        await SyncService.instance.mirrorProfile(updated);
        await SyncService.instance.syncNow();
      }
    }
  }

  // ── Session ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear session keys but keep remember-me preference
    final remember = prefs.getBool(AppStrings.prefRememberMe) ?? false;
    final rememberedEmail =
        prefs.getString(AppStrings.prefRememberedEmail) ?? '';
    await prefs.clear();
    if (remember) {
      await prefs.setBool(AppStrings.prefRememberMe, true);
      await prefs.setString(AppStrings.prefRememberedEmail, rememberedEmail);
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppStrings.prefChwEmail)?.isNotEmpty ?? false;
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _persistSession(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppStrings.prefChwName, profile['name'] as String);
    await prefs.setString(
      AppStrings.prefChwCenter,
      profile['center'] as String,
    );
    await prefs.setString(
      AppStrings.prefChwDistrict,
      profile['district'] as String,
    );
    await prefs.setString(AppStrings.prefChwEmail, profile['email'] as String);
    await prefs.setString(AppStrings.prefChwPhone, profile['phone'] as String);
    await prefs.setString(
      AppStrings.prefFacilityId,
      (profile['facility_id'] as String?)?.isNotEmpty == true
          ? profile['facility_id'] as String
          : IdUtils.facilityId(
              center: profile['center'] as String,
              district: profile['district'] as String,
            ),
    );

    // Generate CHW ID if not already set
    final currentId = (profile['chw_id'] as String?)?.isNotEmpty == true
        ? profile['chw_id'] as String
        : IdUtils.generate('chw');
    await prefs.setString(AppStrings.prefChwId, currentId);

    final role = (profile['role'] as String?) ?? 'chw';
    await prefs.setString(
      AppStrings.prefLastLoginRole,
      role == 'admin' ? 'Administrator' : 'Community Health Worker',
    );
    await prefs.setString(
      AppStrings.prefLastLoginTime,
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
