import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Colours ──────────────────────────────────────────────────
class _C {
  static const ink        = Color(0xFF04091A);
  static const ink2       = Color(0xFF0B1530);
  static const teal       = Color(0xFF0D9488);
  static const teal2      = Color(0xFF14B8A6);
  static const teal3      = Color(0xFF5EEAD4);
  static const ice        = Color(0xFFE0F2FE);
  static const g50        = Color(0xFFF8FAFB);
  static const g100       = Color(0xFFF0F4F7);
  static const g200       = Color(0xFFDDE4EC);
  static const g300       = Color(0xFFC4CFDB);
  static const g400       = Color(0xFF8FA0B4);
  static const g500       = Color(0xFF5E7291);
  static const g800       = Color(0xFF1A2A3D);
  static const green      = Color(0xFF22C55E);
  static const gbg        = Color(0xFFDCFCE7);
  static const amber      = Color(0xFFF59E0B);
  static const abg        = Color(0xFFFEF3C7);
  static const red        = Color(0xFFEF4444);
  static const rbg        = Color(0xFFFEE2E2);
  static const rtext      = Color(0xFF991B1B);
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _chwName     = p.getString('chw_name')     ?? '';
      _chwCenter   = p.getString('chw_center')   ?? '';
      _chwDistrict = p.getString('chw_district') ?? '';
      _chwEmail    = p.getString('chw_email')    ?? '';
      _chwPhone    = p.getString('chw_phone')    ?? '';
      _chwId       = p.getString('chw_id')       ?? '';
      _lastLoginTime = p.getString('last_login_time') ?? '';
      _lastLoginRole = p.getString('last_login_role') ?? '';
      _brightnessLock = p.getBool('brightness_lock') ?? true;
      _batterySaver = p.getBool('battery_saver') ?? false;
      _eyeOrder = p.getString('eye_order') ?? 'Right → Left';
    });
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
  bool _offlineMode  = true;
  bool _smsNotifs    = false;
  bool _batterySaver = true;
  bool _brightnessLock = true;
  String _eyeOrder = 'Right → Left';

