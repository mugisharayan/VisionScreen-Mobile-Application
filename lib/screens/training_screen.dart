import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'module1_screen.dart';
import 'module2_screen.dart';
import 'module3_screen.dart';
import 'module4_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final List<Map<String, dynamic>> _modules = [
    {
      'icon': Icons.person_add_rounded,
      'title': 'Patient Registration',
      'desc': 'Register patients individually or in bulk campaigns. Learn all required fields including eye conditions.',
      'duration': '4 min',
      'color': Color(0xFF0D9488),
      'image': 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&q=80',
      'done': false,
      'prefKey': 'module1_done',
    },
    {
      'icon': Icons.remove_red_eye_rounded,
      'title': 'Vision Testing',
      'desc': 'Conduct the Tumbling E staircase test for distance and near vision. Understand LogMAR and Snellen results.',
      'duration': '5 min',
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1574258495973-f010dfbb5371?w=400&q=80',
      'done': false,
      'prefKey': 'module2_done',
    },
    {
      'icon': Icons.groups_rounded,
      'title': 'Bulk Mode & Campaigns',
      'desc': 'Run campaign screenings for schools and communities. Manage patients grouped under campaign cards.',
      'duration': '4 min',
      'color': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/1529156069898-49953e39b3ac?w=400&q=80',
      'done': false,
      'prefKey': 'module3_done',
    },
    {
      'icon': Icons.assignment_rounded,
      'title': 'Referrals & Follow-Up',
      'desc': 'Generate referral letters, set appointments, track referral status and manage patient follow-ups.',
      'duration': '4 min',
      'color': Color(0xFFF59E0B),
      'image': 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=400&q=80',
      'done': false,
      'prefKey': 'module4_done',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final m in _modules) {
        m['done'] = prefs.getBool(m['prefKey'] as String) ?? false;
      }
    });
  }

  Future<void> _markDone(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_modules[index]['prefKey'] as String, true);
    setState(() => _modules[index]['done'] = true);
  }

  @override
  Widget build(BuildContext context) {
    final completed = _modules.where((m) => m['done'] == true).length;
    final progress = completed / _modules.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context, completed, progress),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeBanner(),
                  const SizedBox(height: 20),
                  Row(children: [
                    Container(width: 3, height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(99))),
                    const SizedBox(width: 8),
                    Text('TRAINING MODULES',
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569), letterSpacing: 1.4)),
                  ]),
                  const SizedBox(height: 10),
                  ...List.generate(
                    _modules.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildModuleCard(i),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int completed, double progress) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF134E4A), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Dot pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: CustomPaint(painter: _TrainingDotPainter()),
            ),
          ),
          Positioned(top: -50, right: -50,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1)))),
          Positioned(top: -10, right: -10,
            child: Container(width: 100, height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1)))),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TRAINING CENTRE',
                              style: GoogleFonts.inter(
                                  fontSize: 9, fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  letterSpacing: 1.8)),
                          const SizedBox(height: 2),
                          Text('Training',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22, fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    // Progress badge
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (_, t, child) =>
                          Transform.scale(scale: t, child: child),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            completed == _modules.length
                                ? Icons.check_circle_rounded
                                : Icons.school_rounded,
                            size: 13,
                            color: completed == _modules.length
                                ? const Color(0xFF34D399)
                                : Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text('$completed/${_modules.length} done',
                              style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  // Progress bar
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, val, __) => LinearProgressIndicator(
                            value: val,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF34D399)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${(progress * 100).toInt()}%',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF134E4A), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.3),
            blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _TrainingDotPainter())),
          Positioned(top: -30, right: -30,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1)))),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Text('WELCOME TO TRAINING',
                        style: GoogleFonts.inter(
                            fontSize: 8, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: 1.3)),
                  ),
                  const SizedBox(height: 10),
                  Text('Master VisionScreen\nin 4 Modules',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: Colors.white, height: 1.2)),
                  const SizedBox(height: 6),
                  Text('Registration · Testing · Bulk Mode · Referrals',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400)),
                ]),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildModuleCard(int index) {
    final m = _modules[index];
    final isDone = m['done'] as bool;
    final color = m['color'] as Color;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _onModuleTap(index),
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDone ? color.withOpacity(0.3) : const Color(0xFFEEF2F6), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
                child: Stack(
                  children: [
                    Image.network(m['image'] as String, width: 90, height: 90, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: color.withOpacity(0.15),
                            child: Icon(m['icon'] as IconData, color: color, size: 32))),
                    Container(width: 90, height: 90,
                        decoration: BoxDecoration(gradient: LinearGradient(
                            colors: [color.withOpacity(0.4), Colors.transparent],
                            begin: Alignment.bottomCenter, end: Alignment.topCenter))),
                    Positioned(top: 8, left: 8,
                        child: Container(width: 22, height: 22,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            child: Center(child: Text('${index + 1}',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))))),
                    if (isDone)
                      Positioned(bottom: 8, left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(99)),
                            child: Row(children: [
                              const Icon(Icons.check_rounded, size: 9, color: Colors.white),
                              const SizedBox(width: 2),
                              Text('Done', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                            ]),
                          )),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(m['title'] as String,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1A2A3D)))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
                          child: Row(children: [
                            Icon(Icons.timer_rounded, size: 9, color: color),
                            const SizedBox(width: 3),
                            Text(m['duration'] as String,
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Text(m['desc'] as String,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400,
                              color: const Color(0xFF8FA0B4), height: 1.5)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFFDCFCE7) : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(isDone ? '✓ Completed' : 'Start Module →',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800,
                                color: isDone ? const Color(0xFF15803D) : color)),
                      ),
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

  void _onModuleTap(int index) {
    final routes = [
      () => Module1Screen(onCompleted: () => _markDone(0)),
      () => Module2Screen(onCompleted: () => _markDone(1)),
      () => Module3Screen(onCompleted: () => _markDone(2)),
      () => Module4Screen(onCompleted: () => _markDone(3)),
    ];
    if (index < routes.length) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => routes[index]()));
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 12)),
      backgroundColor: const Color(0xFF0D9488),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }
}


class _TrainingDotPainter extends CustomPainter {
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
  bool shouldRepaint(_TrainingDotPainter old) => false;
}

