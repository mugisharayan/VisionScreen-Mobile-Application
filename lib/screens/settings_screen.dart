import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../db/database_helper.dart';
import '../repositories/auth_repository.dart';
import '../repositories/screening_repository.dart';
import '../services/permission_coordinator.dart';
import '../services/sync/sync_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../utils/haptics.dart';
import '../utils/id_utils.dart';
import '../utils/legal_copy.dart';
import '../widgets/vs_logo.dart';
import '../widgets/vs_toast.dart';
import '../widgets/vs_ui.dart';
import '../features/settings/settings_export_service.dart';

// Colours
class _C {
  static const ink = Color(0xFF04091A);
  static const ink2 = Color(0xFF0B1530);
  static const teal = Color(0xFF0D9488);
  static const teal2 = Color(0xFF14B8A6);
  static const teal3 = Color(0xFF5EEAD4);
  static const g100 = Color(0xFFF0F4F7);
  static const g200 = Color(0xFFDDE4EC);
  static const g300 = Color(0xFFC4CFDB);
  static const g400 = Color(0xFF8FA0B4);
  static const g500 = Color(0xFF5E7291);
  static const g800 = Color(0xFF1A2A3D);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
}

enum _ProfilePhotoAction { camera, gallery, remove }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _chwName = '';
  String _chwCenter = '';
  String _chwDistrict = '';
  String _chwEmail = '';
  String _chwPhone = '';
  String _chwId = '';
  String _lastLoginTime = '';
  String _lastLoginRole = '';
  String _chwPhoto = '';
  int _unsyncedCount = 0;
  bool _syncConfigured = false;
  String _lastSyncAt = '';
  String _lastSyncError = '';
  String _lastBackupAt = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _chwName = p.getString(AppStrings.prefChwName) ?? '';
      _chwCenter = p.getString(AppStrings.prefChwCenter) ?? '';
      _chwDistrict = p.getString(AppStrings.prefChwDistrict) ?? '';
      _chwEmail = p.getString(AppStrings.prefChwEmail) ?? '';
      _chwPhone = p.getString(AppStrings.prefChwPhone) ?? '';
      _chwId = p.getString(AppStrings.prefChwId) ?? '';
      _lastLoginTime = p.getString(AppStrings.prefLastLoginTime) ?? '';
      _lastLoginRole = p.getString(AppStrings.prefLastLoginRole) ?? '';
      _brightnessLock = p.getBool(AppStrings.prefBrightnessLock) ?? true;
      _hapticFeedback = p.getBool(AppStrings.prefHapticFeedback) ?? true;
      _language =
          p.getString(AppStrings.prefReferralLanguage) ?? 'English Only';
      _chwPhoto = p.getString(AppStrings.prefChwPhoto) ?? '';
      _syncConfigured = SyncService.instance.isConfigured;
      _lastSyncAt = p.getString(AppStrings.prefLastSyncAt) ?? '';
      _lastSyncError = p.getString(AppStrings.prefLastSyncError) ?? '';
      _lastBackupAt = p.getString(AppStrings.prefLastBackupAt) ?? '';
    });
    final count = await ScreeningRepository.instance.getUnsyncedCount();
    if (!mounted) return;
    setState(() => _unsyncedCount = count);
  }

  Future<void> _setHapticFeedback(bool value) async {
    setState(() => _hapticFeedback = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppStrings.prefHapticFeedback, value);
  }

  void _haptic() {
    if (!_hapticFeedback) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  String _formatLastLoginLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;

    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${days[local.weekday - 1]}, ${local.day} ${months[local.month - 1]} $hh:$mm';
  }

  String get _roleLabel => _lastLoginRole == 'Administrator' ? 'Admin' : 'CHW';

  String get _profileSummary {
    final location = [
      _chwCenter,
      _chwDistrict,
    ].where((part) => part.trim().isNotEmpty).join(' · ');
    if (location.isNotEmpty) {
      return location;
    }
    if (_chwEmail.isNotEmpty) {
      return _chwEmail;
    }
    return 'Health center, contact and badge details';
  }

  String get _accountSummary {
    if (_lastLoginTime.isEmpty) {
      return 'Password, role and sign-in details';
    }
    return 'Last login ${_formatLastLoginLabel(_lastLoginTime)}';
  }

  String get _preferencesSummary =>
      '$_language · ${_hapticFeedback ? 'Haptics on' : 'Haptics off'}';

  String get _screeningSummary =>
      _brightnessLock ? 'Brightness lock is on' : 'Brightness lock is off';

  String get _dataSyncSummary {
    if (!_syncConfigured) {
      return 'Cloud workspace ready by default';
    }
    if (_lastSyncError.isNotEmpty) {
      return 'Last sync failed. Open to retry or restore.';
    }
    if (_unsyncedCount == 0) {
      if (_lastSyncAt.isEmpty) {
        return 'All local changes are synced';
      }
      return 'Last synced ${_formatLastLoginLabel(_lastSyncAt)}';
    }
    return '$_unsyncedCount change${_unsyncedCount == 1 ? '' : 's'} waiting to sync';
  }

  Future<void> _setBrightnessLock(bool value) async {
    setState(() => _brightnessLock = value);
    final p = await SharedPreferences.getInstance();
    await p.setBool(AppStrings.prefBrightnessLock, value);
    try {
      if (value) {
        await ScreenBrightness().setScreenBrightness(1.0);
      } else {
        await ScreenBrightness().resetScreenBrightness();
      }
    } catch (_) {}
  }

  Future<void> _runSync() async {
    final result = await SyncService.instance.syncNow();
    await _loadProfile();
    if (!mounted) return;
    _showToast(
      result.success
          ? 'Sync finished: ${result.appliedChanges} uploaded, ${result.restoredRecords} refreshed.'
          : result.errorMessage ?? 'Sync failed.',
      result.success ? _C.green : _C.red,
    );
  }

  Future<void> _createBackup() async {
    final result = await SyncService.instance.createBackup();
    await _loadProfile();
    if (!mounted) return;
    _showToast(
      result.success
          ? 'Cloud backup saved with ${result.rowsCaptured} rows.'
          : result.errorMessage ?? 'Backup failed.',
      result.success ? _C.teal : _C.red,
    );
  }

  Future<void> _restoreLatestBackup() async {
    final result = await SyncService.instance.restoreLatestBackup();
    await _loadProfile();
    if (!mounted) return;
    _showToast(
      result.success
          ? 'Cloud backup restored: ${result.rowsRestored} rows across ${result.tablesRestored} tables.'
          : result.errorMessage ?? 'Restore failed.',
      result.success ? _C.teal : _C.red,
    );
  }

  bool _hapticFeedback = true;
  bool _brightnessLock = true;

  String _language = 'English Only';
  static const _languages = [
    'English Only',
    'Luganda',
    'Runyankole/Rukiga',
    'Acholi',
    'Ateso',
    'Lugbara',
    'Luo',
    'Runyoro',
    'Swahili',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
              child: Column(
                children: [
                  // ── Account group ──
                  // Identity-and-preferences cluster. Three drill-down
                  // rows live in one card so the section header earns
                  // its keep (was 1-row-per-header before).
                  _buildSection(
                    title: 'Account',
                    children: [
                      _buildRow(
                        badgeColor: _C.teal,
                        badgeIcon: Icons.person_outline_rounded,
                        label: _chwName.isNotEmpty ? _chwName : 'Profile',
                        subtitle: _profileSummary,
                        isFirst: true,
                        onTap: _showProfileOverviewSheet,
                      ),
                      _buildRow(
                        badgeColor: const Color(0xFF6366F1),
                        badgeIcon: Icons.lock_outline_rounded,
                        label: 'Sign-in & security',
                        subtitle: _accountSummary,
                        onTap: _showAccountSheet,
                      ),
                      _buildRow(
                        badgeColor: const Color(0xFF3B82F6),
                        badgeIcon: Icons.tune_rounded,
                        label: 'Preferences',
                        subtitle: _preferencesSummary,
                        isLast: true,
                        onTap: _showPreferencesSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ── App group ──
                  // Workflow + data plumbing + product info. Status
                  // pill on Data & Sync is preserved here.
                  _buildSection(
                    title: 'App',
                    children: [
                      _buildRow(
                        badgeColor: const Color(0xFFEAB308),
                        badgeIcon: Icons.remove_red_eye_outlined,
                        label: 'Screening',
                        subtitle: _screeningSummary,
                        isFirst: true,
                        onTap: _showScreeningSheet,
                      ),
                      _buildRow(
                        badgeColor: const Color(0xFF22C55E),
                        badgeIcon: Icons.cloud_outlined,
                        label: 'Data & Sync',
                        subtitle: _dataSyncSummary,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: !_syncConfigured
                                ? _C.red.withValues(alpha: 0.1)
                                : _unsyncedCount == 0
                                ? _C.green.withValues(alpha: 0.1)
                                : _C.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            !_syncConfigured
                                ? 'Offline'
                                : _unsyncedCount == 0
                                ? 'Synced'
                                : 'Pending',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: !_syncConfigured
                                  ? _C.red
                                  : _unsyncedCount == 0
                                  ? _C.green
                                  : _C.amber,
                            ),
                          ),
                        ),
                        onTap: _showDataAndSyncSheet,
                      ),
                      _buildRow(
                        badgeColor: _C.teal,
                        badgeIcon: Icons.info_outline_rounded,
                        label: 'About VisionScreen',
                        subtitle: 'Version, support, privacy and release notes',
                        isLast: true,
                        onTap: _showAboutDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ── Danger row ──
                  // Separated into its own card (no group header) so it
                  // doesn't sit next to neutral rows. Red badge + red
                  // label are the only visual difference needed.
                  _buildSection(
                    children: [
                      _buildRow(
                        badgeColor: const Color(0xFFEF4444),
                        badgeIcon: Icons.shield_outlined,
                        label: 'Device & Session',
                        labelColor: const Color(0xFFEF4444),
                        subtitle: 'Clear local workspace or log out',
                        isFirst: true,
                        isLast: true,
                        onTap: _showDangerZoneSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }

  // Header: profile card
  Widget _buildHeader() {
    final initials = _chwName.trim().isNotEmpty
        ? _chwName
              .trim()
              .split(' ')
              .map((w) => w.isEmpty ? '' : w[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'VS';
    final roleLabel = _lastLoginRole == 'Administrator' ? 'Admin' : 'CHW';

    return Container(
      decoration: const BoxDecoration(
        gradient: VsGradients.hero,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: VsDotPatternPainter()),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (_, t, child) =>
                        Transform.scale(scale: t, child: child),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _chwPhoto.isNotEmpty
                          ? ClipOval(
                              child: Image.file(
                                File(_chwPhoto),
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Text(
                                        initials,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _chwName.isNotEmpty ? _chwName : 'VisionScreen User',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _chwCenter.isNotEmpty
                              ? '$_chwCenter \u00b7 $_chwDistrict'
                              : 'Community Health Worker',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        if (_chwPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '+256 $_chwPhone',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                roleLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                _chwId.isNotEmpty ? _chwId : 'No ID',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  VsIconButton(
                    icon: Icons.edit_rounded,
                    iconSize: 16,
                    size: 36,
                    foreground: Colors.white,
                    tint: Colors.white.withValues(alpha: 0.15),
                    tooltip: 'Edit profile',
                    onTap: _showEditProfileSheet,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _ensureProfilePhotoPermission(_ProfilePhotoAction action) {
    final uiContext = context;
    final request = action == _ProfilePhotoAction.camera
        ? PermissionCoordinator.instance.requestProfilePhotoCamera(uiContext)
        : PermissionCoordinator.instance.requestProfilePhotoLibrary(uiContext);
    return request.then((permission) => mounted && permission.isGranted);
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _chwName);
    final centerCtrl = TextEditingController(text: _chwCenter);
    final districtCtrl = TextEditingController(text: _chwDistrict);
    final emailCtrl = TextEditingController(text: _chwEmail);
    final phoneCtrl = TextEditingController(text: _chwPhone);
    String photoPath = _chwPhoto;
    bool saving = false;
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                32 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _C.g200,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _C.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: _C.teal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profile',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _C.g800,
                              ),
                            ),
                            Text(
                              'Changes saved to this device',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _C.g400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: StatefulBuilder(
                      builder: (_, setPhoto) => Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () async {
                            final action =
                                await showModalBottomSheet<_ProfilePhotoAction>(
                                  context: ctx,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (sheetCtx) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                            top: 12,
                                            bottom: 8,
                                          ),
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: _C.g200,
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          leading: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: _C.teal.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_rounded,
                                              color: _C.teal,
                                              size: 18,
                                            ),
                                          ),
                                          title: Text(
                                            'Take a photo',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _C.g800,
                                            ),
                                          ),
                                          onTap: () => Navigator.pop(
                                            sheetCtx,
                                            _ProfilePhotoAction.camera,
                                          ),
                                        ),
                                        ListTile(
                                          leading: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF3B82F6,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.photo_library_rounded,
                                              color: Color(0xFF3B82F6),
                                              size: 18,
                                            ),
                                          ),
                                          title: Text(
                                            'Choose from gallery',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _C.g800,
                                            ),
                                          ),
                                          onTap: () => Navigator.pop(
                                            sheetCtx,
                                            _ProfilePhotoAction.gallery,
                                          ),
                                        ),
                                        if (photoPath.isNotEmpty)
                                          ListTile(
                                            leading: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: _C.red.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: _C.red,
                                                size: 18,
                                              ),
                                            ),
                                            title: Text(
                                              'Remove photo',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: _C.red,
                                                  ),
                                            ),
                                            onTap: () => Navigator.pop(
                                              sheetCtx,
                                              _ProfilePhotoAction.remove,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                );
                            if (action == _ProfilePhotoAction.remove) {
                              setPhoto(() => photoPath = '');
                              setSheet(() {});
                              return;
                            }
                            if (action == null) return;
                            if (!await _ensureProfilePhotoPermission(action)) {
                              return;
                            }
                            final picked = await picker.pickImage(
                              source: action == _ProfilePhotoAction.camera
                                  ? ImageSource.camera
                                  : ImageSource.gallery,
                              imageQuality: 80,
                              maxWidth: 400,
                            );
                            if (!mounted) return;
                            if (picked != null) {
                              // Copy to permanent app documents directory so
                              // the path stays valid across app restarts.
                              // image_picker returns a temp cache path that
                              // becomes stale after the session ends.
                              final appDir =
                                  await getApplicationDocumentsDirectory();
                              final fileName =
                                  'chw_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
                              final permanent = await File(
                                picked.path,
                              ).copy('${appDir.path}/$fileName');
                              setPhoto(() => photoPath = permanent.path);
                              setSheet(() {});
                            }
                          },
                          customBorder: const CircleBorder(),
                          child: Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [_C.teal, _C.teal2],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: _C.g200, width: 2),
                                ),
                                child: photoPath.isNotEmpty
                                    ? ClipOval(
                                        child: Image.file(
                                          File(photoPath),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              Center(
                                                child: Text(
                                                  nameCtrl.text.trim().isEmpty
                                                      ? 'VS'
                                                      : nameCtrl.text
                                                            .trim()
                                                            .split(' ')
                                                            .map(
                                                              (w) => w.isEmpty
                                                                  ? ''
                                                                  : w[0],
                                                            )
                                                            .take(2)
                                                            .join()
                                                            .toUpperCase(),
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          nameCtrl.text.trim().isEmpty
                                              ? 'VS'
                                              : nameCtrl.text
                                                    .trim()
                                                    .split(' ')
                                                    .map(
                                                      (w) =>
                                                          w.isEmpty ? '' : w[0],
                                                    )
                                                    .take(2)
                                                    .join()
                                                    .toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: _C.teal,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _editField(
                    nameCtrl,
                    'Full Name',
                    Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _editField(
                    centerCtrl,
                    'Health Center',
                    Icons.local_hospital_outlined,
                  ),
                  const SizedBox(height: 12),
                  _editField(
                    districtCtrl,
                    'District',
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),
                  _editField(
                    emailCtrl,
                    'Email (Sign-In ID)',
                    Icons.mail_outline_rounded,
                    keyboard: TextInputType.emailAddress,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  _editField(
                    phoneCtrl,
                    'Phone (9 digits)',
                    Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheet(() => saving = true);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                AppStrings.prefChwName,
                                nameCtrl.text.trim(),
                              );
                              await prefs.setString(
                                AppStrings.prefChwCenter,
                                centerCtrl.text.trim(),
                              );
                              await prefs.setString(
                                AppStrings.prefChwDistrict,
                                districtCtrl.text.trim(),
                              );
                              await prefs.setString(
                                AppStrings.prefChwPhone,
                                phoneCtrl.text.trim(),
                              );
                              await prefs.setString(
                                AppStrings.prefFacilityId,
                                IdUtils.facilityId(
                                  center: centerCtrl.text.trim(),
                                  district: districtCtrl.text.trim(),
                                ),
                              );
                              await prefs.setString(
                                AppStrings.prefChwPhoto,
                                photoPath,
                              );
                              if (_chwEmail.isNotEmpty) {
                                await DatabaseHelper.instance
                                    .updateChwProfile(_chwEmail, {
                                      'name': nameCtrl.text.trim(),
                                      'center': centerCtrl.text.trim(),
                                      'district': districtCtrl.text.trim(),
                                      'phone': phoneCtrl.text.trim(),
                                    });
                                if (SyncService.instance.isConfigured) {
                                  final updated = await DatabaseHelper.instance
                                      .getChwProfileByEmail(
                                        _chwEmail.toLowerCase(),
                                      );
                                  if (updated != null) {
                                    await SyncService.instance.mirrorProfile(
                                      updated,
                                    );
                                    await SyncService.instance.syncNow();
                                  }
                                }
                              }
                              await _loadProfile();
                              if (mounted) {
                                Navigator.pop(context);
                                _showToast('Profile updated', _C.teal);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      centerCtrl.dispose();
      districtCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  Widget _editField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _C.g400,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _C.g100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.g200, width: 1.5),
          ),
          child: TextField(
            controller: ctrl,
            enabled: enabled,
            keyboardType: keyboard,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _C.g800,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(icon, size: 16, color: _C.g400),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({String? title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 13,
                    decoration: BoxDecoration(
                      color: _C.teal,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: _intersperse(children)),
          ),
        ],
      ),
    );
  }

  // Inserts a thin divider between rows
  List<Widget> _intersperse(List<Widget> rows) {
    if (rows.isEmpty) return rows;
    final result = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      result.add(rows[i]);
      if (i < rows.length - 1) {
        result.add(
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF2F4F7),
            indent: 16,
            endIndent: 0,
          ),
        );
      }
    }
    return result;
  }

  Widget _buildRow({
    required Color badgeColor,
    required IconData badgeIcon,
    required String label,
    String? subtitle,
    Widget? trailing,
    bool showChevron = true,
    Color? labelColor,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final radius = BorderRadius.only(
      topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
      topRight: isFirst ? const Radius.circular(16) : Radius.zero,
      bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
      bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
    );
    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap != null
            ? () {
                VsHaptics.light();
                onTap();
              }
            : null,
        borderRadius: radius,
        splashColor: _C.teal.withValues(alpha: 0.06),
        highlightColor: _C.g100.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(badgeIcon, size: 18, color: badgeColor),
              ),
              const SizedBox(width: 14),
              // Label + optional subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: labelColor ?? const Color(0xFF1C1C1E),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.inter(fontSize: 12, color: _C.g400),
                      ),
                    ],
                  ],
                ),
              ),
              // Trailing widget
              // ignore: use_null_aware_elements
              if (trailing != null) trailing,
              // Chevron
              if (showChevron) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFC7C7CC),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileOverviewSheet() {
    _showSettingsDetailSheet(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      iconColor: _C.teal,
      subtitle: 'Contact and badge details for this device',
      rows: [
        _buildRow(
          badgeColor: _C.teal,
          badgeIcon: Icons.local_hospital_outlined,
          label: _chwCenter.isNotEmpty ? _chwCenter : 'Not set',
          subtitle: 'Health center',
          showChevron: false,
          isFirst: true,
        ),
        _buildRow(
          badgeColor: const Color(0xFF3B82F6),
          badgeIcon: Icons.location_on_outlined,
          label: _chwDistrict.isNotEmpty ? _chwDistrict : 'Not set',
          subtitle: 'District',
          showChevron: false,
        ),
        _buildRow(
          badgeColor: const Color(0xFFF59E0B),
          badgeIcon: Icons.mail_outline_rounded,
          label: _chwEmail.isNotEmpty ? _chwEmail : 'Not set',
          subtitle: 'Email address',
          showChevron: false,
        ),
        _buildRow(
          badgeColor: const Color(0xFF22C55E),
          badgeIcon: Icons.phone_outlined,
          label: _chwPhone.isNotEmpty ? '+256 $_chwPhone' : 'Not set',
          subtitle: 'Phone number',
          showChevron: false,
        ),
        _buildRow(
          badgeColor: _C.teal,
          badgeIcon: Icons.badge_outlined,
          label: _chwId.isNotEmpty ? _chwId : 'No ID assigned',
          subtitle: 'CHW badge ID',
          showChevron: false,
          isLast: true,
          trailing: _chwId.isNotEmpty
              ? _buildStatusPill(
                  'Active',
                  _C.teal,
                  _C.teal.withValues(alpha: 0.1),
                )
              : null,
        ),
      ],
      footer: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Future<void>.delayed(Duration.zero, _showEditProfileSheet);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.teal,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Edit Profile',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountSheet() {
    _showSettingsDetailSheet(
      title: 'Sign-in & security',
      icon: Icons.lock_outline_rounded,
      iconColor: const Color(0xFF6366F1),
      subtitle: 'Password and sign-in details',
      rows: [
        _buildRow(
          badgeColor: const Color(0xFF22C55E),
          badgeIcon: Icons.access_time_rounded,
          label: _lastLoginTime.isNotEmpty
              ? _formatLastLoginLabel(_lastLoginTime)
              : 'Not recorded yet',
          subtitle: 'Last login',
          showChevron: false,
          isFirst: true,
          trailing: _lastLoginRole.isNotEmpty
              ? _buildStatusPill(
                  _roleLabel,
                  _C.teal,
                  _C.teal.withValues(alpha: 0.1),
                )
              : null,
        ),
        _buildRow(
          badgeColor: const Color(0xFF6366F1),
          badgeIcon: Icons.lock_outline_rounded,
          label: 'Change Password',
          subtitle: 'Update your account password',
          isLast: true,
          onTap: _showChangePasswordSheet,
        ),
      ],
    );
  }

  void _showPreferencesSheet() {
    _showSettingsDetailSheet(
      title: 'Preferences',
      icon: Icons.tune_rounded,
      iconColor: const Color(0xFF3B82F6),
      subtitle: 'Language and feedback preferences',
      rows: [
        _buildRow(
          badgeColor: const Color(0xFF3B82F6),
          badgeIcon: Icons.language_rounded,
          label: 'Referral Language',
          subtitle: _language,
          isFirst: true,
          onTap: _showLanguagePicker,
        ),
        _buildRow(
          badgeColor: const Color(0xFFF59E0B),
          badgeIcon: Icons.vibration_rounded,
          label: 'Haptic Feedback',
          subtitle: 'Vibrate on actions',
          showChevron: false,
          isLast: true,
          trailing: _buildToggle(
            value: _hapticFeedback,
            onChanged: _setHapticFeedback,
          ),
        ),
      ],
    );
  }

  void _showScreeningSheet() {
    _showSettingsDetailSheet(
      title: 'Screening',
      icon: Icons.remove_red_eye_outlined,
      iconColor: const Color(0xFFEAB308),
      subtitle: 'Behavior during active tests',
      rows: [
        _buildRow(
          badgeColor: const Color(0xFFEAB308),
          badgeIcon: Icons.wb_sunny_rounded,
          label: 'Brightness Lock',
          subtitle: 'Auto full brightness during test',
          showChevron: false,
          isFirst: true,
          isLast: true,
          trailing: _buildToggle(
            value: _brightnessLock,
            onChanged: _setBrightnessLock,
          ),
        ),
      ],
    );
  }

  void _showDataAndSyncSheet() {
    _showSettingsDetailSheet(
      title: 'Data & Sync',
      icon: Icons.cloud_outlined,
      iconColor: _C.teal,
      subtitle: 'Cloud sync, backup, restore and exports',
      rows: [
        _buildRow(
          badgeColor: const Color(0xFF22C55E),
          badgeIcon: Icons.cloud_outlined,
          label: 'Sync Status',
          subtitle: _dataSyncSummary,
          showChevron: false,
          isFirst: true,
          trailing: _buildStatusPill(
            !_syncConfigured
                ? 'Offline'
                : _unsyncedCount == 0
                ? 'Synced'
                : 'Pending',
            !_syncConfigured
                ? _C.red
                : _unsyncedCount == 0
                ? _C.green
                : _C.amber,
            (!_syncConfigured
                    ? _C.red
                    : _unsyncedCount == 0
                    ? _C.green
                    : _C.amber)
                .withValues(alpha: 0.1),
          ),
        ),
        _buildRow(
          badgeColor: const Color(0xFF0EA5E9),
          badgeIcon: Icons.sync_rounded,
          label: 'Sync Now',
          subtitle: 'Upload queued changes and refresh workspace data',
          onTap: _runSync,
        ),
        _buildRow(
          badgeColor: const Color(0xFF14B8A6),
          badgeIcon: Icons.save_alt_rounded,
          label: 'Create Cloud Backup',
          subtitle: 'Save a full Atlas backup of this workspace',
          onTap: _createBackup,
        ),
        _buildRow(
          badgeColor: const Color(0xFFF59E0B),
          badgeIcon: Icons.restore_rounded,
          label: 'Restore Latest Cloud Backup',
          subtitle: _lastBackupAt.isEmpty
              ? 'Restore the latest backup for this facility'
              : 'Latest backup ${_formatLastLoginLabel(_lastBackupAt)}',
          onTap: _restoreLatestBackup,
        ),
        _buildRow(
          badgeColor: const Color(0xFF3B82F6),
          badgeIcon: Icons.picture_as_pdf_outlined,
          label: 'Export as PDF',
          subtitle: 'Patient, campaign and activity PDFs',
          isLast: true,
          onTap: _showExportSheet,
        ),
      ],
    );
  }

  void _showDangerZoneSheet() {
    _showSettingsDetailSheet(
      title: 'Device & Session',
      icon: Icons.shield_outlined,
      iconColor: _C.red,
      subtitle: 'Device-only cleanup and sign-out actions',
      rows: [
        _buildRow(
          badgeColor: _C.red,
          badgeIcon: Icons.delete_outline_rounded,
          label: 'Clear Local Workspace',
          labelColor: _C.red,
          subtitle: 'Remove local records from this device only',
          isFirst: true,
          onTap: _showClearDataDialog,
        ),
        _buildRow(
          badgeColor: _C.red,
          badgeIcon: Icons.logout_rounded,
          label: 'Logout',
          labelColor: _C.red,
          subtitle: 'Return to the sign-in screen',
          isLast: true,
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }

  void _showSettingsDetailSheet({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String subtitle,
    required List<Widget> rows,
    Widget? footer,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        // White surface extends edge-to-edge at the bottom so there's
        // no gray gap behind the home indicator. SafeArea is moved
        // INSIDE the container to pad content above the indicator
        // without pulling the white surface up.
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              28 + MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _C.g200,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _C.g800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _C.g400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Column(children: _intersperse(rows)),
                ),
                if (footer != null) ...[const SizedBox(height: 16), footer],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, ctrl) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.g200,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Referral Language',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF2F4F7)),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: _languages.map((lang) {
                    final active = _language == lang;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: active ? _C.teal : _C.g100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            lang.substring(0, 1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: active ? Colors.white : _C.g400,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        lang,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: active ? _C.teal : const Color(0xFF1C1C1E),
                        ),
                      ),
                      trailing: active
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: _C.teal,
                              size: 22,
                            )
                          : null,
                      onTap: () async {
                        setState(() => _language = lang);
                        setSheet(() {});
                        final nav = Navigator.of(context);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('referral_language', lang);
                        if (context.mounted) nav.pop();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Switch.adaptive(
      value: value,
      onChanged: (next) {
        _haptic();
        onChanged(next);
      },
      activeTrackColor: _C.teal,
      inactiveTrackColor: _C.g200,
      thumbColor: WidgetStateProperty.all(Colors.white),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showToast(String msg, Color color) {
    VsToast.showText(context, msg, backgroundColor: color);
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _C.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _C.teal,
                  size: 24,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Clear Local Workspace',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _C.g800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This removes patient records, screenings, campaigns and queued sync work from this device. Your account stays available, and cloud data can be synced back after you sign in again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _C.g400,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: _C.g200, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _C.g500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await DatabaseHelper.instance.clearWorkspaceData();
                        if (mounted) {
                          _showToast(
                            'Local workspace cleared from this device.',
                            _C.teal,
                          );
                          await _loadProfile();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.teal,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _C.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: _C.teal,
                  size: 24,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _C.g800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _C.g400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: _C.g200, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _C.g500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final nav = Navigator.of(context, rootNavigator: true);
                        nav.pop();
                        VsToast.hide();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool(AppStrings.prefRememberMe, false);
                        await prefs.remove(AppStrings.prefRememberedEmail);
                        if (!mounted) return;
                        nav.pushNamedAndRemoveUntil('/login', (_) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.teal,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsOfService() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LegalSheet(
        title: 'Terms of Service',
        icon: Icons.gavel_rounded,
        iconColor: _C.teal,
        sections: termsOfServiceSections
            .map((section) => _LegalSection(section.heading, section.body))
            .toList(growable: false),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LegalSheet(
        title: 'Privacy Policy',
        icon: Icons.lock_outline_rounded,
        iconColor: const Color(0xFF38BDF8),
        sections: privacyPolicySections
            .map((section) => _LegalSection(section.heading, section.body))
            .toList(growable: false),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          // clipBehavior so the dark-gradient header's rectangular
          // edges are trimmed to the dialog's rounded outline.
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header: brand mark on dark ink gradient ──
              // Uses the actual VsLogo eye mark (onDark variant) so the
              // dialog carries real brand identity instead of a generic
              // eye icon. Radial teal halo behind the mark anchors it
              // visually against the dark backdrop.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_C.ink, _C.ink2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _C.teal.withValues(alpha: 0.32),
                            _C.teal.withValues(alpha: 0.0),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                      child: const Center(
                        child: VsLogo(size: 64, onDark: true),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Wordmark — matches the splash/login treatment.
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Vision',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'Screen',
                            style: TextStyle(color: _C.teal3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Quiet version chip — outlined, not filled, so it
                    // doesn't compete with the wordmark for attention.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Version 1.0.0',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Body: info rows ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  children: [
                    _aboutRow(
                      Icons.groups_rounded,
                      'Built for',
                      'Community health workers in Uganda',
                    ),
                    _aboutRow(
                      Icons.visibility_rounded,
                      'Test method',
                      'Tumbling E with LogMAR scoring',
                    ),
                    _aboutRow(
                      Icons.storage_rounded,
                      'Storage',
                      'SQLite on device',
                    ),
                    _aboutRow(
                      Icons.cloud_sync_rounded,
                      'Cloud sync',
                      _syncConfigured
                          ? 'MongoDB workspace enabled'
                          : 'Not configured in this build',
                    ),
                    _aboutRow(
                      Icons.support_agent_rounded,
                      'Support',
                      'support@visionscreen.ug',
                    ),
                  ],
                ),
              ),
              // ── Inline links ──
              // Replaces the three competing OutlinedButton.icon
              // widgets with quiet text links + bullet separators.
              // The dialog now ends on info, not button clutter.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _aboutLink("What's new", () {
                      Navigator.pop(context);
                      Future<void>.delayed(Duration.zero, _showChangelogSheet);
                    }),
                    _aboutDot(),
                    _aboutLink('Terms', () {
                      Navigator.pop(context);
                      Future<void>.delayed(Duration.zero, _showTermsOfService);
                    }),
                    _aboutDot(),
                    _aboutLink('Privacy', () {
                      Navigator.pop(context);
                      Future<void>.delayed(Duration.zero, _showPrivacyPolicy);
                    }),
                  ],
                ),
              ),
              // ── Close: subdued, divider-separated ──
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEF2F6)),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      'Close',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _C.teal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Inline text link used in the About dialog footer.
  Widget _aboutLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _C.teal,
          ),
        ),
      ),
    );
  }

  // Tiny bullet separator between About-dialog links.
  Widget _aboutDot() {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(color: _C.g300, shape: BoxShape.circle),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _C.g500),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: _C.g400)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.g800,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangelogSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _C.g200,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              "What's New in v1.0",
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.g800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Initial release - March 2026',
              style: GoogleFonts.inter(fontSize: 11, color: _C.g400),
            ),
            const SizedBox(height: 16),
            ...[
              'Tumbling E vision test with LogMAR scale',
              'Offline-first SQLite storage',
              'Atlas workspace sync and cloud backup',
              'Age-based clinical thresholds',
              'Structured referral document generation',
              'Bulk campaign screening mode',
              'Referral lifecycle tracking',
              'Multi-language referral support',
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _C.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _C.g800,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool currentVisible = false;
    bool newVisible = false;
    bool confirmVisible = false;
    bool loading = false;
    String? currentError;
    String? newError;
    String? confirmError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _C.g200,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Text(
                    'Change Password',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _C.g800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a strong password of at least 8 characters.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _C.g400,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Current password
                  _sheetFieldLabel('Current password'),
                  const SizedBox(height: 5),
                  _sheetPasswordField(
                    ctrl: currentCtrl,
                    hint: 'Enter current password',
                    visible: currentVisible,
                    error: currentError,
                    onToggle: () =>
                        setSheet(() => currentVisible = !currentVisible),
                    onChanged: (_) => setSheet(() => currentError = null),
                  ),
                  if (currentError != null) _sheetError(currentError!),
                  const SizedBox(height: 14),
                  // New password
                  _sheetFieldLabel('New password'),
                  const SizedBox(height: 5),
                  _sheetPasswordField(
                    ctrl: newCtrl,
                    hint: 'Enter new password',
                    visible: newVisible,
                    error: newError,
                    onToggle: () => setSheet(() => newVisible = !newVisible),
                    onChanged: (_) => setSheet(() => newError = null),
                  ),
                  if (newError != null) _sheetError(newError!),
                  const SizedBox(height: 14),
                  // Confirm password
                  _sheetFieldLabel('Confirm new password'),
                  const SizedBox(height: 5),
                  _sheetPasswordField(
                    ctrl: confirmCtrl,
                    hint: 'Re-enter new password',
                    visible: confirmVisible,
                    error: confirmError,
                    onToggle: () =>
                        setSheet(() => confirmVisible = !confirmVisible),
                    onChanged: (_) => setSheet(() => confirmError = null),
                  ),
                  if (confirmError != null) _sheetError(confirmError!),
                  const SizedBox(height: 24),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              String? ce, ne, co;
                              if (currentCtrl.text.isEmpty) {
                                ce = 'Current password is required';
                              }
                              if (newCtrl.text.length < 8) {
                                ne = 'Must be at least 8 characters';
                              }
                              if (confirmCtrl.text != newCtrl.text) {
                                co = 'Passwords do not match';
                              }
                              setSheet(() {
                                currentError = ce;
                                newError = ne;
                                confirmError = co;
                              });
                              if (ce != null || ne != null || co != null) {
                                return;
                              }
                              setSheet(() => loading = true);
                              // Verify current password and update via AuthRepository
                              final error = await AuthRepository.instance
                                  .changePassword(
                                    email: _chwEmail,
                                    currentPassword: currentCtrl.text,
                                    newPassword: newCtrl.text,
                                  );
                              if (error != null) {
                                setSheet(() {
                                  loading = false;
                                  currentError = error;
                                });
                                return;
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                _showToast(
                                  'Password updated successfully!',
                                  _C.teal,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Password',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    });
  }

  Widget _sheetFieldLabel(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _C.g500,
      letterSpacing: 0.8,
    ),
  );

  Widget _sheetError(String text) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, size: 13, color: _C.red),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _C.red,
          ),
        ),
      ],
    ),
  );

  Widget _sheetPasswordField({
    required TextEditingController ctrl,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
    required ValueChanged<String> onChanged,
    String? error,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: error != null ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: error != null ? _C.red : _C.g200, width: 1.5),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: !visible,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 13, color: _C.g800),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: _C.g300),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.lock_outline_rounded, size: 16, color: _C.g400),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: IconButton(
            tooltip: visible ? 'Hide password' : 'Show password',
            onPressed: onToggle,
            padding: const EdgeInsets.only(right: 12),
            icon: Icon(
              visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: _C.g400,
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 12,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _C.g200,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            // Title row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _C.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: _C.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export as PDF',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _C.g800,
                      ),
                    ),
                    Text(
                      'Choose a PDF to export',
                      style: GoogleFonts.inter(fontSize: 12, color: _C.g400),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF0F4F7)),
            const SizedBox(height: 16),
            // Option 1
            _exportOption(
              icon: Icons.people_outline_rounded,
              color: _C.teal,
              title: 'Patient Records',
              subtitle: 'All individual screenings, VA results & referrals',
              onTap: () {
                Navigator.pop(context);
                _exportPDF();
              },
            ),
            const SizedBox(height: 10),
            // Option 2
            _exportOption(
              icon: Icons.campaign_outlined,
              color: const Color(0xFF8B5CF6),
              title: 'Campaign Records',
              subtitle: 'All campaigns with patient summaries & stats',
              onTap: () {
                Navigator.pop(context);
                _exportCampaignPDF();
              },
            ),
            const SizedBox(height: 10),
            // Option 3
            _exportOption(
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Activity Report',
              subtitle: 'Screening activity, outcomes and referrals',
              onTap: () {
                Navigator.pop(context);
                _exportActivityPDF();
              },
            ),
            const SizedBox(height: 16),
            // Export all button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _exportPDF();
                  await _exportCampaignPDF();
                  await _exportActivityPDF();
                },
                icon: const Icon(
                  Icons.download_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  'Export All PDFs',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPDF() async {
    try {
      _showToast('Generating patient records PDF...', _C.teal);
      final file = await SettingsExportService.exportPatientRecordsPdf(
        SettingsExportProfile(
          chwName: _chwName,
          chwCenter: _chwCenter,
          chwDistrict: _chwDistrict,
          chwId: _chwId,
        ),
      );
      if (file == null) {
        _showToast('No patients to export.', _C.amber);
        return;
      }

      if (mounted) {
        _showToast(
          'Patient records PDF saved: ${file.path.split('/').last}',
          _C.green,
        );
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) _showToast('Export failed: ${e.toString()}', _C.red);
    }
  }

  Future<void> _exportCampaignPDF() async {
    try {
      _showToast('Generating campaign records PDF...', _C.teal);
      final file = await SettingsExportService.exportCampaignRecordsPdf(
        SettingsExportProfile(
          chwName: _chwName,
          chwCenter: _chwCenter,
          chwDistrict: _chwDistrict,
          chwId: _chwId,
        ),
      );
      if (file == null) {
        if (mounted) _showToast('No campaigns found to export.', _C.amber);
        return;
      }

      if (mounted) {
        _showToast(
          'Campaign PDF saved: ${file.path.split('/').last}',
          _C.green,
        );
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) _showToast('Export failed. Please try again.', _C.red);
    }
  }

  Future<void> _exportActivityPDF() async {
    try {
      _showToast('Generating activity report...', _C.teal);
      final file = await SettingsExportService.exportActivityPdf(
        SettingsExportProfile(
          chwName: _chwName,
          chwCenter: _chwCenter,
          chwDistrict: _chwDistrict,
          chwId: _chwId,
        ),
      );

      if (mounted) {
        _showToast(
          'Activity PDF saved: ${file.path.split('/').last}',
          _C.green,
        );
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) _showToast('Export failed: ${e.toString()}', _C.red);
    }
  }

  Widget _exportOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _C.g800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _C.g400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

// Reusable legal bottom sheet
class _LegalSheet extends StatelessWidget {
  const _LegalSheet({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.sections,
  });
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.g200,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _C.g800,
                          ),
                        ),
                        Text(
                          'VisionScreen | Community Screening',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _C.g400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  VsIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    onTap: () => Navigator.pop(context),
                    size: 32,
                    iconSize: 16,
                    foreground: _C.g500,
                    tint: _C.g100,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Divider(color: _C.g100, thickness: 1),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                itemCount: sections.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 18),
                itemBuilder: (_, i) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _C.teal.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sections[i].heading,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sections[i].body,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _C.g500,
                        height: 1.75,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
