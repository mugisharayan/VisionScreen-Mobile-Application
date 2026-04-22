import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../db/database_helper.dart';

// ── Colours (shared with the rest of the app) ──
const _ink = Color(0xFF04091A);
const _ink2 = Color(0xFF0B1530);
const _teal = Color(0xFF0D9488);
const _teal2 = Color(0xFF14B8A6);
const _teal3 = Color(0xFF5EEAD4);
const _green = Color(0xFF22C55E);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _blue = Color(0xFF3B82F6);

// ── Screening history entry ──
class _ScreeningEntry {
  const _ScreeningEntry({
    required this.date,
    required this.od,
    required this.os,
    required this.ou,
    required this.outcome,
    this.chw = '',
  });
  final String date;
  final String od, os, ou;
  final String outcome;
  final String chw;
}

// ── Patient model ──
class _Patient {
  final String initials;
  final List<Color> avatarGradient;
  final String photoUrl;
  final String name;
  final int age;
  final String gender;
  final String village;
  final String ageGroup;
  final String od, os, ou;
  final String outcome;
  final String date;
  final String id;
  final String phone;
  final String? facility;
  final String? dueDate;
  final String? referralStatus;
  final List<_ScreeningEntry> history;
  final List<String> conditions;

  _Patient({
    required this.initials,
    required this.avatarGradient,
    required this.photoUrl,
    required this.name,
    required this.age,
    required this.gender,
    required this.village,
    required this.ageGroup,
    required this.od,
    required this.os,
    required this.ou,
    required this.outcome,
    required this.date,
    required this.id,
    required this.phone,
    this.facility,
    this.dueDate,
    this.referralStatus,
    List<_ScreeningEntry>? history,
    List<String>? conditions,
  })  : history = history ?? const <_ScreeningEntry>[],
        conditions = conditions ?? const <String>[];

  List<String> get safeConditions => conditions.toList();
}

