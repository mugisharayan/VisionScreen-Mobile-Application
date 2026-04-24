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

  // ── Stats cards
  int _totalScreened = 0;
  int _totalPassed   = 0;
  int _totalReferred = 0;

  // ── Demographics
  Map<String, int> _ageGroups   = {};
  Map<String, int> _genderCounts = {};

  // ── Trend chart
  List<Map<String, dynamic>> _trendData = [];

  // ── Visual acuity
  Map<String, int> _visualAcuity = {};

  // ── Eye conditions
  Map<String, int> _conditionCounts = {};

  // ── Severity
  Map<String, int> _severityCounts = {};

  // ── Referrals
  Map<String, int> _referralStatuses = {};

  // ── Follow-up compliance
  Map<String, int> _followUpCounts = {};

  // ── Campaigns
  List<Map<String, dynamic>> _campaigns = [];

  // ── Conditions by age
  Map<String, Map<String, int>> _conditionsByAge = {};

  // ── Villages
  List<Map<String, dynamic>> _villages = [];

  // ── UI state
  bool _loading  = true;
  bool _hasError = false;
  int  _demoTab  = 0; // 0=Age, 1=Gender

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final db = DatabaseHelper.instance;
      final results = await Future.wait([
        db.getOutcomeCounts(period: _selectedPeriod),
        db.getAgeGroupCounts(period: _selectedPeriod),
        db.getGenderCounts(period: _selectedPeriod),
        db.getPassRateTrend(_selectedPeriod),
        db.getVisualAcuityDistribution(period: _selectedPeriod),
        db.getConditionCounts(period: _selectedPeriod),
        db.getSeverityClassification(period: _selectedPeriod),
        db.getReferralStatusCounts(period: _selectedPeriod),
        db.getFollowUpCompliance(period: _selectedPeriod),
        db.getAllCampaigns(),
        db.getConditionsByAgeGroup(period: _selectedPeriod),
        db.getVillageBreakdown(period: _selectedPeriod),
      ]);
      if (!mounted) return;
      setState(() {
        final outcomes         = results[0]  as Map<String, int>;
        _totalPassed           = outcomes['pass']  ?? 0;
        _totalReferred         = outcomes['refer'] ?? 0;
        _totalScreened         = _totalPassed + _totalReferred;
        _ageGroups             = results[1]  as Map<String, int>;
        _genderCounts          = results[2]  as Map<String, int>;
        _trendData             = results[3]  as List<Map<String, dynamic>>;
        _visualAcuity          = results[4]  as Map<String, int>;
        _conditionCounts       = results[5]  as Map<String, int>;
        _severityCounts        = results[6]  as Map<String, int>;
        _referralStatuses      = results[7]  as Map<String, int>;
        _followUpCounts        = results[8]  as Map<String, int>;
        _campaigns             = results[9]  as List<Map<String, dynamic>>;
        _conditionsByAge       = results[10] as Map<String, Map<String, int>>;
        _villages              = results[11] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _hasError = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _hasError
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.wifi_off_rounded, color: Color(0xFF8FA0B4), size: 40),
                      const SizedBox(height: 12),
                      Text('Failed to load data',
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5E7291))),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _loadStats,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF0D9488)),
                      ),
                    ]),
                  )
                : _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
                    : SingleChildScrollView(
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
            onTap: () {
              setState(() => _selectedPeriod = p);
              _loadStats();
            },
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
    // Strip the __total__ summary row appended by getPassRateTrend
    final totalRow   = _trendData.where((r) => r['label'] == '__total__').firstOrNull;
    final chartData  = _trendData.where((r) => r['label'] != '__total__').toList();
    final hasData    = chartData.length >= 2;

    // Period-wide pass rate from the total row (accurate headline)
    double periodPassRate = 0.0;
    double periodReferRate = 0.0;
    if (totalRow != null) {
      final tp = (totalRow['pass_count']  as int).toDouble();
      final tr = (totalRow['refer_count'] as int).toDouble();
      final tt = tp + tr;
      periodPassRate  = tt > 0 ? tp / tt * 100 : 0.0;
      periodReferRate = tt > 0 ? tr / tt * 100 : 0.0;
    }

    // Per-bucket pass% series for the chart line
    final passData = chartData.map((r) {
      final p = (r['pass_count']  as int).toDouble();
      final q = (r['refer_count'] as int).toDouble();
      final total = p + q;
      return total > 0 ? (p / total * 100) : 0.0;
    }).toList();

    final referData = chartData.map((r) {
      final p = (r['pass_count']  as int).toDouble();
      final q = (r['refer_count'] as int).toDouble();
      final total = p + q;
      return total > 0 ? (q / total * 100) : 0.0;
    }).toList();

    final labels = chartData.map((r) => r['label'] as String).toList();

    final subtitle = switch (_selectedPeriod) {
      'Today'  => 'Hourly breakdown — today',
      'Month'  => 'Daily breakdown — last 30 days',
      'Year'   => 'Monthly breakdown — last 12 months',
      _        => 'Last 7 days performance',
    };

    // Trend badge: compare last two buckets
    final prevRate = passData.length >= 2 ? passData[passData.length - 2] : periodPassRate;
    final lastRate = passData.isNotEmpty ? passData.last : periodPassRate;
    final diff     = lastRate - prevRate;
    final isUp     = diff >= 0;

    // Peak label from chart buckets
    String peakLabel = '—';
    if (passData.isNotEmpty) {
      final peakIdx = passData.indexOf(passData.reduce((a, b) => a > b ? a : b));
      peakLabel = '${labels[peakIdx]} ${passData[peakIdx].toStringAsFixed(0)}%';
    }

    // Need at least 2 points to draw a line chart
    if (!hasData) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF04091A), Color(0xFF0B1530)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.show_chart_rounded, color: Colors.white.withOpacity(0.2), size: 36),
            const SizedBox(height: 10),
            Text('No screenings recorded for this period',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.35))),
          ]),
        ),
      );
    }

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
                    Text(subtitle,
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
                    Text('${diff.abs().toStringAsFixed(0)}% vs prev',
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
              Text('${periodPassRate.toStringAsFixed(0)}%',
                  style: GoogleFonts.spaceGrotesk(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('pass rate · ${_selectedPeriod.toLowerCase()}',
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
          // X-axis labels
          Padding(
            padding: const EdgeInsets.fromLTRB(44, 6, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(labels.length, (i) {
                final isLast = i == labels.length - 1;
                // Shorten label to fit: take last 5 chars max
                final short = labels[i].length > 5 ? labels[i].substring(labels[i].length - 5) : labels[i];
                return Text(short,
                    style: GoogleFonts.inter(
                        fontSize: 8,
                        color: isLast ? const Color(0xFF5EEAD4) : Colors.white.withOpacity(0.3),
                        fontWeight: isLast ? FontWeight.w700 : FontWeight.w500));
              }),
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
              _legendDot(const Color(0xFF0D9488), 'Pass rate', '${periodPassRate.toStringAsFixed(0)}%'),
              Container(width: 1, height: 28, color: Colors.white.withOpacity(0.1)),
              _legendDot(const Color(0xFFF59E0B), 'Refer rate', '${periodReferRate.toStringAsFixed(0)}%'),
              Container(width: 1, height: 28, color: Colors.white.withOpacity(0.1)),
              _legendDot(const Color(0xFF5EEAD4), 'Peak', peakLabel),
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
              Text('Patient breakdown · $_selectedPeriod',
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
      ('0–17',  _ageGroups['0-17']  ?? 0, const Color(0xFF3B82F6)),
      ('18–40', _ageGroups['18-40'] ?? 0, const Color(0xFF0D9488)),
      ('41–60', _ageGroups['41-60'] ?? 0, const Color(0xFFF59E0B)),
      ('60+',   _ageGroups['60+']   ?? 0, const Color(0xFFEF4444)),
    ];
    final maxVal = groups.map((e) => e.$2).fold(0, (a, b) => a > b ? a : b);

    if (total == 0) {
      return Center(
        key: const ValueKey('age'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text('No patient data yet',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8FA0B4))),
        ),
      );
    }

    return Column(
      key: const ValueKey('age'),
      children: groups.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          SizedBox(width: 40,
              child: Text(e.$1,
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: const Color(0xFF5E7291)))),
          Expanded(
            child: Stack(children: [
              Container(height: 10, decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(99))),
              FractionallySizedBox(
                widthFactor: maxVal > 0 ? (e.$2 / maxVal).clamp(0.0, 1.0) : 0.0,
                child: Container(height: 10, decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [e.$3.withOpacity(0.6), e.$3]),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [BoxShadow(color: e.$3.withOpacity(0.4), blurRadius: 4)],
                )),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${e.$2}',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w800, color: e.$3)),
            Text('${(e.$2 / total * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                    fontSize: 9, color: const Color(0xFF8FA0B4))),
          ]),
        ]),
      )).toList(),
    );
  }

  Widget _buildGenderChart() {
    final male   = _genderCounts['M'] ?? 0;
    final female = _genderCounts['F'] ?? 0;
    final total  = male + female;
    final mRatio = total > 0 ? male   / total : 0.0;
    final fRatio = total > 0 ? female / total : 0.0;

    if (total == 0) {
      return Center(
        key: const ValueKey('gender'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text('No patient data yet',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8FA0B4))),
        ),
      );
    }
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
    const meta = [
      ('Normal',      Color(0xFF22C55E), '6/6'),
      ('Near Normal', Color(0xFF0D9488), '6/9–6/12'),
      ('Moderate',    Color(0xFFF59E0B), '6/18–6/24'),
      ('Severe',      Color(0xFFEF4444), '6/36–6/60'),
      ('Blind Range', Color(0xFF8B5CF6), '<6/60'),
    ];

    final total = _visualAcuity.values.fold(0, (s, v) => s + v);
    final levels = meta.map((m) {
      final count = _visualAcuity[m.$1] ?? 0;
      final ratio = total > 0 ? count / total : 0.0;
      return (m.$1, ratio, m.$2, m.$3, count);
    }).toList();

    final normalRatio = levels[0].$2;
    final normalPct   = '${(normalRatio * 100).toStringAsFixed(0)}%';

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
              Text('Snellen chart results — $total eyes assessed',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8FA0B4))),
            ]),
          ]),
          const SizedBox(height: 20),
          total == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No screening data yet',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8FA0B4))),
                  ),
                )
              : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  SizedBox(
                    width: 110, height: 110,
                    child: CustomPaint(
                      painter: _DonutChartPainter(
                        values: levels.map((e) => e.$2 == 0 ? 0.001 : e.$2).toList(),
                        colors: levels.map((e) => e.$3).toList(),
                      ),
                      child: Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(normalPct,
                              style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF22C55E))),
                          Text('Normal',
                              style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8FA0B4))),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
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
                                Text('${(e.$2 * 100).toStringAsFixed(0)}%',
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
                              Text(e.$4, style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF8FA0B4))),
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
    // Colour + icon palette keyed by condition name
    const palette = <String, (Color, IconData)>{
      'Red Eyes':        (Color(0xFFEF4444), Icons.remove_red_eye_rounded),
      'Blurred Vision':  (Color(0xFF3B82F6), Icons.blur_on_rounded),
      'Eye Pain':        (Color(0xFFF59E0B), Icons.warning_amber_rounded),
      'Swollen Eyes':    (Color(0xFF8B5CF6), Icons.visibility_off_rounded),
      'Eye Discharge':   (Color(0xFF0D9488), Icons.water_drop_rounded),
      'Wears Glasses':   (Color(0xFF22C55E), Icons.remove_red_eye_outlined),
      'Diabetes':        (Color(0xFFEC4899), Icons.monitor_heart_rounded),
      'Hypertension':    (Color(0xFFFF6B35), Icons.favorite_rounded),
      'Previous Surgery':(Color(0xFF6366F1), Icons.medical_services_rounded),
    };
    const Color _defaultColor = Color(0xFF8FA0B4);

    // Sort by count descending, take top 9
    final sorted = _conditionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final entries  = sorted.take(9).toList();
    final maxCount = entries.isEmpty ? 1 : entries.first.value;
    // Count of unique patients who have at least one condition
    final patientCount = _conditionCounts.isEmpty ? 0
        : _conditionCounts.values.fold(0, (s, v) => s + v);
    // Note: patientCount is sum of tag occurrences, not unique patients.
    // We show it as "X condition reports" to be accurate.
    final reportCount = patientCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0xFF8B5CF6), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Eye Conditions Reported',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('CHW-observed symptoms · $reportCount reports',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.4))),
            ]),
          ]),
          const SizedBox(height: 16),
          entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No conditions recorded yet',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.35))),
                  ),
                )
              : Column(
                  children: entries.map((entry) {
                    final name   = entry.key;
                    final count  = entry.value;
                    final color  = palette[name]?.$1 ?? _defaultColor;
                    final icon   = palette[name]?.$2 ?? Icons.circle;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Icon(icon, color: color, size: 15),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name,
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.85))),
                                Text('$count patients',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Stack(children: [
                              Container(height: 6, decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(99))),
                              FractionallySizedBox(
                              widthFactor: maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
                                    borderRadius: BorderRadius.circular(99),
                                    boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                        ),
                      ]),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildSeverityClassificationSection() {
    const meta = [
      ('Normal',   Color(0xFF22C55E)),
      ('Mild',     Color(0xFF0D9488)),
      ('Moderate', Color(0xFFF59E0B)),
      ('Severe',   Color(0xFFEF4444)),
      ('Critical', Color(0xFF8B5CF6)),
    ];

    final total  = _severityCounts.values.fold(0, (s, v) => s + v);
    final levels = meta.map((m) => (m.$1, _severityCounts[m.$1] ?? 0, m.$2)).toList();

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
          total == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No classification data yet',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8FA0B4))),
                  ),
                )
              : Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 36,
                      child: Row(
                        children: levels.map((e) {
                          final pct = e.$2 / total;
                          return Flexible(
                            flex: e.$2 == 0 ? 1 : e.$2,
                            child: Container(
                              color: e.$2 == 0 ? e.$3.withOpacity(0.15) : e.$3,
                              child: Center(
                                child: pct >= 0.08
                                    ? Text('${(pct * 100).toStringAsFixed(0)}%',
                                        style: GoogleFonts.spaceGrotesk(
                                            fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: levels.map((e) {
                      final pct = total > 0 ? (e.$2 / total * 100).toStringAsFixed(0) : '0';
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
                ]),
        ],
      ),
    );
  }

  Widget _buildReferralAnalytics() {
    const meta = [
      ('Pending',   Color(0xFFF59E0B), Icons.schedule_rounded),
      ('Notified',  Color(0xFF3B82F6), Icons.notifications_active_rounded),
      ('Attended',  Color(0xFF0D9488), Icons.check_circle_outline_rounded),
      ('Completed', Color(0xFF22C55E), Icons.check_circle_rounded),
      ('Overdue',   Color(0xFFEF4444), Icons.error_rounded),
      ('Cancelled', Color(0xFF8FA0B4), Icons.cancel_rounded),
    ];

    // Map DB keys (lowercase) to display labels
    const keyMap = {
      'pending':   'Pending',
      'notified':  'Notified',
      'attended':  'Attended',
      'completed': 'Completed',
      'overdue':   'Overdue',
      'cancelled': 'Cancelled',
    };

    final counts = <String, int>{};
    for (final e in _referralStatuses.entries) {
      final label = keyMap[e.key.toLowerCase()] ?? e.key;
      counts[label] = (counts[label] ?? 0) + e.value;
    }

    final total = counts.values.fold(0, (s, v) => s + v);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C1A2E), Color(0xFF0F2744)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.15),
            blurRadius: 20, offset: const Offset(0, 6))],
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
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('$total total referrals · status breakdown',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: Colors.white.withOpacity(0.4))),
            ]),
          ]),
          const SizedBox(height: 16),
          total == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No referrals recorded yet',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white.withOpacity(0.35))),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.1,
                  children: meta.map((m) {
                    final count = counts[m.$1] ?? 0;
                    final pct   = total > 0
                        ? (count / total * 100).toStringAsFixed(0)
                        : '0';
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: m.$2.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: m.$2.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: m.$2.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(m.$3, color: m.$2, size: 15),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('$count',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 22, fontWeight: FontWeight.w900,
                                    color: Colors.white, height: 1.0)),
                            Text(m.$1,
                                style: GoogleFonts.inter(
                                    fontSize: 9, fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.5))),
                            Text('$pct%',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: m.$2)),
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
    const meta = [
      ('Attended',    Color(0xFF22C55E)),
      ('Rescheduled', Color(0xFF0D9488)),
      ('Pending',     Color(0xFFF59E0B)),
      ('Missed',      Color(0xFFEF4444)),
    ];

    final items     = meta.map((m) => (m.$1, _followUpCounts[m.$1] ?? 0, m.$2)).toList();
    final total     = items.fold(0, (s, e) => s + e.$2);
    final compliant = _followUpCounts['Attended'] ?? 0;
    final compliancePct = total > 0
        ? (compliant / total * 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event_available_rounded,
                  color: Color(0xFF22C55E), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Follow-Up Compliance',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2A3D))),
                Text('$total follow-ups scheduled',
                    style: GoogleFonts.inter(
                        fontSize: 10, color: const Color(0xFF8FA0B4))),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$compliancePct%',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: const Color(0xFF22C55E))),
              Text('compliance',
                  style: GoogleFonts.inter(
                      fontSize: 9, color: const Color(0xFF8FA0B4))),
            ]),
          ]),
          const SizedBox(height: 14),
          total == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No follow-ups scheduled yet',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF8FA0B4))),
                  ),
                )
              : Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Row(
                      children: items.map((e) => Flexible(
                        flex: e.$2 == 0 ? 1 : e.$2,
                        child: Container(
                          height: 10,
                          color: e.$2 == 0 ? e.$3.withOpacity(0.15) : e.$3,
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...items.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: e.$3, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                              color: e.$3.withOpacity(0.5), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.$1,
                          style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A2A3D)))),
                      Text('${e.$2}',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: e.$3)),
                      const SizedBox(width: 4),
                      Text('(${total > 0 ? (e.$2 / total * 100).toStringAsFixed(0) : 0}%)',
                          style: GoogleFonts.inter(
                              fontSize: 10, color: const Color(0xFF8FA0B4))),
                    ]),
                  )),
                ]),
        ],
      ),
    );
  }
  Widget _buildCampaignOutcomesSection() {
    // Cycle through these colours per campaign index
    const colours = [
      Color(0xFF0D9488), Color(0xFF3B82F6),
      Color(0xFF8B5CF6), Color(0xFFF59E0B),
      Color(0xFFEC4899), Color(0xFF22C55E),
    ];

    final totalScreened = _campaigns.fold(0, (s, e) => s + ((e['total'] as int?) ?? 0));

    // Sort by pass rate descending for ranking
    final sorted = [..._campaigns]..sort((a, b) {
      final t1 = (a['total']  as int?) ?? 0;
      final t2 = (b['total']  as int?) ?? 0;
      final p1 = (a['passed'] as int?) ?? 0;
      final p2 = (b['passed'] as int?) ?? 0;
      final r1 = t1 > 0 ? p1 / t1 : 0.0;
      final r2 = t2 > 0 ? p2 / t2 : 0.0;
      return r2.compareTo(r1);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF042F2E), Color(0xFF0D3D3B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.2),
            blurRadius: 20, offset: const Offset(0, 6))],
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
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('${_campaigns.length} campaigns · $totalScreened total screened',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: Colors.white.withOpacity(0.4))),
            ]),
          ]),
          const SizedBox(height: 16),
          _campaigns.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No campaigns recorded yet',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white.withOpacity(0.35))),
                  ),
                )
              : Column(
                  children: List.generate(sorted.length, (i) {
                    final e        = sorted[i];
                    final name     = (e['name']     as String?) ?? 'Unknown';
                    final total    = (e['total']    as int?)    ?? 0;
                    final passed   = (e['passed']   as int?)    ?? 0;
                    final referred = (e['referred'] as int?)    ?? 0;
                    final color    = colours[i % colours.length];
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
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: rankColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: rankColor.withOpacity(0.5), width: 1.5),
                          ),
                          child: Center(
                            child: Text('#$rank',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11, fontWeight: FontWeight.w900, color: rankColor)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Stack(children: [
                              Container(height: 6, decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(99))),
                              FractionallySizedBox(
                                widthFactor: passRate.clamp(0.0, 1.0),
                                child: Container(height: 6, decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [color.withOpacity(0.6), color]),
                                  borderRadius: BorderRadius.circular(99),
                                )),
                              ),
                            ]),
                            const SizedBox(height: 5),
                            Row(children: [
                              _campChip('$passed',   'Pass', const Color(0xFF22C55E)),
                              const SizedBox(width: 6),
                              _campChip('$referred', 'Ref',  const Color(0xFFEF4444)),
                            ]),
                          ]),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 52, height: 52,
                          child: CustomPaint(
                            painter: _DonutChartPainter(
                              values: [passRate == 0 ? 0.001 : passRate, 1 - passRate],
                              colors: [color, Colors.white.withOpacity(0.1)],
                            ),
                            child: Center(
                              child: Text('${(passRate * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10, fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ]),
                    );
                  }),
                ),
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
    const ageColors = [Color(0xFF3B82F6), Color(0xFF0D9488), Color(0xFF8B5CF6)];
    const ageKeys   = ['0-17', '18-60', '60+'];
    const ageLabels = ['0–17', '18–60', '60+'];

    // Take top 6 conditions by total count
    final sorted = _conditionsByAge.entries.toList()
      ..sort((a, b) {
        final tA = a.value.values.fold(0, (s, v) => s + v);
        final tB = b.value.values.fold(0, (s, v) => s + v);
        return tB.compareTo(tA);
      });
    final data = sorted.take(6).toList();

    final maxVal = data.fold(0, (m, entry) {
      final rowMax = ageKeys.map((k) => entry.value[k] ?? 0).reduce((a, b) => a > b ? a : b);
      return rowMax > m ? rowMax : m;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 3))],
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
              child: const Icon(Icons.people_rounded,
                  color: Color(0xFF3B82F6), size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Conditions by Age Group',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2A3D))),
              Text('CHW-reported symptoms per age group',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: const Color(0xFF8FA0B4))),
            ]),
          ]),
          const SizedBox(height: 14),
          // Legend
          Row(
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: ageColors[i],
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 5),
                Text(ageLabels[i],
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: const Color(0xFF5E7291))),
              ]),
            )),
          ),
          const SizedBox(height: 16),
          data.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No condition data yet',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF8FA0B4))),
                  ),
                )
              : Column(
                  children: data.map((entry) {
                    final condition = entry.key;
                    final counts    = ageKeys.map((k) => entry.value[k] ?? 0).toList();
                    final total     = counts.fold(0, (s, v) => s + v);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Text(condition,
                                style: GoogleFonts.inter(
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A2A3D)))),
                            Text('$total total',
                                style: GoogleFonts.inter(
                                    fontSize: 10, color: const Color(0xFF8FA0B4))),
                          ]),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(3, (i) {
                              final count  = counts[i];
                              final height = maxVal > 0
                                  ? (count / maxVal * 48).clamp(4.0, 48.0)
                                  : 4.0;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('$count',
                                          style: GoogleFonts.spaceGrotesk(
                                              fontSize: 11, fontWeight: FontWeight.w800,
                                              color: ageColors[i])),
                                      const SizedBox(height: 3),
                                      Container(
                                        height: height,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [ageColors[i].withOpacity(0.6), ageColors[i]],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft:  Radius.circular(4),
                                            topRight: Radius.circular(4),
                                          ),
                                          boxShadow: [BoxShadow(
                                              color: ageColors[i].withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2))],
                                        ),
                                      ),
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
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildVillageBreakdownSection() {
    const colours = [
      Color(0xFF0D9488), Color(0xFF3B82F6), Color(0xFF8B5CF6),
      Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF6366F1),
    ];

    final totalPatients = _villages.fold(0, (s, e) => s + ((e['total'] as int?) ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 3))],
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
              child: const Icon(Icons.holiday_village_rounded,
                  color: Color(0xFF0D9488), size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Village / Location Breakdown',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2A3D))),
              Text('$totalPatients patients across ${_villages.length} locations',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: const Color(0xFF8FA0B4))),
            ]),
          ]),
          const SizedBox(height: 16),
          _villages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No location data yet',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF8FA0B4))),
                  ),
                )
              : Column(
                  children: List.generate(_villages.length, (i) {
                    final e        = _villages[i];
                    final village  = (e['village']  as String?) ?? 'Unknown';
                    final total    = (e['total']    as int?)    ?? 0;
                    final referred = (e['referred'] as int?)    ?? 0;
                    final color    = colours[i % colours.length];
                    final ratio    = totalPatients > 0
                        ? (total / totalPatients).clamp(0.0, 1.0)
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10, fontWeight: FontWeight.w800,
                                    color: color)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_rounded, size: 14, color: color),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 62,
                          child: Text(village,
                              style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A2A3D)),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Expanded(
                          child: Stack(children: [
                            Container(height: 8, decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(99))),
                            FractionallySizedBox(
                              widthFactor: ratio,
                              child: Container(height: 8, decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [color.withOpacity(0.5), color]),
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: [BoxShadow(
                                    color: color.withOpacity(0.35), blurRadius: 4)],
                              )),
                            ),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Text('$total',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11, fontWeight: FontWeight.w800,
                                  color: color)),
                        ),
                        const SizedBox(width: 6),
                        referred > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                      color: const Color(0xFFEF4444).withOpacity(0.25)),
                                ),
                                child: Text('$referred ref',
                                    style: GoogleFonts.inter(
                                        fontSize: 9, fontWeight: FontWeight.w700,
                                        color: const Color(0xFFEF4444))),
                              )
                            : const SizedBox(width: 44),
                      ]),
                    );
                  }),
                ),
        ],
      ),
    );
  }

  Widget _buildCampaignProgressSection() {
    const colours = [
      Color(0xFF0D9488), Color(0xFF3B82F6),
      Color(0xFF8B5CF6), Color(0xFFF59E0B),
      Color(0xFFEC4899), Color(0xFF22C55E),
    ];

    final totalScreened = _campaigns.fold(0, (s, e) => s + ((e['total']    as int?) ?? 0));
    final totalPassed   = _campaigns.fold(0, (s, e) => s + ((e['passed']   as int?) ?? 0));
    final totalReferred = _campaigns.fold(0, (s, e) => s + ((e['referred'] as int?) ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 3))],
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
              child: const Icon(Icons.campaign_rounded,
                  color: Color(0xFF0D9488), size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Campaign Progress',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2A3D))),
              Text('${_campaigns.length} campaigns · $totalScreened screened',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: const Color(0xFF8FA0B4))),
            ]),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _campProgressStat('$totalScreened',       'Screened',  const Color(0xFF0D9488)),
            _campProgressStat('$totalPassed',         'Passed',    const Color(0xFF22C55E)),
            _campProgressStat('$totalReferred',       'Referred',  const Color(0xFFEF4444)),
            _campProgressStat('${_campaigns.length}', 'Campaigns', const Color(0xFF8B5CF6)),
          ]),
          const SizedBox(height: 16),
          _campaigns.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No campaigns yet',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF8FA0B4))),
                  ),
                )
              : Column(
                  children: List.generate(_campaigns.length, (i) {
                    final e        = _campaigns[i];
                    final name     = (e['name']     as String?) ?? 'Unknown';
                    final screened = (e['total']    as int?)    ?? 0;
                    final passed   = (e['passed']   as int?)    ?? 0;
                    final referred = (e['referred'] as int?)    ?? 0;
                    final color    = colours[i % colours.length];
                    // campaigns table has no target column — show screened vs passed
                    final passRate = screened > 0 ? (passed / screened * 100).round() : 0;
                    final progress = screened > 0 ? (passed / screened).clamp(0.0, 1.0) : 0.0;

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
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(name,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A2A3D)),
                              overflow: TextOverflow.ellipsis)),
                          Text('$screened screened',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: color)),
                        ]),
                        const SizedBox(height: 8),
                        Stack(children: [
                          Container(height: 7, decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(99))),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(height: 7, decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [color.withOpacity(0.6), color]),
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [BoxShadow(
                                  color: color.withOpacity(0.4), blurRadius: 4)],
                            )),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text('$passRate% pass rate',
                              style: GoogleFonts.inter(
                                  fontSize: 9, color: const Color(0xFF8FA0B4))),
                          const Spacer(),
                          _campChip('$passed',   'Pass', const Color(0xFF22C55E)),
                          const SizedBox(width: 6),
                          _campChip('$referred', 'Ref',  const Color(0xFFEF4444)),
                        ]),
                      ]),
                    );
                  }),
                ),
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
    final children = _ageGroups['0-17']  ?? 0;
    final elderly  = _ageGroups['60+']   ?? 0;
    final total    = _ageGroups.values.fold(0, (s, v) => s + v);
    final childPct = total > 0 ? (children / total * 100).toStringAsFixed(0) : '0';
    final elderPct = total > 0 ? (elderly  / total * 100).toStringAsFixed(0) : '0';
    final childRatio = total > 0 ? (children / total).clamp(0.0, 1.0) : 0.0;
    final elderRatio = total > 0 ? (elderly  / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0533), Color(0xFF240A45)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(
            color: Color(0xFF8B5CF6), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.35)),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Color(0xFFA78BFA), size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Vulnerable Populations',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text('Priority age groups · $total total patients',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: Colors.white.withOpacity(0.4))),
            ]),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            // Children card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.3)),
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
                      child: const Icon(Icons.child_care_rounded,
                          color: Color(0xFF3B82F6), size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text('$children',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 32, fontWeight: FontWeight.w900,
                            color: Colors.white, height: 1.0)),
                    const SizedBox(height: 4),
                    Text('Children',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B82F6))),
                    Text('Ages 0 – 17',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.4))),
                    const SizedBox(height: 10),
                    Stack(children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: childRatio,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('$childPct% of total',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.white.withOpacity(0.4))),
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
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3)),
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
                      child: const Icon(Icons.elderly_rounded,
                          color: Color(0xFF8B5CF6), size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text('$elderly',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 32, fontWeight: FontWeight.w900,
                            color: Colors.white, height: 1.0)),
                    const SizedBox(height: 4),
                    Text('Elderly',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: const Color(0xFF8B5CF6))),
                    Text('Ages 60+',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.4))),
                    const SizedBox(height: 10),
                    Stack(children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: elderRatio,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('$elderPct% of total',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.white.withOpacity(0.4))),
                  ],
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  /// Generates insights dynamically from live state values.
  List<({String text, Color accent, IconData icon, String priority, List<Color> gradients})> get _computedInsights {
    final insights = <({String text, Color accent, IconData icon, String priority, List<Color> gradients})>[];

    // 1. Pass rate trend
    if (_trendData.length >= 2) {
      final passData = _trendData.map((r) {
        final p = (r['pass_count']  as int).toDouble();
        final q = (r['refer_count'] as int).toDouble();
        final t = p + q;
        return t > 0 ? p / t * 100 : 0.0;
      }).toList();
      final curr = passData.last;
      final prev = passData[passData.length - 2];
      final diff = curr - prev;
      if (diff.abs() >= 1) {
        final up = diff > 0;
        insights.add((
          text: '${up ? 'Pass rate up' : 'Pass rate down'} ${diff.abs().toStringAsFixed(0)}% vs previous period — ${up ? 'performance improving.' : 'review recent screenings.'}',
          accent: up ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          priority: up ? 'Positive' : 'Warning',
          gradients: up
              ? [const Color(0xFF052E16), const Color(0xFF14532D)]
              : [const Color(0xFF2D0A0A), const Color(0xFF450A0A)],
        ));
      }
    }

    // 2. High referral rate
    if (_totalScreened > 0) {
      final referRate = _totalReferred / _totalScreened * 100;
      if (referRate >= 30) {
        insights.add((
          text: 'Referral rate is ${referRate.toStringAsFixed(0)}% — ${referRate >= 40 ? 'critically high' : 'elevated'}. Consider targeted follow-up sessions.',
          accent: referRate >= 40 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
          icon: Icons.assignment_rounded,
          priority: referRate >= 40 ? 'Urgent' : 'Action',
          gradients: referRate >= 40
              ? [const Color(0xFF2D0A0A), const Color(0xFF450A0A)]
              : [const Color(0xFF2D1A00), const Color(0xFF3D2200)],
        ));
      }
    }

    // 3. Children referral burden
    final childTotal = (_ageGroups['0-17'] ?? 0);
    final allTotal   = _ageGroups.values.fold(0, (s, v) => s + v);
    if (childTotal > 0 && allTotal > 0) {
      final childShare = childTotal / allTotal * 100;
      if (childShare >= 20) {
        insights.add((
          text: 'Children (0–17) make up ${childShare.toStringAsFixed(0)}% of patients — prioritise school and community outreach.',
          accent: const Color(0xFFF59E0B),
          icon: Icons.child_care_rounded,
          priority: 'Action',
          gradients: [const Color(0xFF2D1A00), const Color(0xFF3D2200)],
        ));
      }
    }

    // 4. Overdue referrals
    final overdue = _referralStatuses['overdue'] ?? 0;
    if (overdue > 0) {
      insights.add((
        text: '$overdue referral${overdue == 1 ? '' : 's'} overdue — follow up with ${overdue == 1 ? 'this patient' : 'these patients'} immediately.',
        accent: const Color(0xFFEF4444),
        icon: Icons.error_rounded,
        priority: 'Urgent',
        gradients: [const Color(0xFF2D0A0A), const Color(0xFF450A0A)],
      ));
    }

    // 5. Follow-up compliance
    final attended = _followUpCounts['Attended'] ?? 0;
    final followTotal = _followUpCounts.values.fold(0, (s, v) => s + v);
    if (followTotal > 0) {
      final compliance = attended / followTotal * 100;
      if (compliance >= 70) {
        insights.add((
          text: 'Follow-up compliance at ${compliance.toStringAsFixed(0)}% — patients are attending scheduled appointments.',
          accent: const Color(0xFF0D9488),
          icon: Icons.event_available_rounded,
          priority: 'On Track',
          gradients: [const Color(0xFF022C22), const Color(0xFF042F2E)],
        ));
      } else if (compliance < 50) {
        insights.add((
          text: 'Follow-up compliance at ${compliance.toStringAsFixed(0)}% — ${_followUpCounts['Missed'] ?? 0} missed appointments need rescheduling.',
          accent: const Color(0xFFF59E0B),
          icon: Icons.event_busy_rounded,
          priority: 'Action',
          gradients: [const Color(0xFF2D1A00), const Color(0xFF3D2200)],
        ));
      }
    }

    // 6. Village coverage
    if (_villages.length >= 2) {
      final topVillage = _villages.first;
      final name  = (topVillage['village'] as String?) ?? 'Unknown';
      final count = (topVillage['total']   as int?)    ?? 0;
      insights.add((
        text: '$name leads with $count patients screened — replicate this campaign model in lower-coverage locations.',
        accent: const Color(0xFF8B5CF6),
        icon: Icons.location_on_rounded,
        priority: 'Insight',
        gradients: [const Color(0xFF1A0533), const Color(0xFF240A45)],
      ));
    }

    // 7. Dominant eye condition
    if (_conditionCounts.isNotEmpty) {
      final top = _conditionCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add((
        text: '${top.key} is the most reported condition with ${top.value} cases — ensure CHWs are trained to identify and document it.',
        accent: const Color(0xFF3B82F6),
        icon: Icons.health_and_safety_rounded,
        priority: 'Info',
        gradients: [const Color(0xFF0C1A2E), const Color(0xFF0F2744)],
      ));
    }

    // Fallback when no data at all
    if (insights.isEmpty) {
      insights.add((
        text: 'No screening data available for this period. Start a new screening session to generate insights.',
        accent: const Color(0xFF8FA0B4),
        icon: Icons.info_outline_rounded,
        priority: 'Info',
        gradients: [const Color(0xFF0C1A2E), const Color(0xFF0F2744)],
      ));
    }

    return insights;
  }

  Widget _buildInsightsSection() {
    final insights = _computedInsights;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF04091A), Color(0xFF0B1530)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.15),
            blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.4)),
              ),
              child: const Icon(Icons.lightbulb_rounded,
                  color: Color(0xFF5EEAD4), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Key Insights',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text('Auto-generated from current data',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: Colors.white.withOpacity(0.4))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Text('${insights.length} insights',
                  style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.6))),
            ),
          ]),
          const SizedBox(height: 16),
          ...List.generate(insights.length, (i) {
            final e        = insights[i];
            final num      = (i + 1).toString().padLeft(2, '0');
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: e.gradients,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: e.accent.withOpacity(0.3), width: 1.2),
                boxShadow: [BoxShadow(
                    color: e.accent.withOpacity(0.12),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: e.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: e.accent.withOpacity(0.45), width: 1.2),
                        ),
                        child: Center(
                          child: Text(num,
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11, fontWeight: FontWeight.w900,
                                  color: e.accent)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: e.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(e.icon, color: e.accent, size: 15),
                      ),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: e.accent.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: e.accent.withOpacity(0.4)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 5, height: 5,
                                decoration: BoxDecoration(
                                  color: e.accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(
                                      color: e.accent.withOpacity(0.7),
                                      blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(e.priority,
                                  style: GoogleFonts.inter(
                                      fontSize: 9, fontWeight: FontWeight.w800,
                                      color: e.accent)),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          Text(e.text,
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
