import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'referrals_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

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

// ── Patient model ──
class _Patient {
  const _Patient({
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
  });

  final String initials;
  final List<Color> avatarGradient;
  final String photoUrl;
  final String name;
  final int age;
  final String gender;
  final String village;
  final String ageGroup; // adult | child | elderly
  final String od, os, ou;
  final String outcome; // pass | refer | pending
  final String date;
  final String id;
}

final _patients = <_Patient>[
  _Patient(
    initials: 'AK',
    avatarGradient: [_teal, _teal2],
    photoUrl:
        'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=150&q=80',
    name: 'Akello Mercy',
    age: 34,
    gender: 'F',
    village: 'Nakawa, Kampala',
    ageGroup: 'adult',
    od: '6/6',
    os: '6/9',
    ou: '6/6',
    outcome: 'pass',
    date: 'Today · 8m ago',
    id: 'PAT-00312',
  ),
  _Patient(
    initials: 'OJ',
    avatarGradient: [Color(0xFF7F1D1D), _red],
    photoUrl:
        'https://images.unsplash.com/photo-1506277886164-e25aa3f4ef7f?w=150&q=80',
    name: 'Okello James',
    age: 58,
    gender: 'M',
    village: 'Bwaise, Kampala',
    ageGroup: 'adult',
    od: '6/12',
    os: '6/18',
    ou: '6/12',
    outcome: 'refer',
    date: 'Today · 22m ago',
    id: 'PAT-00298',
  ),
  _Patient(
    initials: 'NA',
    avatarGradient: [Color(0xFF065F46), _green],
    photoUrl:
        'https://images.unsplash.com/photo-1589156280159-27698a70f29e?w=150&q=80',
    name: 'Nakato Aisha',
    age: 27,
    gender: 'F',
    village: 'Ntinda, Kampala',
    ageGroup: 'adult',
    od: '6/9',
    os: '6/9',
    ou: '6/6',
    outcome: 'pass',
    date: 'Today · 1hr ago',
    id: 'PAT-00301',
  ),
  _Patient(
    initials: 'MW',
    avatarGradient: [Color(0xFF78350F), _amber],
    photoUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
    name: 'Mugisha Wilson',
    age: 45,
    gender: 'M',
    village: 'Kireka, Wakiso',
    ageGroup: 'adult',
    od: '—',
    os: '—',
    ou: '—',
    outcome: 'pending',
    date: 'Today · Pending',
    id: 'PAT-00315',
  ),
  _Patient(
    initials: 'KR',
    avatarGradient: [_teal, _teal2],
    photoUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&q=80',
    name: 'Kyomuhendo Rose',
    age: 19,
    gender: 'F',
    village: 'Rubaga, Kampala',
    ageGroup: 'adult',
    od: '6/6',
    os: '6/6',
    ou: '6/6',
    outcome: 'pass',
    date: '26 Mar',
    id: 'PAT-00289',
  ),
  _Patient(
    initials: 'BS',
    avatarGradient: [Color(0xFF1E3A5F), _blue],
    photoUrl:
        'https://images.unsplash.com/photo-1552058544-f2b08422138a?w=150&q=80',
    name: 'Byaruhanga Sam',
    age: 62,
    gender: 'M',
    village: 'Kawempe, Kampala',
    ageGroup: 'elderly',
    od: '6/24',
    os: '6/36',
    ou: '6/24',
    outcome: 'refer',
    date: '25 Mar',
    id: 'PAT-00276',
  ),
  _Patient(
    initials: 'TK',
    avatarGradient: [Color(0xFF1E3A5F), _blue],
    photoUrl:
        'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=150&q=80',
    name: 'Tendo Kevin',
    age: 9,
    gender: 'M',
    village: 'Nansana, Wakiso',
    ageGroup: 'child',
    od: '6/9',
    os: '6/9',
    ou: '6/6',
    outcome: 'pass',
    date: '24 Mar',
    id: 'PAT-00261',
  ),
  _Patient(
    initials: 'AN',
    avatarGradient: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    photoUrl:
        'https://images.unsplash.com/photo-1516627145497-ae6968895b74?w=150&q=80',
    name: 'Apio Norah',
    age: 8,
    gender: 'F',
    village: 'Kira, Wakiso',
    ageGroup: 'child',
    od: '6/18',
    os: '6/12',
    ou: '6/12',
    outcome: 'refer',
    date: '23 Mar',
    id: 'PAT-00254',
  ),
];

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'All';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Patient> get _filtered => _patients.where((p) {
    final matchQ =
        _query.isEmpty ||
        p.name.toLowerCase().contains(_query) ||
        p.id.toLowerCase().contains(_query) ||
        p.village.toLowerCase().contains(_query);
    final matchF =
        _filter == 'All' ||
        (_filter == 'Pass' && p.outcome == 'pass') ||
        (_filter == 'Refer' && p.outcome == 'refer') ||
        (_filter == 'Pending' && p.outcome == 'pending') ||
        (_filter == 'Child' && p.ageGroup == 'child') ||
        (_filter == 'Adult' && p.ageGroup == 'adult') ||
        (_filter == 'Elderly' && p.ageGroup == 'elderly');
    return matchQ && matchF;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: list.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                    itemCount: list.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0)
                        return _sectionLabel(
                          'Today · ${DateTime.now().day} Mar ${DateTime.now().year}',
                        );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _buildCard(list[i - 1]),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
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
                        'Patients',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '247 registered · Wakiso & Kampala',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _teal3.withOpacity(0.55),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // New Patient button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_teal, _teal2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _teal.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'New Patient',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  _statChip('247', 'Total', Colors.white),
                  const SizedBox(width: 8),
                  _statChip('183', 'Passed', _green),
                  const SizedBox(width: 8),
                  _statChip('55', 'Referred', _red),
                  const SizedBox(width: 8),
                  _statChip('9', 'Pending', _amber),
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
                    hintText: 'Search by name, ID or village...',
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
        onTap: () {},
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
                        child: Image.network(
                          p.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
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
                child: Row(
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

  // ── Empty state ──
  Widget _buildEmpty() {
    return Center(
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

  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.people_alt_rounded, 'label': 'Patients'},
      {'icon': Icons.assignment_rounded, 'label': 'Referrals'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Analytics'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEEF2F6), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isActive = e.key == 1; // Patients is index 1
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (e.key == 0) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(-1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOutCubic;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
                        );
                        return FadeTransition(
                          opacity: fadeAnimation,
                          child: SlideTransition(position: offsetAnimation, child: child),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                      reverseTransitionDuration: const Duration(milliseconds: 350),
                    ),
                    (_) => false,
                  );
                }
                if (e.key == 2) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const ReferralsScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOutCubic;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
                        );
                        return FadeTransition(
                          opacity: fadeAnimation,
                          child: SlideTransition(position: offsetAnimation, child: child),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                      reverseTransitionDuration: const Duration(milliseconds: 350),
                    ),
                  );
                }
                if (e.key == 3) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const AnalyticsScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOutCubic;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
                        );
                        return FadeTransition(
                          opacity: fadeAnimation,
                          child: SlideTransition(position: offsetAnimation, child: child),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                      reverseTransitionDuration: const Duration(milliseconds: 350),
                    ),
                  );
                }
                if (e.key == 4) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOutCubic;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
                        );
                        return FadeTransition(
                          opacity: fadeAnimation,
                          child: SlideTransition(position: offsetAnimation, child: child),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                      reverseTransitionDuration: const Duration(milliseconds: 350),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0D9488).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      e.value['icon'] as IconData,
                      size: isActive ? 26 : 22,
                      color: isActive
                          ? const Color(0xFF0D9488)
                          : const Color(0xFF8FA0B4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.value['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: isActive ? 10 : 9,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF8FA0B4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: isActive ? 18 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(99),
                      ),
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
