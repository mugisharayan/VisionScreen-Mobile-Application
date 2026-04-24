import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../db/database_helper.dart';
import '../services/pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bulk_mode_screen.dart';

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
  List<Map<String,dynamic>> _campaigns = [];
  List<_Patient> _allCampaignPatients = [];
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
    final campaignRows = await DatabaseHelper.instance.getAllCampaigns();
    setState(() => _loading = true);
    final allPatients = await DatabaseHelper.instance.getAllPatients();
    final patientRows = allPatients.where((r) {
      final cid = r['campaign_id'];
      return cid == null || cid.toString().isEmpty;
    }).toList();
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
    // Load all campaign patients for search
    final campPatientRows = (await DatabaseHelper.instance.getAllPatients())
        .where((r) => r['campaign_id'] != null && (r['campaign_id'] as String).isNotEmpty)
        .toList();
    final campList = <_Patient>[];
    for (final r in campPatientRows) {
      final age = (r['age'] as int?) ?? 0;
      final latest = await DatabaseHelper.instance.getLatestScreening(r['id'] as String);
      final outcome = (latest?['outcome'] as String?) ?? 'pending';
      campList.add(_Patient(
        initials: (r['name'] as String).split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join(),
        avatarGradient: [_teal, _teal2],
        photoUrl: (r['photo_path'] as String?) ?? '',
        name: r['name'] as String,
        age: age,
        gender: r['gender'] as String,
        village: (r['village'] as String?) ?? '',
        ageGroup: age < 18 ? 'child' : age > 60 ? 'elderly' : 'adult',
        od: (latest?['od_snellen'] as String?) ?? '—',
        os: (latest?['os_snellen'] as String?) ?? '—',
        ou: (latest?['ou_near_snellen'] as String?) ?? '—',
        outcome: outcome,
        date: latest?['screening_date'] != null ? _formatDate(latest!['screening_date'] as String) : 'Not screened',
        id: r['id'] as String,
        phone: (r['phone'] as String?) ?? '',
        facility: (latest?['referral_facility'] as String?)?.let((f) => f.isEmpty ? null : f),
        referralStatus: (latest?['referral_status'] as String?)?.let((s) => s.isEmpty ? null : s),
        conditions: ((r['conditions'] as String?) ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      ));
    }
    if (mounted) setState(() { _patients = list; _campaigns = campaignRows; _allCampaignPatients = campList; _loading = false; });
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

  List<Map<String,dynamic>> get _filteredCampaigns => _query.isEmpty
      ? _campaigns
      : _campaigns.where((c) {
          final q = _query.toLowerCase();
          return (c['name'] as String).toLowerCase().contains(q) ||
                 (c['location'] as String).toLowerCase().contains(q) ||
                 (c['target_group'] as String).toLowerCase().contains(q);
        }).toList();

  List<_Patient> get _filteredCampaignPatients => _query.isEmpty
      ? []
      : _allCampaignPatients.where((p) {
          return p.name.toLowerCase().contains(_query) ||
                 p.id.toLowerCase().contains(_query) ||
                 p.village.toLowerCase().contains(_query) ||
                 (p.facility?.toLowerCase().contains(_query) ?? false);
        }).toList();

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
    // Individual patient stats
    final indivTotal   = _patients.length;
    final indivPassed  = _patients.where((p) => p.outcome == 'pass').length;
    final indivReferred = _patients.where((p) => p.outcome == 'refer').length;
    final indivPending  = _patients.where((p) => p.outcome == 'pending').length;
    // Campaign stats
    final campTotal    = _campaigns.fold<int>(0, (sum, c) => sum + ((c['total'] as int?) ?? 0));
    final campPassed   = _campaigns.fold<int>(0, (sum, c) => sum + ((c['passed'] as int?) ?? 0));
    final campReferred = _campaigns.fold<int>(0, (sum, c) => sum + ((c['referred'] as int?) ?? 0));
    // Combined
    final total    = indivTotal + campTotal;
    final passed   = indivPassed + campPassed;
    final referred = indivReferred + campReferred;
    final pending  = indivPending;
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
                    child: () {
                      if (_query.isEmpty) {
                        // No search — show campaigns + individual patients
                        if (_campaigns.isEmpty && list.isEmpty) return ListView(children: [_buildEmpty()]);
                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                          itemCount: (_campaigns.isNotEmpty ? _campaigns.length + 1 : 0) + list.length + 1,
                          itemBuilder: (_, i) {
                            int idx = i;
                            if (_campaigns.isNotEmpty) {
                              if (idx == 0) return _sectionLabel('Campaigns (' + _campaigns.length.toString() + ')');
                              if (idx <= _campaigns.length) return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildCampaignCard(_campaigns[idx - 1]),
                              );
                              idx -= _campaigns.length + 1;
                            }
                            if (idx == 0) return _sectionLabel(list.length.toString() + ' individual patient' + (list.length == 1 ? '' : 's'));
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _buildCard(list[idx - 1]),
                            );
                          },
                        );
                      }
                      // Has search query — show ONLY exact matches per section
                      final mCampaigns = _filteredCampaigns;
                      final mCampPatients = _filteredCampaignPatients;
                      final mIndiv = list;
                      if (mCampaigns.isEmpty && mCampPatients.isEmpty && mIndiv.isEmpty) return ListView(children: [_buildEmpty()]);
                      int total = 0;
                      if (mCampaigns.isNotEmpty) total += mCampaigns.length + 1;
                      if (mCampPatients.isNotEmpty) total += mCampPatients.length + 1;
                      if (mIndiv.isNotEmpty) total += mIndiv.length + 1;
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                        itemCount: total,
                        itemBuilder: (_, i) {
                          int idx = i;
                          if (mCampaigns.isNotEmpty) {
                            if (idx == 0) return _sectionLabel('Campaigns (' + mCampaigns.length.toString() + ')');
                            if (idx <= mCampaigns.length) return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildCampaignCard(mCampaigns[idx - 1]),
                            );
                            idx -= mCampaigns.length + 1;
                          }
                          if (mCampPatients.isNotEmpty) {
                            if (idx == 0) return _sectionLabel('Campaign Patients (' + mCampPatients.length.toString() + ')');
                            if (idx <= mCampPatients.length) return Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _buildCard(mCampPatients[idx - 1]),
                            );
                            idx -= mCampPatients.length + 1;
                          }
                          if (idx == 0) return _sectionLabel('Individual Patients (' + mIndiv.length.toString() + ')');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _buildCard(mIndiv[idx - 1]),
                          );
                        },
                      );
                    }(),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(int total, int passed, int referred, int pending) {
    final passRate = total > 0 ? (passed / total * 100).round() : 0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF04091A), Color(0xFF0B1A2E)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Large teal glow top-right
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _teal.withOpacity(0.2),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Small blue accent bottom-left
          Positioned(
            bottom: 40, left: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _blue.withOpacity(0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar: label + icon ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: _teal3, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 7),
                            Text('PATIENT REGISTRY', style: GoogleFonts.ibmPlexSans(fontSize: 10, fontWeight: FontWeight.w800, color: _teal3.withOpacity(0.7), letterSpacing: 2.0)),
                          ]),
                          const SizedBox(height: 6),
                          Text('Patients &', style: GoogleFonts.barlow(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.2, height: 1.0)),
                          Text('Referrals', style: GoogleFonts.barlow(fontSize: 34, fontWeight: FontWeight.w900, color: _teal3, letterSpacing: -1.2, height: 1.0, fontStyle: FontStyle.italic)),
                        ],
                      ),
                      const Spacer(),
                      // Hero number circle
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_teal, _teal2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: _teal.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$total', style: GoogleFonts.barlow(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                            Text('patients', style: GoogleFonts.ibmPlexSans(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7), letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ── Stats cards row ──
                  Row(children: [
                    _statChip('$passed', 'Passed', _green, Icons.check_circle_rounded, passed / (total == 0 ? 1 : total)),
                    const SizedBox(width: 8),
                    _statChip('$referred', 'Referred', _red, Icons.warning_rounded, referred / (total == 0 ? 1 : total)),
                    const SizedBox(width: 8),
                    _statChip('$pending', 'Pending', _amber, Icons.schedule_rounded, pending / (total == 0 ? 1 : total)),
                    const SizedBox(width: 8),
                    _statChip('$passRate%', 'Pass Rate', _teal3, Icons.insights_rounded, passed / (total == 0 ? 1 : total)),
                  ]),
                  const SizedBox(height: 16),
                  // ── Search bar ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEF2F6)),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Icon(Icons.search_rounded, size: 18, color: const Color(0xFF0D9488)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v.toLowerCase()),
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A2A3D)),
                            decoration: InputDecoration(
                              hintText: 'Search name, ID, village...',
                              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(color: const Color(0xFFEEF2F6), shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, size: 13, color: const Color(0xFF8FA0B4)),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _teal.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _teal3.withOpacity(0.3)),
                              ),
                              child: Text('Search', style: GoogleFonts.ibmPlexSans(fontSize: 9, fontWeight: FontWeight.w700, color: _teal3)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Filter chips ──
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        'All','Pass','Refer','Pending','Child','Adult','Elderly',
                        'Overdue','Notified','Attended','Completed','Cancelled',
                      ].map((f) => _filterChip(f)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String number, String label, Color color, IconData icon, double ratio) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 11, color: color.withOpacity(0.8)),
              const Spacer(),
              Text(number, style: GoogleFonts.barlow(fontSize: 18, fontWeight: FontWeight.w900, color: color, height: 1.0)),
            ]),
            const SizedBox(height: 6),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 5),
            Text(label.toUpperCase(), style: GoogleFonts.ibmPlexSans(fontSize: 7, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.35), letterSpacing: 1.0)),
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

  // ── Campaign card ──
  Widget _buildCampaignCard(Map<String,dynamic> c) {
    final name     = c['name'] as String;
    final location = c['location'] as String;
    final group    = c['target_group'] as String;
    final total    = (c['total'] as int?) ?? 0;
    final passed   = (c['passed'] as int?) ?? 0;
    final referred = (c['referred'] as int?) ?? 0;
    final passRate = total > 0 ? (passed / total * 100).round() : 0;
    final createdAt = c['created_at'] as String;
    String dateLabel = '';
    try {
      final dt = DateTime.parse(createdAt);
      const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      dateLabel = dt.day.toString() + ' ' + months[dt.month] + ' ' + dt.year.toString();
    } catch (_) {}

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => _CampaignDetailScreen(campaign: c),
        )).then((_) => _loadPatients()),
        onLongPress: () => _confirmDeleteCampaign(c),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_ink, _ink2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_teal, _teal2]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: _teal.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(location + ' · ' + group, style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.5))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _teal.withOpacity(0.2), borderRadius: BorderRadius.circular(99), border: Border.all(color: _teal3.withOpacity(0.3))),
                  child: Text('CAMPAIGN', style: GoogleFonts.ibmPlexSans(fontSize: 8, fontWeight: FontWeight.w800, color: _teal3, letterSpacing: 1.0)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                _campStat(total.toString(),    'Screened', Colors.black87),
                _campStat(passed.toString(),   'Passed',   _green),
                _campStat(referred.toString(), 'Referred', _red),
                _campStat(passRate.toString() + '%', 'Pass Rate', _teal),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(dateLabel, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
                  const SizedBox(height: 2),
                  Text('View →', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _teal)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmDeleteCampaign(Map<String,dynamic> c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_rounded, color: _red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Delete Campaign',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D)))),
        ]),
        content: Text(
          'Delete "${c['name']}" and all ${(c['total'] as int?) ?? 0} patient records inside? This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5E7291), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF8FA0B4))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteCampaign(c['id'] as String);
              await _loadPatients();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Campaign "${c['name']}" deleted.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                backgroundColor: _red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('Delete All', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _campStat(String value, String label, Color color) => Padding(
    padding: const EdgeInsets.only(right: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: GoogleFonts.barlow(fontSize: 18, fontWeight: FontWeight.w900, color: color, height: 1.0)),
      Text(label, style: GoogleFonts.ibmPlexSans(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF8FA0B4))),
    ]),
  );

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
                              Flexible(
                                child: Text(
                                  '${p.age} yrs · ${p.gender} · ${p.village}',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF8FA0B4),
                                    fontWeight: FontWeight.w400,
                                  ),
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
                                      GestureDetector(
                                        onTap: () => _showUpdateStatusSheet(p),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _referralStatusColor(p.referralStatus).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(99),
                                            border: Border.all(color: _referralStatusColor(p.referralStatus).withOpacity(0.3), width: 1),
                                          ),
                                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                                            Text(p.referralStatus?.toUpperCase() ?? '',
                                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                                                    color: _referralStatusColor(p.referralStatus))),
                                            const SizedBox(width: 4),
                                            Icon(Icons.edit_rounded, size: 9, color: _referralStatusColor(p.referralStatus)),
                                          ]),
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
                                      Flexible(
                                        child: Text(
                                          p.id,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF8FA0B4),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 11,
                                        color: Color(0xFF8FA0B4),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          p.date,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF8FA0B4),
                                            fontWeight: FontWeight.w500,
                                          ),
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

  void _showUpdateStatusSheet(_Patient p) {
    final statuses = [
      {'value': 'pending',   'label': 'Pending',   'icon': Icons.schedule_rounded,             'color': _amber},
      {'value': 'notified',  'label': 'Notified',  'icon': Icons.notifications_active_rounded, 'color': _blue},
      {'value': 'attended',  'label': 'Attended',  'icon': Icons.check_circle_outline_rounded, 'color': _teal},
      {'value': 'completed', 'label': 'Completed', 'icon': Icons.check_circle_rounded,         'color': _green},
      {'value': 'overdue',   'label': 'Overdue',   'icon': Icons.error_rounded,                'color': _red},
      {'value': 'cancelled', 'label': 'Cancelled', 'icon': Icons.cancel_rounded,               'color': Colors.grey},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFDDE4EC), borderRadius: BorderRadius.circular(99)),
            )),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.update_rounded, color: _teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Update Referral Status', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D))),
                Text(p.name, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8FA0B4))),
              ])),
            ]),
            const SizedBox(height: 20),
            ...statuses.map((st) {
              final val = st['value'] as String;
              final isActive = p.referralStatus == val;
              final color = st['color'] as Color;
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final screenings = await DatabaseHelper.instance.getScreeningsForPatient(p.id);
                  if (screenings.isEmpty) return;
                  final screeningId = screenings.first['id'] as int;
                  await DatabaseHelper.instance.updateReferralStatus(screeningId, val);
                  await _loadPatients();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Status updated to ' + (st['label'] as String) + ' for ' + p.name,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                    backgroundColor: color,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isActive ? color.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isActive ? color : const Color(0xFFEEF2F6), width: isActive ? 2 : 1.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(st['icon'] as IconData, size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(st['label'] as String,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                            color: isActive ? color : const Color(0xFF1A2A3D)))),
                    if (isActive) Icon(Icons.check_circle_rounded, color: color, size: 20),
                  ]),
                ),
              );
            }),
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

  String _toWhatsAppPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('256') && digits.length >= 12) return digits;
    if (digits.startsWith('0') && digits.length == 10) return '256${digits.substring(1)}';
    return digits;
  }

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

  Future<void> _exportPatientToPDF(_Patient p) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
        const SizedBox(width: 12),
        Text('Generating PDF...', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
      ]),
      backgroundColor: _teal, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 30),
    ));
    try {
      final screenings = await DatabaseHelper.instance.getScreeningsForPatient(p.id);
      final latest = screenings.isNotEmpty ? screenings.first : null;
      final eyeResults = <Map<String, dynamic>>[];
      if (latest != null) {
        final od = (latest['od_logmar'] as String? ?? '');
        final os = (latest['os_logmar'] as String? ?? '');
        if (od.isNotEmpty) eyeResults.add({'eye': 'OD', 'logmar': od, 'cantTell': 0});
        if (os.isNotEmpty) eyeResults.add({'eye': 'OS', 'logmar': os, 'cantTell': 0});
        if (eyeResults.isEmpty) {
          final ods = (latest['od_snellen'] as String? ?? '');
          final oss = (latest['os_snellen'] as String? ?? '');
          if (ods.isNotEmpty && ods != '—') eyeResults.add({'eye': 'OD', 'logmar': _snellenToLogmar(ods), 'cantTell': 0});
          if (oss.isNotEmpty && oss != '—') eyeResults.add({'eye': 'OS', 'logmar': _snellenToLogmar(oss), 'cantTell': 0});
        }
      }
      final patientMap = {'name': p.name, 'id': p.id, 'age': p.age.toString(),
          'gender': p.gender, 'village': p.village, 'phone': p.phone};
      final date = (latest?['screening_date'] as String? ?? DateTime.now().toIso8601String()).substring(0, 10);
      final prefs = await SharedPreferences.getInstance();
      final chwName   = prefs.getString('chw_name')   ?? '';
      final chwCenter = prefs.getString('chw_center') ?? '';
      final chwTitle  = chwCenter.isNotEmpty ? 'Community Health Worker · $chwCenter' : 'Community Health Worker';
      String filePath;
      if (p.outcome == 'refer') {
        filePath = await PdfService.generateReferralPdf(
          patient: patientMap, eyeResults: eyeResults, screeningDate: date,
          facility: p.facility ?? 'Nearest Eye Clinic',
          chwName: chwName, chwTitle: chwTitle,
          appointmentDate: latest?['appointment_date'] as String?,
          conditions: p.safeConditions,
        );
      } else {
        filePath = await PdfService.generatePassResultPdf(
          patient: patientMap, eyeResults: eyeResults, screeningDate: date,
          chwName: chwName, chwTitle: chwTitle, conditions: p.safeConditions,
        );
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) await PdfService.openOrShare(context, filePath,
          '${p.outcome == 'refer' ? 'Referral Letter' : 'Screening Result'} — ${p.name}');
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) _showErrorSnackBar('PDF failed', e.toString());
    }
  }

  String _snellenToLogmar(String s) {
    const m = {'6/6':'0.0','6/9':'0.2','6/12':'0.3','6/18':'0.5',
               '6/24':'0.6','6/36':'0.8','6/48':'0.9','6/60':'1.0'};
    return m[s] ?? '0.5';
  }
  

  

  


  

  Future<void> _shareToWhatsApp(_Patient p) async {
    final message =
        '🏥 *VisionScreen ${p.outcome == 'refer' ? 'Referral' : 'Patient'} Update*\n\n'
        '👤 *Patient:* ${p.name}\n'
        '📊 *Demographics:* ${p.age} yrs · ${p.gender} · ${p.village}\n'
        '🏥 *Facility:* ${p.facility ?? 'N/A'}\n'
        '🔄 *Status:* ${p.referralStatus?.toUpperCase() ?? p.outcome.toUpperCase()}\n\n'
        '👁️ *Visual Acuity:*\n'
        '• OD (Right Eye): ${p.od}\n'
        '• OS (Left Eye): ${p.os}\n'
        '• OU (Both Eyes): ${p.ou}\n\n'
        '📱 *Generated by VisionScreen*';
    final phone = _toWhatsAppPhone(p.phone);
    final encoded = Uri.encodeComponent(message);
    final uri = phone.isNotEmpty
        ? Uri.parse('whatsapp://send?phone=$phone&text=$encoded')
        : Uri.parse('whatsapp://send?text=$encoded');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      if (mounted) _showErrorSnackBar('WhatsApp not available', 'Could not open WhatsApp on this device.');
    }
  }

  Future<void> _callPatient(_Patient p) async {
    if (p.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No phone number for ${p.name}.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
        backgroundColor: _amber, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
      return;
    }
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


// ── Campaign Detail Screen ────────────────────────────────────────────────────
class _CampaignDetailScreen extends StatefulWidget {
  final Map<String,dynamic> campaign;
  const _CampaignDetailScreen({required this.campaign});
  @override
  State<_CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<_CampaignDetailScreen> {
  List<_Patient> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
      return '${dt.day} ${['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month]}';
    } catch (_) { return iso.substring(0, 10); }
  }

  Future<void> _load() async {
    final rows = await DatabaseHelper.instance.getPatientsForCampaign(widget.campaign['id'] as String);
    final list = <_Patient>[];
    for (final r in rows) {
      final age = (r['age'] as int?) ?? 0;
      final conditions = ((r['conditions'] as String?) ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final outcome = (r['outcome'] as String?) ?? 'pending';
      final screeningDate = r['screening_date'] as String?;
      list.add(_Patient(
        initials: (r['name'] as String).split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join(),
        avatarGradient: [_teal, _teal2],
        photoUrl: (r['photo_path'] as String?) ?? '',
        name: r['name'] as String,
        age: age,
        gender: r['gender'] as String,
        village: (r['village'] as String?) ?? '',
        ageGroup: age < 18 ? 'child' : age > 60 ? 'elderly' : 'adult',
        od: (r['od_snellen'] as String?) ?? '—',
        os: (r['os_snellen'] as String?) ?? '—',
        ou: (r['ou_near_snellen'] as String?) ?? '—',
        outcome: outcome,
        date: screeningDate != null ? _formatDate(screeningDate) : 'Not screened',
        id: r['id'] as String,
        phone: (r['phone'] as String?) ?? '',
        facility: (r['referral_facility'] as String?)?.let((f) => f.isEmpty ? null : f),
        referralStatus: (r['referral_status'] as String?)?.let((s) => s.isEmpty ? null : s),
        conditions: conditions,
      ));
    }
    if (mounted) setState(() { _patients = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c        = widget.campaign;
    final name     = c['name'] as String;
    final location = c['location'] as String;
    final group    = c['target_group'] as String;
    final total    = (c['total'] as int?) ?? 0;
    final passed   = (c['passed'] as int?) ?? 0;
    final referred = (c['referred'] as int?) ?? 0;
    final passRate = total > 0 ? (passed / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_ink, _ink2], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
                  ),
                ),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _teal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: _teal3.withOpacity(0.3)),
                      ),
                      child: Text('CAMPAIGN · $group', style: GoogleFonts.ibmPlexSans(fontSize: 9, fontWeight: FontWeight.w800, color: _teal3, letterSpacing: 1.0)),
                    ),
                    const SizedBox(height: 8),
                    Text(name, style: GoogleFonts.barlow(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.8, height: 1.1)),
                    const SizedBox(height: 4),
                    Text(location, style: GoogleFonts.ibmPlexSans(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                  ])),
                  const SizedBox(width: 12),
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_teal, _teal2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: _teal.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                  ),
                ]),
                const SizedBox(height: 18),
                // Stats
                Row(children: [
                  _hStat('$total',    'Screened', Colors.white),
                  const SizedBox(width: 8),
                  _hStat('$passed',   'Passed',   _green),
                  const SizedBox(width: 8),
                  _hStat('$referred', 'Referred', _red),
                  const SizedBox(width: 8),
                  _hStat('$passRate%','Pass Rate', _teal3),
                ]),
              ]),
            ),
          ),
        ),
        // Patient list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _teal))
              : _patients.isEmpty
                  ? Center(child: Text('No patients in this campaign yet.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4))))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: _teal,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
                        itemCount: _patients.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(_patients.length.toString() + ' patient' + (_patients.length == 1 ? '' : 's'),
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: const Color(0xFF8FA0B4), letterSpacing: 1.2)),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _CampaignPatientCard(patient: _patients[i - 1], onRefresh: _load),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _hStat(String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.barlow(fontSize: 20, fontWeight: FontWeight.w900, color: color, height: 1.0)),
        Text(label.toUpperCase(), style: GoogleFonts.ibmPlexSans(fontSize: 7, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.35), letterSpacing: 0.8)),
      ]),
    ),
  );

  Widget _detailVaPill(String eye, String snellen, String outcome) {
    final col = outcome == 'refer' ? _red : _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: col.withOpacity(0.08), borderRadius: BorderRadius.circular(7), border: Border.all(color: col.withOpacity(0.2))),
      child: Text('$eye $snellen', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: col)),
    );
  }
}

