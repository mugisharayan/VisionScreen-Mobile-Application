import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../db/database_helper.dart';

// ── Colours ──────────────────────────────────────────────────
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Profile (read-only, from registration) ──────────────
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _chwName = p.getString('chw_name') ?? '';
      _chwCenter = p.getString('chw_center') ?? '';
      _chwDistrict = p.getString('chw_district') ?? '';
      _chwEmail = p.getString('chw_email') ?? '';
      _chwPhone = p.getString('chw_phone') ?? '';
      _chwId = p.getString('chw_id') ?? '';
      _lastLoginTime = p.getString('last_login_time') ?? '';
      _lastLoginRole = p.getString('last_login_role') ?? '';
      _brightnessLock = p.getBool('brightness_lock') ?? true;
      _batterySaver = p.getBool('battery_saver') ?? false;
      _eyeOrder = p.getString('eye_order') ?? 'Right → Left';
      _hapticFeedback = p.getBool('haptic_feedback') ?? true;
      _language = p.getString('referral_language') ?? 'English Only';
      _chwPhoto = p.getString('chw_photo') ?? '';
    });
    final count = await DatabaseHelper.instance.getUnsyncedCount();
    if (!mounted) return;
    setState(() => _unsyncedCount = count);
  }

  Future<void> _setHapticFeedback(bool value) async {
    setState(() => _hapticFeedback = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_feedback', value);
    if (value) HapticFeedback.selectionClick();
  }

  Future<void> _setBatterySaver(bool value) async {
    setState(() => _batterySaver = value);
    final p = await SharedPreferences.getInstance();
    await p.setBool('battery_saver', value);
    try {
      if (value) {
        await ScreenBrightness().setScreenBrightness(0.3);
      } else {
        await ScreenBrightness().resetScreenBrightness();
      }
    } catch (_) {}
  }

  Future<void> _setBrightnessLock(bool value) async {
    setState(() => _brightnessLock = value);
    final p = await SharedPreferences.getInstance();
    await p.setBool('brightness_lock', value);
    try {
      if (value) {
        await ScreenBrightness().setScreenBrightness(1.0);
      } else {
        await ScreenBrightness().resetScreenBrightness();
      }
    } catch (_) {}
  }

  // ── Toggles ──────────────────────────────────────────────
  bool _hapticFeedback = true;
  bool _batterySaver = true;
  bool _brightnessLock = true;
  String _eyeOrder = 'Right → Left';

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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            // Teal separator line
            Container(
              height: 1,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.teal.withValues(alpha: 0.0),
                    _C.teal.withValues(alpha: 0.35),
                    _C.teal.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
                child: Column(
                  children: [
                    _buildSection(
                      title: 'Profile',
                      children: [
                        _buildRow(
                          badgeColor: const Color(0xFF6366F1),
                          badgeIcon: Icons.person_outline_rounded,
                          label: _chwName.isNotEmpty ? _chwName : 'Not set',
                          subtitle: 'Full name',
                          showChevron: false,
                          isFirst: true,
                        ),
                        _buildRow(
                          badgeColor: _C.teal,
                          badgeIcon: Icons.local_hospital_outlined,
                          label: _chwCenter.isNotEmpty ? _chwCenter : 'Not set',
                          subtitle: 'Health center',
                          showChevron: false,
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
                        _buildChwIdRow(),
                      ],
                    ),
                    const SizedBox(height: 11),
                    _buildSection(
                      title: 'Account',
                      children: [
                        _buildRow(
                          badgeColor: const Color(0xFF22C55E),
                          badgeIcon: Icons.access_time_rounded,
                          label: _lastLoginTime.isNotEmpty
                              ? _lastLoginTime
                              : 'Not recorded yet',
                          subtitle: 'Last login',
                          showChevron: false,
                          isFirst: true,
                          trailing: _lastLoginRole.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _C.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    _lastLoginRole == 'Administrator'
                                        ? 'Admin'
                                        : 'CHW',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _C.teal,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        _buildRow(
                          badgeColor: const Color(0xFF6366F1),
                          badgeIcon: Icons.lock_outline_rounded,
                          label: 'Change Password',
                          subtitle: 'Update your account password',
                          isLast: true,
                          onTap: () => _showChangePasswordSheet(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    _buildSection(
                      title: 'Preferences',
                      children: [
                        _buildRow(
                          badgeColor: const Color(0xFF3B82F6),
                          badgeIcon: Icons.language_rounded,
                          label: 'Referral Language',
                          subtitle: _language,
                          isFirst: true,
                          onTap: () => _showLanguagePicker(),
                        ),
                        _buildRow(
                          badgeColor: const Color(0xFFF59E0B),
                          badgeIcon: Icons.vibration_rounded,
                          label: 'Haptic Feedback',
                          subtitle: 'Vibrate on actions',
                          showChevron: false,
                          trailing: _buildToggle(
                            value: _hapticFeedback,
                            onChanged: _setHapticFeedback,
                          ),
                        ),
                        _buildRow(
                          badgeColor: const Color(0xFFEF4444),
                          badgeIcon: Icons.battery_saver_rounded,
                          label: 'Battery Saver',
                          subtitle: 'Reduce brightness during screening',
                          showChevron: false,
                          isLast: true,
                          trailing: _buildToggle(
                            value: _batterySaver,
                            onChanged: _setBatterySaver,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    _buildSection(
                      title: 'Screening',
                      children: [
                        _buildRow(
                          badgeColor: _C.teal,
                          badgeIcon: Icons.remove_red_eye_outlined,
                          label: 'Test Eye Order',
                          subtitle: _eyeOrder,
                          isFirst: true,
                          onTap: () => _showEyeOrderPicker(),
                        ),
                        _buildRow(
                          badgeColor: const Color(0xFFEAB308),
                          badgeIcon: Icons.wb_sunny_rounded,
                          label: 'Brightness Lock',
                          subtitle: 'Auto full brightness during test',
                          showChevron: false,
                          isLast: true,
                          trailing: _buildToggle(
                            value: _brightnessLock,
                            onChanged: _setBrightnessLock,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    _buildSection(
                      title: 'Data & Sync',
                      children: [
                        _buildRow(
                          badgeColor: const Color(0xFF22C55E),
                          badgeIcon: Icons.cloud_outlined,
                          label: 'Sync Status',
                          subtitle: _unsyncedCount == 0 ? 'All records synced' : '$_unsyncedCount record${_unsyncedCount == 1 ? '' : 's'} pending sync',
                          showChevron: false,
                          isFirst: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _unsyncedCount == 0
                                  ? _C.green.withValues(alpha: 0.1)
                                  : _C.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              _unsyncedCount == 0 ? 'Synced' : 'Pending',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _unsyncedCount == 0 ? _C.green : _C.amber,
                              ),
                            ),
                          ),
                        ),
                        _buildRow(
                          badgeColor: const Color(0xFF3B82F6),
                          badgeIcon: Icons.download_rounded,
                          label: 'Export as CSV',
                          subtitle: 'Spreadsheet · Excel / Google Sheets',
                          isLast: true,
                          onTap: () => _showExportSheet(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    _buildSection(
                      title: 'Danger Zone',
                      children: [
                        _buildRow(
                          badgeColor: const Color(0xFFEF4444),
                          badgeIcon: Icons.delete_outline_rounded,
                          label: 'Clear All Data',
                          labelColor: const Color(0xFFEF4444),
                          subtitle: 'Permanently wipe all local records',
                          isFirst: true,
                          onTap: () => _showClearDataDialog(),
                        ),
                        _buildRow(
                          badgeColor: const Color(0xFFEF4444),
                          badgeIcon: Icons.logout_rounded,
                          label: 'Logout',
                          labelColor: const Color(0xFFEF4444),
                          isLast: true,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/login', (_) => false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    _buildSection(
                      title: 'App Info',
                      children: [
                        _buildRow(
                          badgeColor: _C.teal,
                          badgeIcon: Icons.info_outline_rounded,
                          label: 'About VisionScreen',
                          isFirst: true,
                          onTap: () => _showAboutDialog(),
                        ),
                        _buildRow(
                          badgeColor: const Color(0xFF8B5CF6),
                          badgeIcon: Icons.auto_awesome_rounded,
                          label: "What's New",
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _C.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'NEW',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _C.amber,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          onTap: () => _showChangelogSheet(),
                        ),
                        _buildRow(
                          badgeColor: const Color(0xFF1A2A3D),
                          badgeIcon: Icons.gavel_rounded,
                          label: 'Terms of Service',
                          onTap: () => _showTermsOfService(),
                        ),
                        _buildRow(
                          badgeColor: const Color(0xFF1A2A3D),
                          badgeIcon: Icons.lock_outline_rounded,
                          label: 'Privacy Policy',
                          onTap: () => _showPrivacyPolicy(),
                        ),
                        _buildRow(
                          badgeColor: _C.teal,
                          badgeIcon: Icons.tag_rounded,
                          label: 'Version',
                          showChevron: false,
                          isLast: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _C.teal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'v1.0.0',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _C.teal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // ── Footer ──
                    Text(
                      'VisionScreen v1.0',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(fontSize: 11, color: _C.g400),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Made for Community Health Workers · Uganda',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(fontSize: 10, color: _C.g400),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  // ── HEADER — Profile Card ──────────────────────────────
  Widget _buildHeader() {
    final initials = _chwName.trim().isNotEmpty
        ? _chwName.trim().split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase()
        : 'VS';
    final roleLabel = _lastLoginRole == 'Administrator' ? 'Admin' : 'CHW';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.ink, _C.ink2],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.ink.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative blob top-right
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _C.teal.withValues(alpha: 0.22),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Decorative blob bottom-left
          Positioned(
            bottom: -30, left: 40,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _C.teal2.withValues(alpha: 0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar — 64x64
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_C.teal, _C.teal2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _C.teal.withValues(alpha: 0.55),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _chwPhoto.isNotEmpty
                          ? ClipOval(
                              child: Image.file(
                                File(_chwPhoto),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Center(
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.barlow(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.barlow(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Info
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
                                ? '$_chwCenter · $_chwDistrict'
                                : 'Community Health Worker',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          // Phone number
                          if (_chwPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '+256 $_chwPhone',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Role chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _C.teal.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                      color: _C.teal3.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  roleLabel,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _C.teal3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // CHW ID chip — always visible
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  _chwId.isNotEmpty ? _chwId : 'No ID assigned',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _chwId.isNotEmpty
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : Colors.white.withValues(alpha: 0.3),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Edit button
                    GestureDetector(
                      onTap: _showEditProfileSheet,
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── EDIT PROFILE SHEET ─────────────────────────────────────────
  void _showEditProfileSheet() {
    final nameCtrl     = TextEditingController(text: _chwName);
    final centerCtrl   = TextEditingController(text: _chwCenter);
    final districtCtrl = TextEditingController(text: _chwDistrict);
    final emailCtrl    = TextEditingController(text: _chwEmail);
    final phoneCtrl    = TextEditingController(text: _chwPhone);
    String photoPath   = _chwPhoto;
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
                20, 16, 20,
                32 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
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
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _C.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_rounded, color: _C.teal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Profile',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: _C.g800,
                                )),
                            Text('Changes saved to this device',
                                style: GoogleFonts.inter(fontSize: 11, color: _C.g400)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ── Profile photo picker ──
                  Center(
                    child: StatefulBuilder(
                      builder: (_, setPhoto) => GestureDetector(
                        onTap: () async {
                          final source = await showModalBottomSheet<ImageSource>(
                            context: ctx,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (sheetCtx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                                    width: 40, height: 4,
                                    decoration: BoxDecoration(
                                      color: _C.g200,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  ListTile(
                                    leading: Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: _C.teal.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, color: _C.teal, size: 18),
                                    ),
                                    title: Text('Take a photo', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: _C.g800)),
                                    onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
                                  ),
                                  ListTile(
                                    leading: Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.photo_library_rounded, color: Color(0xFF3B82F6), size: 18),
                                    ),
                                    title: Text('Choose from gallery', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: _C.g800)),
                                    onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
                                  ),
                                  if (photoPath.isNotEmpty)
                                    ListTile(
                                      leading: Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          color: _C.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.delete_outline_rounded, color: _C.red, size: 18),
                                      ),
                                      title: Text('Remove photo', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: _C.red)),
                                      onTap: () => Navigator.pop(sheetCtx, null),
                                    ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          );
                          if (source == null && photoPath.isNotEmpty) {
                            setPhoto(() => photoPath = '');
                            setSheet(() {});
                            return;
                          }
                          if (source == null) return;
                          final picked = await picker.pickImage(
                            source: source,
                            imageQuality: 80,
                            maxWidth: 400,
                          );
                          if (picked != null) {
                            setPhoto(() => photoPath = picked.path);
                            setSheet(() {});
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 80, height: 80,
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
                                        width: 80, height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => Center(
                                          child: Text(
                                            nameCtrl.text.trim().isEmpty ? 'VS'
                                                : nameCtrl.text.trim().split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase(),
                                            style: GoogleFonts.barlow(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        nameCtrl.text.trim().isEmpty ? 'VS'
                                            : nameCtrl.text.trim().split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase(),
                                        style: GoogleFonts.barlow(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 26, height: 26,
                                decoration: BoxDecoration(
                                  color: _C.teal,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _editField(nameCtrl, 'Full Name', Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _editField(centerCtrl, 'Health Center', Icons.local_hospital_outlined),
                  const SizedBox(height: 12),
                  _editField(districtCtrl, 'District', Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  _editField(emailCtrl, 'Email', Icons.mail_outline_rounded,
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _editField(phoneCtrl, 'Phone (9 digits)', Icons.phone_outlined,
                      keyboard: TextInputType.phone),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheet(() => saving = true);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('chw_name', nameCtrl.text.trim());
                              await prefs.setString('chw_center', centerCtrl.text.trim());
                              await prefs.setString('chw_district', districtCtrl.text.trim());
                              await prefs.setString('chw_email', emailCtrl.text.trim());
                              await prefs.setString('chw_phone', phoneCtrl.text.trim());
                              await prefs.setString('chw_photo', photoPath);
                              if (_chwEmail.isNotEmpty) {
                                final db = await DatabaseHelper.instance.db;
                                await db.update(
                                  'chw_profiles',
                                  {
                                    'name':     nameCtrl.text.trim(),
                                    'center':   centerCtrl.text.trim(),
                                    'district': districtCtrl.text.trim(),
                                    'email':    emailCtrl.text.trim().toLowerCase(),
                                    'phone':    phoneCtrl.text.trim(),
                                  },
                                  where: 'email = ?',
                                  whereArgs: [_chwEmail.toLowerCase()],
                                );
                              }
                              await _loadProfile();
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) { _showSnack('Profile updated', _C.teal); }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Save Changes',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.ibmPlexSans(
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
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ── SECTION CARD ─────────────────────────────────────────
  // Renders a labelled group: uppercase label above + white card with rows
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _C.g400,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
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

  // ── UNIFIED ROW BUILDER ───────────────────────────────────────
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
        onTap: onTap,
        borderRadius: radius,
        splashColor: _C.teal.withValues(alpha: 0.06),
        highlightColor: _C.g100.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(badgeIcon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 14),
              // Label + optional subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
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

  // ── CHW BADGE ID ROW ───────────────────────────────────────────
  Widget _buildChwIdRow() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _C.teal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.badge_outlined, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _chwId.isNotEmpty ? _chwId : 'No ID assigned',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _chwId.isNotEmpty
                        ? const Color(0xFF1C1C1E)
                        : _C.g400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'CHW Badge ID · Prints on referrals',
                  style: GoogleFonts.inter(fontSize: 12, color: _C.g400),
                ),
              ],
            ),
          ),
          if (_chwId.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _C.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Active',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _C.teal,
                ),
              ),
            ),
        ],
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
                width: 40, height: 4,
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
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language_rounded,
                          size: 18, color: Colors.white),
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: active ? _C.teal : _C.g100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            lang.substring(0, 1),
                            style: GoogleFonts.barlow(
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
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          color: active
                              ? _C.teal
                              : const Color(0xFF1C1C1E),
                        ),
                      ),
                      trailing: active
                          ? Icon(Icons.check_circle_rounded,
                              color: _C.teal, size: 22)
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

  // ── CUSTOM TOGGLE ────────────────────────────────────────
  Widget _buildToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: value ? _C.teal : _C.g200,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── ABOUT & HELP HELPERS ─────────────────────────────────
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.sora(fontSize: 12, color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
        sections: const [
          _LegalSection(
            '1. Purpose',
            'VisionScreen is a clinical-grade mobile application for trained Community Health Workers (CHWs) under the Uganda Ministry of Health (MOH) framework.',
          ),
          _LegalSection(
            '2. Authorised Use',
            'This application is authorised only for registered CHWs under a recognised Ugandan Health Centre (HC II–HC IV) and health administrators with valid MOH credentials.',
          ),
          _LegalSection(
            '3. Patient Data',
            'All patient data is subject to the Uganda Data Protection and Privacy Act 2019. CHWs must obtain verbal informed consent before screening.',
          ),
          _LegalSection(
            '4. Clinical Disclaimer',
            'VisionScreen is a screening tool, not a diagnostic instrument. All clinical decisions must be made by a licensed eye care professional.',
          ),
          _LegalSection(
            '5. Amendments',
            'These Terms may be updated periodically. Continued use of VisionScreen constitutes acceptance of the updated terms.',
          ),
        ],
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
        sections: const [
          _LegalSection(
            '1. Data We Collect',
            'Patient demographics, visual acuity scores, referral data, device calibration data, and CHW account information.',
          ),
          _LegalSection(
            '2. How We Use It',
            'Data is used exclusively for vision screening, referral tracking, and anonymised public health analytics. Never sold or shared commercially.',
          ),
          _LegalSection(
            '3. Storage & Security',
            'Data is stored locally using SQLite encryption and synced to MongoDB Atlas (ISO/IEC 27001) with AES-256 encryption and TLS 1.3 in transit.',
          ),
          _LegalSection(
            '4. Your Rights',
            'Under the Uganda Data Protection and Privacy Act 2019, you may access, correct, or request erasure of your data at any time.',
          ),
          _LegalSection(
            '5. Contact',
            'For privacy concerns, contact the VisionScreen Programme Coordinator through your district health office or Uganda MOH Community Health Division.',
          ),
        ],
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_C.ink, _C.ink2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_C.teal, _C.teal2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.remove_red_eye_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'VisionScreen',
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: _C.teal3.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _aboutRow(
                      '🏥',
                      'Built for',
                      'Community Health Workers · Uganda',
                    ),
                    _aboutRow(
                      '👁️',
                      'Test Method',
                      'Tumbling E · LogMAR Scale',
                    ),
                    _aboutRow('📱', 'Storage', 'SQLite (offline-first)'),
                    _aboutRow('☁️', 'Cloud Sync', 'MongoDB Atlas'),
                    _aboutRow('📞', 'Support', 'support@visionscreen.ug'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.teal,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.sora(fontSize: 12, color: _C.g400)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.sora(
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
              style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.g800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Initial release · March 2026',
              style: GoogleFonts.sora(fontSize: 11, color: _C.g400),
            ),
            const SizedBox(height: 16),
            ...[
              'Tumbling E vision test with LogMAR scale',
              'Offline-first SQLite storage',
              'MongoDB Atlas cloud sync',
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
                        style: GoogleFonts.sora(
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
                    style: GoogleFonts.sora(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _C.g800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a strong password of at least 8 characters.',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: _C.g400,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Current password
                  _sheetFieldLabel('Current Password'),
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
                  _sheetFieldLabel('New Password'),
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
                  _sheetFieldLabel('Confirm New Password'),
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
                              if (currentCtrl.text.isEmpty) { ce = 'Current password is required'; }
                              if (newCtrl.text.length < 8) { ne = 'Must be at least 8 characters'; }
                              if (confirmCtrl.text != newCtrl.text) { co = 'Passwords do not match'; }
                              setSheet(() {
                                currentError = ce;
                                newError = ne;
                                confirmError = co;
                              });
                              if (ce != null || ne != null || co != null) { return; }
                              setSheet(() => loading = true);
                              // Verify current password against DB
                              final profile = await DatabaseHelper.instance
                                  .getChwProfileByEmail(_chwEmail);
                              if (profile == null ||
                                  profile['password'] != currentCtrl.text) {
                                setSheet(() {
                                  loading = false;
                                  currentError = 'Incorrect current password';
                                });
                                return;
                              }
                              // Update password in DB
                              final db = await DatabaseHelper.instance.db;
                              await db.update(
                                'chw_profiles',
                                {'password': newCtrl.text},
                                where: 'email = ?',
                                whereArgs: [_chwEmail.toLowerCase()],
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                _showSnack('Password updated successfully!', _C.teal);
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
                              style: GoogleFonts.sora(
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
    style: GoogleFonts.sora(
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
          style: GoogleFonts.sora(
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
        style: GoogleFonts.sora(fontSize: 13, color: _C.g800),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sora(fontSize: 13, color: _C.g300),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.lock_outline_rounded, size: 16, color: _C.g400),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: _C.g400,
              ),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              'Export All Data',
              style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.g800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Export all patient screening records from this device.',
              style: GoogleFonts.sora(
                fontSize: 12,
                color: _C.g400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _exportOption(
              icon: Icons.table_chart_outlined,
              color: _C.green,
              title: 'Export as CSV',
              subtitle: 'Spreadsheet format · Excel / Google Sheets',
              onTap: () {
                Navigator.pop(context);
                _exportCSV();
              },
            ),
            const SizedBox(height: 12),
            _exportOption(
              icon: Icons.picture_as_pdf_outlined,
              color: _C.red,
              title: 'Export as PDF',
              subtitle: 'Printable report · MOH audit format',
              onTap: () {
                Navigator.pop(context);
                _showSnack('PDF export coming soon', _C.amber);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.g200, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.g800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.sora(fontSize: 11, color: _C.g400),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: _C.g300,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCSV() async {
    try {
      _showSnack('Generating CSV...', _C.teal);
      final screenings = await DatabaseHelper.instance.getRecentScreeningsWithPatient(limit: 10000);
      final rows = <List<dynamic>>[
        ['Patient ID', 'Name', 'Age', 'Gender', 'Village', 'Phone',
         'OD', 'OS', 'OU (Near)', 'Outcome', 'Date',
         'Referral Facility', 'Referral Status', 'Appointment', 'CHW'],
      ];
      for (final r in screenings) {
        rows.add([
          r['patient_id'] ?? '',
          r['name'] ?? '',
          r['age'] ?? '',
          r['gender'] ?? '',
          r['village'] ?? '',
          r['phone'] ?? '',
          r['od_snellen'] ?? '',
          r['os_snellen'] ?? '',
          r['ou_near_snellen'] ?? '',
          (r['outcome'] as String? ?? '').toUpperCase(),
          r['screening_date'] ?? '',
          r['referral_facility'] ?? '',
          r['referral_status'] ?? '',
          r['appointment_date'] ?? '',
          r['chw_name'] ?? _chwName,
        ]);
      }
      if (rows.length == 1) {
        if (mounted) _showSnack('No screening records to export', _C.amber);
        return;
      }
      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/visionscreen_export_$timestamp.csv');
      await file.writeAsString(csv);
      if (mounted) {
        _showSnack('Exported ${rows.length - 1} records', _C.green);
        await Future.delayed(const Duration(milliseconds: 600));
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) { _showSnack('Export failed. Please try again.', _C.red); }
    }
  }

  void _showEyeOrderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
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
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _C.teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.remove_red_eye_outlined,
                        size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Test Eye Order',
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
            ...['Right → Left', 'Left → Right'].map((order) {
              final active = _eyeOrder == order;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: active ? _C.teal : _C.g100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.remove_red_eye_outlined,
                    size: 18,
                    color: active ? Colors.white : _C.g400,
                  ),
                ),
                title: Text(
                  order,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? _C.teal : const Color(0xFF1C1C1E),
                  ),
                ),
                trailing: active
                    ? Icon(Icons.check_circle_rounded,
                        color: _C.teal, size: 22)
                    : null,
                onTap: () async {
                  setState(() => _eyeOrder = order);
                  setSheet(() {});
                  final nav = Navigator.of(context);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('eye_order', order);
                  if (context.mounted) nav.pop();
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Clear All Data',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all patient records, campaigns, and referral history. This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, color: _C.g500, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _C.g400,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final db = await DatabaseHelper.instance.db;
              await db.delete('screenings');
              await db.delete('patients');
              await db.delete('campaigns');
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await _loadProfile();
              if (mounted) { _showSnack('All data cleared', const Color(0xFFEF4444)); }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────
// Legal section data
// ─────────────────────────────────────────────────────────────
class _LegalSection {
  const _LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

// ─────────────────────────────────────────────────────────────
// Reusable legal bottom sheet
// ─────────────────────────────────────────────────────────────
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
                      border: Border.all(color: iconColor.withValues(alpha: 0.25)),
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
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _C.g800,
                          ),
                        ),
                        Text(
                          'VisionScreen · Uganda MOH',
                          style: GoogleFonts.sora(fontSize: 11, color: _C.g400),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _C.g100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: _C.g500,
                      ),
                    ),
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
                separatorBuilder: (context, index) => const SizedBox(height: 18),
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
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sections[i].body,
                      style: GoogleFonts.sora(
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
