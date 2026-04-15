import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // ── Editable fields ──────────────────────────────────────
  final _nameCtrl   = TextEditingController(text: 'Nakato Mary');
  final _centerCtrl = TextEditingController(text: 'Nakawa Health Centre III');
  final _chwIdCtrl  = TextEditingController(text: 'CHW-UG-00412');

  // ── Toggles ──────────────────────────────────────────────
  bool _offlineMode  = true;
  bool _smsNotifs    = false;
  bool _batterySaver = true;

  // ── Default Age Group ────────────────────────────────────
  String _defaultAgeGroup = 'Adult';
  static const _ageGroups = [
    {'label': 'Child',      'range': '6–12 yrs',  'threshold': '≥ 6/9',  'emoji': '🧒'},
    {'label': 'Adult',      'range': '13–60 yrs', 'threshold': '≥ 6/12', 'emoji': '👤'},
    {'label': 'Elderly',    'range': '60+ yrs',   'threshold': '≥ 6/18', 'emoji': '🧓'},
    {'label': 'Pre-school', 'range': '3–5 yrs',   'threshold': '≥ 6/12', 'emoji': '👶'},
  ];

  // ── Language ─────────────────────────────────────────────
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
    _nameCtrl.dispose();
    _centerCtrl.dispose();
    _chwIdCtrl.dispose();
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
      backgroundColor: _C.g50,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                children: [
                  _buildSection(
                    title: 'Profile Information',
                    children: [_buildProfileFields()],
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
                        onChanged: (v) => setState(() => _batterySaver = v),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _buildSection(
                    title: 'Default Age Group',
                    children: [_buildAgeGroupSelector()],
                  ),
                  const SizedBox(height: 11),
                  _buildSection(
                    title: 'Data Sync — MongoDB Atlas',
                    children: [
                      _buildSyncRow(),
                      _buildDivider(),
                      _buildArrowRow(emoji: '📤', emojiBg: _C.ice, label: 'Export All Data'),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _buildSection(
                    title: 'Actions',
                    children: [
                      _buildArrowRow(
                        emoji: '🗑️',
                        emojiBg: _C.rbg,
                        label: 'Clear All Local Data',
                        labelColor: _C.red,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Clearing all local data...',
                                style: GoogleFonts.sora(fontSize: 12)),
                            backgroundColor: _C.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 2),
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          ),
                        ),
                      ),
                      _buildDivider(),
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
                    title: 'About & Help',
                    children: [
                      _buildArrowRow(
                        emoji: 'ℹ️',
                        emojiBg: _C.ice,
                        label: 'About VisionScreen',
                        onTap: () => _showAboutDialog(),
                      ),
                      _buildDivider(),
                      _buildArrowRow(
                        emoji: '🎓',
                        emojiBg: _C.gbg,
                        label: 'Training Videos',
                        onTap: () => _showSnack('Opening training videos...', _C.teal),
                      ),
                      _buildDivider(),
                      _buildArrowRow(
                        emoji: '📞',
                        emojiBg: _C.abg,
                        label: 'Contact Support',
                        onTap: () => _showSnack('support@visionscreen.ug', _C.amber),
                      ),
                      _buildDivider(),
                      _buildArrowRow(
                        emoji: '📋',
                        emojiBg: Color(0xFFEDE9FE),
                        label: 'What\'s New in v1.0',
                        isLast: true,
                        onTap: () => _showChangelogSheet(),
                      ),
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── HEADER ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.ink, _C.ink2],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_C.teal, _C.teal2],
                  ),
                ),
                child: Center(
                  child: Text('NM',
                      style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nakato Mary',
                      style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('CHW · Nakawa Health Centre III',
                      style: GoogleFonts.sora(
                          fontSize: 11,
                          color: _C.teal3.withOpacity(0.55))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SECTION CARD ─────────────────────────────────────────
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.g200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 7),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _C.g100)),
            ),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.sora(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _C.g400,
                  letterSpacing: 1.0),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // ── PROFILE FIELDS ───────────────────────────────────────
  Widget _buildProfileFields() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Health Worker Name'),
          _textField(_nameCtrl),
          _fieldLabel('Health Center'),
          _textField(_centerCtrl),
          _fieldLabel('CHW ID / Badge Number'),
          _buildChwIdField(),
        ],
      ),
    );
  }

  Widget _buildChwIdField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: TextField(
        controller: _chwIdCtrl,
        style: GoogleFonts.sora(fontSize: 13, color: _C.g800),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.g200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.teal, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: _C.teal.withOpacity(0.25)),
                  ),
                  child: Text('Prints on referrals',
                      style: GoogleFonts.sora(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _C.teal)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(text,
            style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _C.g500,
                letterSpacing: 0.8)),
      );

  Widget _textField(TextEditingController ctrl, {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 13),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.sora(fontSize: 13, color: _C.g800),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.g200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.teal, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  // ── DEFAULT AGE GROUP ─────────────────────────────────────
  Widget _buildAgeGroupSelector() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pre-select the age group used most in your campaigns. This will be auto-selected when starting a new test.',
            style: GoogleFonts.sora(
                fontSize: 11, color: _C.g400, height: 1.6),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: _ageGroups.map((ag) {
              final selected = _defaultAgeGroup == ag['label'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _defaultAgeGroup = ag['label']!);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _C.teal.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? _C.teal : _C.g200,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(ag['emoji']!,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(ag['label']!,
                                style: GoogleFonts.sora(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? _C.teal
                                        : _C.g800)),
                            Text(ag['threshold']!,
                                style: GoogleFonts.sora(
                                    fontSize: 10,
                                    color: selected
                                        ? _C.teal
                                        : _C.g400)),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: _C.teal, size: 14),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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

  Widget _buildDivider() => const Padding(
        padding: EdgeInsets.only(left: 57),
        child: Divider(height: 1, color: _C.g100),
      );

  // ── BOTTOM NAV ───────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded,       'label': 'Home'},
      {'icon': Icons.people_alt_rounded, 'label': 'Patients'},
      {'icon': Icons.assignment_rounded, 'label': 'Referrals'},
      {'icon': Icons.bar_chart_rounded,  'label': 'Analytics'},
      {'icon': Icons.settings_rounded,   'label': 'Settings'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _C.g100, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, -3))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 18),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isActive = e.key == 4;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isActive) Navigator.maybePop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? _C.teal.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      e.value['icon'] as IconData,
                      size: isActive ? 22 : 20,
                      color: isActive ? _C.teal : _C.g400,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      e.value['label'] as String,
                      style: GoogleFonts.sora(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isActive ? _C.teal : _C.g400),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
