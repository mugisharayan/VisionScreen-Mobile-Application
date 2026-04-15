import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'patients_screen.dart';
import 'referrals_screen.dart';
import 'settings_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Today';
  final List<String> _periods = ['Today', 'Week', 'Month', 'Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 20),
                  _buildPassRateChart(),
                  const SizedBox(height: 20),
                  _buildDemographicsSection(),
                  const SizedBox(height: 20),
                  _buildReferralAnalytics(),
                  const SizedBox(height: 20),
                  _buildInsightsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 50, 22, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF04091A), Color(0xFF0B1530)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text('Analytics',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const Spacer(),
              _buildPeriodSelector(),
              const SizedBox(width: 12),
              _buildExportButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(period,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(isSelected ? 1.0 : 0.7))),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExportButton() {
    return GestureDetector(
      onTap: _showExportOptions,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.share_rounded,
            color: Colors.white, size: 20),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportOptionsSheet(),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        _buildStatCard('47', 'Screened', '↑ 8', const Color(0xFF0D9488)),
        const SizedBox(width: 12),
        _buildStatCard('35', 'Passed', '74%', const Color(0xFF22C55E)),
        const SizedBox(width: 12),
        _buildStatCard('12', 'Referred', '26%', const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildStatCard(String number, String label, String change, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEF2F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(number,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A2A3D))),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8FA0B4),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(change,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPassRateChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pass Rate Trend',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _PassRateChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsSection() {
    return Row(
      children: [
        Expanded(child: _buildAgeGroupChart()),
        const SizedBox(width: 16),
        Expanded(child: _buildGenderChart()),
      ],
    );
  }

  Widget _buildAgeGroupChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Age Groups',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 12),
          _buildAgeBar('0-17', 12, const Color(0xFF3B82F6)),
          _buildAgeBar('18-40', 18, const Color(0xFF0D9488)),
          _buildAgeBar('41-60', 14, const Color(0xFFF59E0B)),
          _buildAgeBar('60+', 8, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildAgeBar(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8FA0B4))),
          ),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: count / 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2A3D))),
        ],
      ),
    );
  }

  Widget _buildGenderChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gender Split',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.male_rounded,
                          color: Color(0xFF3B82F6), size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text('28',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A2A3D))),
                    Text('Male',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF8FA0B4))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.female_rounded,
                          color: Color(0xFFEC4899), size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text('24',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A2A3D))),
                    Text('Female',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF8FA0B4))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferralAnalytics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Referral Status',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildReferralStatusCard('Pending', '8', const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              _buildReferralStatusCard('Attended', '4', const Color(0xFF22C55E)),
              const SizedBox(width: 12),
              _buildReferralStatusCard('Overdue', '2', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferralStatusCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(count,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Key Insights',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            '74% pass rate is above target',
            'Continue current screening protocols',
            Icons.trending_up_rounded,
          ),
          _buildInsightItem(
            '2 overdue referrals need follow-up',
            'Contact patients for appointment status',
            Icons.warning_rounded,
          ),
          _buildInsightItem(
            'Peak screening age: 18-40 years',
            'Focus outreach on older demographics',
            Icons.people_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.people_alt_rounded, 'label': 'Patients'},
      {'icon': Icons.assignment_rounded, 'label': 'Referrals'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Analytics'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
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
          final isActive = e.key == 3;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                switch (e.key) {
                  case 0:
                    Navigator.push(
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
                    );
                    break;
                  case 1:
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const PatientsScreen(),
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
                    );
                    break;
                  case 2:
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const ReferralsScreen(),
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
                    );
                    break;
                  case 3:
                    // Already on analytics screen
                    break;
                  case 4:
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
                    break;
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
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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

class _PassRateChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0D9488).withOpacity(0.3),
          const Color(0xFF0D9488).withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final data = [65, 72, 68, 74, 78, 74, 76];
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final y = size.height - (data[i] / 100 * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ExportOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE4EC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Export Analytics',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2A3D))),
                const SizedBox(height: 16),
                _buildExportOption(
                  Icons.picture_as_pdf_rounded,
                  'Export as PDF',
                  'Generate detailed report',
                  const Color(0xFFEF4444),
                  () => Navigator.pop(context),
                ),
                _buildExportOption(
                  Icons.table_chart_rounded,
                  'Export as CSV',
                  'Raw data for analysis',
                  const Color(0xFF22C55E),
                  () => Navigator.pop(context),
                ),
                _buildExportOption(
                  Icons.share_rounded,
                  'Share Summary',
                  'Quick overview via WhatsApp',
                  const Color(0xFF0D9488),
                  () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2A3D))),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8FA0B4))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: color),
          ],
        ),
      ),
    );
  }
}