// Static mock data removed — patients loaded from SQLite

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'All';
  String _query = '';
  List<_Patient> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    final patientRows = await DatabaseHelper.instance.getAllPatients();
    final list = <_Patient>[];
    for (final r in patientRows) {
      final pid = r['id'] as String;
      final latest = await DatabaseHelper.instance.getLatestScreening(pid);
      final age = (r['age'] as int?) ?? 0;
      final conditions = ((r['conditions'] as String?) ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final outcome = (latest?['outcome'] as String?) ?? 'pending';
      final od = (latest?['od_snellen'] as String?) ?? '—';
      final os = (latest?['os_snellen'] as String?) ?? '—';
      final ou = (latest?['ou_near_snellen'] as String?) ?? '—';
      final screeningDate = latest?['screening_date'] as String?;
      list.add(_Patient(
        initials: (r['name'] as String)
            .split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join(),
        avatarGradient: [_teal, _teal2],
        photoUrl: (r['photo_path'] as String?) ?? '',
        name: r['name'] as String,
        age: age,
        gender: r['gender'] as String,
        village: r['village'] as String,
        ageGroup: age < 18 ? 'child' : age > 60 ? 'elderly' : 'adult',
        od: od, os: os, ou: ou,
        outcome: outcome,
        date: screeningDate != null ? _formatDate(screeningDate) : 'Not screened',
        id: pid,
        phone: (r['phone'] as String?) ?? '',
        facility: (latest?['referral_facility'] as String?)
            ?.let((f) => f.isEmpty ? null : f),
        referralStatus: (latest?['referral_status'] as String?)
            ?.let((s) => s.isEmpty ? null : s),
        conditions: conditions,
      ));
    }
    if (mounted) setState(() { _patients = list; _loading = false; });
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final diff = now.difference(dt);
        if (diff.inMinutes < 60) return 'Today · ${diff.inMinutes}m ago';
        return 'Today · ${diff.inHours}hr ago';
      }
      return '${dt.day} ${_month(dt.month)}';
    } catch (_) { return iso.substring(0, 10); }
  }

  String _month(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];

  List<_Patient> get _filtered => _patients.where((p) {
    final matchQ =
        _query.isEmpty ||
        p.name.toLowerCase().contains(_query) ||
        p.id.toLowerCase().contains(_query) ||
        p.village.toLowerCase().contains(_query) ||
        (p.facility?.toLowerCase().contains(_query) ?? false);
    final matchF =
        _filter == 'All' ||
        (_filter == 'Pass' && p.outcome == 'pass') ||
        (_filter == 'Refer' && p.outcome == 'refer') ||
        (_filter == 'Pending' && p.outcome == 'pending') ||
        (_filter == 'Child' && p.ageGroup == 'child') ||
        (_filter == 'Adult' && p.ageGroup == 'adult') ||
        (_filter == 'Elderly' && p.ageGroup == 'elderly') ||
        (_filter == 'Overdue' && p.referralStatus == 'overdue') ||
        (_filter == 'Notified' && p.referralStatus == 'notified') ||
        (_filter == 'Attended' && p.referralStatus == 'attended') ||
        (_filter == 'Completed' && p.referralStatus == 'completed') ||
        (_filter == 'Cancelled' && p.referralStatus == 'cancelled');
    return matchQ && matchF;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final total = _patients.length;
    final passed = _patients.where((p) => p.outcome == 'pass').length;
    final referred = _patients.where((p) => p.outcome == 'refer').length;
    final pending = _patients.where((p) => p.outcome == 'pending').length;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(total, passed, referred, pending),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _teal))
                : RefreshIndicator(
                    onRefresh: _loadPatients,
                    color: _teal,
                    child: list.isEmpty
                        ? ListView(children: [_buildEmpty()])
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                            itemCount: list.length + 1,
                            itemBuilder: (_, i) {
                              if (i == 0) return _sectionLabel(
                                '${list.length} patient${list.length == 1 ? '' : 's'} registered',
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _buildCard(list[i - 1]),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(int total, int passed, int referred, int pending) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ink, _ink2],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patients & Referrals',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$total registered · Wakiso & Kampala',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _teal3.withOpacity(0.55),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _statChip('$total', 'Total', Colors.white),
                  const SizedBox(width: 8),
                  _statChip('$passed', 'Passed', _green),
                  const SizedBox(width: 8),
                  _statChip('$referred', 'Referred', _red),
                  const SizedBox(width: 8),
                  _statChip('$pending', 'Pending', _amber),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID, village, or facility...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: _teal3.withOpacity(0.4),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: _teal3.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Filter chips
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  'All',
                  'Pass',
                  'Refer',
                  'Pending',
                  'Child',
                  'Adult',
                  'Elderly',
                  'Overdue',
                  'Notified',
                  'Attended',
                  'Completed',
                  'Cancelled',
                ].map((f) => _filterChip(f)).toList(),
              ),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String number, String label, Color numColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: numColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: _teal3.withOpacity(0.5),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final active = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? _teal.withOpacity(0.25)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? _teal3 : Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? _teal3 : Colors.white.withOpacity(0.55),
          ),
        ),
      ),
    );
  }

  // ── Section label ──
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF8FA0B4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Patient card ──
  Widget _buildCard(_Patient p) {
    final (badgeLabel, badgeBg, badgeText, badgeIcon, accentColor) =
        _badgeProps(p.outcome);
    final ageGroupColor = _ageGroupColor(p.ageGroup);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showHistory(p),
        onLongPress: () => _confirmDelete(p),
        borderRadius: BorderRadius.circular(16),
        highlightColor: const Color(0xFFF0F4F7),
        splashColor: const Color(0xFFDDE4EC),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Top body ──
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left accent bar
                    Container(
                      width: 4,
                      height: 72,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Avatar with photo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: p.avatarGradient.last.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: p.photoUrl.isNotEmpty && File(p.photoUrl).existsSync()
                            ? Image.file(File(p.photoUrl), fit: BoxFit.cover, width: 50, height: 50)
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: p.avatarGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    p.initials,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + age group badge
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A2A3D),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ageGroupColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: ageGroupColor.withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _capitalize(p.ageGroup),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: ageGroupColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Demographics
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 11,
                                color: Color(0xFF8FA0B4),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${p.age} yrs · ${p.gender} · ${p.village}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF8FA0B4),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // VA chips row
                          if (p.outcome != 'pending')
                            Row(
                              children: [
                                _vaPill('OD', p.od, p.outcome),
                                const SizedBox(width: 5),
                                _vaPill('OS', p.os, p.outcome),
                                const SizedBox(width: 5),
                                _vaPill('OU', p.ou, p.outcome),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _amber.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _amber.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.hourglass_top_rounded,
                                    size: 11,
                                    color: _amber,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Awaiting screening',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: _amber,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Conditions chips
                          if (p.safeConditions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: p.safeConditions.map((c) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _amber.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _amber.withOpacity(0.25)),
                                ),
                                child: Text(c,
                                    style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: _amber)),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Outcome badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: accentColor.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 11, color: accentColor),
                              const SizedBox(width: 4),
                              Text(
                                badgeLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: badgeText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Bottom strip ──
              Container(
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: accentColor.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: p.outcome != 'pending'
                    ? Row(
                        children: [
                          Expanded(
                            child: p.outcome == 'refer' && p.facility != null
                                ? Row(
                                    children: [
                                      const Icon(
                                        Icons.local_hospital_rounded,
                                        size: 12,
                                        color: Color(0xFF8FA0B4),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          '${p.facility}',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF5E7291),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _referralStatusColor(
                                            p.referralStatus,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                          border: Border.all(
                                            color: _referralStatusColor(
                                              p.referralStatus,
                                            ).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          p.referralStatus?.toUpperCase() ?? '',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: _referralStatusColor(
                                              p.referralStatus,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      const Icon(
                                        Icons.badge_outlined,
                                        size: 12,
                                        color: Color(0xFF8FA0B4),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        p.id,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF8FA0B4),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 11,
                                        color: Color(0xFF8FA0B4),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        p.date,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF8FA0B4),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _exportPatientData(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFEEF2F6),
                                ),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 14,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (p.outcome == 'refer')
                            GestureDetector(
                              onTap: () => _sendNotification(p),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _amber.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_rounded,
                                  size: 14,
                                  color: _amber,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _shareToWhatsApp(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF25D366,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                size: 14,
                                color: Color(0xFF25D366),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _callPatient(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                size: 14,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 12,
                            color: Color(0xFF8FA0B4),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            p.id,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF8FA0B4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: Color(0xFF8FA0B4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.date,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF8FA0B4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _callPatient(p),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                size: 14,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'View →',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
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

  Widget _vaPill(String eye, String value, String outcome) {
    final isBad =
        outcome == 'refer' &&
        value != '6/6' &&
        value != '6/9' &&
        value != '6/12';
    final bg = isBad ? _red.withOpacity(0.08) : _teal.withOpacity(0.08);
    final fg = isBad ? _red : _teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: fg.withOpacity(0.2), width: 1),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$eye ',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: const Color(0xFF8FA0B4),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(_Patient p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_rounded, color: _red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Delete Patient',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A2A3D))),
            ),
          ],
        ),
        content: Text(
          'Delete ${p.name} and all their screening records? This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5E7291), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600,
                    color: const Color(0xFF8FA0B4))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deletePatient(p.id);
              await _loadPatients();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${p.name} deleted',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                  backgroundColor: _red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHistory(_Patient p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PatientHistorySheet(patient: p),
    );
  }

  Widget _historyEntry(_ScreeningEntry e, int index, int total) {
    final isLatest = index == 0;
    final col = e.outcome == 'pass' ? _green : _red;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: col.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                e.outcome == 'pass'
                    ? Icons.check_rounded
                    : Icons.warning_rounded,
                size: 14,
                color: col,
              ),
            ),
            if (index < total - 1)
              Container(width: 2, height: 60, color: const Color(0xFFEEF2F6)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isLatest ? col.withValues(alpha: 0.04) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLatest
                      ? col.withValues(alpha: 0.2)
                      : const Color(0xFFEEF2F6),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        e.date,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2A3D),
                        ),
                      ),
                      const Spacer(),
                      if (isLatest)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Latest',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _teal,
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: col.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          e.outcome == 'pass' ? 'Pass' : 'Refer',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: col,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _histVaPill('OD', e.od),
                      const SizedBox(width: 6),
                      _histVaPill('OS', e.os),
                      const SizedBox(width: 6),
                      _histVaPill('OU', e.ou),
                      const Spacer(),
                      Icon(
                        Icons.person_outline_rounded,
                        size: 11,
                        color: const Color(0xFF8FA0B4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        e.chw,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF8FA0B4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _histVaPill(String eye, String value) {
    final isBad = value != '6/6' && value != '6/9';
    final col = isBad ? _amber : _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: col.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$eye ',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: const Color(0xFF8FA0B4),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: col,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──
  Widget _buildEmpty() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Color(0xFFDDE4EC),
            ),
            const SizedBox(height: 12),
            Text(
              'No patients found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A2A3D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different name, ID or village,\nor clear the filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8FA0B4),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──
  (String, Color, Color, IconData, Color) _badgeProps(String outcome) {
    return switch (outcome) {
      'pass' => (
        'Pass',
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
        Icons.check_circle_rounded,
        _green,
      ),
      'refer' => (
        'Refer',
        const Color(0xFFFEE2E2),
        const Color(0xFF991B1B),
        Icons.warning_rounded,
        _red,
      ),
      _ => (
        'Pending',
        const Color(0xFFE0F2FE),
        const Color(0xFF0369A1),
        Icons.schedule_rounded,
        _amber,
      ),
    };
  }

  Color _ageGroupColor(String group) => switch (group) {
    'child' => _blue,
    'elderly' => _red,
    _ => _teal,
  };

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Color _referralStatusColor(String? status) {
    switch (status) {
      case 'overdue':
        return _red;
      case 'pending':
        return _amber;
      case 'notified':
        return _blue;
      case 'attended':
        return _teal;
      case 'completed':
        return _green;
      case 'cancelled':
        return Colors.grey;
      default:
        return _teal;
    }
  }

  void _exportPatientData(_Patient p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE4EC),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Export Patient Data',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A2A3D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${p.name} · ${p.facility ?? p.id}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8FA0B4),
              ),
            ),
            const SizedBox(height: 20),
            // Export options
            _exportPatientOption(
              Icons.picture_as_pdf_outlined,
              'Export as PDF',
              'Complete referral report',
              () => _exportPatientToPDF(p),
            ),
            const SizedBox(height: 12),
            _exportPatientOption(
              Icons.table_chart_outlined,
              'Export as CSV',
              'Data for spreadsheet analysis',
              () => _exportPatientToCSV(p),
            ),
            const SizedBox(height: 12),
            _exportPatientOption(
              Icons.email_outlined,
              'Email Report',
              'Send via email',
              () => _emailPatientReport(p),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportPatientOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEEF2F6)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _teal, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2A3D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8FA0B4),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF8FA0B4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportPatientToPDF(_Patient p) async {
    Navigator.pop(context);

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Generating PDF for ${p.name}...',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Simulate PDF generation
      await Future.delayed(const Duration(seconds: 2));

      // Simulate random failure (20% chance)
      if (DateTime.now().millisecond % 5 == 0) {
        throw Exception('PDF generation failed');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'PDF exported successfully! Saved to Downloads.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar(
        'Export failed',
        'Unable to generate PDF for ${p.name}. Please try again.',
        retryAction: () => _exportPatientToPDF(p),
      );
    }
  }

  void _exportPatientToCSV(_Patient p) async {
    Navigator.pop(context);

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Exporting ${p.name} data to CSV...',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'CSV exported successfully!',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar(
        'Export failed',
        'Unable to export CSV for ${p.name}.',
        retryAction: () => _exportPatientToCSV(p),
      );
    }
  }

  void _emailPatientReport(_Patient p) {
    Navigator.pop(context);

    // In a real app, this would open the email client
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.email_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Opening email client for ${p.name}...',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: _blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sendNotification(_Patient p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE4EC),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: _amber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Referral Reminder',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A2A3D),
                        ),
                      ),
                      Text(
                        p.name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8FA0B4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (p.facility != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEF2F6)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_hospital_rounded,
                      size: 14,
                      color: Color(0xFF8FA0B4),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.facility!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF5E7291),
                        ),
                      ),
                    ),
                    if (p.dueDate != null)
                      Text(
                        'Due: ${p.dueDate}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _red,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Notification options
            _notifOption(
              icon: Icons.sms_rounded,
              color: _teal,
              title: 'Send SMS Reminder',
              subtitle: 'Text message to ${p.phone}',
              onTap: () {
                Navigator.pop(context);
                _showNotifConfirm(
                  p,
                  'SMS',
                  'Reminder sent via SMS to ${p.phone}',
                );
              },
            ),
            const SizedBox(height: 10),
            _notifOption(
              icon: Icons.send_rounded,
              color: const Color(0xFF25D366),
              title: 'Send WhatsApp Reminder',
              subtitle: 'WhatsApp message to ${p.phone}',
              onTap: () {
                Navigator.pop(context);
                _showNotifConfirm(
                  p,
                  'WhatsApp',
                  'Reminder sent via WhatsApp to ${p.phone}',
                );
              },
            ),
            const SizedBox(height: 10),
            _notifOption(
              icon: Icons.phone_rounded,
              color: _blue,
              title: 'Call Patient',
              subtitle: 'Voice call to ${p.phone}',
              onTap: () {
                Navigator.pop(context);
                _callPatient(p);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifOption({
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
          border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2A3D),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF8FA0B4),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF8FA0B4),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifConfirm(_Patient p, String channel, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _shareToWhatsApp(_Patient p) {
    final message =
        '''
🏥 *VisionScreen ${p.outcome == 'refer' ? 'Referral' : 'Patient'} Update*

👤 *Patient:* ${p.name}
📊 *Demographics:* ${p.age} yrs · ${p.gender} · ${p.village}
🏥 *Facility:* ${p.facility ?? 'N/A'}
📅 *Due Date:* ${p.dueDate ?? 'N/A'}
🔄 *Status:* ${p.referralStatus?.toUpperCase() ?? p.outcome.toUpperCase()}

👁️ *Visual Acuity:*
• OD (Right Eye): ${p.od}
• OS (Left Eye): ${p.os}
• OU (Both Eyes): ${p.ou}

📱 *Generated by VisionScreen Mobile App*
⏰ ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}
''';

    // In a real app, this would use url_launcher to open WhatsApp
    // For now, we'll show a preview and copy to clipboard
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Share to WhatsApp',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2A3D),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message Preview:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8FA0B4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEEF2F6)),
              ),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF1A2A3D),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8FA0B4),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app: launch('https://wa.me/?text=${Uri.encodeComponent(message)}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Message copied! Opening WhatsApp...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF25D366),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Share on WhatsApp',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callPatient(_Patient p) async {
    final uri = Uri(scheme: 'tel', path: p.phone);
    if (!await launchUrl(uri)) {
      _showErrorSnackBar(
        'Call failed',
        'Unable to dial ${p.name}. Please check your device settings.',
      );
    }
  }

  void _showErrorSnackBar(
    String title,
    String message, {
    VoidCallback? retryAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: retryAction != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: retryAction,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}


// ── Patient history bottom sheet — loads real screenings from SQLite ──
class _PatientHistorySheet extends StatefulWidget {
  final _Patient patient;
  const _PatientHistorySheet({required this.patient});
  @override
  State<_PatientHistorySheet> createState() => _PatientHistorySheetState();
}

class _PatientHistorySheetState extends State<_PatientHistorySheet> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseHelper.instance.getScreeningsForPatient(widget.patient.id);
    if (mounted) setState(() { _history = rows; _loading = false; });
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1];
      return '${dt.day} $m ${dt.year}';
    } catch (_) { return iso.substring(0, 10); }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFDDE4EC), borderRadius: BorderRadius.circular(99)),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: p.photoUrl.isNotEmpty && File(p.photoUrl).existsSync()
                        ? Image.file(File(p.photoUrl), width: 44, height: 44, fit: BoxFit.cover)
                        : Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: p.avatarGradient),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(p.initials,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D))),
                        Text('${p.id} · ${p.age} yrs · ${p.village}',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFF0F4F7), borderRadius: BorderRadius.circular(99)),
                    child: Text('${_history.length} screening${_history.length == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF5E7291))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Conditions
            if (p.safeConditions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Wrap(
                  spacing: 6, runSpacing: 6,
                  children: p.safeConditions.map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: _amber.withOpacity(0.3)),
                    ),
                    child: Text(c, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _amber)),
                  )).toList(),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEF2F6)),
            ],
            // Screenings list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _teal))
                  : _history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_rounded, size: 40, color: Color(0xFFDDE4EC)),
                              const SizedBox(height: 12),
                              Text('No screenings yet',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: ctrl,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          itemCount: _history.length,
                          itemBuilder: (_, i) => _historyRow(_history[i], i, _history.length),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyRow(Map<String, dynamic> r, int index, int total) {
    final isLatest = index == 0;
    final outcome = r['outcome'] as String;
    final col = outcome == 'pass' ? _green : _red;
    final od = (r['od_snellen'] as String?) ?? '—';
    final os = (r['os_snellen'] as String?) ?? '—';
    final ou = (r['ou_near_snellen'] as String?) ?? '—';
    final chw = (r['chw_name'] as String?) ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: col.withOpacity(0.1), shape: BoxShape.circle,
                border: Border.all(color: col.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(outcome == 'pass' ? Icons.check_rounded : Icons.warning_rounded, size: 14, color: col),
            ),
            if (index < total - 1)
              Container(width: 2, height: 60, color: const Color(0xFFEEF2F6)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isLatest ? col.withOpacity(0.04) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLatest ? col.withOpacity(0.2) : const Color(0xFFEEF2F6),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_fmtDate(r['screening_date'] as String),
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
                      const Spacer(),
                      if (isLatest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
                          child: Text('Latest', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: _teal)),
                        ),
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
                        child: Text(outcome == 'pass' ? 'Pass' : 'Refer',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: col)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _pill('OD', od),
                      const SizedBox(width: 6),
                      _pill('OS', os),
                      const SizedBox(width: 6),
                      _pill('OU', ou),
                      const Spacer(),
                      if (chw.isNotEmpty) ...[
                        const Icon(Icons.person_outline_rounded, size: 11, color: Color(0xFF8FA0B4)),
                        const SizedBox(width: 4),
                        Text(chw, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(String eye, String value) {
    final isBad = value != '6/6' && value != '6/9' && value != '—';
    final col = isBad ? _amber : _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: col.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: '$eye ', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8FA0B4), fontWeight: FontWeight.w500)),
          TextSpan(text: value, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: col)),
        ]),
      ),
    );
  }
}

