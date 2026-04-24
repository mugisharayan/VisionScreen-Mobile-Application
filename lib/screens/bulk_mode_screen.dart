import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';

const _ink   = Color(0xFF04091A);
const _ink2  = Color(0xFF0B1530);
const _teal  = Color(0xFF0D9488);
const _teal2 = Color(0xFF14B8A6);
const _teal3 = Color(0xFF5EEAD4);
const _amber = Color(0xFFF59E0B);
const _red   = Color(0xFFEF4444);
const _green = Color(0xFF22C55E);

class BulkModeScreen extends StatefulWidget {
  const BulkModeScreen({super.key});

  @override
  State<BulkModeScreen> createState() => _BulkModeScreenState();
}

class _BulkBoundingBox extends CustomPainter {
  final double size;
  const _BulkBoundingBox({required this.size});
  @override
  void paint(Canvas canvas, Size canvasSize) {
    final strokeW = size / 5;
    final gap     = size / 2;
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;
    final half = size / 2 + gap + strokeW / 2;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: half * 2, height: half * 2);
    canvas.drawRect(rect, Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = strokeW);
  }
  @override bool shouldRepaint(_BulkBoundingBox o) => o.size != size;
}

class _BulkTumblingE extends CustomPainter {
  final Color color;
  const _BulkTumblingE({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.height / 5;
    final p = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, u, size.height), p);
    canvas.drawRect(Rect.fromLTWH(0, 0, u * 4, u), p);
    canvas.drawRect(Rect.fromLTWH(0, u * 2, u * 4, u), p);
    canvas.drawRect(Rect.fromLTWH(0, u * 4, u * 4, u), p);
  }
  @override bool shouldRepaint(_BulkTumblingE o) => o.color != color;
}

class _BulkModeScreenState extends State<BulkModeScreen> {
  // ── Section 1: Session Setup ─────────────────────────────
  int _section = 0; // 0=setup, 1=screening loop (coming next)

  final _campaignNameCtrl = TextEditingController();
  final _locationCtrl     = TextEditingController();
  String _targetGroup     = 'Mixed';
  bool   _saving          = false;
  String? _campaignId;

  // ── Section 2 state ─────────────────────────────────────
  int    _patientCount    = 0;
  final  _nameCtrl        = TextEditingController();
  int    _quickAge        = 10;
  String _quickGender     = 'M';
  bool   _registering     = false;
  String? _currentPatientId;

  // ── Section 3: Eye test state ────────────────────────────
  static const _eyeOrder = ['OD', 'OS'];
  static const _staircaseJumps = [0, 2, 5, 8, 10];
  static const _rows = [
    {'logmar': '1.0', 'mm': 29.10}, {'logmar': '0.9', 'mm': 23.12},
    {'logmar': '0.8', 'mm': 18.36}, {'logmar': '0.7', 'mm': 14.59},
    {'logmar': '0.6', 'mm': 11.59}, {'logmar': '0.5', 'mm':  9.21},
    {'logmar': '0.4', 'mm':  7.31}, {'logmar': '0.3', 'mm':  5.81},
    {'logmar': '0.2', 'mm':  4.61}, {'logmar': '0.1', 'mm':  3.66},
    {'logmar': '0.0', 'mm':  2.91},
  ];

  int _eyeIndex       = 0;
  int _currentRow     = 0;
  int _rotation       = 0;
  int _letterIndex    = 0;
  int _correctCount   = 0;
  int _lastPassedRow  = 0;
  int _jumpIndex      = 0;
  bool _jumpPhase     = true;
  int _cantTell       = 0;
  List<Map<String,dynamic>> _eyeResults = [];
  final _facilityCtrl = TextEditingController();
  String? _selectedFacility;
  DateTime? _appointmentDate;

  static const _facilities = [
    'Mulago National Referral Hospital Eye Clinic',
    'Kampala Eye Clinic',
    'Mengo Hospital Eye Department',
    'Kibuli Muslim Hospital Eye Clinic',
    'St. Francis Hospital Nsambya Eye Clinic',
    'Jinja Regional Referral Hospital',
    'Mbarara Regional Referral Hospital',
    'Gulu Regional Referral Hospital',
    'Other (specify below)',
  ];

  // ── Section 6: Summary state ─────────────────────────────
  List<Map<String,dynamic>> _sessionPatients = [];
  bool _loadingSummary = false;

