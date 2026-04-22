import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';

const _ink  = Color(0xFF04091A);
const _ink2 = Color(0xFF0B1530);
const _teal = Color(0xFF0D9488);
const _teal3 = Color(0xFF5EEAD4);
const _red  = Color(0xFFEF4444);
const _green = Color(0xFF22C55E);
const _amber = Color(0xFFF59E0B);

// Uganda eye clinics / referral facilities
const _facilities = [
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

class ReferralLetterScreen extends StatefulWidget {
  final Map<String, String> patient;
  final List<Map<String, dynamic>> eyeResults;
  final Map<String, dynamic>? nearResult;
  final String screeningDate;
  final List<String> conditions;
  final int? screeningId;

  const ReferralLetterScreen({
    super.key,
    required this.patient,
    required this.eyeResults,
    this.nearResult,
    required this.screeningDate,
    this.conditions = const [],
    this.screeningId,
  });

  @override
  State<ReferralLetterScreen> createState() => _ReferralLetterScreenState();
}

class _ReferralLetterScreenState extends State<ReferralLetterScreen> {
  final _chwNameCtrl       = TextEditingController();
  final _chwTitleCtrl      = TextEditingController(text: 'Community Health Worker');
  final _facilityOtherCtrl = TextEditingController();
  String _selectedFacility = _facilities[0];
  DateTime? _appointmentDate;
  bool _showLetter = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadChwProfile();
  }

  Future<void> _loadChwProfile() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    final name   = p.getString('chw_name')   ?? '';
    final center = p.getString('chw_center') ?? '';
    setState(() {
      if (name.isNotEmpty)   _chwNameCtrl.text  = name;
      if (center.isNotEmpty) _chwTitleCtrl.text = 'Community Health Worker · $center';
      final match = _facilities.where((f) =>
        center.isNotEmpty &&
        (f.toLowerCase().contains(center.toLowerCase()) ||
         center.toLowerCase().contains(f.toLowerCase().split(' ').first))
      ).firstOrNull;
      if (match != null) _selectedFacility = match;
    });
  }

  @override
  void dispose() {
    _chwNameCtrl.dispose();
    _chwTitleCtrl.dispose();
    _facilityOtherCtrl.dispose();
    super.dispose();
  }

  String get _appointmentDateStr => _appointmentDate == null
      ? ''
      : '${_appointmentDate!.day}/${_appointmentDate!.month}/${_appointmentDate!.year}';

  Future<void> _saveToDb() async {
    if (widget.screeningId == null) return;
    await DatabaseHelper.instance.updateReferralDetails(
      widget.screeningId!,
      facility: _facilityName,
      appointmentDate: _appointmentDate?.toIso8601String(),
      status: 'pending',
    );
    if (mounted) setState(() => _saved = true);
  }

  String _toSnellen(String logmar) {
    final v = double.tryParse(logmar);
    if (v == null) return logmar;
    const snaps = [6, 9, 12, 18, 24, 36, 48, 60, 120];
    final second = (6 * pow(10, v)).round();
    return '6/${snaps.reduce((a, b) => (a - second).abs() < (b - second).abs() ? a : b)}';
  }

  String _vaClass(String logmar) {
    final v = double.tryParse(logmar);
    if (v == null) return logmar;
    if (v <= 0.0) return 'Normal';
    if (v <= 0.3) return 'Near Normal';
    if (v <= 0.5) return 'Moderate Visual Impairment';
    if (v <= 1.0) return 'Severe Visual Impairment';
    return 'Blind';
  }

  String get _facilityName => _selectedFacility == 'Other (specify below)'
      ? (_facilityOtherCtrl.text.trim().isEmpty
          ? 'Nearest Eye Clinic'
          : _facilityOtherCtrl.text.trim())
      : _selectedFacility;

  String get _letterText {
    final p = widget.patient;
    final buf = StringBuffer();
    buf.writeln('REFERRAL LETTER');
    buf.writeln('=' * 50);
    buf.writeln('Date: ${widget.screeningDate}');
    buf.writeln('');
    buf.writeln('TO: The Eye Specialist');
    buf.writeln('    $_facilityName');
    buf.writeln('');
    buf.writeln('FROM: ${_chwNameCtrl.text.trim().isEmpty ? '[CHW Name]' : _chwNameCtrl.text.trim()}');
    buf.writeln('      ${_chwTitleCtrl.text.trim()}');
    buf.writeln('');
    buf.writeln('RE: VISION SCREENING REFERRAL');
    buf.writeln('-' * 50);
    buf.writeln('');
    buf.writeln('PATIENT DETAILS');
    buf.writeln('Name   : ${p['name']}');
    buf.writeln('ID     : ${p['id']}');
    buf.writeln('Age    : ${p['age']} years');
    buf.writeln('Gender : ${p['gender'] == 'M' ? 'Male' : 'Female'}');
    buf.writeln('Village: ${p['village']}');
    if (widget.conditions.isNotEmpty) {
      buf.writeln('Conditions: ${widget.conditions.join(', ')}');
    }
    if (_appointmentDate != null) {
      buf.writeln('Appointment: $_appointmentDateStr');
    }
    buf.writeln('');
    buf.writeln('VISUAL ACUITY RESULTS (Tumbling E, LogMAR Scale)');
    buf.writeln('-' * 50);
    buf.writeln('Distance Vision (Monocular):');
    for (final r in widget.eyeResults) {
      final eye    = r['eye'] as String;
      final logmar = r['logmar'] as String;
      final eyeFull = eye == 'OD' ? 'Right Eye (OD)' : 'Left Eye (OS)';
      buf.writeln('$eyeFull:');
      buf.writeln('  Snellen : ${_toSnellen(logmar)}');
      buf.writeln('  LogMAR  : $logmar');
      buf.writeln('  Class   : ${_vaClass(logmar)}');
      if ((r['cantTell'] as int) > 0) {
        buf.writeln('  Note    : ${r['cantTell']} "Can\'t Tell" responses recorded');
      }
      buf.writeln('');
    }
    if (widget.nearResult != null) {
      final logmar = widget.nearResult!['logmar'] as String;
      buf.writeln('Near Vision (Binocular — 40cm):');
      buf.writeln('Both Eyes (OU):');
      buf.writeln('  Snellen : ${_toSnellen(logmar)}');
      buf.writeln('  LogMAR  : $logmar');
      buf.writeln('  Class   : ${_vaClass(logmar)}');
      if ((widget.nearResult!['cantTell'] as int) > 0) {
        buf.writeln('  Note    : ${widget.nearResult!['cantTell']} "Can\'t Tell" responses recorded');
      }
      buf.writeln('');
    }
    buf.writeln('REASON FOR REFERRAL');
    buf.writeln('-' * 50);
    buf.writeln('Visual acuity below 6/12 detected in one or more eyes.');
    buf.writeln('Further examination and management recommended.');
    buf.writeln('');
    buf.writeln('Please assess and manage as appropriate.');
    buf.writeln('');
    buf.writeln('Thank you.');
    buf.writeln('');
    buf.writeln('_' * 30);
    buf.writeln('${_chwNameCtrl.text.trim().isEmpty ? '[CHW Name]' : _chwNameCtrl.text.trim()}');
    buf.writeln('${_chwTitleCtrl.text.trim()}');
    buf.writeln('Date: ${widget.screeningDate}');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _showLetter ? _buildLetterPreview() : _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_ink, _ink2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showLetter
                    ? setState(() => _showLetter = false)
                    : Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_showLetter ? 'Referral Letter' : 'Generate Referral',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text(widget.patient['name']!,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _teal3.withValues(alpha: 0.7))),
                ],
              ),
              const Spacer(),
              if (_showLetter)
                GestureDetector(
                  onTap: () => Share.share(_letterText,
                      subject: 'Vision Screening Referral — ${widget.patient['name']}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: _teal3.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.share_rounded, size: 14, color: _teal3),
                        const SizedBox(width: 5),
                        Text('Share',
                            style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: _teal3)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    final p = widget.patient;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          p['name']!.split(' ').map((w) => w[0]).take(2).join(),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, fontWeight: FontWeight.w800,
                              color: _teal3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name']!,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text('${p['id']} · ${p['gender'] == 'M' ? 'Male' : 'Female'} · ${p['age']} yrs',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.conditions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: widget.conditions.map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: _amber.withValues(alpha: 0.3)),
                      ),
                      child: Text(c,
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: _amber)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          // VA results summary
          Text('VA Results',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 6),
          Text('Distance Vision',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: const Color(0xFF8FA0B4))),
          const SizedBox(height: 8),
          ...widget.eyeResults.map((r) {
            final eye    = r['eye'] as String;
            final logmar = r['logmar'] as String;
            final v      = double.tryParse(logmar);
            final col    = v == null ? _red
                : v <= 0.3 ? _green : v <= 0.5 ? _amber : _red;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              ),
              child: Row(
                children: [
                  Text(eye,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 13, fontWeight: FontWeight.w800, color: col)),
                  const SizedBox(width: 10),
                  Text(eye == 'OD' ? 'Right Eye' : 'Left Eye',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF8FA0B4))),
                  const Spacer(),
                  Text(_toSnellen(logmar),
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 14, fontWeight: FontWeight.w800, color: col)),
                  const SizedBox(width: 6),
                  Text('(LogMAR $logmar)',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: const Color(0xFF8FA0B4))),
                ],
              ),
            );
          }),
          if (widget.nearResult != null) ...[
            const SizedBox(height: 8),
            Text('Near Vision (40cm)',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: const Color(0xFF8FA0B4))),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final logmar = widget.nearResult!['logmar'] as String;
              final v = double.tryParse(logmar);
              final col = v == null ? _red : v <= 0.3 ? _green : v <= 0.5 ? _amber : _red;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
                ),
                child: Row(
                  children: [
                    Text('OU',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 13, fontWeight: FontWeight.w800, color: col)),
                    const SizedBox(width: 10),
                    Text('Both Eyes — Near',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF8FA0B4))),
                    const Spacer(),
                    Text(_toSnellen(logmar),
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14, fontWeight: FontWeight.w800, color: col)),
                    const SizedBox(width: 6),
                    Text('(LogMAR $logmar)',
                        style: GoogleFonts.inter(
                            fontSize: 10, color: const Color(0xFF8FA0B4))),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          // CHW details
          Text('CHW Details',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 10),
          _infoRow(Icons.person_rounded, 'CHW Name',
              _chwNameCtrl.text.isEmpty ? '[Not set in Settings]' : _chwNameCtrl.text),
          const SizedBox(height: 8),
          _infoRow(Icons.badge_rounded, 'Title / Role',
              _chwTitleCtrl.text.isEmpty ? '[Not set in Settings]' : _chwTitleCtrl.text),
          const SizedBox(height: 24),
          // Facility selector
          Text('Refer To',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFacility,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                borderRadius: BorderRadius.circular(12),
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF1A2A3D)),
                items: _facilities.map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(f, style: GoogleFonts.inter(fontSize: 13)),
                )).toList(),
                onChanged: (v) => setState(() => _selectedFacility = v!),
              ),
            ),
          ),
          if (_selectedFacility == 'Other (specify below)') ...[
            const SizedBox(height: 8),
            _formField(_facilityOtherCtrl, 'Facility name', Icons.local_hospital_rounded),
          ],
          const SizedBox(height: 20),
          // Appointment date
          Text('Appointment Date',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 10),
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
                    colorScheme: const ColorScheme.light(
                      primary: _teal, onPrimary: Colors.white),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _appointmentDate != null
                      ? _teal : const Color(0xFFEEF2F6),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16,
                      color: _appointmentDate != null
                          ? _teal : const Color(0xFF8FA0B4)),
                  const SizedBox(width: 10),
                  Text(
                    _appointmentDate == null
                        ? 'Select appointment date (optional)'
                        : 'Appointment: $_appointmentDateStr',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _appointmentDate != null
                            ? const Color(0xFF1A2A3D)
                            : const Color(0xFF8FA0B4),
                        fontWeight: _appointmentDate != null
                            ? FontWeight.w600 : FontWeight.w400),
                  ),
                  const Spacer(),
                  if (_appointmentDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _appointmentDate = null),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: Color(0xFF8FA0B4)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showLetter = true),
              icon: const Icon(Icons.description_rounded,
                  size: 18, color: Colors.white),
              label: Text('Preview Referral Letter',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Letter preview ────────────────────────────────────────────────────────
  Widget _buildLetterPreview() {
    final p = widget.patient;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Letter card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_hospital_rounded,
                          color: _red, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('REFERRAL LETTER',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1A2A3D),
                                  letterSpacing: 1.2)),
                          Text('Vision Screening Programme',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF8FA0B4))),
                        ],
                      ),
                    ),
                    Text(widget.screeningDate,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: const Color(0xFF8FA0B4))),
                  ],
                ),
                const SizedBox(height: 20),
                _divider(),
                const SizedBox(height: 16),
                // To / From
                _letterRow('To', _facilityName),
                const SizedBox(height: 8),
                _letterRow('From',
                    '${_chwNameCtrl.text.trim().isEmpty ? '[CHW Name]' : _chwNameCtrl.text.trim()}\n${_chwTitleCtrl.text.trim()}'),
                const SizedBox(height: 16),
                _divider(),
                const SizedBox(height: 16),
                // Patient
                Text('PATIENT DETAILS',
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: const Color(0xFF8FA0B4),
                        letterSpacing: 1.0)),
                const SizedBox(height: 10),
                _letterRow('Name', p['name']!),
                const SizedBox(height: 6),
                _letterRow('Patient ID', p['id']!),
                const SizedBox(height: 6),
                _letterRow('Age / Sex',
                    '${p['age']} years · ${p['gender'] == 'M' ? 'Male' : 'Female'}'),
                const SizedBox(height: 6),
                _letterRow('Village', p['village']!),
                if (widget.conditions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _letterRow('Conditions', widget.conditions.join(', ')),
                ],
                if (_appointmentDate != null) ...[
                  const SizedBox(height: 6),
                  _letterRow('Appointment', _appointmentDateStr),
                ],
                const SizedBox(height: 16),
                _divider(),
                const SizedBox(height: 16),
                // VA results
                Text('VISUAL ACUITY RESULTS',
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: const Color(0xFF8FA0B4),
                        letterSpacing: 1.0)),
                const SizedBox(height: 6),
                Text('Distance Vision (Monocular)',
                    style: GoogleFonts.inter(
                        fontSize: 10, color: const Color(0xFF8FA0B4))),
                const SizedBox(height: 8),
                ...widget.eyeResults.map((r) {
                  final eye    = r['eye'] as String;
                  final logmar = r['logmar'] as String;
                  final v      = double.tryParse(logmar);
                  final col    = v == null ? _red
                      : v <= 0.3 ? _green : v <= 0.5 ? _amber : _red;
                  final eyeFull = eye == 'OD' ? 'Right Eye (OD)' : 'Left Eye (OS)';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: col.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: col.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(eyeFull,
                                  style: GoogleFonts.inter(
                                      fontSize: 11, fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A2A3D))),
                              Text(_vaClass(logmar),
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: const Color(0xFF8FA0B4))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_toSnellen(logmar),
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16, fontWeight: FontWeight.w800,
                                    color: col)),
                            Text('LogMAR $logmar',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: col.withValues(alpha: 0.7))),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                if (widget.nearResult != null) ...[
                  const SizedBox(height: 8),
                  Text('Near Vision (Binocular — 40cm)',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: const Color(0xFF8FA0B4))),
                  const SizedBox(height: 8),
                  Builder(builder: (_) {
                    final logmar = widget.nearResult!['logmar'] as String;
                    final v = double.tryParse(logmar);
                    final col = v == null ? _red : v <= 0.3 ? _green : v <= 0.5 ? _amber : _red;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: col.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: col.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Both Eyes (OU)',
                                    style: GoogleFonts.inter(
                                        fontSize: 11, fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1A2A3D))),
                                Text(_vaClass(logmar),
                                    style: GoogleFonts.inter(
                                        fontSize: 10, color: const Color(0xFF8FA0B4))),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_toSnellen(logmar),
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16, fontWeight: FontWeight.w800,
                                      color: col)),
                              Text('LogMAR $logmar',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: col.withValues(alpha: 0.7))),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                _divider(),
                const SizedBox(height: 16),
                // Reason
                Text('REASON FOR REFERRAL',
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: const Color(0xFF8FA0B4),
                        letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Text(
                  'Visual acuity below 6/12 detected in one or more eyes during '
                  'community vision screening. Further examination and management '
                  'is recommended.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF5E7291), height: 1.6),
                ),
                const SizedBox(height: 24),
                _divider(),
                const SizedBox(height: 16),
                // Signature
                Text('_' * 28,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF8FA0B4))),
                const SizedBox(height: 4),
                Text(
                  _chwNameCtrl.text.trim().isEmpty
                      ? '[CHW Name]' : _chwNameCtrl.text.trim(),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2A3D)),
                ),
                Text(_chwTitleCtrl.text.trim(),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF8FA0B4))),
                Text('Date: ${widget.screeningDate}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF8FA0B4))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saved ? null : () async {
                await _saveToDb();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Referral saved to patient record',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                    backgroundColor: _green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ));
                }
              },
              icon: Icon(_saved ? Icons.check_circle_rounded : Icons.save_rounded,
                  size: 18, color: Colors.white),
              label: Text(_saved ? 'Saved to Record' : 'Save to Patient Record',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved ? _green : _teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Share.share(_letterText,
                  subject: 'Vision Screening Referral — ${p['name']}'),
              icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
              label: Text('Share Referral Letter',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2A3D),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showLetter = false),
              icon: const Icon(Icons.edit_rounded, size: 16, color: _teal),
              label: Text('Edit Details',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _teal)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: _teal, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _letterRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 80,
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: const Color(0xFF8FA0B4))),
      ),
      Expanded(
        child: Text(value,
            style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF1A2A3D), height: 1.5)),
      ),
    ],
  );

  Widget _divider() => Container(
    height: 1, color: const Color(0xFFEEF2F6));

  Widget _infoRow(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFB),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8FA0B4)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: const Color(0xFF8FA0B4),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF1A2A3D),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Edit your name in Settings',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
              backgroundColor: _teal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          ),
          child: const Icon(Icons.lock_outline_rounded,
              size: 14, color: Color(0xFF8FA0B4)),
        ),
      ],
    ),
  );

  Widget _formField(TextEditingController ctrl, String hint, IconData icon) =>
    Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A2A3D)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4)),
          prefixIcon: Icon(icon, size: 16, color: const Color(0xFF8FA0B4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
}