// ── Campaign Patient Card — full featured, same as individual patient card ────
class _CampaignPatientCard extends StatelessWidget {
  final _Patient patient;
  final VoidCallback onRefresh;
  const _CampaignPatientCard({required this.patient, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    // Reuse the full patient card by wrapping in a temporary state holder
    return _CampaignPatientCardState(patient: patient, onRefresh: onRefresh);
  }
}

class _CampaignPatientCardState extends StatefulWidget {
  final _Patient patient;
  final VoidCallback onRefresh;
  const _CampaignPatientCardState({required this.patient, required this.onRefresh});
  @override
  State<_CampaignPatientCardState> createState() => __CampaignPatientCardStateState();
}

class __CampaignPatientCardStateState extends State<_CampaignPatientCardState> {
  _Patient get p => widget.patient;

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PatientHistorySheet(patient: p),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_rounded, color: _red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Delete Patient',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D)))),
        ]),
        content: Text('Delete ${p.name} and all their screening records? This cannot be undone.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5E7291), height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF8FA0B4))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deletePatient(p.id);
              widget.onRefresh();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _callPatient() async {
    if (p.phone.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No phone number for ${p.name}.', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
        backgroundColor: _amber, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    final uri = Uri(scheme: 'tel', path: p.phone);
    if (!await launchUrl(uri)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unable to dial ${p.name}.', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
        backgroundColor: _red, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (badgeLabel, badgeBg, badgeText, badgeIcon, accentColor) = _badgeProps(p.outcome);
    final ageGroupColor = _ageGroupColor(p.ageGroup);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _showHistory,
        onLongPress: _confirmDelete,
        borderRadius: BorderRadius.circular(16),
        highlightColor: const Color(0xFFF0F4F7),
        splashColor: const Color(0xFFDDE4EC),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 4, height: 72,
                  decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(99)),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: p.avatarGradient.last.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: p.photoUrl.isNotEmpty && File(p.photoUrl).existsSync()
                        ? Image.file(File(p.photoUrl), fit: BoxFit.cover, width: 50, height: 50)
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: p.avatarGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text(p.initials,
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(p.name, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D)))),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: ageGroupColor.withOpacity(0.1), borderRadius: BorderRadius.circular(99), border: Border.all(color: ageGroupColor.withOpacity(0.25))),
                        child: Text(_capitalize(p.ageGroup), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: ageGroupColor)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.person_outline_rounded, size: 11, color: Color(0xFF8FA0B4)),
                      const SizedBox(width: 4),
                      Flexible(child: Text('${p.age} yrs · ${p.gender} · ${p.village}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4)))),
                    ]),
                    const SizedBox(height: 8),
                    if (p.outcome != 'pending')
                      Row(children: [
                        _vaPill('OD', p.od, p.outcome),
                        const SizedBox(width: 5),
                        _vaPill('OS', p.os, p.outcome),
                        const SizedBox(width: 5),
                        _vaPill('OU', p.ou, p.outcome),
                      ])
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: _amber.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: _amber.withOpacity(0.2))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.hourglass_top_rounded, size: 11, color: _amber),
                          const SizedBox(width: 5),
                          Text('Awaiting screening', style: GoogleFonts.inter(fontSize: 11, color: _amber, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    if (p.safeConditions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 4, runSpacing: 4,
                        children: p.safeConditions.map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: _amber.withOpacity(0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: _amber.withOpacity(0.25))),
                          child: Text(c, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: _amber)),
                        )).toList(),
                      ),
                    ],
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(99), border: Border.all(color: accentColor.withOpacity(0.25))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(badgeIcon, size: 11, color: accentColor),
                      const SizedBox(width: 4),
                      Text(badgeLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: badgeText)),
                    ]),
                  ),
                ]),
              ]),
            ),
            // Bottom strip
            Container(
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                border: Border(top: BorderSide(color: accentColor.withOpacity(0.12))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(children: [
                const Icon(Icons.badge_outlined, size: 12, color: Color(0xFF8FA0B4)),
                const SizedBox(width: 5),
                Flexible(child: Text(p.id, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4), fontWeight: FontWeight.w500))),
                const Spacer(),
                const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF8FA0B4)),
                const SizedBox(width: 4),
                Flexible(child: Text(p.date, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4), fontWeight: FontWeight.w500))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _callPatient,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: p.phone.isNotEmpty ? _blue.withOpacity(0.1) : const Color(0xFFF0F4F7),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: p.phone.isNotEmpty ? _blue.withOpacity(0.3) : const Color(0xFFEEF2F6)),
                    ),
                    child: Icon(Icons.phone_rounded, size: 13, color: p.phone.isNotEmpty ? _blue : const Color(0xFFB0BEC5)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _shareToWhatsAppCampaign(p),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.1), borderRadius: BorderRadius.circular(7), border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3))),
                    child: const Icon(Icons.send_rounded, size: 13, color: Color(0xFF25D366)),
                  ),
                ),
                const SizedBox(width: 6),
                if (p.outcome == 'refer') ...[
                  GestureDetector(
                    onTap: () => _showUpdateStatusSheetCampaign(p),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: _amber.withOpacity(0.1), borderRadius: BorderRadius.circular(7), border: Border.all(color: _amber.withOpacity(0.3))),
                      child: const Icon(Icons.update_rounded, size: 13, color: _amber),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                GestureDetector(
                  onTap: () => _exportPatientDataCampaign(p),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
                    child: const Icon(Icons.picture_as_pdf_outlined, size: 13, color: _teal),
                  ),
                ),
                const SizedBox(width: 6),
                Text('View →', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _showUpdateStatusSheetCampaign(_Patient p) {
    final statuses = [
      {'value': 'pending',   'label': 'Pending',   'icon': Icons.schedule_rounded,             'color': _amber},
      {'value': 'notified',  'label': 'Notified',  'icon': Icons.notifications_active_rounded, 'color': _blue},
      {'value': 'attended',  'label': 'Attended',  'icon': Icons.check_circle_outline_rounded, 'color': _teal},
      {'value': 'completed', 'label': 'Completed', 'icon': Icons.check_circle_rounded,         'color': _green},
      {'value': 'overdue',   'label': 'Overdue',   'icon': Icons.error_rounded,                'color': _red},
      {'value': 'cancelled', 'label': 'Cancelled', 'icon': Icons.cancel_rounded,               'color': Colors.grey},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFDDE4EC), borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 16),
          Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.update_rounded, color: _teal, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Update Referral Status', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D))),
              Text(p.name, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8FA0B4))),
            ])),
          ]),
          const SizedBox(height: 20),
          ...statuses.map((st) {
            final val = st['value'] as String;
            final isActive = p.referralStatus == val;
            final color = st['color'] as Color;
            return GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final screenings = await DatabaseHelper.instance.getScreeningsForPatient(p.id);
                if (screenings.isEmpty) return;
                await DatabaseHelper.instance.updateReferralStatus(screenings.first['id'] as int, val);
                widget.onRefresh();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Status updated to ' + (st['label'] as String),
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                  backgroundColor: color, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isActive ? color.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isActive ? color : const Color(0xFFEEF2F6), width: isActive ? 2 : 1.5),
                ),
                child: Row(children: [
                  Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(st['icon'] as IconData, size: 18, color: color)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(st['label'] as String,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                          color: isActive ? color : const Color(0xFF1A2A3D)))),
                  if (isActive) Icon(Icons.check_circle_rounded, color: color, size: 20),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  Future<void> _shareToWhatsAppCampaign(_Patient p) async {
    final message =
        '🏥 *VisionScreen ${p.outcome == 'refer' ? 'Referral' : 'Patient'} Update*\n\n'
        '👤 *Patient:* ${p.name}\n'
        '📊 *Demographics:* ${p.age} yrs · ${p.gender} · ${p.village}\n'
        '🏥 *Facility:* ${p.facility ?? 'N/A'}\n'
        '🔄 *Status:* ${p.referralStatus?.toUpperCase() ?? p.outcome.toUpperCase()}\n\n'
        '👁️ *Visual Acuity:*\n'
        '• OD (Right Eye): ${p.od}\n'
        '• OS (Left Eye): ${p.os}\n'
        '• OU (Both Eyes): ${p.ou}\n\n'
        '📱 *Generated by VisionScreen*';
    final phone = _toWhatsAppPhone(p.phone);
    final encoded = Uri.encodeComponent(message);
    final uri = phone.isNotEmpty
        ? Uri.parse('whatsapp://send?phone=$phone&text=$encoded')
        : Uri.parse('whatsapp://send?text=$encoded');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not open WhatsApp.', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
        backgroundColor: _red, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _exportPatientDataCampaign(_Patient p) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
        const SizedBox(width: 12),
        Text('Generating PDF...', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
      ]),
      backgroundColor: _teal, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 30),
    ));
    try {
      final screenings = await DatabaseHelper.instance.getScreeningsForPatient(p.id);
      final latest = screenings.isNotEmpty ? screenings.first : null;
      final eyeResults = <Map<String, dynamic>>[];
      if (latest != null) {
        final od = (latest['od_logmar'] as String? ?? '');
        final os = (latest['os_logmar'] as String? ?? '');
        if (od.isNotEmpty) eyeResults.add({'eye': 'OD', 'logmar': od, 'cantTell': 0});
        if (os.isNotEmpty) eyeResults.add({'eye': 'OS', 'logmar': os, 'cantTell': 0});
        if (eyeResults.isEmpty) {
          if (p.od != '—') eyeResults.add({'eye': 'OD', 'logmar': _snellenToLogmar(p.od), 'cantTell': 0});
          if (p.os != '—') eyeResults.add({'eye': 'OS', 'logmar': _snellenToLogmar(p.os), 'cantTell': 0});
        }
      }
      final patientMap = {'name': p.name, 'id': p.id, 'age': p.age.toString(),
          'gender': p.gender, 'village': p.village, 'phone': p.phone};
      final date = (latest?['screening_date'] as String? ?? DateTime.now().toIso8601String()).substring(0, 10);
      final prefs = await SharedPreferences.getInstance();
      final chwName   = prefs.getString('chw_name')   ?? '';
      final chwCenter = prefs.getString('chw_center') ?? '';
      final chwTitle  = chwCenter.isNotEmpty ? 'Community Health Worker · $chwCenter' : 'Community Health Worker';
      String filePath;
      if (p.outcome == 'refer') {
        filePath = await PdfService.generateReferralPdf(
          patient: patientMap, eyeResults: eyeResults, screeningDate: date,
          facility: p.facility ?? 'Nearest Eye Clinic',
          chwName: chwName, chwTitle: chwTitle,
          appointmentDate: latest?['appointment_date'] as String?,
          conditions: p.safeConditions,
        );
      } else {
        filePath = await PdfService.generatePassResultPdf(
          patient: patientMap, eyeResults: eyeResults, screeningDate: date,
          chwName: chwName, chwTitle: chwTitle, conditions: p.safeConditions,
        );
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) await PdfService.openOrShare(context, filePath,
          '${p.outcome == 'refer' ? 'Referral Letter' : 'Screening Result'} — ${p.name}');
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('PDF failed: $e', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
        backgroundColor: _red, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }
  Widget _vaPill(String eye, String value, String outcome) {
    final isBad = outcome == 'refer' && value != '6/6' && value != '6/9' && value != '6/12';
    final fg = isBad ? _red : _teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: fg.withOpacity(0.08), borderRadius: BorderRadius.circular(7), border: Border.all(color: fg.withOpacity(0.2))),
      child: RichText(text: TextSpan(children: [
        TextSpan(text: '$eye ', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8FA0B4), fontWeight: FontWeight.w500)),
        TextSpan(text: value, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      ])),
    );
  }

  (String, Color, Color, IconData, Color) _badgeProps(String outcome) {
    return switch (outcome) {
      'pass' => ('Pass', const Color(0xFFDCFCE7), const Color(0xFF15803D), Icons.check_circle_rounded, _green),
      'refer' => ('Refer', const Color(0xFFFEE2E2), const Color(0xFF991B1B), Icons.warning_rounded, _red),
      _ => ('Pending', const Color(0xFFE0F2FE), const Color(0xFF0369A1), Icons.schedule_rounded, _amber),
    };
  }

  Color _ageGroupColor(String group) => switch (group) {
    'child' => _blue,
    'elderly' => _red,
    _ => _teal,
  };

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _toWhatsAppPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('256') && digits.length >= 12) return digits;
    if (digits.startsWith('0') && digits.length == 10) return '256${digits.substring(1)}';
    return digits;
  }

  String _snellenToLogmar(String s) {
    const m = {'6/6':'0.0','6/9':'0.2','6/12':'0.3','6/18':'0.5',
               '6/24':'0.6','6/36':'0.8','6/48':'0.9','6/60':'1.0'};
    return m[s] ?? '0.5';
  }
}
