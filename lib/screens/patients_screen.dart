import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../repositories/patient_repository.dart';
import '../repositories/campaign_repository.dart';
import '../repositories/screening_repository.dart';
import '../features/patients/patient_actions.dart';
import '../features/patients/patient_list_item.dart';
import '../features/patients/patients_controller.dart';
import 'bulk_mode_screen.dart';
import '../widgets/vs_skeleton.dart';
import '../utils/page_transitions.dart';
import '../utils/haptics.dart';

// -- Colours (shared with the rest of the app) --
const _teal = Color(0xFF0D9488);
const _teal2 = Color(0xFF14B8A6);
const _green = Color(0xFF22C55E);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _blue = Color(0xFF3B82F6);

String? _nullIfEmpty(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

Widget _buildVaPill(String eye, String value, String outcome) {
  final isBad =
      outcome == 'refer' && value != '6/6' && value != '6/9' && value != '6/12';
  final foreground = isBad ? _red : _teal;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: foreground.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: foreground.withValues(alpha: 0.2), width: 1),
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
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showReferralStatusSheet(
  BuildContext context, {
  required PatientListItem patient,
  required Future<void> Function(String status) onStatusSelected,
}) async {
  await showModalBottomSheet(
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
                  color: _teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.update_rounded, color: _teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Referral Status',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A2A3D),
                      ),
                    ),
                    Text(
                      patient.name,
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
          const SizedBox(height: 20),
          ...patientReferralStatusOptions.map((statusOption) {
            final isActive = patient.referralStatus == statusOption.value;
            return GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await onStatusSelected(statusOption.value);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Status updated to ${statusOption.label}${patient.name.isEmpty ? '' : ' for ${patient.name}'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: statusOption.color,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isActive
                      ? statusOption.color.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? statusOption.color
                        : const Color(0xFFEEF2F6),
                    width: isActive ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusOption.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        statusOption.icon,
                        size: 18,
                        color: statusOption.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusOption.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? statusOption.color
                              : const Color(0xFF1A2A3D),
                        ),
                      ),
                    ),
                    if (isActive)
                      Icon(
                        Icons.check_circle_rounded,
                        color: statusOption.color,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _searchCtrl = TextEditingController();
  late final PatientsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PatientsController()..addListener(_handleControllerChanged);
    unawaited(_controller.loadPatients());
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() => _controller.loadPatients();

  String get _filter => _controller.filter;
  String get _query => _controller.query;
  List<Map<String, dynamic>> get _campaigns => _controller.campaigns;
  bool get _loading => _controller.loading;
  List<Map<String, dynamic>> get _filteredCampaigns => _controller.filteredCampaigns;
  List<PatientListItem> get _filteredCampaignPatients =>
      _controller.filteredCampaignPatients;
  List<PatientListItem> get _filtered => _controller.filteredPatients;

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final total = _controller.totalCount;
    final passed = _controller.passedCount;
    final referred = _controller.referredCount;
    final pending = _controller.pendingCount;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(total, passed, referred, pending),
          Expanded(
            child: _loading
                ? const VsSkeletonList(count: 5)
                : RefreshIndicator(
                    onRefresh: _loadPatients,
                    color: _teal,
                    child: () {
                      if (_query.isEmpty) {
                        if (_campaigns.isEmpty && list.isEmpty) {
                          return ListView(children: [_buildEmpty()]);
                        }
                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                          itemCount:
                              (_campaigns.isNotEmpty
                                  ? _campaigns.length + 1
                                  : 0) +
                              list.length +
                              1,
                          itemBuilder: (_, i) {
                            int idx = i;
                            if (_campaigns.isNotEmpty) {
                              if (idx == 0) {
                                return _sectionLabel(
                                  'Campaigns (${_campaigns.length})',
                                );
                              }
                              if (idx <= _campaigns.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildCampaignCard(
                                    _campaigns[idx - 1],
                                  ),
                                );
                              }
                              idx -= _campaigns.length + 1;
                            }
                            if (idx == 0) {
                              return _sectionLabel(
                                '${list.length} individual patient${list.length == 1 ? '' : 's'}',
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _buildCard(list[idx - 1]),
                            );
                          },
                        );
                      }
                      // Search query present: show exact matches per section.
                      final mCampaigns = _filteredCampaigns;
                      final mCampPatients = _filteredCampaignPatients;
                      final mIndiv = list;
                      if (mCampaigns.isEmpty &&
                          mCampPatients.isEmpty &&
                          mIndiv.isEmpty) {
                        return ListView(children: [_buildEmpty()]);
                      }
                      int total = 0;
                      if (mCampaigns.isNotEmpty) {
                        total += mCampaigns.length + 1;
                      }
                      if (mCampPatients.isNotEmpty) {
                        total += mCampPatients.length + 1;
                      }
                      if (mIndiv.isNotEmpty) {
                        total += mIndiv.length + 1;
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                        itemCount: total,
                        itemBuilder: (_, i) {
                          int idx = i;
                          if (mCampaigns.isNotEmpty) {
                            if (idx == 0) {
                              return _sectionLabel(
                                'Campaigns (${mCampaigns.length})',
                              );
                            }
                            if (idx <= mCampaigns.length) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildCampaignCard(mCampaigns[idx - 1]),
                              );
                            }
                            idx -= mCampaigns.length + 1;
                          }
                          if (mCampPatients.isNotEmpty) {
                            if (idx == 0) {
                              return _sectionLabel(
                                'Campaign Patients (${mCampPatients.length})',
                              );
                            }
                            if (idx <= mCampPatients.length) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _buildCard(mCampPatients[idx - 1]),
                              );
                            }
                            idx -= mCampPatients.length + 1;
                          }
                          if (idx == 0) {
                            return _sectionLabel(
                              'Individual Patients (${mIndiv.length})',
                            );
                          }
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

  // -- Header --
  Widget _buildHeader(int total, int passed, int referred, int pending) {
    final passRate = total > 0 ? (passed / total * 100).round() : 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4C45), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Dot pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: CustomPaint(painter: _PatientsDotPainter()),
            ),
          ),
          // Large decorative arc, top right.
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
          ),
          // Small accent circle, bottom left.
          Positioned(
            bottom: 60,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -- Top bar: title + total badge ----------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: label + title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Breadcrumb label
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5EEAD4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'PATIENT REGISTRY',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Title
                            Text(
                              'Patients',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '& Referrals',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF5EEAD4),
                                height: 1.0,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: animated total circle
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.elasticOut,
                        builder: (_, t, child) =>
                            Transform.scale(scale: t, child: child),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white.withValues(alpha: 0.08),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<int>(
                                tween: IntTween(begin: 0, end: total),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) => Text(
                                  '$value',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              Text(
                                'total',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // -- Stats row -----------------------------
                  Row(
                    children: [
                      _statChip(
                        '$passed',
                        'Passed',
                        const Color(0xFF34D399),
                        Icons.check_circle_rounded,
                        passed / (total == 0 ? 1 : total),
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        '$referred',
                        'Referred',
                        const Color(0xFFF87171),
                        Icons.warning_rounded,
                        referred / (total == 0 ? 1 : total),
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        '$pending',
                        'Pending',
                        const Color(0xFFFBBF24),
                        Icons.schedule_rounded,
                        pending / (total == 0 ? 1 : total),
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        '$passRate%',
                        'Pass Rate',
                        const Color(0xFF5EEAD4),
                        Icons.insights_rounded,
                        passed / (total == 0 ? 1 : total),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // -- Search bar ----------------------------
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 14),
                          child: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: _teal,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _controller.setQuery,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search name, ID, village...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              _controller.setQuery('');
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _teal.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Search',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _teal,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // -- Filter chips --------------------------
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(
    String number,
    String label,
    Color color,
    IconData icon,
    double ratio,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 10, color: color),
                ),
                const Spacer(),
                TweenAnimationBuilder<int>(
                  tween: IntTween(
                    begin: 0,
                    end: int.tryParse(number.replaceAll('%', '')) ?? 0,
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Text(
                    number.contains('%') ? '$value%' : '$value',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 2.5,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 0.8,
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
      onTap: () {
        VsHaptics.selection();
        _controller.setFilter(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? _teal : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  // -- Section label --
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // -- Campaign card --
  Widget _buildCampaignCard(Map<String, dynamic> c) {
    final name = c['name'] as String;
    final location = c['location'] as String;
    final group = c['target_group'] as String;
    final total = (c['total'] as int?) ?? 0;
    final passed = (c['passed'] as int?) ?? 0;
    final referred = (c['referred'] as int?) ?? 0;
    final passRate = total > 0 ? (passed / total * 100).round() : 0;
    final createdAt = c['created_at'] as String;
    String dateLabel = '';
    try {
      final dt = DateTime.parse(createdAt);
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      dateLabel = '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {}

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          VsPageRoute(builder: (_) => _CampaignDetailScreen(campaign: c)),
        ).then((_) => _loadPatients()),
        onLongPress: () => _confirmDeleteCampaign(c),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF134E4A), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _teal.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: _teal.withValues(alpha: 0.15),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Dot pattern
                Positioned.fill(
                  child: CustomPaint(painter: _CampaignCardDotPainter()),
                ),
                // Decorative arc
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$location | $group',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'CAMPAIGN',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            _campStatNew(
                              total.toString(),
                              'Screened',
                              Colors.white,
                            ),
                            _campStatNew(
                              passed.toString(),
                              'Passed',
                              const Color(0xFF6EE7B7),
                            ),
                            _campStatNew(
                              referred.toString(),
                              'Referred',
                              const Color(0xFFFCA5A5),
                            ),
                            _campStatNew(
                              '$passRate%',
                              'Pass Rate',
                              const Color(0xFF5EEAD4),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  dateLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'View',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _campStatNew(String value, String label, Color color) => Padding(
    padding: const EdgeInsets.only(right: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.0,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    ),
  );

  void _confirmDeleteCampaign(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_rounded, color: _red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Campaign',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Delete "${c['name']}" and all ${(c['total'] as int?) ?? 0} patient records inside? This cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF5E7291),
            height: 1.5,
          ),
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
            onPressed: () async {
              Navigator.pop(context);
              await _controller.deleteCampaign(c['id'] as String);
              await _loadPatients();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Campaign "${c['name']}" deleted.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: _red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete All',
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

  // -- Patient card --
  Widget _buildCard(PatientListItem p) {
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
        splashColor: accentColor.withValues(alpha: 0.06),
        highlightColor: accentColor.withValues(alpha: 0.03),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // -- Top body --
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child:
                                p.photoUrl.isNotEmpty &&
                                    File(p.photoUrl).existsSync()
                                ? Image.file(
                                    File(p.photoUrl),
                                    fit: BoxFit.cover,
                                    width: 48,
                                    height: 48,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accentColor,
                                          accentColor.withValues(alpha: 0.7),
                                        ],
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
                        // Outcome dot indicator
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              badgeIcon,
                              size: 7,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + age group
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ageGroupColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(99),
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
                          const SizedBox(height: 3),
                          // Demographics
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  p.demographics,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // VA pills or pending badge
                          if (p.outcome != 'pending')
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _vaPill('OD', p.od, p.outcome),
                                  const SizedBox(width: 4),
                                  _vaPill('OS', p.os, p.outcome),
                                  const SizedBox(width: 4),
                                  _vaPill('OU', p.ou, p.outcome),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _amber.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _amber.withValues(alpha: 0.2),
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
                          // Conditions
                          if (p.safeConditions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: p.safeConditions
                                  .map(
                                    (c) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _amber.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _amber.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        c,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: _amber,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Outcome badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 13, color: accentColor),
                          const SizedBox(height: 2),
                          Text(
                            badgeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: badgeText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // -- Bottom action strip --
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: accentColor.withValues(alpha: 0.10),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: p.outcome != 'pending'
                    ? Row(
                        children: [
                          // ID or facility
                          Expanded(
                            child: p.outcome == 'refer' && p.facility != null
                                ? Row(
                                    children: [
                                      Icon(
                                        Icons.local_hospital_rounded,
                                        size: 11,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${p.facility}',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: const Color(0xFF475569),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      const Icon(
                                        Icons.badge_outlined,
                                        size: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          p.id,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 6),
                          if (p.outcome == 'refer')
                            GestureDetector(
                              onTap: () => _showUpdateStatusSheet(p),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _referralStatusColor(
                                    p.referralStatus,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: _referralStatusColor(
                                      p.referralStatus,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 12,
                                  color: _referralStatusColor(p.referralStatus),
                                ),
                              ),
                            ),
                          if (p.outcome == 'refer') const SizedBox(width: 5),
                          _actionBtn(
                            Icons.picture_as_pdf_outlined,
                            _teal,
                            () => _exportPatientData(p),
                          ),
                          const SizedBox(width: 5),
                          _actionBtn(
                            Icons.send_rounded,
                            const Color(0xFF25D366),
                            () => _shareToWhatsApp(p),
                          ),
                          const SizedBox(width: 5),
                          _actionBtn(
                            Icons.phone_rounded,
                            _blue,
                            () => _callPatient(p),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 11,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              p.id,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _actionBtn(
                            Icons.phone_rounded,
                            _blue,
                            () => _callPatient(p),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () => _screenPatientNow(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_teal, Color(0xFF0F766E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: _teal.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.remove_red_eye_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Screen Now',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _vaPill(String eye, String value, String outcome) {
    return _buildVaPill(eye, value, outcome);
  }

  void _showUpdateStatusSheet(PatientListItem p) {
    unawaited(
      _showReferralStatusSheet(
        context,
        patient: p,
        onStatusSelected: (status) async {
          await PatientActions.updateReferralStatus(p, status);
          await _loadPatients();
        },
      ),
    );
  }

  void _confirmDelete(PatientListItem p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_rounded, color: _red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Patient',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Delete ${p.name} and all their screening records? This cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF5E7291),
            height: 1.5,
          ),
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
            onPressed: () async {
              Navigator.pop(context);
              await _controller.deletePatient(p.id);
              await _loadPatients();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${p.name} deleted',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: _red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
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

  void _showHistory(PatientListItem p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PatientHistorySheet(patient: p),
    );
  }

  // -- Empty state --
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

  // -- Helpers --
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

  void _exportPatientData(PatientListItem p) {
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
              '${p.name} | ${p.facility ?? p.id}',
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
                  color: _teal.withValues(alpha: 0.1),
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

  Future<void> _exportPatientToPDF(PatientListItem p) async {
    await PatientActions.exportReport(context, p, closeSheet: true);
  }

  Future<void> _screenPatientNow(PatientListItem p) async {
    if (!mounted) return;
    await PatientActions.openScreening(context, p);
    _loadPatients();
  }

  Future<void> _shareToWhatsApp(PatientListItem p) async {
    await PatientActions.shareToWhatsApp(context, p);
  }

  Future<void> _callPatient(PatientListItem p) async {
    await PatientActions.callPatient(context, p);
  }
}

// -- Patient history bottom sheet: loads real screenings from SQLite --
class _PatientHistorySheet extends StatefulWidget {
  final PatientListItem patient;
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
    final rows = await ScreeningRepository.instance.getScreeningsForPatient(
      widget.patient.id,
    );
    if (mounted) {
      setState(() {
        _history = rows;
        _loading = false;
      });
    }
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][dt.month - 1];
      return '${dt.day} $m ${dt.year}';
    } catch (_) {
      return iso.substring(0, 10);
    }
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE4EC),
                    borderRadius: BorderRadius.circular(99),
                  ),
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
                    child:
                        p.photoUrl.isNotEmpty && File(p.photoUrl).existsSync()
                        ? Image.file(
                            File(p.photoUrl),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: p.avatarGradient,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                p.initials,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2A3D),
                          ),
                        ),
                        Text(
                          '${p.id} | ${p.age} yrs | ${p.village}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF8FA0B4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${_history.length} screening${_history.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5E7291),
                      ),
                    ),
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
                  spacing: 6,
                  runSpacing: 6,
                  children: p.safeConditions
                      .map(
                        (c) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: _amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            c,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _amber,
                            ),
                          ),
                        ),
                      )
                      .toList(),
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
                          const Icon(
                            Icons.history_rounded,
                            size: 40,
                            color: Color(0xFFDDE4EC),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No screenings yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A2A3D),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: _history.length,
                      itemBuilder: (_, i) =>
                          _historyRow(_history[i], i, _history.length),
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
    final od = normaliseVisualAcuity(r['od_snellen'] as String?);
    final os = normaliseVisualAcuity(r['os_snellen'] as String?);
    final ou = normaliseVisualAcuity(r['ou_near_snellen'] as String?);
    final chw = (r['chw_name'] as String?) ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                outcome == 'pass' ? Icons.check_rounded : Icons.warning_rounded,
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
                        _fmtDate(r['screening_date'] as String),
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
                          outcome == 'pass' ? 'Pass' : 'Refer',
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
                      _pill('OD', od),
                      const SizedBox(width: 6),
                      _pill('OS', os),
                      const SizedBox(width: 6),
                      _pill('OU', ou),
                      const Spacer(),
                      if (chw.isNotEmpty) ...[
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 11,
                          color: Color(0xFF8FA0B4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chw,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF8FA0B4),
                          ),
                        ),
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
    final isBad =
        value != '6/6' && value != '6/9' && value != patientMissingVaValue;
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
              style: GoogleFonts.inter(
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
}

// -- Campaign Detail Screen ----------------------------------------------------
class _CampaignDetailScreen extends StatefulWidget {
  final Map<String, dynamic> campaign;
  const _CampaignDetailScreen({required this.campaign});
  @override
  State<_CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<_CampaignDetailScreen> {
  List<PatientListItem> _patients = [];
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
        if (diff.inMinutes < 60) return 'Today | ${diff.inMinutes}m ago';
        return 'Today | ${diff.inHours}hr ago';
      }
      return '${dt.day} ${['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dt.month]}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }

  Future<void> _load() async {
    final rows = await CampaignRepository.instance.getPatientsForCampaign(
      widget.campaign['id'] as String,
    );
    final list = <PatientListItem>[];
    for (final r in rows) {
      final age = (r['age'] as int?) ?? 0;
      final conditions = ((r['conditions'] as String?) ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final outcome = (r['outcome'] as String?) ?? 'pending';
      final screeningDate = r['screening_date'] as String?;
      list.add(
        PatientListItem(
          initials: (r['name'] as String)
              .split(' ')
              .map((w) => w.isEmpty ? '' : w[0])
              .take(2)
              .join(),
          avatarGradient: [_teal, _teal2],
          photoUrl: (r['photo_path'] as String?) ?? '',
          name: r['name'] as String,
          age: age,
          gender: r['gender'] as String,
          village: (r['village'] as String?) ?? '',
          ageGroup: age < 18
              ? 'child'
              : age > 60
              ? 'elderly'
              : 'adult',
          od: normaliseVisualAcuity(r['od_snellen'] as String?),
          os: normaliseVisualAcuity(r['os_snellen'] as String?),
          ou: normaliseVisualAcuity(r['ou_near_snellen'] as String?),
          outcome: outcome,
          date: screeningDate != null
              ? _formatDate(screeningDate)
              : 'Not screened',
          id: r['id'] as String,
          phone: (r['phone'] as String?) ?? '',
          facility: _nullIfEmpty(r['referral_facility'] as String?),
          referralStatus: _nullIfEmpty(r['referral_status'] as String?),
          campaignId: widget.campaign['id'] as String,
          conditions: conditions,
        ),
      );
    }
    if (mounted) {
      setState(() {
        _patients = list;
        _loading = false;
      });
    }
  }

  Future<void> _deletePatient(PatientListItem patient) async {
    await PatientRepository.instance.deletePatient(patient.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    final name = c['name'] as String;
    final location = c['location'] as String;
    final group = c['target_group'] as String;
    final total = (c['total'] as int?) ?? 0;
    final passed = (c['passed'] as int?) ?? 0;
    final referred = (c['referred'] as int?) ?? 0;
    final passRate = total > 0 ? (passed / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            VsPageRoute(
              builder: (_) => BulkModeScreen(
                existingCampaignId: widget.campaign['id'] as String,
                existingCampaignName: widget.campaign['name'] as String,
                existingCampaignLocation: widget.campaign['location'] as String,
              ),
            ),
          );
          _load();
        },
        backgroundColor: _teal,
        icon: const Icon(
          Icons.person_add_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          'Add Patient',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        elevation: 4,
      ),
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F4C45), Color(0xFF0D9488)],
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
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    child: CustomPaint(painter: _PatientsDotPainter()),
                  ),
                ),
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 1,
                      ),
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
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF5EEAD4),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'CAMPAIGN \u00b7 $group',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(
                                            alpha: 0.65,
                                          ),
                                          letterSpacing: 1.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 11,
                                        color: Colors.white.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          location,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.white.withValues(
                                              alpha: 0.65,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                              builder: (_, t, child) =>
                                  Transform.scale(scale: t, child: child),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$total',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      'patients',
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _hStat('$total', 'Screened', Colors.white),
                            const SizedBox(width: 8),
                            _hStat(
                              '$passed',
                              'Passed',
                              const Color(0xFF34D399),
                            ),
                            const SizedBox(width: 8),
                            _hStat(
                              '$referred',
                              'Referred',
                              const Color(0xFFF87171),
                            ),
                            const SizedBox(width: 8),
                            _hStat(
                              '$passRate%',
                              'Pass Rate',
                              const Color(0xFF5EEAD4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Patient list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _teal))
                : _patients.isEmpty
                ? Center(
                    child: Text(
                      'No patients in this campaign yet.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: _teal,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
                      itemCount: _patients.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${_patients.length} patient${_patients.length == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF8FA0B4),
                                letterSpacing: 1.2,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _CampaignPatientCard(
                            key: ValueKey(_patients[i - 1].id),
                            patient: _patients[i - 1],
                            onDelete: _deletePatient,
                            onRefresh: _load,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _hStat(String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 7,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    ),
  );
}

// -- Campaign Patient Card ----------------------------------------------------
class _CampaignPatientCard extends StatefulWidget {
  final PatientListItem patient;
  final Future<void> Function(PatientListItem patient) onDelete;
  final VoidCallback onRefresh;
  const _CampaignPatientCard({
    super.key,
    required this.patient,
    required this.onDelete,
    required this.onRefresh,
  });
  @override
  State<_CampaignPatientCard> createState() => _CampaignPatientCardState();
}

class _CampaignPatientCardState extends State<_CampaignPatientCard> {
  PatientListItem get p => widget.patient;

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
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_rounded, color: _red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Patient',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Delete ${p.name} and all their screening records? This cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF5E7291),
            height: 1.5,
          ),
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
            onPressed: () async {
              Navigator.pop(context);
              await widget.onDelete(p);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
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

  Future<void> _callPatient() async {
    await PatientActions.callPatient(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final (badgeLabel, badgeBg, badgeText, badgeIcon, accentColor) =
        _badgeProps(p.outcome);
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 72,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: p.avatarGradient.last.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child:
                            p.photoUrl.isNotEmpty &&
                                File(p.photoUrl).existsSync()
                            ? Image.file(
                                File(p.photoUrl),
                                fit: BoxFit.cover,
                                width: 50,
                                height: 50,
                              )
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  color: ageGroupColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: ageGroupColor.withValues(
                                      alpha: 0.25,
                                    ),
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
                                  p.demographics,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF8FA0B4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                                color: _amber.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _amber.withValues(alpha: 0.2),
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
                          if (p.safeConditions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: p.safeConditions
                                  .map(
                                    (c) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _amber.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _amber.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        c,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: _amber,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
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
                              color: accentColor.withValues(alpha: 0.25),
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
              // Bottom strip
              Container(
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  border: Border(
                    top: BorderSide(color: accentColor.withValues(alpha: 0.12)),
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
                      size: 11,
                      color: Color(0xFF8FA0B4),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p.id,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF8FA0B4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _campBtn(
                      Icons.phone_rounded,
                      p.phone.isNotEmpty ? _blue : const Color(0xFFB0BEC5),
                      _callPatient,
                    ),
                    const SizedBox(width: 4),
                    _campBtn(
                      Icons.send_rounded,
                      const Color(0xFF25D366),
                      () => _shareToWhatsAppCampaign(p),
                    ),
                    if (p.outcome == 'refer') ...[
                      const SizedBox(width: 4),
                      _campBtn(
                        Icons.update_rounded,
                        _amber,
                        () => _showUpdateStatusSheetCampaign(p),
                      ),
                    ],
                    const SizedBox(width: 4),
                    _campBtn(
                      Icons.picture_as_pdf_outlined,
                      _teal,
                      () => _exportPatientDataCampaign(p),
                    ),
                    if (p.outcome == 'pending') ...[
                      const SizedBox(width: 4),
                      _campBtn(
                        Icons.remove_red_eye_rounded,
                        _teal,
                        () => _screenCampaignPatientNow(p),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateStatusSheetCampaign(PatientListItem p) {
    unawaited(
      _showReferralStatusSheet(
        context,
        patient: p,
        onStatusSelected: (status) async {
          await PatientActions.updateReferralStatus(p, status);
          widget.onRefresh();
        },
      ),
    );
  }

  Future<void> _shareToWhatsAppCampaign(PatientListItem p) async {
    await PatientActions.shareToWhatsApp(context, p);
  }

  Future<void> _exportPatientDataCampaign(PatientListItem p) async {
    await PatientActions.exportReport(context, p);
  }

  Widget _vaPill(String eye, String value, String outcome) {
    return _buildVaPill(eye, value, outcome);
  }

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

  Future<void> _screenCampaignPatientNow(PatientListItem p) async {
    if (!mounted) return;
    await PatientActions.openScreening(context, p);
    widget.onRefresh();
  }

  Widget _campBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }
}

// -- Dot pattern painter for header --------------------------
class _PatientsDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    const spacing = 26.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.8, p);
      }
    }
  }

  @override
  bool shouldRepaint(_PatientsDotPainter old) => false;
}

// -- Dot pattern painter for campaign cards ------------------
class _CampaignCardDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    const spacing = 18.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.4, p);
      }
    }
  }

  @override
  bool shouldRepaint(_CampaignCardDotPainter old) => false;
}
