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
  int _demoTab = 0; // 0=Age, 1=Gender

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
                  _buildEyeConditionsSection(),
                  const SizedBox(height: 12),
                  _buildSeverityClassificationSection(),
                  const SizedBox(height: 12),
                  _buildReferralAnalytics(),
                  const SizedBox(height: 12),
                  _buildFollowUpComplianceSection(),
                  const SizedBox(height: 12),
                  _buildCampaignOutcomesSection(),
                  const SizedBox(height: 12),
                  _buildConditionsByAgeSection(),
                  const SizedBox(height: 12),
                  _buildVillageBreakdownSection(),
                  const SizedBox(height: 12),
                  _buildCampaignProgressSection(),
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
    final passRate = _totalScreened > 0
        ? (_totalPassed / _totalScreened)
        : 0.0;
    final referRate = _totalScreened > 0
        ? (_totalReferred / _totalScreened)
        : 0.0;
    return Row(
      children: [
        _buildStatCard('$_totalScreened', 'Screened', 'All time',
            const Color(0xFF0D9488), Icons.visibility_rounded, 1.0),
        const SizedBox(width: 8),
        _buildStatCard('$_totalPassed', 'Passed',
            '${(passRate * 100).toStringAsFixed(0)}%',
            const Color(0xFF22C55E), Icons.check_circle_rounded, passRate),
        const SizedBox(width: 8),
        _buildStatCard('$_totalReferred', 'Referred',
            '${(referRate * 100).toStringAsFixed(0)}%',
            const Color(0xFFF59E0B), Icons.assignment_rounded, referRate),
      ],
    );
  }

  Widget _buildStatCard(String number, String label, String change,
      Color color, IconData icon, double progress) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + change badge
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
                  child: Text(change,
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Large number
            Text(number,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 32, fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A2A3D), height: 1.0)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: const Color(0xFF5E7291))),
            const SizedBox(height: 14),
            // Progress ring + bar combined
            Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                // Filled bar
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [color.withOpacity(0.7), color]),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [BoxShadow(
                            color: color.withOpacity(0.5), blurRadius: 6)],
                      ),
                    ),
                  ),
                ),
                // Glowing dot at progress point
                Align(
                  alignment: Alignment(
                      (progress.clamp(0.0, 1.0) * 2 - 1).clamp(-1.0, 1.0), 0),
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(
                          color: color.withOpacity(0.7), blurRadius: 6)],
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
    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      const names = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return names[d.weekday - 1];
    });
    final dateLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${d.day}/${d.month}';
    });
    const passData  = [65.0, 72.0, 68.0, 74.0, 78.0, 74.0, 76.0];
    const referData = [35.0, 28.0, 32.0, 26.0, 22.0, 26.0, 24.0];
    final currentRate = passData.last;
    final prevRate    = passData[passData.length - 2];
    final diff        = currentRate - prevRate;
    final isUp        = diff >= 0;

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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pass Rate Trend',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text('Last 7 days performance',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.45))),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: (isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withOpacity(0.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444), size: 11),
                    const SizedBox(width: 3),
                    Text('${diff.abs().toStringAsFixed(0)}% vs yesterday',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                            color: isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444))),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${currentRate.toStringAsFixed(0)}%',
                  style: GoogleFonts.spaceGrotesk(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('pass rate today',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.4))),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: _PassRateTrendPainter(passData: passData, referData: referData),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(44, 6, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) => Column(children: [
                Text(dayLabels[i],
                    style: GoogleFonts.inter(fontSize: 9,
                        color: i == 6 ? const Color(0xFF5EEAD4) : Colors.white.withOpacity(0.3),
                        fontWeight: i == 6 ? FontWeight.w700 : FontWeight.w500)),
                Text(dateLabels[i],
                    style: GoogleFonts.inter(fontSize: 8, color: Colors.white.withOpacity(0.2))),
              ])),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(children: [
              _legendDot(const Color(0xFF0D9488), 'Pass rate', '${passData.last.toStringAsFixed(0)}%'),
              Container(width: 1, height: 28, color: Colors.white.withOpacity(0.1)),
              _legendDot(const Color(0xFFF59E0B), 'Refer rate', '${referData.last.toStringAsFixed(0)}%'),
              Container(width: 1, height: 28, color: Colors.white.withOpacity(0.1)),
              _legendDot(const Color(0xFF5EEAD4), 'Peak day',
                  '${dayLabels[passData.indexOf(passData.reduce((a,b)=>a>b?a:b))]} ${passData.reduce((a,b)=>a>b?a:b).toStringAsFixed(0)}%'),
            ]),
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
          // Header + tab switcher
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_alt_rounded, color: Color(0xFF0D9488), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Demographics',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
              Text('Patient breakdown by age & gender',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
            ])),
            // Tab switcher
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _demoTabBtn('Age',    0),
                _demoTabBtn('Gender', 1),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _demoTab == 0
                ? _buildAgeGroupChart()
                : _buildGenderChart(),
          ),
        ],
      ),
    );
  }

  Widget _demoTabBtn(String label, int idx) => GestureDetector(
    onTap: () => setState(() => _demoTab = idx),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _demoTab == idx ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: _demoTab == idx
            ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
            : [],
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: _demoTab == idx ? const Color(0xFF0D9488) : const Color(0xFF8FA0B4))),
    ),
  );

  Widget _buildAgeGroupChart() {
    final total = _ageGroups.values.fold(0, (s, v) => s + v);
    final groups = [
      ('0–17',  _ageGroups['0-17']  ?? 12, const Color(0xFF3B82F6)),
      ('18–40', _ageGroups['18-40'] ?? 18, const Color(0xFF0D9488)),
      ('41–60', _ageGroups['41-60'] ?? 14, const Color(0xFFF59E0B)),
      ('60+',   _ageGroups['60+']   ?? 8,  const Color(0xFFEF4444)),
    ];
    final maxVal = groups.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
    return Column(
      key: const ValueKey('age'),
      children: groups.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          // Color dot + label
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          SizedBox(width: 40,
              child: Text(e.$1, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF5E7291)))),
          // Bar
          Expanded(
            child: Stack(children: [
              Container(height: 10, decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99))),
              FractionallySizedBox(
                widthFactor: maxVal > 0 ? (e.$2 / maxVal).clamp(0.0, 1.0) : 0,
                child: Container(height: 10, decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [e.$3.withOpacity(0.6), e.$3]),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [BoxShadow(color: e.$3.withOpacity(0.4), blurRadius: 4)],
                )),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          // Count + percentage
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${e.$2}', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800, color: e.$3)),
            Text(total > 0 ? '${(e.$2/total*100).toStringAsFixed(0)}%' : '0%',
                style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8FA0B4))),
          ]),
        ]),
      )).toList(),
    );
  }

  Widget _buildGenderChart() {
    final male   = _genderCounts['M'] ?? 28;
    final female = _genderCounts['F'] ?? 24;
    final total  = male + female;
    final mRatio = total > 0 ? male / total : 0.5;
    final fRatio = total > 0 ? female / total : 0.5;
    return Column(
      key: const ValueKey('gender'),
      children: [
        // Stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Row(children: [
            Flexible(
              flex: male,
              child: Container(
                height: 14,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)]),
                ),
              ),
            ),
            Flexible(
              flex: female,
              child: Container(
                height: 14,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFF9A8D4), Color(0xFFEC4899)]),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          // Male
          Expanded(child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
            ),
            child: Column(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.male_rounded, color: Color(0xFF3B82F6), size: 24),
              ),
              const SizedBox(height: 10),
              Text('$male', style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF1A2A3D))),
              Text('Male', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF8FA0B4))),
              const SizedBox(height: 6),
              Text('${(mRatio * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF3B82F6))),
            ]),
          )),
          const SizedBox(width: 12),
          // Female
          Expanded(child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.2)),
            ),
            child: Column(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.female_rounded, color: Color(0xFFEC4899), size: 24),
              ),
              const SizedBox(height: 10),
              Text('$female', style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF1A2A3D))),
              Text('Female', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF8FA0B4))),
              const SizedBox(height: 6),
              Text('${(fRatio * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFFEC4899))),
            ]),
          )),
        ]),
      ],
    );
  }

  Widget _buildVisualAcuitySection() {
    const levels = [
      ('Normal',      0.62, Color(0xFF22C55E)),
      ('Near Normal', 0.20, Color(0xFF0D9488)),
      ('Moderate',    0.11, Color(0xFFF59E0B)),
      ('Severe',      0.05, Color(0xFFEF4444)),
      ('Blind Range', 0.02, Color(0xFF8B5CF6)),
    ];
    const snellen = ['6/6', '6/9–6/12', '6/18–6/24', '6/36–6/60', '<6/60'];

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
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF0D9488), size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Visual Acuity Distribution',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
              Text('Snellen chart results — all eyes tested',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
            ]),
          ]),
          const SizedBox(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Donut chart
            SizedBox(
              width: 110, height: 110,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  values: levels.map((e) => e.$2).toList(),
                  colors: levels.map((e) => e.$3).toList(),
                ),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('62%',
                        style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF22C55E))),
                    Text('Normal',
                        style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8FA0B4))),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Legend bars
            Expanded(
              child: Column(
                children: List.generate(levels.length, (i) {
                  final e = levels[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Container(width: 8, height: 8,
                          decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle)),
                      const SizedBox(width: 7),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(e.$1, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF1A2A3D))),
                          Text('${(e.$2 * 100).toInt()}%',
                              style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: e.$3)),
                        ]),
                        const SizedBox(height: 3),
                        Stack(children: [
                          Container(height: 5, decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99))),
                          FractionallySizedBox(
                            widthFactor: e.$2.clamp(0.0, 1.0),
                            child: Container(height: 5, decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [e.$3.withOpacity(0.6), e.$3]),
                              borderRadius: BorderRadius.circular(99),
                            )),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text(snellen[i], style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF8FA0B4))),
                      ])),
                    ]),
                  );
                }),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildEyeConditionsSection() {
    const conditions = [
      ('Red Eyes',         18, Color(0xFFEF4444), Icons.remove_red_eye_rounded),
      ('Blurred Vision',   14, Color(0xFF3B82F6), Icons.blur_on_rounded),
      ('Eye Pain',          9, Color(0xFFF59E0B), Icons.warning_amber_rounded),
      ('Swollen Eyes',      7, Color(0xFF8B5CF6), Icons.visibility_off_rounded),
      ('Eye Discharge',     5, Color(0xFF0D9488), Icons.water_drop_rounded),
      ('Wears Glasses',    11, Color(0xFF22C55E), Icons.remove_red_eye_outlined),
      ('Diabetes',          6, Color(0xFFEC4899), Icons.monitor_heart_rounded),
      ('Hypertension',      4, Color(0xFFFF6B35), Icons.favorite_rounded),
      ('Previous Surgery',  2, Color(0xFF6366F1), Icons.medical_services_rounded),
    ];
    const total = 47;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Color(0xFF8B5CF6), blurRadius: 20, offset: const Offset(0, 6))],
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
                child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFFA78BFA), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Eye Conditions Reported',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('CHW-observed symptoms · $total patients',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...conditions.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
                          Text('${e.$2} patients',
                              style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: e.$3)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Stack(
                        children: [
                          Container(height: 6, decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(99))),
                          FractionallySizedBox(
                            widthFactor: (e.$2 / total).clamp(0.0, 1.0),
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
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bar_chart_rounded, color: Color(0xFFF59E0B), size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Severity Classification',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
              Text('$total patients classified',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
            ]),
          ]),
          const SizedBox(height: 18),
          // Tall stacked bar with percentage labels on each segment
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 36,
              child: Row(
                children: levels.map((e) {
                  final pct = e.$2 / total;
                  return Flexible(
                    flex: e.$2,
                    child: Container(
                      color: e.$3,
                      child: Center(
                        child: pct >= 0.08
                            ? Text(
                                '${(pct * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend chips
          Wrap(
            spacing: 8, runSpacing: 8,
            children: levels.map((e) {
              final pct = (e.$2 / total * 100).toStringAsFixed(0);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: e.$3.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: e.$3.withOpacity(0.25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: e.$3.withOpacity(0.5), blurRadius: 4)])),
                  const SizedBox(width: 6),
                  Text(e.$1,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF1A2A3D))),
                  const SizedBox(width: 5),
                  Text('${e.$2}',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800, color: e.$3)),
                  const SizedBox(width: 3),
                  Text('($pct%)',
                      style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8FA0B4))),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralAnalytics() {
    const statuses = [
      ('Pending',   5, Color(0xFFF59E0B), Icons.schedule_rounded),
      ('Notified',  3, Color(0xFF3B82F6), Icons.notifications_active_rounded),
      ('Attended',  2, Color(0xFF0D9488), Icons.check_circle_outline_rounded),
      ('Completed', 3, Color(0xFF22C55E), Icons.check_circle_rounded),
      ('Overdue',   1, Color(0xFFEF4444), Icons.error_rounded),
      ('Cancelled', 1, Color(0xFF8FA0B4), Icons.cancel_rounded),
    ];
    const total = 15;

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
          Row(children: [
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
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Referral Analytics',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('$total total referrals · status breakdown',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
            ]),
          ]),
          const SizedBox(height: 16),
          // 2x3 grid of status cards
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: statuses.map((e) {
              final pct = (e.$2 / total * 100).toStringAsFixed(0);
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: e.$3.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: e.$3.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: e.$3.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(e.$4, color: e.$3, size: 15),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${e.$2}',
                          style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                      Text(e.$1,
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5))),
                      Text('$pct%',
                          style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: e.$3)),
                    ]),
                  ],
                ),
              );
            }).toList(),
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
  Widget _buildCampaignOutcomesSection() {
    final campaigns = [
      ('Nakawa Primary School', 24, 18, 6,  const Color(0xFF0D9488)),
      ('Wakiso Health Drive',   18, 12, 6,  const Color(0xFF3B82F6)),
      ('Kampala Eye Week',      31, 25, 6,  const Color(0xFF8B5CF6)),
      ('Entebbe Outreach',      15,  9, 6,  const Color(0xFFF59E0B)),
    ];
    // Sort by pass rate descending for ranking
    final sorted = [...campaigns]..sort((a, b) {
      final rA = a.$2 > 0 ? a.$3 / a.$2 : 0.0;
      final rB = b.$2 > 0 ? b.$3 / b.$2 : 0.0;
      return rB.compareTo(rA);
    });
    final totalScreened = campaigns.fold(0, (s, e) => s + e.$2);

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
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.4)),
              ),
              child: const Icon(Icons.groups_rounded, color: Color(0xFF5EEAD4), size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Screening Outcomes by Campaign',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('${campaigns.length} campaigns · $totalScreened total screened',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
            ]),
          ]),
          const SizedBox(height: 16),
          ...List.generate(sorted.length, (i) {
            final e        = sorted[i];
            final name     = e.$1;
            final total    = e.$2;
            final passed   = e.$3;
            final referred = e.$4;
            final color    = e.$5;
            final passRate = total > 0 ? passed / total : 0.0;
            final rank     = i + 1;
            final rankColor = rank == 1
                ? const Color(0xFFFFD700)
                : rank == 2
                    ? const Color(0xFFC0C0C0)
                    : rank == 3
                        ? const Color(0xFFCD7F32)
                        : Colors.white.withOpacity(0.3);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(children: [
                // Rank badge
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: rankColor.withOpacity(0.5), width: 1.5),
                  ),
                  child: Center(
                    child: Text('#$rank',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: rankColor)),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + bar
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Stack(children: [
                      Container(height: 6, decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(99))),
                      FractionallySizedBox(
                        widthFactor: passRate.clamp(0.0, 1.0),
                        child: Container(height: 6, decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
                          borderRadius: BorderRadius.circular(99),
                        )),
                      ),
                    ]),
                    const SizedBox(height: 5),
                    Row(children: [
                      _campChip('$passed', 'Pass', const Color(0xFF22C55E)),
                      const SizedBox(width: 6),
                      _campChip('$referred', 'Ref', const Color(0xFFEF4444)),
                    ]),
                  ]),
                ),
                const SizedBox(width: 10),
                // Mini donut
                SizedBox(
                  width: 52, height: 52,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      values: [passRate, 1 - passRate],
                      colors: [color, Colors.white.withOpacity(0.1)],
                    ),
                    child: Center(
                      child: Text('${(passRate * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _campChip(String value, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    ]),
  );

  Widget _buildConditionsByAgeSection() {
    // (condition, children 0-17, adults 18-60, elderly 60+)
    final data = [
      ('Red Eyes',       5, 9, 4),
      ('Blurred Vision', 3, 8, 3),
      ('Wears Glasses',  2, 6, 3),
      ('Eye Pain',       2, 5, 2),
      ('Diabetes',       0, 4, 2),
      ('Hypertension',   0, 2, 2),
    ];
    const ageColors = [Color(0xFF3B82F6), Color(0xFF0D9488), Color(0xFF8B5CF6)];
    const ageLabels = ['0–17', '18–60', '60+'];
    // Max value across all for scaling
    final maxVal = data.fold(0, (m, e) {
      final rowMax = [e.$2, e.$3, e.$4].reduce((a, b) => a > b ? a : b);
      return rowMax > m ? rowMax : m;
    });

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
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_rounded, color: Color(0xFF3B82F6), size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Conditions by Age Group',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
              Text('CHW-reported symptoms per age group',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
            ]),
          ]),
          const SizedBox(height: 14),
          // Legend
          Row(children: List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: ageColors[i], borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 5),
              Text(ageLabels[i],
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF5E7291))),
            ]),
          ))),
          const SizedBox(height: 16),
          ...data.map((e) {
            final counts = [e.$2, e.$3, e.$4];
            final total  = counts.reduce((a, b) => a + b);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(e.$1,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1A2A3D)))),
                  Text('$total total',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
                ]),
                const SizedBox(height: 8),
                // Grouped vertical bars side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(3, (i) {
                    final count  = counts[i];
                    final height = maxVal > 0 ? (count / maxVal * 48).clamp(4.0, 48.0) : 4.0;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Count label above bar
                            Text('$count',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11, fontWeight: FontWeight.w800,
                                    color: ageColors[i])),
                            const SizedBox(height: 3),
                            // Bar
                            Container(
                              height: height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [ageColors[i].withOpacity(0.6), ageColors[i]],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                                boxShadow: [BoxShadow(color: ageColors[i].withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                            ),
                            // Age label below bar
                            const SizedBox(height: 4),
                            Text(ageLabels[i],
                                style: GoogleFonts.inter(
                                    fontSize: 8, fontWeight: FontWeight.w600,
                                    color: const Color(0xFF8FA0B4))),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVillageBreakdownSection() {
    final villages = [
      ('Nakawa',    14, 4,  const Color(0xFF0D9488)),
      ('Wakiso',    11, 3,  const Color(0xFF3B82F6)),
      ('Kampala',    9, 2,  const Color(0xFF8B5CF6)),
      ('Entebbe',    7, 2,  const Color(0xFFF59E0B)),
      ('Mukono',     4, 1,  const Color(0xFFEC4899)),
      ('Other',      2, 0,  const Color(0xFF6366F1)),
    ];
    final totalPatients = villages.fold(0, (s, e) => s + e.$2);

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
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.holiday_village_rounded, color: Color(0xFF0D9488), size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Village / Location Breakdown',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
              Text('$totalPatients patients across ${villages.length} locations',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
            ]),
          ]),
          const SizedBox(height: 16),
          ...List.generate(villages.length, (i) {
            final e        = villages[i];
            final village  = e.$1;
            final total    = e.$2;
            final referred = e.$3;
            final color    = e.$4;
            final ratio    = totalPatients > 0 ? total / totalPatients : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                // Rank number
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                  ),
                ),
                const SizedBox(width: 8),
                // Map pin icon
                Icon(Icons.location_on_rounded, size: 14, color: color),
                const SizedBox(width: 4),
                // Village name
                SizedBox(
                  width: 62,
                  child: Text(village,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1A2A3D))),
                ),
                // Bar
                Expanded(
                  child: Stack(children: [
                    Container(height: 8, decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99))),
                    FractionallySizedBox(
                      widthFactor: ratio.clamp(0.0, 1.0),
                      child: Container(height: 8, decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color.withOpacity(0.5), color]),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 4)],
                      )),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                // Patient count bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text('$total',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                ),
                const SizedBox(width: 6),
                // Referred badge
                if (referred > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25)),
                    ),
                    child: Text('$referred ref',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                  )
                else
                  const SizedBox(width: 44),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCampaignProgressSection() {
    // (name, screened, target, passed, referred, color)
    final campaigns = [
      ('Nakawa Primary School', 24, 30, 18, 6,  const Color(0xFF0D9488)),
      ('Wakiso Health Drive',   18, 20, 12, 6,  const Color(0xFF3B82F6)),
      ('Kampala Eye Week',      31, 40, 25, 6,  const Color(0xFF8B5CF6)),
      ('Entebbe Outreach',      15, 25,  9, 6,  const Color(0xFFF59E0B)),
    ];
    final totalCampaigns  = campaigns.length;
    final totalScreened   = campaigns.fold(0, (s, e) => s + e.$2);
    final totalPassed     = campaigns.fold(0, (s, e) => s + e.$4);
    final totalReferred   = campaigns.fold(0, (s, e) => s + e.$5);
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
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign_rounded, color: Color(0xFF0D9488), size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Campaign Progress',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D))),
              Text('$totalCampaigns campaigns · $totalScreened screened',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
            ]),
          ]),
          const SizedBox(height: 14),
          // Summary row
          Row(children: [
            _campProgressStat('$totalScreened', 'Screened', const Color(0xFF0D9488)),
            _campProgressStat('$totalPassed',   'Passed',   const Color(0xFF22C55E)),
            _campProgressStat('$totalReferred', 'Referred', const Color(0xFFEF4444)),
            _campProgressStat('$totalCampaigns','Campaigns',const Color(0xFF8B5CF6)),
          ]),
          const SizedBox(height: 16),
          ...campaigns.map((e) {
            final name     = e.$1;
            final screened = e.$2;
            final target   = e.$3;
            final passed   = e.$4;
            final referred = e.$5;
            final color    = e.$6;
            final progress = target > 0 ? screened / target : 0.0;
            final passRate = screened > 0 ? (passed / screened * 100).round() : 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D)))),
                  Text('$screened / $target',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ]),
                const SizedBox(height: 8),
                Stack(children: [
                  Container(height: 7, decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99))),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(height: 7, decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
                    )),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Text('${(progress * 100).toStringAsFixed(0)}% of target',
                      style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8FA0B4))),
                  const Spacer(),
                  _campChip('$passRate%', 'Pass', const Color(0xFF22C55E)),
                  const SizedBox(width: 6),
                  _campChip('$referred', 'Ref', const Color(0xFFEF4444)),
                ]),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _campProgressStat(String value, String label, Color color) => Expanded(
    child: Column(children: [
      Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8FA0B4))),
    ]),
  );

  Widget _buildVulnerablePopulationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0533), Color(0xFF240A45)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Color(0xFF8B5CF6), blurRadius: 20, offset: const Offset(0, 6))],
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
                  Text('Priority age groups screened',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Children card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.child_care_rounded, color: Color(0xFF3B82F6), size: 20),
                      ),
                      const SizedBox(height: 12),
                      Text('12',
                          style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                      const SizedBox(height: 4),
                      Text('Children',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6))),
                      Text('Ages 0 – 17',
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
                      const SizedBox(height: 10),
                      Stack(children: [
                        Container(height: 5, decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(99))),
                        FractionallySizedBox(
                          widthFactor: 12 / 47,
                          child: Container(height: 5, decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(99),
                          )),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('26% of total',
                          style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.4))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Elderly card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.elderly_rounded, color: Color(0xFF8B5CF6), size: 20),
                      ),
                      const SizedBox(height: 12),
                      Text('8',
                          style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                      const SizedBox(height: 4),
                      Text('Elderly',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF8B5CF6))),
                      Text('Ages 60+',
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
                      const SizedBox(height: 10),
                      Stack(children: [
                        Container(height: 5, decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(99))),
                        FractionallySizedBox(
                          widthFactor: 8 / 47,
                          child: Container(height: 5, decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(99),
                          )),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('17% of total',
                          style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.4))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    // (text, color, icon, priority label, priority color, gradient colors)
    const insights = [
      (
        'Pass rate up 9% vs last week — best performance in Wakiso district this month.',
        Color(0xFF22C55E),
        Icons.trending_up_rounded,
        'Positive',
        Color(0xFF22C55E),
        [Color(0xFF052E16), Color(0xFF14532D)],
      ),
      (
        'Referral slips stock at 30% — reorder needed before next field session.',
        Color(0xFFEF4444),
        Icons.inventory_2_rounded,
        'Urgent',
        Color(0xFFEF4444),
        [Color(0xFF2D0A0A), Color(0xFF450A0A)],
      ),
      (
        'Children 0–17 show highest referral rate (42%) — prioritise school outreach.',
        Color(0xFFF59E0B),
        Icons.child_care_rounded,
        'Action',
        Color(0xFFF59E0B),
        [Color(0xFF2D1A00), Color(0xFF3D2200)],
      ),
      (
        'Average screening time 4.2 min — within the 5-min CHW target.',
        Color(0xFF0D9488),
        Icons.timer_rounded,
        'On Track',
        Color(0xFF0D9488),
        [Color(0xFF022C22), Color(0xFF042F2E)],
      ),
      (
        '3 of 4 villages in Kampala not yet reached — schedule visits this week.',
        Color(0xFF8B5CF6),
        Icons.location_off_rounded,
        'Pending',
        Color(0xFF8B5CF6),
        [Color(0xFF1A0533), Color(0xFF240A45)],
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF04091A), Color(0xFF0B1530)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.4)),
              ),
              child: const Icon(Icons.lightbulb_rounded, color: Color(0xFF5EEAD4), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Key Insights',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Auto-generated from current data',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Text('${insights.length} insights',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.6))),
            ),
          ]),
          const SizedBox(height: 16),
          // Cards
          ...List.generate(insights.length, (i) {
            final e         = insights[i];
            final text      = e.$1;
            final accent    = e.$2;
            final icon      = e.$3;
            final priority  = e.$4;
            final priColor  = e.$5;
            final gradients = e.$6;
            final num       = '${(i + 1).toString().padLeft(2, '0')}';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradients,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withOpacity(0.3), width: 1.2),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number + icon column
                    Column(
                      children: [
                        // Number badge
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accent.withOpacity(0.45), width: 1.2),
                          ),
                          child: Center(
                            child: Text(num,
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11, fontWeight: FontWeight.w900, color: accent)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Icon
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: accent, size: 15),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Text + priority badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Priority badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: priColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: priColor.withOpacity(0.4)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 5, height: 5,
                                decoration: BoxDecoration(
                                  color: priColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: priColor.withOpacity(0.7), blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(priority,
                                  style: GoogleFonts.inter(
                                      fontSize: 9, fontWeight: FontWeight.w800, color: priColor)),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          // Insight text
                          Text(text,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                  height: 1.5,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  const _DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 8;
    const strokeW = 14.0;
    const gap = 0.03;
    final total = values.fold(0.0, (s, v) => s + v);
    double startAngle = -3.14159 / 2;

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * (3.14159 * 2) - gap;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle + gap / 2,
        sweep,
        false,
        paint,
      );
      // Glow
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle + gap / 2,
        sweep,
        false,
        Paint()
          ..color = colors[i].withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 6
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) => old.values != values;
}

