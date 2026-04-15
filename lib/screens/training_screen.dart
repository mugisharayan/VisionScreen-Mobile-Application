import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      'desc': 'Learn how to register patients correctly with all required demographics.',
      'duration': '3 min',
      'color': Color(0xFF0D9488),
      'image': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=400&q=80',
      'done': true,
    },
    {
      'icon': Icons.straighten_rounded,
      'title': 'Distance Calibration',
      'desc': 'Set up the correct 3-metre testing distance for accurate results.',
      'duration': '2 min',
      'color': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/photo-1581595220892-b0739db3ba8c?w=400&q=80',
      'done': true,
    },
    {
      'icon': Icons.remove_red_eye_rounded,
      'title': 'Vision Testing',
      'desc': 'Conduct the Tumbling E test correctly for each eye.',
      'duration': '5 min',
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=400&q=80',
      'done': false,
    },
    {
      'icon': Icons.assignment_rounded,
      'title': 'Referral Generation',
      'desc': 'Create and manage structured referral documents for patients.',
      'duration': '4 min',
      'color': Color(0xFFF59E0B),
      'image': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400&q=80',
      'done': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final completed = _modules.where((m) => m['done'] == true).length;
    final progress = completed / _modules.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
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
                  Text('TRAINING MODULES',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A2A3D),
                          letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  ...List.generate(
                    _modules.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildModuleCard(i),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildPracticeMode(),
                  const SizedBox(height: 20),
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
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF10B981)],
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Training',
                      style: GoogleFonts.barlow(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  Text('Learn VisionScreen step-by-step',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.65),
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Text('$completed/${_modules.length} done',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) => LinearProgressIndicator(
                      value: val,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${(progress * 100).toInt()}%',
                  style: GoogleFonts.barlow(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=600&q=80',
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                height: 140,
                color: const Color(0xFF064E3B),
              ),
            ),
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    const Color(0xFF064E3B).withOpacity(0.7),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.5)),
                    ),
                    child: Text('WELCOME TO TRAINING',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.3)),
                  ),
                  const SizedBox(height: 8),
                  Text('Welcome to\nVisionScreen Training',
                      style: GoogleFonts.barlow(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2)),
                  const SizedBox(height: 6),
                  Text('Complete all modules to become a certified screener',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
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
            border: Border.all(
              color: isDone ? color.withOpacity(0.3) : const Color(0xFFEEF2F6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              // Photo
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      m['image'] as String,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 90,
                        height: 90,
                        color: color.withOpacity(0.15),
                        child: Icon(m['icon'] as IconData,
                            color: color, size: 32),
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.4),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    // Module number
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${index + 1}',
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                    if (isDone)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_rounded,
                                  size: 9, color: Colors.white),
                              const SizedBox(width: 2),
                              Text('Done',
                                  style: GoogleFonts.ibmPlexSans(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(m['title'] as String,
                                style: GoogleFonts.barlow(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A2A3D))),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_rounded,
                                    size: 9, color: color),
                                const SizedBox(width: 3),
                                Text(m['duration'] as String,
                                    style: GoogleFonts.ibmPlexSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: color)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(m['desc'] as String,
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF8FA0B4),
                              height: 1.5)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFFDCFCE7)
                                  : color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              isDone ? '✓ Completed' : 'Start Module →',
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isDone
                                      ? const Color(0xFF15803D)
                                      : color),
                            ),
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
      ),
    );
  }

  Widget _buildPracticeMode() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showSnack('Practice mode starting...'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF04091A), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25), width: 1.5),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Practice Mode',
                        style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text('Test with dummy patients · Unlimited tries',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.65),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onModuleTap(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Module1Screen(
            onCompleted: () => setState(() => _modules[0]['done'] = true),
          ),
        ),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Module2Screen(
            onCompleted: () => setState(() => _modules[1]['done'] = true),
          ),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Module3Screen(
            onCompleted: () => setState(() => _modules[2]['done'] = true),
          ),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Module4Screen(
            onCompleted: () => setState(() => _modules[3]['done'] = true),
          ),
        ),
      );
    } else {
      _showSnack('Module ${index + 1} coming soon...');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.ibmPlexSans(fontSize: 12)),
      backgroundColor: const Color(0xFF0D9488),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }
}
