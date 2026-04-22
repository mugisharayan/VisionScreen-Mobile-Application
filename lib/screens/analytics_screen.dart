import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../db/database_helper.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Today';
  final List<String> _periods = ['Today', 'Week', 'Month', 'Year'];

  int _totalScreened = 0;
  int _totalPassed = 0;
  int _totalReferred = 0;
  Map<String, int> _ageGroups = {};
  Map<String, int> _genderCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final outcomes = await DatabaseHelper.instance.getOutcomeCounts();
    final ages = await DatabaseHelper.instance.getAgeGroupCounts();
    final genders = await DatabaseHelper.instance.getGenderCounts();
    if (!mounted) return;
    setState(() {
      _totalPassed = outcomes['pass'] ?? 0;
      _totalReferred = outcomes['refer'] ?? 0;
      _totalScreened = _totalPassed + _totalReferred;
      _ageGroups = ages;
      _genderCounts = genders;
      _loading = false;
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildStatsCards(),
                  const SizedBox(height: 12),
                  _buildPassRateChart(),
                  const SizedBox(height: 12),
                  _buildDemographicsSection(),
                  const SizedBox(height: 12),
                  _buildVisualAcuitySection(),
                  const SizedBox(height: 12),
                  _buildVisionConditionsSection(),
                  const SizedBox(height: 12),
                  _buildSeverityClassificationSection(),
                  const SizedBox(height: 12),
                  _buildReferralAnalytics(),
                  const SizedBox(height: 12),
                  _buildFollowUpComplianceSection(),
                  const SizedBox(height: 12),
                  _buildTreatmentOutcomesSection(),
                  const SizedBox(height: 12),
                  _buildFieldOperationsSection(),
                  const SizedBox(height: 12),
                  _buildCommunityEngagementSection(),
                  const SizedBox(height: 12),
                  _buildResourceManagementSection(),
                  const SizedBox(height: 12),
                  _buildVulnerablePopulationSection(),
                  const SizedBox(height: 12),
                  _buildInsightsSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // stubs
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 50, 12, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF04091A), Color(0xFF0B1530)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Analytics',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          _buildPeriodSelector(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _periods.map((p) {
          final isSelected = p == _selectedPeriod;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(p,
                  style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(isSelected ? 1.0 : 0.7))),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget _buildStatsCards() {
    return Row(
      children: [
        _buildStatCard('47', 'Screened', '↑ 8 today', const Color(0xFF0D9488), Icons.visibility_rounded, 0.94),
        const SizedBox(width: 8),
        _buildStatCard('35', 'Passed',   '74%',        const Color(0xFF22C55E), Icons.check_circle_rounded, 0.74),
        const SizedBox(width: 8),
        _buildStatCard('12', 'Referred', '26%',        const Color(0xFFF59E0B), Icons.assignment_rounded, 0.26),
      ],
    );
  }

  Widget _buildStatCard(String number, String label, String change, Color color, IconData icon, double progress) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: color.withOpacity(0.4)),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(change, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(number,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 30, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2A3D), height: 1.0)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF5E7291))),
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(height: 5, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(99))),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPassRateChart() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF04091A), Color(0xFF0B1530)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pass Rate Trend',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 3),
                      Text('7-day performance · Wakiso & Kampala',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.45))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward_rounded, color: Color(0xFF22C55E), size: 11),
                      const SizedBox(width: 3),
                      Text('↑ 9% this week',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF22C55E))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('74%',
                    style: GoogleFonts.spaceGrotesk(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0)),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('pass rate today',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: CustomPaint(size: const Size(double.infinity, 140), painter: _PassRateTrendPainter()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(44, 6, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
                  .map((d) => Text(d, style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w500)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                _legendDot(const Color(0xFF0D9488), 'Pass rate', '74%'),
                Container(width: 1, height: 28, color: Colors.white.withOpacity(0.1)),
                _legendDot(const Color(0xFFF59E0B), 'Refer rate', '26%'),
                Container(width: 1, height: 28, color: Colors.white.withOpacity(0.1)),
                _legendDot(const Color(0xFF5EEAD4), 'Peak day', 'Sat 78%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)])),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w500)),
                  Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDemographicsSection() {
    return Row(
      children: [
        Expanded(child: _buildAgeGroupChart()),
        const SizedBox(width: 12),
        Expanded(child: _buildGenderChart()),
      ],
    );
  }

  Widget _buildAgeGroupChart() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Age Groups', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 12),
          _ageBar('0–17',  12, const Color(0xFF3B82F6)),
          _ageBar('18–40', 18, const Color(0xFF0D9488)),
          _ageBar('41–60', 14, const Color(0xFFF59E0B)),
          _ageBar('60+',   8,  const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _ageBar(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF5E7291))),
              Text('$count', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99))),
              FractionallySizedBox(
                widthFactor: count / 20,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChart() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gender Split', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1), shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.male_rounded, color: Color(0xFF3B82F6), size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text('28', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D))),
                    Text('Male', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99))),
                        FractionallySizedBox(widthFactor: 0.54,
                          child: Container(height: 4, decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)]),
                            borderRadius: BorderRadius.circular(99)))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 80, color: const Color(0xFFEEF2F6)),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withOpacity(0.1), shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.female_rounded, color: Color(0xFFEC4899), size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text('24', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D))),
                    Text('Female', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99))),
                        FractionallySizedBox(widthFactor: 0.46,
                          child: Container(height: 4, decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFF9A8D4), Color(0xFFEC4899)]),
                            borderRadius: BorderRadius.circular(99)))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildVisualAcuitySection() {
    const levels = [
      ('20/20', 'Normal',       0.62, Color(0xFF22C55E)),
      ('20/40', 'Mild Loss',    0.20, Color(0xFF0D9488)),
      ('20/80', 'Moderate',     0.11, Color(0xFFF59E0B)),
      ('20/200','Severe',       0.05, Color(0xFFEF4444)),
      ('<20/200','Blind Range', 0.02, Color(0xFF8B5CF6)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF0D9488), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visual Acuity Distribution',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
                  Text('Snellen chart results',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...levels.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(e.$1,
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(height: 8, decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99))),
                      FractionallySizedBox(
                        widthFactor: e.$3,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [e.$4.withOpacity(0.6), e.$4]),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [BoxShadow(color: e.$4.withOpacity(0.4), blurRadius: 4)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text('${(e.$3 * 100).toInt()}%',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: e.$4)),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 60,
                  child: Text(e.$2,
                      style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8FA0B4))),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  Widget _buildVisionConditionsSection() {
    const conditions = [
      ('Myopia',       0.38, Color(0xFF3B82F6), Icons.search_rounded),
      ('Hyperopia',    0.22, Color(0xFF0D9488), Icons.zoom_out_rounded),
      ('Astigmatism',  0.18, Color(0xFF8B5CF6), Icons.blur_on_rounded),
      ('Presbyopia',   0.14, Color(0xFFF59E0B), Icons.elderly_rounded),
      ('Cataracts',    0.08, Color(0xFFEF4444), Icons.lens_blur_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.35)),
                ),
                child: const Icon(Icons.visibility_rounded, color: Color(0xFFA78BFA), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vision Conditions',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Diagnosed conditions breakdown',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...conditions.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: e.$3.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: e.$3.withOpacity(0.3)),
                  ),
                  child: Icon(e.$4, color: e.$3, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.$1, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85))),
                          Text('${(e.$2 * 100).toInt()}%',
                              style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: e.$3)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Stack(
                        children: [
                          Container(height: 6, decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(99))),
                          FractionallySizedBox(
                            widthFactor: e.$2,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [e.$3.withOpacity(0.6), e.$3]),
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: [BoxShadow(color: e.$3.withOpacity(0.5), blurRadius: 6)],
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
          )),
        ],
      ),
    );
  }
  Widget _buildSeverityClassificationSection() {
    const levels = [
      ('Normal',   29, Color(0xFF22C55E)),
      ('Mild',     10, Color(0xFF0D9488)),
      ('Moderate',  5, Color(0xFFF59E0B)),
      ('Severe',    2, Color(0xFFEF4444)),
      ('Critical',  1, Color(0xFF8B5CF6)),
    ];
    const total = 47;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFFF59E0B), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Severity Classification',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
                  Text('$total patients classified',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Row(
              children: levels.map((e) => Flexible(
                flex: e.$2,
                child: Container(
                  height: 10,
                  color: e.$3,
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: levels.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: e.$3.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: e.$3.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: e.$3.withOpacity(0.5), blurRadius: 4)])),
                  const SizedBox(width: 6),
                  Text(e.$1, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF1A2A3D))),
                  const SizedBox(width: 4),
                  Text('${(e.$2 / total * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: e.$3)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  Widget _buildReferralAnalytics() {
    const priorities = [
      ('Urgent',   4, Color(0xFFEF4444)),
      ('High',     5, Color(0xFFF59E0B)),
      ('Medium',   2, Color(0xFF0D9488)),
      ('Low',      1, Color(0xFF3B82F6)),
    ];
    const statuses = [
      ('Pending',    5, Color(0xFFF59E0B)),
      ('Scheduled',  3, Color(0xFF3B82F6)),
      ('Completed',  3, Color(0xFF22C55E)),
      ('Missed',     1, Color(0xFFEF4444)),
    ];
    const total = 12;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C1A2E), Color(0xFF0F2744)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: const Icon(Icons.assignment_rounded, color: Color(0xFFF59E0B), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Referral Analytics',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('$total total referrals this period',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Priority Breakdown',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 10),
          ...priorities.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: e.$3.withOpacity(0.6), blurRadius: 4)]),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 52,
                    child: Text(e.$1, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8)))),
                Expanded(
                  child: Stack(
                    children: [
                      Container(height: 6, decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(99))),
                      FractionallySizedBox(
                        widthFactor: e.$2 / total,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [e.$3.withOpacity(0.6), e.$3]),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [BoxShadow(color: e.$3.withOpacity(0.5), blurRadius: 4)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.$2}', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: e.$3)),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withOpacity(0.07)),
          const SizedBox(height: 12),
          Text('Status Overview',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 10),
          Row(
            children: statuses.map((e) => Expanded(
              child: Column(
                children: [
                  Text('${e.$2}',
                      style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: e.$3)),
                  const SizedBox(height: 3),
                  Text(e.$1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.45))),
                  const SizedBox(height: 6),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: e.$3,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [BoxShadow(color: e.$3.withOpacity(0.6), blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  Widget _buildFollowUpComplianceSection() {
    const items = [
      ('Attended',   8, Color(0xFF22C55E)),
      ('Rescheduled',2, Color(0xFF0D9488)),
      ('Pending',    3, Color(0xFFF59E0B)),
      ('Missed',     1, Color(0xFFEF4444)),
    ];
    const total = 14;
    const compliant = 8;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_available_rounded, color: Color(0xFF22C55E), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Follow-Up Compliance',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
                    Text('$total follow-ups scheduled',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(compliant / total * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF22C55E))),
                  Text('compliance', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8FA0B4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Row(
              children: items.map((e) => Flexible(
                flex: e.$2,
                child: Container(height: 10, color: e.$3),
              )).toList(),
            ),
          ),
          const SizedBox(height: 14),
          ...items.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: e.$3.withOpacity(0.5), blurRadius: 4)])),
                const SizedBox(width: 8),
                Expanded(child: Text(e.$1,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1A2A3D)))),
                Text('${e.$2}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: e.$3)),
                const SizedBox(width: 4),
                Text('(${(e.$2 / total * 100).toStringAsFixed(0)}%)',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
              ],
            ),
          )),
        ],
      ),
    );
  }
  Widget _buildTreatmentOutcomesSection() {
    const outcomes = [
      ('Glasses Prescribed', 18, Color(0xFF3B82F6), Icons.visibility_rounded),
      ('Referred to Clinic',  9, Color(0xFFF59E0B), Icons.local_hospital_rounded),
      ('Surgery Needed',      3, Color(0xFFEF4444), Icons.medical_services_rounded),
      ('No Treatment',       17, Color(0xFF22C55E), Icons.check_circle_rounded),
    ];
    const total = 47;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF042F2E), Color(0xFF0D3D3B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.4)),
                ),
                child: const Icon(Icons.healing_rounded, color: Color(0xFF5EEAD4), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Treatment Outcomes',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('$total patients assessed',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: outcomes.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: e.$3.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: e.$3.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(e.$4, color: e.$3, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${e.$2}',
                            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text(e.$1,
                            style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.45)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text('${(e.$2 / total * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: e.$3)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  Widget _buildFieldOperationsSection() {
    const metrics = [
      ('Sites Visited',   '6',  'of 8 planned',  Color(0xFF3B82F6), Icons.location_on_rounded),
      ('Avg per Site',    '7.8','patients/site',  Color(0xFF0D9488), Icons.people_rounded),
      ('Screening Time',  '4.2','min avg',        Color(0xFF8B5CF6), Icons.timer_rounded),
      ('CHW Active',      '3',  'of 4 deployed',  Color(0xFFF59E0B), Icons.badge_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map_rounded, color: Color(0xFF3B82F6), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Field Operations',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
                  Text('Wakiso & Kampala districts',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: metrics.map((e) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: e.$4.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: e.$4.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: e.$4.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(e.$5, color: e.$4, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(e.$2,
                            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D))),
                        Text(e.$3,
                            style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8FA0B4)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(e.$1,
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: e.$4),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  Widget _buildCommunityEngagementSection() {
    const cards = [
      ('Outreach Events',  '12', '+3 this week',  Color(0xFFEC4899), Icons.campaign_rounded),
      ('Villages Reached', '18', 'of 24 target',  Color(0xFFF43F5E), Icons.holiday_village_rounded),
      ('Awareness Score',  '82%','community avg', Color(0xFFFF6B9D), Icons.thumb_up_rounded),
      ('Referral Uptake',  '71%','accepted rate', Color(0xFFE11D48), Icons.trending_up_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D0A1E), Color(0xFF3D0F2A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFFEC4899).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.35)),
                ),
                child: const Icon(Icons.groups_rounded, color: Color(0xFFFF6B9D), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Community Engagement',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Outreach & awareness metrics',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: cards.map((e) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: e.$4.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: e.$4.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: e.$4.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(e.$5, color: e.$4, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(e.$2,
                            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text(e.$3,
                            style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.4)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(e.$1,
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: e.$4),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  Widget _buildResourceManagementSection() {
    const resources = [
      ('Eye Charts',      42, 50, Color(0xFF3B82F6)),
      ('Occluders',       38, 50, Color(0xFF0D9488)),
      ('Record Forms',    27, 100, Color(0xFF8B5CF6)),
      ('Referral Slips',  15, 50, Color(0xFFF59E0B)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF8B5CF6), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resource Management',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
                  Text('Supply levels & stock status',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...resources.map((e) {
            final pct = e.$2 / e.$3;
            final isLow = pct < 0.4;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(e.$1,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1A2A3D))),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 8, decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99))),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [e.$4.withOpacity(0.6), e.$4]),
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [BoxShadow(color: e.$4.withOpacity(0.4), blurRadius: 4)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.$2}/${e.$3}',
                      style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: e.$4)),
                  const SizedBox(width: 6),
                  if (isLow)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: Text('Low', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  Widget _buildVulnerablePopulationSection() {
    const groups = [
      ('Children\n0–17 yrs',   12, '26%', Color(0xFF3B82F6), Icons.child_care_rounded),
      ('Elderly\n60+ yrs',      8, '17%', Color(0xFF8B5CF6), Icons.elderly_rounded),
      ('Low Income',           18, '38%', Color(0xFFF59E0B), Icons.savings_rounded),
      ('Remote Areas',          9, '19%', Color(0xFFEF4444), Icons.location_off_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0533), Color(0xFF240A45)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.35)),
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFFA78BFA), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vulnerable Populations',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Priority groups screened',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.0,
            children: groups.map((e) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: e.$4.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: e.$4.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: e.$4.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(e.$5, color: e.$4, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${e.$2}',
                            style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text(e.$3,
                            style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: e.$4)),
                        Text(e.$1,
                            style: GoogleFonts.inter(fontSize: 8, color: Colors.white.withOpacity(0.4)),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  Widget _buildInsightsSection() {
    const insights = [
      ('Pass rate up 9% vs last week — best performance in Wakiso district this month.', Color(0xFF22C55E), '01'),
      ('Referral slips stock at 30% — reorder needed before next field session.', Color(0xFFEF4444), '02'),
      ('Children 0–17 show highest referral rate (42%) — prioritise school outreach.', Color(0xFFF59E0B), '03'),
      ('Average screening time 4.2 min — within the 5-min CHW target.', Color(0xFF0D9488), '04'),
      ('3 of 4 villages in Kampala not yet reached — schedule visits this week.', Color(0xFF8B5CF6), '05'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: Color(0xFF0D9488), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Key Insights',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
                  Text('Auto-generated from current data',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...insights.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: e.$2,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [BoxShadow(color: e.$2.withOpacity(0.4), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.$3,
                          style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: e.$2)),
                      const SizedBox(height: 2),
                      Text(e.$1,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF3D5166), height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _PassRateTrendPainter extends CustomPainter {
  static const _data  = [65.0, 72.0, 68.0, 74.0, 78.0, 74.0, 76.0];
  static const _refer = [35.0, 28.0, 32.0, 26.0, 22.0, 26.0, 24.0];
  static const _teal  = Color(0xFF0D9488);
  static const _teal3 = Color(0xFF5EEAD4);
  static const _amber = Color(0xFFF59E0B);

  @override
  void paint(Canvas canvas, Size size) {
    const lp = 36.0, tp = 10.0, bp = 8.0;
    final cW = size.width - lp;
    final cH = size.height - tp - bp;
    double xOf(int i) => lp + (i / (_data.length - 1)) * cW;
    double yOf(double v) => tp + cH - (v / 100) * cH;

    final gridP = Paint()..color = Colors.white.withOpacity(0.06)..strokeWidth = 1;
    final lblS  = GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w500);
    for (final pct in [25.0, 50.0, 75.0, 100.0]) {
      final y = yOf(pct);
      canvas.drawLine(Offset(lp, y), Offset(size.width, y), gridP);
      final tp2 = TextPainter(text: TextSpan(text: '${pct.toInt()}%', style: lblS), textDirection: TextDirection.ltr)..layout();
      tp2.paint(canvas, Offset(0, y - tp2.height / 2));
    }

    Path smooth(List<double> vals) {
      final pts = List.generate(vals.length, (i) => Offset(xOf(i), yOf(vals[i])));
      final p = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 0; i < pts.length - 1; i++) {
        final c1 = Offset((pts[i].dx + pts[i+1].dx) / 2, pts[i].dy);
        final c2 = Offset((pts[i].dx + pts[i+1].dx) / 2, pts[i+1].dy);
        p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, pts[i+1].dx, pts[i+1].dy);
      }
      return p;
    }

    final rPath = smooth(_refer);
    canvas.drawPath(Path.from(rPath)..lineTo(xOf(_refer.length-1), size.height)..lineTo(xOf(0), size.height)..close(),
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_amber.withOpacity(0.18), _amber.withOpacity(0.0)]).createShader(Rect.fromLTWH(0,0,size.width,size.height)));

    final pPath = smooth(_data);
    canvas.drawPath(Path.from(pPath)..lineTo(xOf(_data.length-1), size.height)..lineTo(xOf(0), size.height)..close(),
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_teal.withOpacity(0.35), _teal.withOpacity(0.0)]).createShader(Rect.fromLTWH(0,0,size.width,size.height)));

    canvas.drawPath(rPath, Paint()..color = _amber.withOpacity(0.7)..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawPath(pPath, Paint()
      ..shader = LinearGradient(colors: [_teal, _teal3], begin: Alignment.centerLeft, end: Alignment.centerRight).createShader(Rect.fromLTWH(lp, 0, cW, size.height))
      ..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    for (int i = 0; i < _data.length; i++) {
      final x = xOf(i); final y = yOf(_data[i]);
      final isPeak = _data[i] == _data.reduce(max);
      if (isPeak) canvas.drawCircle(Offset(x, y), 10, Paint()..color = _teal3.withOpacity(0.2));
      canvas.drawCircle(Offset(x, y), isPeak ? 6 : 4, Paint()..color = isPeak ? _teal3 : _teal);
      canvas.drawCircle(Offset(x, y), isPeak ? 3 : 2, Paint()..color = Colors.white);
      if (isPeak) {
        final tp2 = TextPainter(text: TextSpan(text: '78%',
            style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)), textDirection: TextDirection.ltr)..layout();
        final bW = tp2.width + 14; const bH = 20.0;
        final bx = (x - bW / 2).clamp(lp, size.width - bW); final by = y - bH - 10;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bW, bH), const Radius.circular(6)), Paint()..color = _teal3);
        canvas.drawPath(Path()..moveTo(x-4, by+bH)..lineTo(x+4, by+bH)..lineTo(x, by+bH+5)..close(), Paint()..color = _teal3);
        tp2.paint(canvas, Offset(bx + 7, by + (bH - tp2.height) / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