class _PassRateTrendPainter extends CustomPainter {
  final List<double> passData;
  final List<double> referData;
  const _PassRateTrendPainter({required this.passData, required this.referData});
  static const _teal  = Color(0xFF0D9488);
  static const _teal3 = Color(0xFF5EEAD4);
  static const _amber = Color(0xFFF59E0B);

  @override
  void paint(Canvas canvas, Size size) {
    const lp = 36.0, tp = 10.0, bp = 8.0;
    final cW = size.width - lp;
    final cH = size.height - tp - bp;
    double xOf(int i) => lp + (i / (passData.length - 1)) * cW;
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

    final rPath = smooth(referData);
    canvas.drawPath(Path.from(rPath)..lineTo(xOf(referData.length-1), size.height)..lineTo(xOf(0), size.height)..close(),
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_amber.withOpacity(0.18), _amber.withOpacity(0.0)]).createShader(Rect.fromLTWH(0,0,size.width,size.height)));

    final pPath = smooth(passData);
    canvas.drawPath(Path.from(pPath)..lineTo(xOf(passData.length-1), size.height)..lineTo(xOf(0), size.height)..close(),
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_teal.withOpacity(0.35), _teal.withOpacity(0.0)]).createShader(Rect.fromLTWH(0,0,size.width,size.height)));

    canvas.drawPath(rPath, Paint()..color = _amber.withOpacity(0.7)..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawPath(pPath, Paint()
      ..shader = LinearGradient(colors: [_teal, _teal3], begin: Alignment.centerLeft, end: Alignment.centerRight).createShader(Rect.fromLTWH(lp, 0, cW, size.height))
      ..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    for (int i = 0; i < passData.length; i++) {
      final x = xOf(i); final y = yOf(passData[i]);
      final isPeak = passData[i] == passData.reduce(max);
      if (isPeak) canvas.drawCircle(Offset(x, y), 10, Paint()..color = _teal3.withOpacity(0.2));
      canvas.drawCircle(Offset(x, y), isPeak ? 6 : 4, Paint()..color = isPeak ? _teal3 : _teal);
      canvas.drawCircle(Offset(x, y), isPeak ? 3 : 2, Paint()..color = Colors.white);
      if (isPeak) {
        final tp2 = TextPainter(text: TextSpan(text: '${passData.reduce(max).toStringAsFixed(0)}%',
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
  bool shouldRepaint(_PassRateTrendPainter old) => old.passData != passData;
}
