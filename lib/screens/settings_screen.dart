import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:printing/printing.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../db/database_helper.dart';

// â”€â”€ Colours â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  // â”€â”€ Profile (read-only, from registration) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      _eyeOrder = p.getString('eye_order') ?? 'Right â†’ Left';
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
  }

  void _haptic() {
    if (!_hapticFeedback) return;
    try { HapticFeedback.lightImpact(); } catch (_) {}
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

  // â”€â”€ Toggles â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _hapticFeedback = true;
  bool _brightnessLock = true;
  String _eyeOrder = 'Right â†’ Left';

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
                        
                      ],
                    ),
                    const SizedBox(height: 11),
                    _buildSection(
                      title: 'Screening',
                      children: [
                        
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
                          badgeIcon: Icons.picture_as_pdf_outlined,
                          label: 'Export as PDF',
                          subtitle: 'Printable report Â· MOH audit format',
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
                          onTap: () => _showLogoutDialog(),
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
                    // â”€â”€ Footer â”€â”€
                    Text(
                      'VisionScreen v1.0',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(fontSize: 11, color: _C.g400),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Made for Community Health Workers Â· Uganda',
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

  // â”€â”€ HEADER â€” Profile Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                    // Avatar â€” 64x64
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
                                ? '$_chwCenter Â· $_chwDistrict'
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
                              // CHW ID chip â€” always visible
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

  // â”€â”€ EDIT PROFILE SHEET â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  // â”€â”€ Profile photo picker â”€â”€
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
                              if (mounted) {
                                Navigator.pop(context);
                                _showSnack('Profile updated', _C.teal);
                              }
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

  // â”€â”€ SECTION CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ UNIFIED ROW BUILDER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ CHW BADGE ID ROW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  'CHW Badge ID Â· Prints on referrals',
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

  // â”€â”€ CUSTOM TOGGLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        _haptic();
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

  // â”€â”€ ABOUT & HELP HELPERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  void _showClearDataDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
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
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: _C.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: _C.teal, size: 24),
              ),
              const SizedBox(height: 14),
              Text('Clear All Data',
                  style: GoogleFonts.sora(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _C.g800)),
              const SizedBox(height: 6),
              Text(
                'This will permanently delete all patient records, screenings and referrals from this device. This cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                    fontSize: 12, color: _C.g400, height: 1.6),
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
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _C.g500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await DatabaseHelper.instance.clearAllData();
                        if (mounted) {
                          _showSnack('All local data cleared.', _C.teal);
                          await _loadProfile();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.teal,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text('Clear',
                          style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
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
      barrierColor: Colors.black.withOpacity(0.6),
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
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: _C.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: _C.teal, size: 24),
              ),
              const SizedBox(height: 14),
              Text('Logout',
                  style: GoogleFonts.sora(
                      fontSize: 17, fontWeight: FontWeight.w800, color: _C.g800)),
              const SizedBox(height: 6),
              Text('Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(fontSize: 12, color: _C.g400, height: 1.5)),
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
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.sora(
                              fontSize: 13, fontWeight: FontWeight.w700, color: _C.g500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.setBool('remember_me', false);
                          prefs.remove('remembered_email');
                          prefs.remove('remembered_password');
                          prefs.remove('remembered_role');
                        });
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/login', (_) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.teal,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text('Logout',
                          style: GoogleFonts.sora(
                              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
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
        sections: const [
          _LegalSection(
            '1. Purpose',
            'VisionScreen is a clinical-grade mobile application for trained Community Health Workers (CHWs) under the Uganda Ministry of Health (MOH) framework.',
          ),
          _LegalSection(
            '2. Authorised Use',
            'This application is authorised only for registered CHWs under a recognised Ugandan Health Centre (HC IIâ€“HC IV) and health administrators with valid MOH credentials.',
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
                      'ðŸ¥',
                      'Built for',
                      'Community Health Workers Â· Uganda',
                    ),
                    _aboutRow(
                      'ðŸ‘ï¸',
                      'Test Method',
                      'Tumbling E Â· LogMAR Scale',
                    ),
                    _aboutRow('ðŸ“±', 'Storage', 'SQLite (offline-first)'),
                    _aboutRow('â˜ï¸', 'Cloud Sync', 'MongoDB Atlas'),
                    _aboutRow('ðŸ“ž', 'Support', 'support@visionscreen.ug'),
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
              'Initial release Â· March 2026',
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
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: _C.g200, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            // Title row
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _C.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_outlined,
                      color: _C.teal, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export as PDF',
                        style: GoogleFonts.sora(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _C.g800)),
                    Text('Choose a report to generate',
                        style: GoogleFonts.sora(
                            fontSize: 12, color: _C.g400)),
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
              onTap: () { Navigator.pop(context); _exportPDF(); },
            ),
            const SizedBox(height: 10),
            // Option 2
            _exportOption(
              icon: Icons.campaign_outlined,
              color: const Color(0xFF8B5CF6),
              title: 'Campaign Records',
              subtitle: 'All campaigns with patient summaries & stats',
              onTap: () { Navigator.pop(context); _exportCampaignPDF(); },
            ),
            const SizedBox(height: 10),
            // Option 3
            _exportOption(
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Analytics Report',
              subtitle: 'Outcomes, age groups, acuity & village breakdown',
              onTap: () { Navigator.pop(context); _exportAnalyticsPDF(); },
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
                  await _exportAnalyticsPDF();
                },
                icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                label: Text('Export All Reports',
                    style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
      _showSnack('Generating patient records PDF...', _C.teal);

      final database = await DatabaseHelper.instance.db;
      final patients = await database.rawQuery('''
        SELECT p.*,
               s.od_snellen, s.os_snellen, s.ou_near_snellen,
               s.od_logmar, s.os_logmar,
               s.outcome, s.referral_facility, s.referral_status,
               s.appointment_date, s.screening_date, s.chw_name
        FROM patients p
        LEFT JOIN screenings s ON s.id = (
          SELECT id FROM screenings WHERE patient_id = p.id
          ORDER BY screening_date DESC LIMIT 1
        )
        ORDER BY p.created_at DESC
      ''');

      if (patients.isEmpty) {
        _showSnack('No patients to export.', _C.amber);
        return;
      }

      // â”€â”€ Colours â”€â”€
      final teal  = PdfColor.fromHex('#0D9488');
      final teal2 = PdfColor.fromHex('#CCFBF1');
      final g900  = PdfColor.fromHex('#0F172A');
      final g700  = PdfColor.fromHex('#334155');
      final g500  = PdfColor.fromHex('#64748B');
      final g200  = PdfColor.fromHex('#E2E8F0');
      final g50   = PdfColor.fromHex('#F8FAFC');
      final green = PdfColor.fromHex('#16A34A');
      final greenL= PdfColor.fromHex('#DCFCE7');
      final red   = PdfColor.fromHex('#DC2626');
      final redL  = PdfColor.fromHex('#FEE2E2');
      final amber = PdfColor.fromHex('#D97706');
      final amberL= PdfColor.fromHex('#FEF3C7');
      final blue  = PdfColor.fromHex('#2563EB');
      final white = PdfColors.white;

      // â”€â”€ Embedded fonts â”€â”€
      final fontR = await PdfGoogleFonts.nunitoRegular();
      final fontB = await PdfGoogleFonts.nunitoBold();

      pw.TextStyle ts(double size, PdfColor color, {bool bold = false}) =>
          pw.TextStyle(font: bold ? fontB : fontR, fontSize: size, color: color);

      final now     = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}';
      final timeStr = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';

      // â”€â”€ Helper: single info cell â”€â”€
      pw.Widget infoCell(String label, String value, PdfColor bg) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 4),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: pw.BoxDecoration(color: bg),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(label, style: ts(8, g500)),
            pw.SizedBox(height: 2),
            pw.Text(value.isNotEmpty ? value : 'N/A', style: ts(10, g900, bold: true)),
          ]),
        ),
      );

      // â”€â”€ Helper: outcome badge â”€â”€
      pw.Widget outcomeBadge(String outcome) {
        final label = outcome == 'pass' ? 'PASS' : outcome == 'refer' ? 'REFER' : 'PENDING';
        final color = outcome == 'pass' ? green : outcome == 'refer' ? red : amber;
        final bg    = outcome == 'pass' ? greenL : outcome == 'refer' ? redL : amberL;
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: pw.BoxDecoration(color: bg),
          child: pw.Text(label, style: ts(10, color, bold: true)),
        );
      }

      // â”€â”€ Helper: VA box â”€â”€
      pw.Widget vaBox(String eye, String? snellen, String? logmar) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(color: g50),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(eye, style: ts(8, g500, bold: true)),
            pw.SizedBox(height: 3),
            pw.Text(snellen?.isNotEmpty == true ? snellen! : 'N/A', style: ts(13, teal, bold: true)),
            if (logmar?.isNotEmpty == true)
              pw.Text('logMAR: $logmar', style: ts(8, g500)),
          ]),
        ),
      );

      // â”€â”€ Build one patient card widget â”€â”€
      pw.Widget patientCard(Map<String, dynamic> p, int index) {
        final name      = (p['name']    as String?) ?? 'Unknown';
        final age       = (p['age']     as int?)    ?? 0;
        final gender    = (p['gender']  as String?) ?? '';
        final village   = (p['village'] as String?) ?? '';
        final phone     = (p['phone']   as String?) ?? '';
        final pid       = (p['id']      as String?) ?? '';
        final outcome   = (p['outcome'] as String?) ?? 'pending';
        final odS       = (p['od_snellen']      as String?) ?? '';
        final osS       = (p['os_snellen']      as String?) ?? '';
        final ouS       = (p['ou_near_snellen'] as String?) ?? '';
        final odL       = (p['od_logmar']       as String?) ?? '';
        final osL       = (p['os_logmar']       as String?) ?? '';
        final scrDate   = (p['screening_date']  as String?) ?? '';
        final chwN      = (p['chw_name']        as String?) ?? _chwName;
        final facility  = (p['referral_facility'] as String?) ?? '';
        final apptDate  = (p['appointment_date']  as String?) ?? '';
        final refStatus = (p['referral_status']   as String?) ?? '';
        final conditions= (p['conditions']        as String?) ?? '';
        final isRefer   = outcome == 'refer';
        final accentColor = outcome == 'pass' ? green : outcome == 'refer' ? red : amber;
        final cardBg    = outcome == 'pass' ? greenL : outcome == 'refer' ? redL : amberL;

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 14),
          decoration: pw.BoxDecoration(
            color: white,
            border: pw.Border.all(color: accentColor, width: 1.5),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [

            // â”€â”€ Card header â”€â”€
            pw.Container(
              color: cardBg,
              padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(children: [
                    pw.Container(
                      width: 4,
                      height: 40,
                      decoration: pw.BoxDecoration(color: accentColor),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(name, style: ts(14, g900, bold: true)),
                      pw.SizedBox(height: 3),
                      pw.Text('$age yrs  |  $gender  |  $village', style: ts(10, g700)),
                    ]),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    outcomeBadge(outcome),
                    pw.SizedBox(height: 4),
                    pw.Text('ID: $pid', style: ts(8, g500)),
                  ]),
                ],
              ),
            ),

            // â”€â”€ Info row: phone + screening date + CHW â”€â”€
            pw.Container(
              color: g50,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: pw.Row(children: [
                infoCell('Phone', phone, g50),
                infoCell('Screened', scrDate.length >= 10 ? scrDate.substring(0, 10) : (scrDate.isNotEmpty ? scrDate : 'Not screened'), g50),
                infoCell('CHW', chwN, g50),
                if (conditions.isNotEmpty)
                  infoCell('Conditions', conditions, g50),
              ]),
            ),

            // â”€â”€ Visual Acuity â”€â”€
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Visual Acuity', style: ts(10, teal, bold: true)),
                pw.SizedBox(height: 5),
                pw.Row(children: [
                  vaBox('OD (Right Eye)', odS, odL),
                  pw.SizedBox(width: 6),
                  vaBox('OS (Left Eye)', osS, osL),
                  pw.SizedBox(width: 6),
                  vaBox('OU (Near)', ouS, null),
                ]),
              ]),
            ),

            // â”€â”€ Referral details (only if referred) â”€â”€
            if (isRefer) pw.Container(
              color: redL,
              padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Referral Details', style: ts(10, red, bold: true)),
                pw.SizedBox(height: 5),
                pw.Row(children: [
                  infoCell('Referral Facility', facility, redL),
                  infoCell('Appointment', apptDate.length >= 10 ? apptDate.substring(0, 10) : (apptDate.isNotEmpty ? apptDate : 'Not set'), redL),
                  infoCell('Referral Status', refStatus.isNotEmpty ? refStatus.toUpperCase() : 'PENDING', redL),
                ]),
              ]),
            ),
          ]),
        );
      }

      // â”€â”€ Build PDF â”€â”€
      final pdf = pw.Document();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 28),

        header: (ctx) => pw.Column(children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('VisionScreen Patient Records', style: ts(18, teal, bold: true)),
              pw.SizedBox(height: 3),
              pw.Text(
                '${_chwName.isNotEmpty ? _chwName : 'CHW'}  |  ${_chwCenter.isNotEmpty ? _chwCenter : _chwDistrict}  |  $dateStr  $timeStr',
                style: ts(10, g700),
              ),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: ts(10, g500)),
              pw.Text('${patients.length} patients  |  CHW ID: ${_chwId.isNotEmpty ? _chwId : 'N/A'}', style: ts(10, g500)),
            ]),
          ]),
          pw.SizedBox(height: 6),
          pw.Divider(color: teal, thickness: 2),
          pw.SizedBox(height: 8),
        ]),

        footer: (ctx) => pw.Column(children: [
          pw.Divider(color: g200, thickness: 1),
          pw.SizedBox(height: 3),
          pw.Text(
            'VisionScreen  |  Uganda MOH  |  WHO Compliant  |  Generated $dateStr at $timeStr',
            style: ts(8, g500),
            textAlign: pw.TextAlign.center,
          ),
        ]),

        build: (ctx) => [
          // Summary strip
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pw.BoxDecoration(color: teal2),
            child: pw.Row(children: [
              pw.Expanded(child: pw.Column(children: [
                pw.Text('${patients.length}', style: ts(20, teal, bold: true)),
                pw.Text('Total Patients', style: ts(9, g700, bold: true)),
              ])),
              pw.Expanded(child: pw.Column(children: [
                pw.Text('${patients.where((p) => p['outcome'] == 'pass').length}', style: ts(20, green, bold: true)),
                pw.Text('Passed', style: ts(9, g700, bold: true)),
              ])),
              pw.Expanded(child: pw.Column(children: [
                pw.Text('${patients.where((p) => p['outcome'] == 'refer').length}', style: ts(20, red, bold: true)),
                pw.Text('Referred', style: ts(9, g700, bold: true)),
              ])),
              pw.Expanded(child: pw.Column(children: [
                pw.Text('${patients.where((p) => p['outcome'] == null || p['outcome'] == 'pending').length}', style: ts(20, amber, bold: true)),
                pw.Text('Pending', style: ts(9, g700, bold: true)),
              ])),
            ]),
          ),
          pw.SizedBox(height: 16),

          // All patient cards â€” flow naturally across pages
          ...patients.asMap().entries.map((e) => patientCard(e.value, e.key)),
        ],
      ));

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/visionscreen_patients_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        _showSnack('Patient records PDF saved: ${file.path.split('/').last}', _C.green);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) _showSnack('Export failed: ${e.toString()}', _C.red);
    }
  }

    Future<void> _exportCampaignPDF() async {
    try {
      _showSnack('Generating campaign records PDF...', _C.teal);

      final database = await DatabaseHelper.instance.db;
      final campaigns = await database.query('campaigns', orderBy: 'created_at DESC');

      if (campaigns.isEmpty) {
        if (mounted) _showSnack('No campaigns found to export.', _C.amber);
        return;
      }

      final pdf = pw.Document();

      final teal  = PdfColor.fromHex('#0D9488');
      final teal2 = PdfColor.fromHex('#14B8A6');
      final ink   = PdfColor.fromHex('#04091A');
      final g400  = PdfColor.fromHex('#8FA0B4');
      final g800  = PdfColor.fromHex('#1A2A3D');
      final green = PdfColor.fromHex('#22C55E');
      final red   = PdfColor.fromHex('#EF4444');
      final amber = PdfColor.fromHex('#F59E0B');
      final white = PdfColors.white;
      final g100  = PdfColor.fromHex('#F0F4F7');
      final purple = PdfColor.fromHex('#8B5CF6');

      // â”€â”€ Cover page â”€â”€
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          build: (ctx) => pw.Container(
            color: ink,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.fromLTRB(40, 48, 40, 36),
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [purple, teal],
                      begin: pw.Alignment.centerLeft,
                      end: pw.Alignment.centerRight,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('VisionScreen',
                          style: pw.TextStyle(
                              fontSize: 32, fontWeight: pw.FontWeight.bold, color: white)),
                      pw.SizedBox(height: 6),
                      pw.Text('Campaign Records Export',
                          style: pw.TextStyle(fontSize: 16, color: white)),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 0),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfInfoRow('CHW Name', _chwName.isNotEmpty ? _chwName : 'â€”', g400, white),
                      _pdfInfoRow('Health Center', _chwCenter.isNotEmpty ? _chwCenter : 'â€”', g400, white),
                      _pdfInfoRow('District', _chwDistrict.isNotEmpty ? _chwDistrict : 'â€”', g400, white),
                      _pdfInfoRow('Badge ID', _chwId.isNotEmpty ? _chwId : 'â€”', g400, white),
                      _pdfInfoRow('Export Date', DateTime.now().toString().substring(0, 16), g400, white),
                      _pdfInfoRow('Total Campaigns', '${campaigns.length}', g400, white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // â”€â”€ One page per campaign â”€â”€
      for (final c in campaigns) {
        final campaignId = c['id'] as String;
        final total    = (c['total']    as int?) ?? 0;
        final passed   = (c['passed']   as int?) ?? 0;
        final referred = (c['referred'] as int?) ?? 0;
        final passRate = total > 0 ? (passed / total * 100).toStringAsFixed(1) : '0.0';

        // Fetch patients for this campaign
        final patients = await DatabaseHelper.instance.getPatientsForCampaign(campaignId);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 32),
            build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Campaign header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: purple,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(c['name'] as String? ?? 'â€”',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold, color: white)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${c['location']} Â· ${c['target_group']} Â· ${c['created_at'].toString().substring(0, 10)}',
                        style: pw.TextStyle(fontSize: 11, color: white),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Stats row
                pw.Row(
                  children: [
                    _pdfStatBox('Total', '$total', teal, white, g100),
                    pw.SizedBox(width: 8),
                    _pdfStatBox('Passed', '$passed', green, white, g100),
                    pw.SizedBox(width: 8),
                    _pdfStatBox('Referred', '$referred', red, white, g100),
                    pw.SizedBox(width: 8),
                    _pdfStatBox('Pass Rate', '$passRate%', amber, white, g100),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Patient table
                pw.Text('Patients',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold, color: teal)),
                pw.SizedBox(height: 8),
                // Table header
                pw.Container(
                  color: teal,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text('Name', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: white))),
                      pw.Expanded(flex: 1, child: pw.Text('Age', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: white))),
                      pw.Expanded(flex: 1, child: pw.Text('OD', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: white))),
                      pw.Expanded(flex: 1, child: pw.Text('OS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: white))),
                      pw.Expanded(flex: 2, child: pw.Text('Outcome', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: white))),
                    ],
                  ),
                ),
                // Table rows
                ...patients.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  final outcome = (p['outcome'] as String?) ?? 'pending';
                  final outcomeColor = outcome == 'pass' ? green : outcome == 'refer' ? red : amber;
                  final bg = i.isEven ? g100 : white;
                  return pw.Container(
                    color: bg,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 3, child: pw.Text(p['name'] as String? ?? 'â€”', style: pw.TextStyle(fontSize: 10, color: g800))),
                        pw.Expanded(flex: 1, child: pw.Text('${p['age']}', style: pw.TextStyle(fontSize: 10, color: g800))),
                        pw.Expanded(flex: 1, child: pw.Text(p['od_snellen'] as String? ?? 'â€”', style: pw.TextStyle(fontSize: 10, color: g800))),
                        pw.Expanded(flex: 1, child: pw.Text(p['os_snellen'] as String? ?? 'â€”', style: pw.TextStyle(fontSize: 10, color: g800))),
                        pw.Expanded(flex: 2, child: pw.Text(outcome.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: outcomeColor))),
                      ],
                    ),
                  );
                }),

                pw.Spacer(),
                pw.Divider(color: g400),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('VisionScreen Â· Uganda MOH', style: pw.TextStyle(fontSize: 9, color: g400)),
                    pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 9, color: g400)),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/visionscreen_campaigns_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        _showSnack('Campaign PDF saved: ${file.path.split('/').last}', _C.green);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) _showSnack('Export failed. Please try again.', _C.red);
    }
  }

  pw.Widget _pdfStatBox(String label, String value,
      PdfColor color, PdfColor white, PdfColor bg) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 2),
            pw.Text(label,
                style: pw.TextStyle(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAnalyticsPDF() async {
    try {
      _showSnack('Generating analytics report...', _C.teal);

      final outcomes   = await DatabaseHelper.instance.getOutcomeCounts();
      final ageGroups  = await DatabaseHelper.instance.getAgeGroupCounts();
      final genders    = await DatabaseHelper.instance.getGenderCounts();
      final acuity     = await DatabaseHelper.instance.getVisualAcuityDistribution();
      final referrals  = await DatabaseHelper.instance.getReferralStatusCounts();
      final conditions = await DatabaseHelper.instance.getConditionCounts();
      final villages   = await DatabaseHelper.instance.getVillageBreakdown();
      final severity   = await DatabaseHelper.instance.getSeverityClassification();
      final campaigns  = await DatabaseHelper.instance.getAllCampaigns();
      final condByAge  = await DatabaseHelper.instance.getConditionsByAgeGroup();

      final passed   = outcomes['pass']    ?? 0;
      final referred = outcomes['refer']   ?? 0;
      final pending  = outcomes['pending'] ?? 0;
      final screened = passed + referred;
      final total    = screened + pending;
      final passRate  = screened > 0 ? (passed  / screened * 100).toStringAsFixed(1) : '0.0';
      final referRate = screened > 0 ? (referred / screened * 100).toStringAsFixed(1) : '0.0';

      final now     = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}';
      final timeStr = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';

      final male   = genders['M'] ?? 0;
      final female = genders['F'] ?? 0;
      final gTotal = male + female;

      final campTotal    = campaigns.fold<int>(0, (s, c) => s + ((c['total']    as int?) ?? 0));
      final campPassed   = campaigns.fold<int>(0, (s, c) => s + ((c['passed']   as int?) ?? 0));
      final campReferred = campaigns.fold<int>(0, (s, c) => s + ((c['referred'] as int?) ?? 0));
      final overdue   = referrals['overdue']   ?? 0;
      final completed = referrals['completed'] ?? 0;
      final topCond    = conditions.isEmpty ? null : conditions.entries.reduce((a, b) => a.value > b.value ? a : b);
      final topVillage = villages.isEmpty ? null : villages.first;

      // ── Colours ──
      final teal  = PdfColor.fromHex('#0D9488');
      final teal2 = PdfColor.fromHex('#CCFBF1');
      final g900  = PdfColor.fromHex('#0F172A');
      final g700  = PdfColor.fromHex('#334155');
      final g500  = PdfColor.fromHex('#64748B');
      final g200  = PdfColor.fromHex('#E2E8F0');
      final g50   = PdfColor.fromHex('#F8FAFC');
      final green = PdfColor.fromHex('#16A34A');
      final greenL= PdfColor.fromHex('#DCFCE7');
      final red   = PdfColor.fromHex('#DC2626');
      final redL  = PdfColor.fromHex('#FEE2E2');
      final amber = PdfColor.fromHex('#D97706');
      final amberL= PdfColor.fromHex('#FEF3C7');
      final blue  = PdfColor.fromHex('#2563EB');
      final blueL = PdfColor.fromHex('#DBEAFE');
      final purp  = PdfColor.fromHex('#7C3AED');
      final purpL = PdfColor.fromHex('#EDE9FE');
      final white = PdfColors.white;

      // ── Fonts (embedded - fixes tofu boxes on all PDF viewers) ──
      final fontRegular = await PdfGoogleFonts.nunitoRegular();
      final fontBold    = await PdfGoogleFonts.nunitoBold();

      pw.TextStyle ts(double size, PdfColor color, {bool bold = false}) =>
          pw.TextStyle(font: bold ? fontBold : fontRegular, fontSize: size, color: color);

      // ── HELPERS ──

      // Section header
      pw.Widget secHeader(String title, PdfColor bg) => pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 18, bottom: 10),
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: pw.BoxDecoration(color: bg),
        child: pw.Text(title, style: ts(13, white, bold: true)),
      );

      // Stat card
      pw.Widget statCard(String label, String value, PdfColor accent, PdfColor bg) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          decoration: pw.BoxDecoration(color: bg),
          child: pw.Row(children: [
            pw.Container(width: 4, height: 52, decoration: pw.BoxDecoration(color: accent)),
            pw.SizedBox(width: 8),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(value, style: ts(20, accent, bold: true)),
              pw.Text(label, style: ts(9, g500)),
            ]),
          ]),
        ),
      );

      // Bar row
      pw.Widget barRow(String label, int count, int denom, PdfColor barColor, PdfColor barBg) {
        final pct = denom > 0 ? (count / denom).clamp(0.0, 1.0) : 0.0;
        const barW = 180.0;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 7),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.SizedBox(width: 130, child: pw.Text(label, style: ts(10, g700))),
            pw.SizedBox(width: 8),
            pw.Stack(children: [
              pw.Container(width: barW, height: 14, decoration: pw.BoxDecoration(color: barBg)),
              pw.Container(width: (pct * barW).clamp(2.0, barW), height: 14, decoration: pw.BoxDecoration(color: barColor)),
            ]),
            pw.SizedBox(width: 8),
            pw.Text('$count  (${(pct * 100).toStringAsFixed(0)}%)', style: ts(10, g900, bold: true)),
          ]),
        );
      }

      // Table header row
      pw.Widget tableHeader(List<(String, int)> cols, PdfColor bg) => pw.Container(
        color: bg,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: pw.Row(children: cols.map((c) => pw.Expanded(
          flex: c.$2,
          child: pw.Text(c.$1, style: ts(10, white, bold: true)),
        )).toList()),
      );

      // Table data row
      pw.Widget tableRow(List<(String, int, PdfColor)> cells, PdfColor bg) => pw.Container(
        color: bg,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: pw.Row(children: cells.map((c) => pw.Expanded(
          flex: c.$2,
          child: pw.Text(c.$1, style: ts(10, c.$3)),
        )).toList()),
      );

      // Insight row
      pw.Widget insightRow(String tag, String text, PdfColor accent, PdfColor bg) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        decoration: pw.BoxDecoration(color: bg),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(width: 4, decoration: pw.BoxDecoration(color: accent)),
          pw.SizedBox(width: 8),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: pw.BoxDecoration(color: accent),
              child: pw.Text(tag, style: ts(8, white, bold: true)),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(text, style: ts(10, g700)),
            ),
          ),
        ]),
      );

      // ── BUILD PDF ──
      final pdf = pw.Document();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 32),

        header: (ctx) => pw.Column(children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('VisionScreen Analytics Report', style: ts(18, teal, bold: true)),
              pw.SizedBox(height: 2),
              pw.Text(
                '${_chwName.isNotEmpty ? _chwName : 'CHW'}   |   ${_chwCenter.isNotEmpty ? _chwCenter : _chwDistrict}   |   $dateStr  $timeStr',
                style: ts(10, g500),
              ),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: ts(9, g500)),
              pw.SizedBox(height: 2),
              pw.Text('CHW ID: ${_chwId.isNotEmpty ? _chwId : 'N/A'}', style: ts(9, g500)),
            ]),
          ]),
          pw.SizedBox(height: 6),
          pw.Divider(color: teal, thickness: 2),
        ]),

        footer: (ctx) => pw.Column(children: [
          pw.Divider(color: g200, thickness: 1),
          pw.SizedBox(height: 4),
          pw.Text(
            'VisionScreen  |  Uganda MOH  |  WHO Compliant  |  Generated $dateStr at $timeStr',
            style: ts(8, g500),
            textAlign: pw.TextAlign.center,
          ),
        ]),

        build: (ctx) => [

          // ══════════════════════════════════════
          // 1. SCREENING SUMMARY
          // ══════════════════════════════════════
          secHeader('1.  Screening Summary', teal),
          pw.Row(children: [
            statCard('Total Patients',  '$total',    g900,  g50),
            statCard('Screened',        '$screened', teal,  teal2),
            statCard('Passed',          '$passed',   green, greenL),
            statCard('Referred',        '$referred', red,   redL),
            statCard('Pending',         '$pending',  amber, amberL),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            statCard('Pass Rate',       '$passRate%',  green, greenL),
            statCard('Referral Rate',   '$referRate%', red,   redL),
            statCard('Campaigns',       '${campaigns.length}', purp, purpL),
            statCard('Camp. Screened',  '$campTotal',  teal,  teal2),
            statCard('Overdue Refs',    '$overdue',    overdue > 0 ? red : g500, overdue > 0 ? redL : g50),
          ]),

          // ══════════════════════════════════════
          // 2. DEMOGRAPHICS
          // ══════════════════════════════════════
          secHeader('2.  Demographics', blue),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Age Groups', style: ts(11, g900, bold: true)),
              pw.SizedBox(height: 8),
              barRow('0 - 17  (Children)', ageGroups['0-17']  ?? 0, total, blue,  blueL),
              barRow('18 - 40  (Youth)',   ageGroups['18-40'] ?? 0, total, teal,  teal2),
              barRow('41 - 60  (Adults)',  ageGroups['41-60'] ?? 0, total, amber, amberL),
              barRow('60+  (Elderly)',     ageGroups['60+']   ?? 0, total, red,   redL),
            ])),
            pw.SizedBox(width: 20),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Gender', style: ts(11, g900, bold: true)),
              pw.SizedBox(height: 8),
              barRow('Male',   male,   gTotal > 0 ? gTotal : 1, blue,  blueL),
              barRow('Female', female, gTotal > 0 ? gTotal : 1, PdfColor.fromHex('#DB2777'), PdfColor.fromHex('#FCE7F3')),
              pw.SizedBox(height: 6),
              pw.Text('Total: $gTotal patients', style: ts(9, g500)),
            ])),
          ]),

          // ══════════════════════════════════════
          // 3. VISUAL ACUITY
          // ══════════════════════════════════════
          secHeader('3.  Visual Acuity Distribution', teal),
          pw.Text('Based on worst-eye Snellen result per patient.', style: ts(10, g500)),
          pw.SizedBox(height: 8),
          barRow('Normal  (6/6)',              acuity['Normal']      ?? 0, screened > 0 ? screened : 1, green, greenL),
          barRow('Near Normal  (6/9 - 6/12)',  acuity['Near Normal'] ?? 0, screened > 0 ? screened : 1, teal,  teal2),
          barRow('Moderate  (6/18 - 6/24)',    acuity['Moderate']    ?? 0, screened > 0 ? screened : 1, amber, amberL),
          barRow('Severe  (6/36 - 6/60)',      acuity['Severe']      ?? 0, screened > 0 ? screened : 1, red,   redL),
          barRow('Blind Range  (<6/60)',        acuity['Blind Range'] ?? 0, screened > 0 ? screened : 1, purp,  purpL),

          // ══════════════════════════════════════
          // 4. SEVERITY CLASSIFICATION
          // ══════════════════════════════════════
          secHeader('4.  Severity Classification', amber),
          pw.Text('Derived from worst-eye logMAR per patient.', style: ts(10, g500)),
          pw.SizedBox(height: 8),
          barRow('Normal',   severity['Normal']   ?? 0, screened > 0 ? screened : 1, green, greenL),
          barRow('Mild',     severity['Mild']     ?? 0, screened > 0 ? screened : 1, teal,  teal2),
          barRow('Moderate', severity['Moderate'] ?? 0, screened > 0 ? screened : 1, amber, amberL),
          barRow('Severe',   severity['Severe']   ?? 0, screened > 0 ? screened : 1, red,   redL),
          barRow('Critical', severity['Critical'] ?? 0, screened > 0 ? screened : 1, purp,  purpL),

          // ══════════════════════════════════════
          // 5. EYE CONDITIONS
          // ══════════════════════════════════════
          if (conditions.isNotEmpty) ...[
            secHeader('5.  Eye Conditions Reported', purp),
            pw.Text('CHW-observed symptoms - top ${conditions.length > 8 ? 8 : conditions.length} conditions.', style: ts(10, g500)),
            pw.SizedBox(height: 8),
            ...(conditions.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                .take(8)
                .map((e) => barRow(e.key, e.value, total > 0 ? total : 1, purp, purpL)),
          ],

          // ══════════════════════════════════════
          // 6. REFERRAL STATUS
          // ══════════════════════════════════════
          secHeader('6.  Referral Status Breakdown', red),
          pw.Text('Total referred: $referred patients.', style: ts(10, g500)),
          pw.SizedBox(height: 8),
          barRow('Pending',   referrals['pending']   ?? 0, referred > 0 ? referred : 1, amber, amberL),
          barRow('Notified',  referrals['notified']  ?? 0, referred > 0 ? referred : 1, blue,  blueL),
          barRow('Attended',  referrals['attended']  ?? 0, referred > 0 ? referred : 1, teal,  teal2),
          barRow('Completed', referrals['completed'] ?? 0, referred > 0 ? referred : 1, green, greenL),
          barRow('Overdue',   referrals['overdue']   ?? 0, referred > 0 ? referred : 1, red,   redL),
          barRow('Cancelled', referrals['cancelled'] ?? 0, referred > 0 ? referred : 1, g500,  g50),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            pw.Text('Completion rate: ', style: ts(10, g500)),
            pw.Text(referred > 0 ? '${(completed / referred * 100).toStringAsFixed(0)}%' : '0%', style: ts(10, green, bold: true)),
            pw.SizedBox(width: 20),
            pw.Text('Overdue rate: ', style: ts(10, g500)),
            pw.Text(referred > 0 ? '${(overdue / referred * 100).toStringAsFixed(0)}%' : '0%', style: ts(10, overdue > 0 ? red : g500, bold: true)),
          ]),

          // ══════════════════════════════════════
          // 7. VILLAGE BREAKDOWN
          // ══════════════════════════════════════
          if (villages.isNotEmpty) ...[
            secHeader('7.  Village / Location Breakdown', teal),
            tableHeader([('No.', 1), ('Village', 4), ('Total', 2), ('Referred', 2), ('Pass Rate', 2)], teal),
            ...villages.asMap().entries.map((e) {
              final i = e.key;
              final v = e.value;
              final vT = (v['total']    as int?) ?? 0;
              final vR = (v['referred'] as int?) ?? 0;
              final vP = vT - vR;
              final vRate = vT > 0 ? '${(vP / vT * 100).toStringAsFixed(0)}%' : '-';
              return tableRow([
                ('${i + 1}',              1, g500),
                (v['village'] as String,  4, g900),
                ('$vT',                   2, g900),
                ('$vR',                   2, vR > 0 ? red : g500),
                (vRate,                   2, teal),
              ], i.isEven ? g50 : white);
            }),
          ],

          // ══════════════════════════════════════
          // 8. CAMPAIGNS
          // ══════════════════════════════════════
          if (campaigns.isNotEmpty) ...[
            secHeader('8.  Campaign Outcomes', purp),
            tableHeader([('Campaign', 4), ('Screened', 2), ('Passed', 2), ('Referred', 2), ('Pass Rate', 2)], purp),
            ...campaigns.asMap().entries.map((e) {
              final i = e.key;
              final c = e.value;
              final ct = (c['total']    as int?) ?? 0;
              final cp = (c['passed']   as int?) ?? 0;
              final cr = (c['referred'] as int?) ?? 0;
              final cRate = ct > 0 ? '${(cp / ct * 100).toStringAsFixed(0)}%' : '-';
              return tableRow([
                (c['name'] as String, 4, g900),
                ('$ct',               2, g900),
                ('$cp',               2, green),
                ('$cr',               2, cr > 0 ? red : g500),
                (cRate,               2, teal),
              ], i.isEven ? g50 : white);
            }),
            pw.SizedBox(height: 6),
            pw.Text('Combined totals - Screened: $campTotal   |   Passed: $campPassed   |   Referred: $campReferred', style: ts(9, g500)),
          ],

          // ══════════════════════════════════════
          // 9. CONDITIONS BY AGE GROUP
          // ══════════════════════════════════════
          if (condByAge.isNotEmpty) ...[
            secHeader('9.  Conditions by Age Group', blue),
            tableHeader([('Condition', 4), ('0-17', 2), ('18-60', 2), ('60+', 2), ('Total', 2)], blue),
            ...(condByAge.entries.toList()
                  ..sort((a, b) {
                    final tA = a.value.values.fold(0, (s, v) => s + v);
                    final tB = b.value.values.fold(0, (s, v) => s + v);
                    return tB.compareTo(tA);
                  }))
                .take(10)
                .toList()
                .asMap()
                .entries
                .map((e) {
              final i  = e.key;
              final cn = e.value.key;
              final cv = e.value.value;
              final c0 = cv['0-17']  ?? 0;
              final c1 = cv['18-60'] ?? 0;
              final c2 = cv['60+']   ?? 0;
              return tableRow([
                (cn,       4, g900),
                ('$c0',    2, blue),
                ('$c1',    2, teal),
                ('$c2',    2, red),
                ('${c0+c1+c2}', 2, g900),
              ], i.isEven ? g50 : white);
            }),
          ],

          // ══════════════════════════════════════
          // 10. KEY INSIGHTS
          // ══════════════════════════════════════
          secHeader('10.  Key Insights & Recommendations', g900),
          pw.SizedBox(height: 4),
          if (screened == 0)
            insightRow('INFO', 'No screening data available. Start a new screening session to generate insights.', g500, g50)
          else ...[
            if (double.parse(passRate) >= 70)
              insightRow('POSITIVE', 'Pass rate of $passRate% is strong. Continue current screening protocols.', green, greenL)
            else
              insightRow('WARNING', 'Pass rate of $passRate% is below target (70%). Review screening quality and patient follow-up.', red, redL),
            if (overdue > 0)
              insightRow('URGENT', '$overdue referral${overdue == 1 ? '' : 's'} overdue - immediate follow-up required with ${overdue == 1 ? 'this patient' : 'these patients'}.', red, redL),
            if ((ageGroups['0-17'] ?? 0) > 0 && total > 0 && ((ageGroups['0-17']! / total) * 100) >= 20)
              insightRow('ACTION', 'Children (0-17) make up ${((ageGroups['0-17']! / total) * 100).toStringAsFixed(0)}% of patients - prioritise school and community outreach.', amber, amberL),
            if ((ageGroups['60+'] ?? 0) > 0 && total > 0 && ((ageGroups['60+']! / total) * 100) >= 15)
              insightRow('ACTION', 'Elderly (60+) represent ${((ageGroups['60+']! / total) * 100).toStringAsFixed(0)}% of screenings - ensure specialist referral pathways are in place.', amber, amberL),
            if (topCond != null)
              insightRow('INFO', '"${topCond.key}" is the most reported condition with ${topCond.value} cases - ensure CHWs are trained to identify and document it.', blue, blueL),
            if (topVillage != null)
              insightRow('INSIGHT', '"${topVillage['village']}" leads with ${topVillage['total']} patients screened - replicate this campaign model in lower-coverage locations.', purp, purpL),
            if (completed > 0 && referred > 0)
              insightRow('POSITIVE', 'Referral completion rate: ${(completed / referred * 100).toStringAsFixed(0)}% - $completed patient${completed == 1 ? '' : 's'} attended their appointment.', green, greenL),
          ],
          pw.SizedBox(height: 16),
        ],
      ));

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/visionscreen_analytics_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        _showSnack('Analytics PDF saved: ${file.path.split('/').last}', _C.green);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) _showSnack('Export failed: ${e.toString()}', _C.red);
    }
  }

    pw.Widget _pdfSectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }

  pw.Widget _pdfBarTable(Map<String, int> data, int total,
      PdfColor color, PdfColor bg, PdfColor textColor, PdfColor labelColor, PdfColor white) {
    if (data.isEmpty) {
      return pw.Text('No data available.',
          style: pw.TextStyle(fontSize: 11, color: labelColor));
    }
    return pw.Column(
      children: data.entries.map((e) {
        final pct = total > 0 ? e.value / total : 0.0;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 110,
                child: pw.Text(e.key,
                    style: pw.TextStyle(fontSize: 10, color: textColor)),
              ),
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    pw.Container(height: 14, color: bg),
                    pw.Container(
                      height: 14,
                      width: pct * 300,
                      color: color,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: textColor)),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _pdfInfoRow(String label, String value, PdfColor labelColor, PdfColor valueColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label,
                style: pw.TextStyle(fontSize: 11, color: labelColor)),
          ),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: valueColor)),
        ],
      ),
    );
  }

  pw.Widget _pdfVaBox(String eye, String snellen, String logmar,
      PdfColor teal, PdfColor white, PdfColor bg) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(eye,
                style: pw.TextStyle(fontSize: 9, color: teal)),
            pw.SizedBox(height: 4),
            pw.Text(snellen,
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: teal)),
            pw.Text('LogMAR: $logmar',
                style: pw.TextStyle(fontSize: 9, color: teal)),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfDetailRow(String label, String value,
      PdfColor valueColor, PdfColor labelColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(label,
                style: pw.TextStyle(fontSize: 11, color: labelColor)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: valueColor)),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
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
                  Text(title,
                      style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _C.g800)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: GoogleFonts.sora(
                          fontSize: 12, color: _C.g400, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 15, color: color.withValues(alpha: 0.5)),
          ],
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Reusable legal bottom sheet
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                          'VisionScreen Â· Uganda MOH',
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
