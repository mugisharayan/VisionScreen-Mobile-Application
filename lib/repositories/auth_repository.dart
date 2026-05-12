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
  static const _resetTokenTtl = Duration(minutes: 10);
  static const _resetAttemptWindow = Duration(minutes: 15);
  static const _maxResetAttempts = 5;

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

    if (!SecurityUtils.verifyPassword(password, stored)) {
      return const AuthResult.failure('Invalid email or password');
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

  /// Confirms the phone number on file for [email]. Reset flow requires this
  /// to succeed before [resetPasswordWithToken] will accept a new password.
  /// Email alone is not enough to identify the account holder.
  Future<String?> verifyResetIdentity({
    required String email,
    required String phone,
  }) async {
    final normalised = email.trim().toLowerCase();
    if (_isResetLocked(normalised)) return null;

    final profile = await _db.getChwProfileByEmail(normalised);
    if (profile == null) {
      _recordResetFailure(normalised);
      return null;
    }
    final onFile = ((profile['phone'] as String?) ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    final entered = phone.replaceAll(RegExp(r'\D'), '');
    if (onFile.isEmpty || entered.isEmpty) {
      _recordResetFailure(normalised);
      return null;
    }
    // Compare the 9 trailing digits — same form we store on signup.
    final a = onFile.length >= 9 ? onFile.substring(onFile.length - 9) : onFile;
    final b = entered.length >= 9
        ? entered.substring(entered.length - 9)
        : entered;
    if (!SecurityUtils.constantTimeEquals(a, b)) {
      _recordResetFailure(normalised);
      return null;
    }
    _resetAttempts.remove(normalised);
    return _issueResetToken(normalised);
  }

  /// Resets the password using a short-lived token issued by
  /// [verifyResetIdentity]. The token is single-use and expires after 10 minutes.
  Future<bool> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final normalised = email.trim().toLowerCase();
    if (!_consumeResetToken(normalised, token)) return false;

    final newHash = SecurityUtils.hashPassword(newPassword);
    await _db.updateChwPassword(normalised, newHash);
    if (SyncService.instance.isConfigured) {
      final updated = await _db.getChwProfileByEmail(normalised);
      if (updated != null) {
        await SyncService.instance.mirrorProfile(updated);
        await SyncService.instance.syncNow();
      }
    }
    return true;
  }

  // Issued reset tokens live in-memory only; a process restart invalidates
  // them, which is the correct behavior for a single-device CHW workspace.
  static final Map<String, ({String token, DateTime expiresAt})>
  _activeResetTokens = {};
  static final Map<String, ({int count, DateTime firstAttempt})>
  _resetAttempts = {};

  String _issueResetToken(String email) {
    final token = SecurityUtils.randomToken(24);
    _activeResetTokens[email] = (
      token: token,
      expiresAt: DateTime.now().toUtc().add(_resetTokenTtl),
    );
    return token;
  }

  bool _consumeResetToken(String email, String token) {
    final issued = _activeResetTokens[email];
    if (issued == null) return false;
    if (DateTime.now().toUtc().isAfter(issued.expiresAt)) {
      _activeResetTokens.remove(email);
      return false;
    }
    if (!SecurityUtils.constantTimeEquals(issued.token, token)) return false;
    _activeResetTokens.remove(email);
    return true;
  }

  bool _isResetLocked(String email) {
    final attempts = _resetAttempts[email];
    if (attempts == null) return false;
    final now = DateTime.now().toUtc();
    if (now.difference(attempts.firstAttempt) > _resetAttemptWindow) {
      _resetAttempts.remove(email);
      return false;
    }
    return attempts.count >= _maxResetAttempts;
  }

  void _recordResetFailure(String email) {
    final now = DateTime.now().toUtc();
    final attempts = _resetAttempts[email];
    if (attempts == null ||
        now.difference(attempts.firstAttempt) > _resetAttemptWindow) {
      _resetAttempts[email] = (count: 1, firstAttempt: now);
      return;
    }
    _resetAttempts[email] = (
      count: attempts.count + 1,
      firstAttempt: attempts.firstAttempt,
    );
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