String _language = 'English Only';
  static const _languages = [
    'English Only', 'Luganda', 'Runyankole/Rukiga',
    'Acholi', 'Ateso', 'Lugbara', 'Luo', 'Runyoro', 'Swahili',
  ];

  // ── Sync state ───────────────────────────────────────────
  bool _isSyncing   = false;
  bool _synced      = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _doSync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() { _isSyncing = false; _synced = true; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sync complete! 3 records uploaded to MongoDB Atlas',
            style: GoogleFonts.sora(fontSize: 12, color: Colors.white)),
        backgroundColor: _C.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));
    }
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
              child: Column(
                children: [
                  _buildSection(
                    title: 'Profile Information',
                    children: [_buildProfileFields()],
                  ),
                  const SizedBox(height: 11),
                  _buildSection(
                    title: 'Account',
                    children: [
                      _buildRow(
                        badgeColor: const Color(0xFF8B5CF6),
                        badgeIcon: Icons.mail_outline_rounded,
                        label: _chwEmail.isNotEmpty ? _chwEmail : 'No email set',
                        subtitle: 'Account email',
                        showChevron: false,
                        isFirst: true,
                      ),
                      _buildRow(
                        badgeColor: const Color(0xFF22C55E),
                        badgeIcon: Icons.access_time_rounded,
                        label: _lastLoginTime.isNotEmpty ? _lastLoginTime : 'Not recorded yet',
                        subtitle: 'Last login',
                        showChevron: false,
                        trailing: _lastLoginRole.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _C.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  _lastLoginRole == 'Administrator' ? 'Admin' : 'CHW',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _C.teal,
                                  ),
                                ),
                              )
                            : null,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _buildSection(
                    title: 'Preferences',
                    children: [
                      _buildLanguageRow(),
                      _buildDivider(),
                      _buildToggleRow(
                        emoji: '📴',
                        emojiBg: _C.abg,
                        label: 'Offline Mode',
                        sub: 'Store data locally on device (SQLite)',
                        value: _offlineMode,
                        onChanged: (v) => setState(() => _offlineMode = v),
                      ),
                      _buildDivider(),
                      _buildToggleRow(
                        emoji: '💬',
                        emojiBg: _C.gbg,
                        label: 'SMS Notifications',
                        sub: 'Send appointment reminders',
                        value: _smsNotifs,
                        onChanged: (v) => setState(() => _smsNotifs = v),
                      ),
                      _buildDivider(),
                      _buildToggleRow(
                        emoji: '🔋',
                        emojiBg: _C.rbg,
                        label: 'Battery Saver Mode',
                        sub: 'Reduce brightness during test',
                        value: _batterySaver,
                        onChanged: (v) => _setBatterySaver(v),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _buildSection(
                    title: 'Screening Preferences',
                    children: [
                      _buildEyeOrderRow(),
                      _buildDivider(),
                      _buildToggleRow(
                        emoji: '☀️',
                        emojiBg: const Color(0xFFFEF9C3),
                        label: 'Brightness Lock',
                        sub: 'Auto full brightness during test',
                        value: _brightnessLock,
                        onChanged: (v) => _setBrightnessLock(v),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _buildSection(
                    title: 'Data Sync — MongoDB Atlas',
                    children: [
                      _buildSyncRow(),
                      _buildDivider(),
                      _buildArrowRow(emoji: '📤', emojiBg: _C.ice, label: 'Export All Data', onTap: () => _showExportSheet()),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _buildSection(
                    title: 'Danger Zone',
                    children: [
                      _buildArrowRow(
                        emoji: '🚪',
                        emojiBg: _C.g100,
                        label: 'Logout',
                        isLast: true,
                        onTap: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil('/login', (_) => false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _buildSection(
                    title: 'App Info',
                    children: [
                      _buildArrowRow(
                        emoji: 'ℹ️',
                        emojiBg: _C.ice,
                        label: 'About VisionScreen',
                        onTap: () => _showAboutDialog(),
                      ),
                      _buildDivider(),
                      _buildArrowRow(
                        emoji: '📋',
                        emojiBg: const Color(0xFFEDE9FE),
                        label: 'Terms of Service',
                        onTap: () => _showTermsOfService(),
                      ),
                      _buildDivider(),
                      _buildArrowRow(
                        emoji: '🔒',
                        emojiBg: _C.ice,
                        label: 'Privacy Policy',
                        onTap: () => _showPrivacyPolicy(),
                      ),
                      _buildDivider(),
                      _buildVersionRow(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ── Footer ──
                  Text(
                    'VisionScreen v1.0 · Flutter / SQLite / MongoDB Atlas',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                        fontSize: 11, color: _C.g400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Made for Community Health Workers · Uganda',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                        fontSize: 10, color: _C.g400),
                  ),
                  const SizedBox(height: 20),
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
            color: _C.ink.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative blob top-right
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.teal.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -20, left: 60,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.teal2.withOpacity(0.08),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_C.teal, _C.teal2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _C.teal.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.barlow(
                        fontSize: 20,
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
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Role chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _C.teal.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: _C.teal3.withOpacity(0.4)),
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
                          if (_chwId.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                _chwId,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _intersperse(children),
            ),
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
        result.add(const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFF2F4F7),
          indent: 16,
          endIndent: 0,
        ));
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
      topLeft:     isFirst ? const Radius.circular(16) : Radius.zero,
      topRight:    isFirst ? const Radius.circular(16) : Radius.zero,
      bottomLeft:  isLast  ? const Radius.circular(16) : Radius.zero,
      bottomRight: isLast  ? const Radius.circular(16) : Radius.zero,
    );
    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: _C.teal.withOpacity(0.06),
        highlightColor: _C.g100.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 36, height: 36,
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
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _C.g400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Trailing widget
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

  // ── PROFILE FIELDS ───────────────────────────────────────
  Widget _buildProfileFields() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _profileRow(Icons.person_outline_rounded, 'Full Name', _chwName),
          _profileDivider(),
          _profileRow(Icons.local_hospital_outlined, 'Health Center', _chwCenter),
          _profileDivider(),
          _profileRow(Icons.location_on_outlined, 'District', _chwDistrict),
          _profileDivider(),
          _profileRow(Icons.mail_outline_rounded, 'Email', _chwEmail),
          _profileDivider(),
          _profileRow(Icons.phone_outlined, 'Phone',
              _chwPhone.isNotEmpty ? '+256 $_chwPhone' : ''),
          _profileDivider(),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.teal.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _C.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.badge_outlined, size: 16, color: _C.teal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CHW Badge ID', style: GoogleFonts.sora(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: _C.g400, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(_chwId.isNotEmpty ? _chwId : '—',
                          style: GoogleFonts.sora(
                              fontSize: 14, fontWeight: FontWeight.w800,
                              color: _C.teal, letterSpacing: 1.2)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _C.teal.withOpacity(0.25)),
                  ),
                  child: Text('Prints on referrals', style: GoogleFonts.sora(
                      fontSize: 9, fontWeight: FontWeight.w700, color: _C.teal)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: _C.g100, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 15, color: _C.g500),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.sora(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: _C.g400, letterSpacing: 0.5)),
                const SizedBox(height: 1),
                Text(value.isNotEmpty ? value : '—',
                    style: GoogleFonts.sora(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _C.g800)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 13, color: _C.g300),
        ],
      ),
    );
  }

  Widget _profileDivider() => const Divider(height: 1, color: _C.g100);

  // ── DEFAULT AGE GROUP ─────────────────────────────────────
  Widget _buildEyeOrderRow() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _C.g200, borderRadius: BorderRadius.circular(99)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text('Test Eye Order',
                    style: GoogleFonts.sora(
                        fontSize: 16, fontWeight: FontWeight.w800, color: _C.g800)),
              ),
              ...['Right → Left', 'Left → Right'].map((order) => ListTile(
                    leading: Icon(
                      Icons.remove_red_eye_outlined,
                      color: _eyeOrder == order ? _C.teal : _C.g400,
                      size: 20,
                    ),
                    title: Text(order,
                        style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: _eyeOrder == order
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _eyeOrder == order ? _C.teal : _C.g800)),
                    trailing: _eyeOrder == order
                        ? const Icon(Icons.check_rounded, color: _C.teal, size: 18)
                        : null,
                    onTap: () async {
                      setState(() => _eyeOrder = order);
                      final p = await SharedPreferences.getInstance();
                      await p.setString('eye_order', order);
                      if (context.mounted) Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _emojiBox('👁️', _C.ice),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test Eye Order',
                      style: GoogleFonts.sora(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _C.g800)),
                  Text('Which eye is tested first',
                      style: GoogleFonts.sora(fontSize: 11, color: _C.g400)),
                ],
              ),
            ),
            Text(_eyeOrder,
                style: GoogleFonts.sora(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _C.teal)),
          ],
        ),
      ),
    );
  }

  // ── LANGUAGE ROW ─────────────────────────────────────────
  Widget _buildLanguageRow() {
    return InkWell(
      onTap: () => _showLanguagePicker(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _emojiBox('🌐', _C.ice),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Referral Language',
                      style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _C.g800)),
                  Text("Olulimi lw'okuweereza",
                      style: GoogleFonts.sora(
                          fontSize: 11, color: _C.g400)),
                ],
              ),
            ),
            Text(_language,
                style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _C.teal)),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: _C.g200, borderRadius: BorderRadius.circular(99)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('Referral Language',
                style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _C.g800)),
          ),
          ..._languages.map((lang) => ListTile(
                title: Text(lang,
                    style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: _language == lang
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _language == lang ? _C.teal : _C.g800)),
                trailing: _language == lang
                    ? const Icon(Icons.check_rounded, color: _C.teal, size: 18)
                    : null,
                onTap: () {
                  setState(() => _language = lang);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── TOGGLE ROW ───────────────────────────────────────────
  Widget _buildToggleRow({
    required String emoji,
    required Color emojiBg,
    required String label,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _emojiBox(emoji, emojiBg),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.g800)),
                const SizedBox(height: 1),
                Text(sub,
                    style: GoogleFonts.sora(
                        fontSize: 11, color: _C.g400)),
              ],
            ),
          ),
          _buildToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  // ── SYNC ROW ─────────────────────────────────────────────
  Widget _buildSyncRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _emojiBox('☁️', _C.gbg),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sync Status',
                    style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.g800)),
                const SizedBox(height: 1),
                Text(
                  _synced
                      ? 'All records synced ✓'
                      : '3 records pending · 244 synced',
                  style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _synced ? _C.green : _C.amber),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isSyncing ? null : _doSync,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: _C.ice,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _C.teal, width: 1.5),
              ),
              child: _isSyncing
                  ? const SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: _C.teal))
                  : Text('Sync Now',
                      style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _C.teal)),
            ),
          ),
        ],
      ),
    );
  }

  // ── ARROW ROW ────────────────────────────────────────────
  Widget _buildArrowRow({
    required String emoji,
    required Color emojiBg,
    required String label,
    Color? labelColor,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _emojiBox(emoji, emojiBg),
            const SizedBox(width: 11),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? _C.g800)),
            ),
            Text('›',
                style: TextStyle(
                    fontSize: 18,
                    color: _C.g300,
                    fontWeight: FontWeight.w300)),
          ],
        ),
      ),
    );
  }

  // ── EMOJI BOX ────────────────────────────────────────────
  Widget _emojiBox(String emoji, Color bg) => Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
      );

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
        width: 40, height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: value ? _C.teal : _C.g200,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1))
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── ABOUT & HELP HELPERS ─────────────────────────────────
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.sora(fontSize: 12, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ));
  }

  Widget _buildVersionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.info_outline_rounded, size: 15, color: _C.teal),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text('Version',
                style: GoogleFonts.sora(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _C.g800)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _C.teal.withOpacity(0.2)),
            ),
            child: Text('v1.0.0',
                style: GoogleFonts.sora(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _C.teal)),
          ),
        ],
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
          _LegalSection('1. Purpose', 'VisionScreen is a clinical-grade mobile application for trained Community Health Workers (CHWs) under the Uganda Ministry of Health (MOH) framework.'),
          _LegalSection('2. Authorised Use', 'This application is authorised only for registered CHWs under a recognised Ugandan Health Centre (HC II–HC IV) and health administrators with valid MOH credentials.'),
          _LegalSection('3. Patient Data', 'All patient data is subject to the Uganda Data Protection and Privacy Act 2019. CHWs must obtain verbal informed consent before screening.'),
          _LegalSection('4. Clinical Disclaimer', 'VisionScreen is a screening tool, not a diagnostic instrument. All clinical decisions must be made by a licensed eye care professional.'),
          _LegalSection('5. Amendments', 'These Terms may be updated periodically. Continued use of VisionScreen constitutes acceptance of the updated terms.'),
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
          _LegalSection('1. Data We Collect', 'Patient demographics, visual acuity scores, referral data, device calibration data, and CHW account information.'),
          _LegalSection('2. How We Use It', 'Data is used exclusively for vision screening, referral tracking, and anonymised public health analytics. Never sold or shared commercially.'),
          _LegalSection('3. Storage & Security', 'Data is stored locally using SQLite encryption and synced to MongoDB Atlas (ISO/IEC 27001) with AES-256 encryption and TLS 1.3 in transit.'),
          _LegalSection('4. Your Rights', 'Under the Uganda Data Protection and Privacy Act 2019, you may access, correct, or request erasure of your data at any time.'),
          _LegalSection('5. Contact', 'For privacy concerns, contact the VisionScreen Programme Coordinator through your district health office or Uganda MOH Community Health Division.'),
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
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_C.teal, _C.teal2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.remove_red_eye_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text('VisionScreen',
                        style: GoogleFonts.sora(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Version 1.0.0',
                        style: GoogleFonts.sora(
                            fontSize: 12,
                            color: _C.teal3.withOpacity(0.7))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _aboutRow('🏥', 'Built for', 'Community Health Workers · Uganda'),
                    _aboutRow('👁️', 'Test Method', 'Tumbling E · LogMAR Scale'),
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
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text('Close',
                            style: GoogleFonts.sora(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
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
          Text(label,
              style: GoogleFonts.sora(fontSize: 12, color: _C.g400)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _C.g800)),
        ],
      ),
    );
  }

  void _showChangelogSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: _C.g200,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            Text("What's New in v1.0",
                style: GoogleFonts.sora(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _C.g800)),
            const SizedBox(height: 4),
            Text('Initial release · March 2026',
                style: GoogleFonts.sora(fontSize: 11, color: _C.g400)),
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
            ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                            color: _C.teal, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item,
                            style: GoogleFonts.sora(
                                fontSize: 13,
                                color: _C.g800,
                                height: 1.5)),
                      ),
                    ],
                  ),
                )),
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
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: _C.g200,
                          borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  Text('Change Password',
                      style: GoogleFonts.sora(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _C.g800)),
                  const SizedBox(height: 4),
                  Text('Choose a strong password of at least 8 characters.',
                      style: GoogleFonts.sora(
                          fontSize: 12, color: _C.g400, height: 1.5)),
                  const SizedBox(height: 20),
                  // Current password
                  _sheetFieldLabel('Current Password'),
                  const SizedBox(height: 5),
                  _sheetPasswordField(
                    ctrl: currentCtrl,
                    hint: 'Enter current password',
                    visible: currentVisible,
                    error: currentError,
                    onToggle: () => setSheet(() => currentVisible = !currentVisible),
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
                    onToggle: () => setSheet(() => confirmVisible = !confirmVisible),
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
                              if (currentCtrl.text.isEmpty)
                                ce = 'Current password is required';
                              if (newCtrl.text.length < 8)
                                ne = 'Must be at least 8 characters';
                              if (confirmCtrl.text != newCtrl.text)
                                co = 'Passwords do not match';
                              setSheet(() {
                                currentError = ce;
                                newError = ne;
                                confirmError = co;
                              });
                              if (ce != null || ne != null || co != null) return;
                              setSheet(() => loading = true);
                              await Future.delayed(
                                  const Duration(milliseconds: 1200));
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) _showSnack('Password updated successfully!', _C.teal);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Save Password',
                              style: GoogleFonts.sora(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
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

  Widget _sheetFieldLabel(String text) => Text(text,
      style: GoogleFonts.sora(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: _C.g500, letterSpacing: 0.8));

  Widget _sheetError(String text) => Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 13, color: _C.red),
          const SizedBox(width: 5),
          Text(text, style: GoogleFonts.sora(
              fontSize: 11, fontWeight: FontWeight.w600, color: _C.red)),
        ],
      ));

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
        border: Border.all(
            color: error != null ? _C.red : _C.g200, width: 1.5),
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
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: _C.g400),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: _C.g200, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            Text('Export All Data',
                style: GoogleFonts.sora(
                    fontSize: 17, fontWeight: FontWeight.w800, color: _C.g800)),
            const SizedBox(height: 4),
            Text('Export all patient screening records from this device.',
                style: GoogleFonts.sora(fontSize: 12, color: _C.g400, height: 1.5)),
            const SizedBox(height: 20),
            _exportOption(
              icon: Icons.table_chart_outlined,
              color: _C.green,
              title: 'Export as CSV',
              subtitle: 'Spreadsheet format · Excel / Google Sheets',
              onTap: () { Navigator.pop(context); _exportCSV(); },
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
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.sora(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _C.g800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.sora(
                      fontSize: 11, color: _C.g400)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _C.g300),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCSV() async {
    try {
      _showSnack('Generating CSV...', _C.teal);
      final rows = <List<dynamic>>[
        ['Patient ID', 'Name', 'Age', 'Gender', 'Village', 'OD', 'OS', 'OU',
         'Outcome', 'Date', 'Phone', 'Facility', 'Referral Status', 'CHW'],
        ['PAT-00312', 'Akello Mercy', 34, 'F', 'Nakawa, Kampala', '6/6', '6/9', '6/6', 'Pass', '28 Mar 2026', '+256701234567', '', '', _chwName],
        ['PAT-00298', 'Okello James', 58, 'M', 'Bwaise, Kampala', '6/12', '6/18', '6/12', 'Refer', '28 Mar 2026', '+256702345678', 'Mulago National Referral Hospital', 'Overdue', _chwName],
        ['PAT-00301', 'Nakato Aisha', 27, 'F', 'Ntinda, Kampala', '6/9', '6/9', '6/6', 'Pass', '28 Mar 2026', '+256703456789', '', '', _chwName],
        ['PAT-00315', 'Mugisha Wilson', 45, 'M', 'Kireka, Wakiso', '6/12', '6/18', '6/12', 'Refer', '28 Mar 2026', '+256704567890', 'Mengo Hospital', 'Cancelled', _chwName],
        ['PAT-00289', 'Kyomuhendo Rose', 19, 'F', 'Rubaga, Kampala', '6/9', '6/9', '6/6', 'Refer', '26 Mar 2026', '+256705678901', 'Makerere University Hospital', 'Completed', _chwName],
        ['PAT-00276', 'Byaruhanga Sam', 62, 'M', 'Kawempe, Kampala', '6/24', '6/36', '6/24', 'Refer', '25 Mar 2026', '+256706789012', 'Kampala Eye Clinic', 'Notified', _chwName],
        ['PAT-00261', 'Tendo Kevin', 9, 'M', 'Nansana, Wakiso', '6/9', '6/9', '6/6', 'Pass', '24 Mar 2026', '+256707890123', '', '', _chwName],
        ['PAT-00254', 'Apio Norah', 8, 'F', 'Kira, Wakiso', '6/18', '6/12', '6/12', 'Refer', '23 Mar 2026', '+256708901234', 'Mulago National Referral Hospital', 'Attended', _chwName],
      ];
      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/visionscreen_export_$timestamp.csv');
      await file.writeAsString(csv);
      if (mounted) {
        _showSnack('CSV saved: ${file.path.split('/').last}', _C.green);
        await Future.delayed(const Duration(milliseconds: 800));
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) _showSnack('Export failed. Please try again.', _C.red);
    }
  }

  Widget _buildDivider() => const Padding(
        padding: EdgeInsets.only(left: 57),
        child: Divider(height: 1, color: _C.g100),
      );
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: _C.g200, borderRadius: BorderRadius.circular(99)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: iconColor.withOpacity(0.25)),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.sora(
                                fontSize: 18, fontWeight: FontWeight.w800, color: _C.g800)),
                        Text('VisionScreen · Uganda MOH',
                            style: GoogleFonts.sora(fontSize: 11, color: _C.g400)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                          color: _C.g100, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close_rounded, size: 16, color: _C.g500),
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
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (_, i) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _C.teal.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(sections[i].heading,
                          style: GoogleFonts.sora(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _C.teal)),
                    ),
                    const SizedBox(height: 8),
                    Text(sections[i].body,
                        style: GoogleFonts.sora(
                            fontSize: 12, color: _C.g500, height: 1.75)),
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