  Timer?  _testTimer;
  int     _testSeconds = 0;

  String get _testDuration {
    final m = _testSeconds ~/ 60;
    final s = _testSeconds % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  void _startTestTimer() {
    _testSeconds = 0;
    _testTimer?.cancel();
    _testTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _testSeconds++);
    });
  }

  void _stopTestTimer() { _testTimer?.cancel(); _testTimer = null; }

  void _resetEyeTest() {
    _eyeIndex = 0; _currentRow = 0; _letterIndex = 0;
    _correctCount = 0; _lastPassedRow = 0; _jumpIndex = 0;
    _jumpPhase = true; _cantTell = 0; _eyeResults = [];
    _generateRotation();
  }

  void _generateRotation() => setState(() => _rotation = Random().nextInt(4));

  void _recordResponse(bool correct) {
    setState(() {
      if (correct) _correctCount++;
      _letterIndex++;
      if (_letterIndex < 5) { _generateRotation(); return; }
      final passed = _correctCount >= 4;
      _letterIndex = 0; _correctCount = 0;
      _advanceStaircase(passed);
    });
  }

  void _recordCantTell() {
    setState(() {
      _cantTell++;
      _letterIndex++;
      if (_letterIndex < 5) { _generateRotation(); return; }
      final passed = _correctCount >= 4;
      _letterIndex = 0; _correctCount = 0;
      _advanceStaircase(passed);
    });
  }

  void _advanceStaircase(bool passed) {
    if (_jumpPhase) {
      if (passed) {
        _lastPassedRow = _currentRow; // track last passed row during jumps
        _jumpIndex++;
        if (_jumpIndex >= _staircaseJumps.length) { _finishEye(_rows[_lastPassedRow]['logmar'] as String); return; }
        _currentRow = _staircaseJumps[_jumpIndex];
      } else {
        _jumpPhase = false;
        _currentRow = (_currentRow + 1).clamp(0, _rows.length - 1);
        if (_currentRow >= _rows.length - 1) { _finishEye(_rows[_lastPassedRow]['logmar'] as String); return; }
      }
    } else {
      if (passed) {
        _lastPassedRow = _currentRow;
        final next = _currentRow - 1;
        if (next < 0) { _finishEye(_rows[_lastPassedRow]['logmar'] as String); return; }
        _currentRow = next;
      } else {
        _finishEye(_rows[_lastPassedRow]['logmar'] as String); return;
      }
    }
    _generateRotation();
  }

  void _finishEye(String logmar) {
    _stopTestTimer();
    _eyeResults.add({'eye': _eyeOrder[_eyeIndex], 'logmar': logmar, 'duration': _testDuration, 'cantTell': _cantTell});
    if (_eyeIndex < _eyeOrder.length - 1) {
      setState(() {
        _eyeIndex++; _currentRow = 0; _lastPassedRow = 0;
        _letterIndex = 0; _correctCount = 0;
        _jumpIndex = 0; _jumpPhase = true; _cantTell = 0;
        _section = 4; // cover eye reminder
      });
    } else {
      _saveAndShowResult();
    }
  }

  String _toSnellen(String logmar) {
    final v = double.tryParse(logmar);
    if (v == null) return logmar;
    const snaps = [6, 9, 12, 18, 24, 36, 48, 60, 120];
    final second = (6 * pow(10, v)).round();
    return '6/${snaps.reduce((a, b) => (a - second).abs() < (b - second).abs() ? a : b)}';
  }

  bool get _needsReferral {
    if (_eyeResults.isEmpty) return false;
    // Refer if BOTH eyes are worse than LogMAR 0.5 (Snellen 6/18)
    // OR if either eye is worse than LogMAR 1.0 (Snellen 6/60 — severe)
    final results = _eyeResults.map((r) => double.tryParse(r['logmar'] as String) ?? 0.0).toList();
    final anyEyeSevere  = results.any((v) => v > 0.5);
    return anyEyeSevere;
  }

  Future<void> _loadSummary() async {
    if (_campaignId == null) return;
    setState(() => _loadingSummary = true);
    final rows = await DatabaseHelper.instance.getPatientsForCampaign(_campaignId!);
    final campaign = await DatabaseHelper.instance.getCampaign(_campaignId!);
    if (mounted) setState(() {
      _sessionPatients = rows;
      _loadingSummary  = false;
    });
  }

  Future<void> _saveFacility() async {
    final facility = _selectedFacility == 'Other (specify below)'
        ? _facilityCtrl.text.trim()
        : _selectedFacility ?? _facilityCtrl.text.trim();
    if (facility.isEmpty) return;
    final database = await DatabaseHelper.instance.db;
    await database.rawUpdate(
      'UPDATE screenings SET referral_facility = ?, appointment_date = ?, referral_status = ? WHERE patient_id = ? ORDER BY screening_date DESC LIMIT 1',
      [
        facility,
        _appointmentDate?.toIso8601String() ?? '',
        'pending',
        _currentPatientId,
      ],
    );
    _facilityCtrl.clear();
  }

  Future<void> _saveAndShowResult() async {
    if (_currentPatientId == null) return;
    String odLogmar = '', osLogmar = '';
    int odCantTell = 0, osCantTell = 0;
    String odDuration = '', osDuration = '';
    for (final r in _eyeResults) {
      if (r['eye'] == 'OD') { odLogmar = r['logmar']; odCantTell = r['cantTell']; odDuration = r['duration']; }
      if (r['eye'] == 'OS') { osLogmar = r['logmar']; osCantTell = r['cantTell']; osDuration = r['duration']; }
    }
    final outcome = _needsReferral ? 'refer' : 'pass';
    await DatabaseHelper.instance.insertScreening({
      'patient_id':      _currentPatientId,
      'screening_date':  DateTime.now().toIso8601String(),
      'od_logmar':       odLogmar,
      'os_logmar':       osLogmar,
      'ou_near_logmar':  '',
      'od_snellen':      odLogmar.isNotEmpty ? _toSnellen(odLogmar) : '',
      'os_snellen':      osLogmar.isNotEmpty ? _toSnellen(osLogmar) : '',
      'ou_near_snellen': '',
      'od_cant_tell':    odCantTell,
      'os_cant_tell':    osCantTell,
      'near_cant_tell':  0,
      'od_duration':     odDuration,
      'os_duration':     osDuration,
      'near_duration':   '',
      'outcome':         outcome,
      'referral_facility': '',
      'referral_status': outcome == 'refer' ? 'pending' : '',
      'chw_name':        '',
      'synced':          0,
    });
    await DatabaseHelper.instance.updateCampaignStats(_campaignId!);
    setState(() => _section = 5); // result screen
  }

  double _mmToPx(double mm, BuildContext ctx) {
    final mq = MediaQuery.of(ctx);
    final pw = mq.size.width * mq.devicePixelRatio;
    final ph = mq.size.height * mq.devicePixelRatio;
    final diag = sqrt(pw * pw + ph * ph);
    final dpi = diag / 5.5;
    return (mm / 25.4) * (dpi / mq.devicePixelRatio);
  }

  final _targetGroups = [
    {'label': 'Children',  'icon': Icons.child_care_rounded,   'sub': 'Under 18'},
    {'label': 'Adults',    'icon': Icons.person_rounded,        'sub': '18 – 60'},
    {'label': 'Elderly',   'icon': Icons.elderly_rounded,       'sub': 'Over 60'},
    {'label': 'Mixed',     'icon': Icons.groups_rounded,        'sub': 'All ages'},
  ];

  @override
  void dispose() {
    _campaignNameCtrl.dispose();
    _locationCtrl.dispose();
    _nameCtrl.dispose();
    _facilityCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final name     = _campaignNameCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    if (name.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in campaign name and location.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    setState(() => _saving = true);

    final id = 'CAM-${DateTime.now().millisecondsSinceEpoch}';
    await DatabaseHelper.instance.insertCampaign({
      'id':           id,
      'name':         name,
      'location':     location,
      'target_group': _targetGroup,
      'created_at':   DateTime.now().toIso8601String(),
      'total':        0,
      'passed':       0,
      'referred':     0,
    });

    setState(() {
      _campaignId = id;
      _saving     = false;
      _section    = 1; // move to screening loop (next section)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _section == 0 ? _buildSetup()
              : _section == 1 ? _buildQuickRegister()
              : _section == 2 ? _buildEyeTest()
              : _section == 3 ? _buildSummaryPlaceholder()
              : _section == 4 ? _buildCoverEyeReminder()
              : _section == 5 ? _buildResultPlaceholder()
              : _buildPlaceholder(),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    // Compact header during eye test and cover eye reminder
    final isEyeTest = _section == 2 || _section == 4;
    if (isEyeTest) return _buildCompactHeader();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_ink, _ink2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _teal.withOpacity(0.18), Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _teal.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                    color: _teal3.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(
                                        color: _teal3,
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('CAMPAIGN MODE',
                                      style: GoogleFonts.ibmPlexSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _teal3)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Bulk',
                                style: GoogleFonts.barlow(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1.2,
                                    height: 1.0)),
                            Text('Screening',
                                style: GoogleFonts.barlow(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: _teal3,
                                    letterSpacing: -1.2,
                                    height: 1.0,
                                    fontStyle: FontStyle.italic)),
                            const SizedBox(height: 4),
                            Text('Screen many patients quickly in one session',
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.4))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_teal, _teal2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: _teal.withOpacity(0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: const Icon(Icons.groups_rounded,
                            color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                  // Step indicator
                  const SizedBox(height: 18),
                  Row(children: [
                    _stepDot(1, 'Setup',    _section >= 0),
                    _stepLine(_section >= 1),
                    _stepDot(2, 'Screen',   _section >= 1),
                    _stepLine(_section >= 2),
                    _stepDot(3, 'Summary',  _section >= 2),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    final eye = _section == 2 ? _eyeOrder[_eyeIndex] : (_eyeIndex < _eyeOrder.length ? _eyeOrder[_eyeIndex] : 'OS');
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_ink, _ink2], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() => _section = 1),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
              ),
            ),
            const SizedBox(width: 12),
            if (_section == 2) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _teal3.withOpacity(0.3)),
                ),
                child: Text('Testing: $eye · LogMAR ${_rows[_currentRow]['logmar']}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: _teal3)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(99)),
                child: Text('$_letterIndex/5', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.7))),
              ),
            ] else ...[
              Text(_section == 4 ? 'Cover Eye Reminder' : 'Bulk Screening',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _stepDot(int n, String label, bool active) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? _teal : Colors.white.withOpacity(0.1),
            border: Border.all(
                color: active ? _teal3 : Colors.white.withOpacity(0.2),
                width: 1.5),
          ),
          child: Center(
            child: Text('$n',
                style: GoogleFonts.barlow(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: active ? Colors.white : Colors.white.withOpacity(0.3))),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: active
                    ? _teal3
                    : Colors.white.withOpacity(0.3),
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _stepLine(bool active) => Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: active ? _teal3.withOpacity(0.5) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
      ),
    ),
  );

  // ── Section 1: Setup Form ────────────────────────────────
  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text('Session Details',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 4),
          Text('Fill in the campaign details before screening begins.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF8FA0B4))),
          const SizedBox(height: 24),

          // Campaign name
          _label('Campaign Name'),
          const SizedBox(height: 6),
          _field(
            ctrl: _campaignNameCtrl,
            hint: 'e.g. Nakawa Primary School Outreach',
            icon: Icons.campaign_rounded,
          ),
          const SizedBox(height: 16),

          // Location
          _label('Location / Venue'),
          const SizedBox(height: 6),
          _field(
            ctrl: _locationCtrl,
            hint: 'e.g. Nakawa, Kampala',
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 24),

          // Target group
          _label('Target Group'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: _targetGroups.map((g) {
              final active = _targetGroup == g['label'];
              return GestureDetector(
                onTap: () => setState(() => _targetGroup = g['label'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? _teal.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? _teal : const Color(0xFFEEF2F6),
                      width: active ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(g['icon'] as IconData,
                          size: 18,
                          color: active ? _teal : const Color(0xFF8FA0B4)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(g['label'] as String,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? _teal
                                        : const Color(0xFF1A2A3D))),
                            Text(g['sub'] as String,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF8FA0B4))),
                          ],
                        ),
                      ),
                      if (active)
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: _teal),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _amber.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _amber.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: _amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All patients screened in this session will be grouped under this campaign and visible individually in the Patients screen.',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF5E7291),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Start button
          GestureDetector(
            onTap: _saving ? null : _startSession,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _saving
                      ? [Colors.grey.shade400, Colors.grey.shade400]
                      : [_teal, const Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: _saving
                    ? []
                    : [
                        BoxShadow(
                            color: _teal.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ],
              ),
              child: _saving
                  ? const Center(
                      child: SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Text('Start Screening Session',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Tap to begin — patients will be added one by one',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.7))),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 2: Quick Register ────────────────────────────
  void _resetRegistration() {
    _nameCtrl.clear();
    _facilityCtrl.clear();
    setState(() {
      _quickAge          = 10;
      _quickGender       = 'M';
      _currentPatientId  = null;
      _selectedFacility  = null;
      _appointmentDate   = null;
    });
  }

  Future<void> _registerAndProceed() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter the patient name.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    setState(() => _registering = true);
    final pid = 'PAT-${DateTime.now().millisecondsSinceEpoch}';
    await DatabaseHelper.instance.insertPatient({
      'id':          pid,
      'name':        name,
      'age':         _quickAge,
      'dob':         '',
      'gender':      _quickGender,
      'village':     _locationCtrl.text.trim(),
      'phone':       '',
      'conditions':  '',
      'photo_path':  '',
      'campaign_id': _campaignId,
      'created_at':  DateTime.now().toIso8601String(),
    });
    setState(() {
      _patientCount++;
      _currentPatientId = pid;
      _registering = false;
      _section = 2;
    });
  }

  Widget _buildQuickRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session progress bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('$_patientCount',
                      style: GoogleFonts.barlow(fontSize: 20, fontWeight: FontWeight.w900, color: _teal)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient ${_patientCount + 1}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D))),
                    Text('$_patientCount screened so far · ${_campaignNameCtrl.text}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _teal.withOpacity(0.2)),
                ),
                child: Text('IN SESSION', style: GoogleFonts.ibmPlexSans(fontSize: 9, fontWeight: FontWeight.w800, color: _teal, letterSpacing: 1.0)),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          Text('Register Patient', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 4),
          Text('Quick 3-field registration — takes under 10 seconds.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4))),
          const SizedBox(height: 24),

          // Name field
          _label('Full Name *'),
          const SizedBox(height: 6),
          _field(ctrl: _nameCtrl, hint: 'e.g. Akello Grace', icon: Icons.person_rounded),
          const SizedBox(height: 16),

          // Age selector
          _label('Age'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => setState(() => _quickAge = (_quickAge - 1).clamp(1, 120)),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFF0F4F7), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.remove_rounded, size: 18, color: Color(0xFF5E7291)),
                ),
              ),
              Expanded(
                child: Column(children: [
                  Text('$_quickAge', style: GoogleFonts.barlow(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF1A2A3D))),
                  Text('years old', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4))),
                ]),
              ),
              GestureDetector(
                onTap: () => setState(() => _quickAge = (_quickAge + 1).clamp(1, 120)),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add_rounded, size: 18, color: _teal),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Gender selector
          _label('Gender'),
          const SizedBox(height: 10),
          Row(children: ['M', 'F'].map((g) {
            final active = _quickGender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _quickGender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: g == 'M' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: active ? _teal.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? _teal : const Color(0xFFEEF2F6), width: active ? 2 : 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(children: [
                    Icon(g == 'M' ? Icons.male_rounded : Icons.female_rounded,
                        size: 24, color: active ? _teal : const Color(0xFF8FA0B4)),
                    const SizedBox(height: 4),
                    Text(g == 'M' ? 'Male' : 'Female',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                            color: active ? _teal : const Color(0xFF5E7291))),
                  ]),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 32),

          // Proceed button
          GestureDetector(
            onTap: _registering ? null : _registerAndProceed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _registering
                      ? [Colors.grey.shade400, Colors.grey.shade400]
                      : [_teal, const Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: _registering ? [] : [BoxShadow(color: _teal.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: _registering
                  ? const Center(child: SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Register & Start Eye Test',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
            ),
          ),
          const SizedBox(height: 16),

          // End session button
          GestureDetector(
            onTap: () async { await _loadSummary(); setState(() => _section = 3); },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.stop_circle_outlined, size: 18, color: Color(0xFF8FA0B4)),
                const SizedBox(width: 8),
                Text('End Session & View Summary',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF5E7291))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 3: Eye Test ──────────────────────────────────
  Widget _buildEyeTest() {
    final row    = _rows[_currentRow];
    final baseMm = row['mm'] as double;
    final size   = _mmToPx(baseMm, context);
    return Column(children: [
      LinearProgressIndicator(
        value: (_currentRow + 1) / _rows.length,
        backgroundColor: const Color(0xFFEEF2F6),
        color: _teal, minHeight: 3,
      ),
      Expanded(
        child: Container(
          color: Colors.white,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                Color c = i < _letterIndex ? _green : i == _letterIndex ? _teal : const Color(0xFFEEF2F6);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _letterIndex ? 20 : 10, height: 10,
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99)),
                );
              }),
            ),
            const Spacer(),
            LayoutBuilder(builder: (ctx, constraints) {
              final maxS = constraints.maxHeight * 0.5;
              final s = size.clamp(0.0, maxS);
              return CustomPaint(
                painter: _BulkBoundingBox(size: s),
                child: Padding(
                  padding: EdgeInsets.all(s * 0.6),
                  child: RotatedBox(
                    quarterTurns: _rotation,
                    child: CustomPaint(size: Size(s * 0.8, s), painter: _BulkTumblingE(color: _ink)),
                  ),
                ),
              );
            }),
            const Spacer(),
          ]),
        ),
      ),
      SafeArea(
        top: false,
        child: Container(
          color: const Color(0xFFF8FAFB),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(99)),
              child: Text('Testing: ${_eyeOrder[_eyeIndex]} · LogMAR ${_rows[_currentRow]['logmar']}',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: _teal)),
            ),
            const SizedBox(height: 8),
            Text('Which way is the E facing?', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4))),
            const SizedBox(height: 6),
            _dirBtn(Icons.arrow_upward_rounded, 3),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _dirBtn(Icons.arrow_back_rounded, 2),
              const SizedBox(width: 10),
              Container(width: 50, height: 50,
                decoration: BoxDecoration(color: const Color(0xFFEEF2F6), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.remove_red_eye_rounded, size: 20, color: Color(0xFF8FA0B4))),
              const SizedBox(width: 10),
              _dirBtn(Icons.arrow_forward_rounded, 0),
            ]),
            const SizedBox(height: 5),
            _dirBtn(Icons.arrow_downward_rounded, 1),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _recordCantTell,
                icon: const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFF8FA0B4)),
                label: Text("Can't Tell", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF5E7291))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  side: const BorderSide(color: Color(0xFFDDE4EC), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _dirBtn(IconData icon, int turns) => GestureDetector(
    onTap: () => _recordResponse(turns == _rotation),
    child: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE4EC), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, size: 20, color: _ink),
    ),
  );

  // ── Section 4: Cover Eye Reminder ───────────────────────
  Widget _buildCoverEyeReminder() {
    final eye = _eyeOrder[_eyeIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _teal.withOpacity(0.08),
            border: Border.all(color: _teal.withOpacity(0.25), width: 2),
          ),
          child: Stack(alignment: Alignment.center, children: [
            Icon(Icons.remove_red_eye_rounded, size: 56, color: _teal.withOpacity(0.3)),
            Positioned(
              left: eye == 'OD' ? 12 : null, right: eye == 'OD' ? null : 12,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: _ink.withOpacity(0.75), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.back_hand_rounded, size: 22, color: Colors.white),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        Text(eye == 'OD' ? 'Cover Left Eye' : 'Cover Right Eye',
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D))),
        const SizedBox(height: 10),
        Text(
          eye == 'OD'
              ? 'Ask the patient to cover their LEFT eye with their palm before continuing.'
              : 'Ask the patient to cover their RIGHT eye with their palm before continuing.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5E7291), height: 1.6),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () {
            _generateRotation();
            _startTestTimer();
            setState(() => _section = 2);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_teal, Color(0xFF0F766E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _teal.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Begin ${eye == 'OD' ? 'Right' : 'Left'} Eye Test',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Placeholders for sections 5 & 3 (coming next) ───────
  // ── Section 5: Result Screen ─────────────────────────────
  Widget _buildResultPlaceholder() {
    final passed = !_needsReferral;
    final col    = passed ? _green : _red;
    final odResult = _eyeResults.firstWhere((r) => r['eye'] == 'OD', orElse: () => {});
    final osResult = _eyeResults.firstWhere((r) => r['eye'] == 'OS', orElse: () => {});
    final odSnellen = odResult.isNotEmpty ? _toSnellen(odResult['logmar'] as String) : '—';
    final osSnellen = osResult.isNotEmpty ? _toSnellen(osResult['logmar'] as String) : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Outcome card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: col.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: col.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: col.withOpacity(0.1),
                border: Border.all(color: col.withOpacity(0.3), width: 2),
              ),
              child: Icon(passed ? Icons.check_rounded : Icons.warning_rounded, color: col, size: 36),
            ),
            const SizedBox(height: 12),
            Text(passed ? 'PASS' : 'REFER',
                style: GoogleFonts.barlow(fontSize: 32, fontWeight: FontWeight.w900, color: col)),
            const SizedBox(height: 4),
            Text(passed ? 'Vision is within normal range' : 'Vision below threshold — referral needed',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8FA0B4))),
            const SizedBox(height: 20),
            // VA results row
            Row(children: [
              Expanded(child: _vaCard('OD', odSnellen, odResult.isNotEmpty ? odResult['logmar'] as String : '')),
              const SizedBox(width: 12),
              Expanded(child: _vaCard('OS', osSnellen, osResult.isNotEmpty ? osResult['logmar'] as String : '')),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        // Referral details (only if refer)
        if (!passed) ...[
          // Facility dropdown
          _label('Referral Facility'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFacility,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(children: [
                    Icon(Icons.local_hospital_rounded, size: 18, color: _teal.withOpacity(0.6)),
                    const SizedBox(width: 10),
                    Text('Select facility', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4))),
                  ]),
                ),
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8FA0B4)),
                items: _facilities.map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(f, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A2A3D))),
                )).toList(),
                onChanged: (v) => setState(() => _selectedFacility = v),
              ),
            ),
          ),
          // Other facility text field
          if (_selectedFacility == 'Other (specify below)') ...[
            const SizedBox(height: 8),
            _field(ctrl: _facilityCtrl, hint: 'Enter facility name', icon: Icons.edit_rounded),
          ],
          const SizedBox(height: 16),

          // Appointment date
          _label('Appointment Date'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                helpText: 'Select Appointment Date',
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(primary: _teal, onPrimary: Colors.white),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _appointmentDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _appointmentDate != null ? _teal.withOpacity(0.4) : const Color(0xFFEEF2F6),
                  width: 1.5,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, size: 18,
                    color: _appointmentDate != null ? _teal : const Color(0xFF8FA0B4)),
                const SizedBox(width: 10),
                Expanded(
                  child: _appointmentDate == null
                      ? Text('Select appointment date',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4)))
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            '${_appointmentDate!.day}/${_appointmentDate!.month}/${_appointmentDate!.year}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A2A3D)),
                          ),
                          Text('Appointment scheduled', style: GoogleFonts.inter(fontSize: 10, color: _teal)),
                        ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF8FA0B4)),
              ]),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Next patient button
        GestureDetector(
          onTap: () async {
            if (!passed && _facilityCtrl.text.trim().isNotEmpty) {
              await _saveFacility();
            }
            _resetRegistration();
            _resetEyeTest();
            setState(() => _section = 1);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_teal, Color(0xFF0F766E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _teal.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Next Patient',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
        ),
        const SizedBox(height: 14),

        // End session button
        GestureDetector(
          onTap: () async {
            if (!passed && _facilityCtrl.text.trim().isNotEmpty) await _saveFacility();
            await _loadSummary();
            setState(() => _section = 3);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.stop_circle_outlined, size: 18, color: Color(0xFF8FA0B4)),
              const SizedBox(width: 8),
              Text('End Session & View Summary',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF5E7291))),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _vaCard(String eye, String snellen, String logmar) {
    final v = double.tryParse(logmar);
    final col = v == null || v > 0.3 ? _red : _green;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(eye, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF8FA0B4))),
        const SizedBox(height: 4),
        Text(snellen, style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w900, color: col)),
        Text('LogMAR $logmar', style: GoogleFonts.inter(fontSize: 10, color: col.withOpacity(0.7))),
      ]),
    );
  }

  // ── Section 6: Session Summary ───────────────────────────
  Widget _buildSummaryPlaceholder() {
    if (_loadingSummary) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }
    final total    = _sessionPatients.length;
    final passed   = _sessionPatients.where((p) => p['outcome'] == 'pass').length;
    final referred = _sessionPatients.where((p) => p['outcome'] == 'refer').length;
    final pending  = _sessionPatients.where((p) => p['outcome'] == null || p['outcome'] == 'pending').length;
    final passRate = total > 0 ? (passed / total * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Campaign banner ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_ink, _ink2], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_teal, _teal2]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _teal.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_campaignNameCtrl.text,
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('${_locationCtrl.text} · ${_targetGroup}',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.5))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _green.withOpacity(0.4)),
                ),
                child: Text('COMPLETE', style: GoogleFonts.ibmPlexSans(fontSize: 9, fontWeight: FontWeight.w800, color: _green, letterSpacing: 1.0)),
              ),
            ]),
            const SizedBox(height: 20),
            // Stats row
            Row(children: [
              _summaryStatCard('$total',    'Screened', Colors.white),
              const SizedBox(width: 8),
              _summaryStatCard('$passed',   'Passed',   _green),
              const SizedBox(width: 8),
              _summaryStatCard('$referred', 'Referred', _red),
              const SizedBox(width: 8),
              _summaryStatCard('$passRate%','Pass Rate', _teal3),
            ]),
          ]),
        ),
        const SizedBox(height: 24),

        // ── Patient list ─────────────────────────────────────
        Text('Screened Patients',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D))),
        const SizedBox(height: 4),
        Text('$total patient${total == 1 ? '' : 's'} in this session',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8FA0B4))),
        const SizedBox(height: 14),

        if (_sessionPatients.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text('No patients screened yet.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4))),
          ))
        else
          ..._sessionPatients.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            final name     = p['name'] as String? ?? '—';
            final age      = p['age'] as int? ?? 0;
            final gender   = p['gender'] as String? ?? '';
            final outcome  = p['outcome'] as String? ?? 'pending';
            final odS      = p['od_snellen'] as String? ?? '—';
            final osS      = p['os_snellen'] as String? ?? '—';
            final facility = p['referral_facility'] as String? ?? '';
            final initials = name.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join();
            final col      = outcome == 'pass' ? _green : outcome == 'refer' ? _red : _amber;
            final badgeLabel = outcome == 'pass' ? 'Pass' : outcome == 'refer' ? 'Refer' : 'Pending';

            return Container(
              margin: EdgeInsets.only(bottom: i < _sessionPatients.length - 1 ? 10 : 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                // Number badge
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: const Color(0xFFF0F4F7), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('${i + 1}',
                      style: GoogleFonts.barlow(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF8FA0B4)))),
                ),
                const SizedBox(width: 10),
                // Avatar
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: col.withOpacity(0.25)),
                  ),
                  child: Center(child: Text(initials,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: col))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
                  Text('$gender · $age yrs', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4))),
                  if (outcome != 'pending') ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      _miniVaPill('OD', odS, outcome),
                      const SizedBox(width: 4),
                      _miniVaPill('OS', osS, outcome),
                    ]),
                  ],
                  if (facility.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.local_hospital_rounded, size: 10, color: Color(0xFF8FA0B4)),
                      const SizedBox(width: 4),
                      Flexible(child: Text(facility,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5E7291)))),
                    ]),
                  ],
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: col.withOpacity(0.25)),
                  ),
                  child: Text(badgeLabel,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: col)),
                ),
              ]),
            );
          }),

        const SizedBox(height: 28),

        // ── Done button ──────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_teal, Color(0xFF0F766E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _teal.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Done — Back to Home',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _summaryStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.barlow(fontSize: 20, fontWeight: FontWeight.w900, color: color, height: 1.0)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: GoogleFonts.ibmPlexSans(fontSize: 7, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.4), letterSpacing: 0.8)),
        ]),
      ),
    );
  }

  Widget _miniVaPill(String eye, String snellen, String outcome) {
    final isBad = outcome == 'refer';
    final col   = isBad ? _red : _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: col.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: Text('$eye $snellen',
          style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700, color: col)),
    );
  }

  Widget _buildPlaceholder() => const SizedBox();

  // ── Helpers ──────────────────────────────────────────────
  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A2A3D),
        letterSpacing: 0.2),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: TextField(
          controller: ctrl,
          style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF1A2A3D)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF8FA0B4)),
            prefixIcon: Icon(icon, size: 18, color: _teal.withOpacity(0.6)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
          ),
        ),
      );
}
