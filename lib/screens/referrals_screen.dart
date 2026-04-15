import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'patients_screen.dart';

const _ink = Color(0xFF04091A);
const _ink2 = Color(0xFF0B1530);
const _teal = Color(0xFF0D9488);
const _teal2 = Color(0xFF14B8A6);
const _teal3 = Color(0xFF5EEAD4);
const _green = Color(0xFF22C55E);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _blue = Color(0xFF3B82F6);

class _Referral {
  const _Referral({
    required this.initials,
    required this.avatarColors,
    required this.photoUrl,
    required this.name,
    required this.demographic,
    required this.facility,
    required this.dueDate,
    required this.status,
    required this.od,
    required this.os,
  });
  final String initials;
  final List<Color> avatarColors;
  final String photoUrl;
  final String name;
  final String demographic;
  final String facility;
  final String dueDate;
  final String
  status; // overdue | notified | pending | attended | completed | cancelled
  final String od, os;
}

final _referrals = <_Referral>[
  _Referral(
    initials: 'OJ',
    avatarColors: [Color(0xFF7F1D1D), _red],
    photoUrl:
        'https://images.unsplash.com/photo-1506277886164-e25aa3f4ef7f?w=150&q=80',
    name: 'Okello James',
    demographic: 'M · 58 yrs',
    facility: 'Mulago National Referral Hospital',
    dueDate: '29 Mar 2026',
    status: 'overdue',
    od: '6/12',
    os: '6/18',
  ),
  _Referral(
    initials: 'BS',
    avatarColors: [Color(0xFF1E3A5F), _blue],
    photoUrl:
        'https://images.unsplash.com/photo-1552058544-f2b08422138a?w=150&q=80',
    name: 'Byaruhanga Sam',
    demographic: 'M · 62 yrs',
    facility: 'Kampala Eye Clinic',
    dueDate: '2 Apr 2026',
    status: 'notified',
    od: '6/24',
    os: '6/36',
  ),
  _Referral(
    initials: 'KK',
    avatarColors: [Color(0xFF78350F), _amber],
    photoUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
    name: 'Kabanda Kevin',
    demographic: 'M · 41 yrs',
    facility: 'Nsambya Hospital',
    dueDate: '5 Apr 2026',
    status: 'pending',
    od: '6/18',
    os: '6/12',
  ),
  _Referral(
    initials: 'AN',
    avatarColors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    photoUrl:
        'https://images.unsplash.com/photo-1516627145497-ae6968895b74?w=150&q=80',
    name: 'Apio Norah',
    demographic: 'F · 8 yrs',
    facility: 'Mulago National Referral Hospital',
    dueDate: '7 Apr 2026',
    status: 'attended',
    od: '6/18',
    os: '6/12',
  ),
  _Referral(
    initials: 'KR',
    avatarColors: [_teal, _teal2],
    photoUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&q=80',
    name: 'Kyomuhendo Rose',
    demographic: 'F · 19 yrs',
    facility: 'Makerere University Hospital',
    dueDate: '10 Apr 2026',
    status: 'completed',
    od: '6/9',
    os: '6/9',
  ),
  _Referral(
    initials: 'MW',
    avatarColors: [Color(0xFF78350F), _amber],
    photoUrl:
        'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=150&q=80',
    name: 'Mugisha Wilson',
    demographic: 'M · 45 yrs',
    facility: 'Mengo Hospital',
    dueDate: '12 Apr 2026',
    status: 'cancelled',
    od: '6/12',
    os: '6/18',
  ),
];

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  String _filter = 'All';

  static const _filters = [
    'All',
    'Pending',
    'Notified',
    'Attended',
    'Overdue',
    'Completed',
    'Cancelled',
  ];

  List<_Referral> get _filtered => _referrals
      .where((r) => _filter == 'All' || r.status == _filter.toLowerCase())
      .toList();

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final overdue = _referrals.where((r) => r.status == 'overdue').length;
    final active = _referrals
        .where((r) => ['pending', 'notified', 'attended'].contains(r.status))
        .length;
    final completed = _referrals.where((r) => r.status == 'completed').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(overdue, active, completed),
          Expanded(
            child: list.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    itemCount: list.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildCard(list[i]),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(int overdue, int active, int completed) {
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
                        'Referrals',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_referrals.length} total · $overdue overdue',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _teal3.withOpacity(0.55),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // New referral button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_teal, _teal2]),
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
                          'New Referral',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
                  _statChip('${_referrals.length}', 'Total', Colors.white),
                  const SizedBox(width: 8),
                  _statChip('$active', 'Active', _amber),
                  const SizedBox(width: 8),
                  _statChip('$overdue', 'Overdue', _red),
                  const SizedBox(width: 8),
                  _statChip('$completed', 'Completed', _green),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Filter chips
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _filters.map(_filterChip).toList(),
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

  Widget _buildCard(_Referral r) {
    final (statusLabel, statusBg, statusText, statusIcon, accentColor) =
        _statusProps(r.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showUpdateSheet(r),
        borderRadius: BorderRadius.circular(16),
        highlightColor: const Color(0xFFF0F4F7),
        splashColor: const Color(0xFFDDE4EC),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top body
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Accent bar
                    Container(
                      width: 4,
                      height: 68,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: r.avatarColors.last.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          r.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: r.avatarColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                r.initials,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
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
                          Text(
                            r.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A2A3D),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            r.demographic,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF8FA0B4),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.local_hospital_rounded,
                                size: 11,
                                color: Color(0xFF8FA0B4),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  r.facility,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF5E7291),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // VA pills
                          Row(
                            children: [
                              _vaPill('OD', r.od),
                              const SizedBox(width: 5),
                              _vaPill('OS', r.os),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: accentColor.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 10, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom bar
              Container(
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  border: Border(
                    top: BorderSide(color: accentColor.withOpacity(0.12)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      r.dueDate,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Update Status →',
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

  Widget _vaPill(String eye, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _teal.withOpacity(0.2)),
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
                color: _teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 48,
            color: Color(0xFFDDE4EC),
          ),
          const SizedBox(height: 12),
          Text(
            'No referrals found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A2A3D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different filter.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8FA0B4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'activeIcon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.people_alt_rounded, 'activeIcon': Icons.people_alt_rounded, 'label': 'Patients'},
      {'icon': Icons.assignment_rounded, 'activeIcon': Icons.assignment_rounded, 'label': 'Referrals'},
      {'icon': Icons.bar_chart_rounded, 'activeIcon': Icons.bar_chart_rounded, 'label': 'Analytics'},
      {'icon': Icons.settings_rounded, 'activeIcon': Icons.settings_rounded, 'label': 'Settings'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEF2F6), width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isActive = e.key == 2; // Referrals tab is active
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (e.key == 0) {
                  Navigator.pushReplacementNamed(context, '/home');
                  return;
                }
                if (e.key == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PatientsScreen()),
                  );
                  return;
                }
                // Current tab (referrals) - do nothing
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
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
                    AnimatedScale(
                      scale: isActive ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        e.value['icon'] as IconData,
                        size: isActive ? 26 : 22,
                        color: isActive
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF8FA0B4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: GoogleFonts.inter(
                        fontSize: isActive ? 10 : 9,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF8FA0B4),
                        letterSpacing: isActive ? 0.3 : 0,
                      ),
                      child: Text(e.value['label'] as String),
                    ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
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

  void _showUpdateSheet(_Referral r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateStatusSheet(referral: r),
    );
  }

  (String, Color, Color, IconData, Color) _statusProps(String status) {
    return switch (status) {
      'overdue' => (
        'Overdue',
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
        Icons.error_rounded,
        _amber,
      ),
      'notified' => (
        'Notified',
        const Color(0xFFE0F2FE),
        const Color(0xFF0369A1),
        Icons.notifications_active_rounded,
        _blue,
      ),
      'attended' => (
        'Attended',
        const Color(0xFFEDE9FE),
        const Color(0xFF6D28D9),
        Icons.how_to_reg_rounded,
        const Color(0xFF8B5CF6),
      ),
      'completed' => (
        'Completed',
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
        Icons.check_circle_rounded,
        _green,
      ),
      'cancelled' => (
        'Cancelled',
        const Color(0xFFF0F4F7),
        const Color(0xFF5E7291),
        Icons.cancel_rounded,
        const Color(0xFF8FA0B4),
      ),
      _ => (
        'Pending',
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
        Icons.schedule_rounded,
        _amber,
      ),
    };
  }
}

// ── Update Status Bottom Sheet ──
class _UpdateStatusSheet extends StatefulWidget {
  const _UpdateStatusSheet({required this.referral});
  final _Referral referral;

  @override
  State<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<_UpdateStatusSheet> {
  String _selected = '';

  static const _statuses = [
    ('pending', 'Pending', _amber, Icons.schedule_rounded),
    ('notified', 'Notified', _blue, Icons.notifications_active_rounded),
    ('attended', 'Attended', Color(0xFF8B5CF6), Icons.how_to_reg_rounded),
    ('completed', 'Completed', _green, Icons.check_circle_rounded),
    ('overdue', 'Overdue', _red, Icons.error_rounded),
    ('cancelled', 'Cancelled', Color(0xFF8FA0B4), Icons.cancel_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.referral.status;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            'Update Referral Status',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A2A3D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.referral.name} · ${widget.referral.facility}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8FA0B4),
            ),
          ),
          const SizedBox(height: 16),
          // Status grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: _statuses.map((s) {
              final (key, label, color, icon) = s;
              final isActive = _selected == key;
              return GestureDetector(
                onTap: () => setState(() => _selected = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withOpacity(0.15)
                        : const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? color : const Color(0xFFEEF2F6),
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 12,
                        color: isActive ? color : const Color(0xFF8FA0B4),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive ? color : const Color(0xFF8FA0B4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Status updated to $_selected',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: _teal,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save Status',
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
    );
  }
}
