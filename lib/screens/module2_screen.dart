import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Module2Screen extends StatefulWidget {
  final VoidCallback? onCompleted;
  const Module2Screen({super.key, this.onCompleted});

  @override
  State<Module2Screen> createState() => _Module2ScreenState();
}

class _Module2ScreenState extends State<Module2Screen> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Why Distance Matters',
      'icon': Icons.straighten_rounded,
      'color': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/photo-1581595220892-b0739db3ba8c?w=600&q=80',
      'body':
          'The testing distance is one of the most critical factors in a vision screening. The Tumbling E chart is designed to be read at exactly 3 metres (approximately 10 feet).\n\nIf the patient stands too close, they will read smaller letters more easily — giving a falsely good result. If they stand too far, they may fail even with normal vision.\n\nAlways measure the distance before every test.',
      'tip': 'Use a measuring tape or mark a fixed spot on the floor at 3 metres from the screen.',
    },
    {
      'title': 'Screen Calibration',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=600&q=80',
      'body':
          'VisionScreen automatically detects your device\'s screen size and pixel density (PPI) to render the Tumbling E optotypes at clinically correct physical sizes.\n\nCalibration steps:\n1. Open the app and tap "New Screening"\n2. Complete patient registration\n3. The app will auto-detect screen PPI\n4. Wait for "Calibration Complete ✓"\n5. Do NOT skip calibration\n\nIf calibration fails, restart the app and try again.',
      'tip': 'Never cover the screen with a screen protector that distorts colours — it can affect optotype clarity.',
    },
    {
      'title': 'Positioning the Patient',
      'icon': Icons.accessibility_new_rounded,
      'color': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=600&q=80',
      'body':
          'Correct patient positioning:\n\n📏 Stand exactly 3 metres from the screen\n👁️ Eyes level with the middle of the chart\n🚫 No glasses or contact lenses (unaided test)\n💡 Room must be well lit — no glare on screen\n🙈 Cover one eye completely with a card\n\nFor children, have them stand next to a parent. For elderly patients, ensure they are comfortable and not straining their neck.',
      'tip': 'Ask the patient to remove glasses BEFORE positioning — not after. This avoids confusion.',
    },
    {
      'title': 'Distance Verification',
      'icon': Icons.gps_fixed_rounded,
      'color': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/photo-1504868584819-f8e8b4b6d7e3?w=600&q=80',
      'body':
          'VisionScreen uses the device camera and proximity sensor to estimate the patient\'s distance in real time.\n\nThe distance meter shows:\n🔴 Red — Too close (move patient back)\n🟡 Amber — Getting close (fine-tune position)\n🟢 Green — Correct distance (3 metres)\n\nOnly proceed to the test when the meter shows GREEN. Tap "Distance OK" to confirm and begin the Tumbling E test.\n\nIf the sensor is unavailable, use a physical measuring tape.',
      'tip': 'On bright outdoor days, the camera may struggle. Move to a shaded area for best sensor accuracy.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final color = step['color'] as Color;
    final isLast = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(context, color),
          _buildProgressBar(color),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _buildStepContent(step, color,
                    key: ValueKey(_currentStep)),
              ),
            ),
          ),
          _buildFooter(context, color, isLast),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF04091A), color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Module 2',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1.2)),
                Text('Distance Calibration',
                    style: GoogleFonts.barlow(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Text(
              '${_currentStep + 1} / ${_steps.length}',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Color color) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            children: List.generate(_steps.length, (i) {
              final isDone = i < _currentStep;
              final isCurrent = i == _currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDone
                        ? color
                        : isCurrent
                            ? color.withOpacity(0.5)
                            : const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_steps[_currentStep]['title'] as String,
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color)),
              Text(
                  '${((_currentStep + 1) / _steps.length * 100).toInt()}% complete',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8FA0B4))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(Map step, Color color, {required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero image
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                step['image'] as String,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 180,
                  color: color.withOpacity(0.15),
                  child:
                      Icon(step['icon'] as IconData, size: 60, color: color),
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.1),
                      color.withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 14, left: 14,
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4)),
                      ),
                      child: Icon(step['icon'] as IconData,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(step['title'] as String,
                        style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Body content card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Text(
            step['body'] as String,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF3D5470),
                height: 1.75),
          ),
        ),
        const SizedBox(height: 12),
        // Tip card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.lightbulb_rounded, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PRO TIP',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(step['tip'] as String,
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF3D5470),
                            height: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, Color color, bool isLast) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEF2F6))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: () => setState(() => _currentStep--),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDDE4EC)),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF5E7291), size: 20),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isLast) {
                  widget.onCompleted?.call();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Module 2 completed! 🎉',
                        style: GoogleFonts.ibmPlexSans(fontSize: 12)),
                    backgroundColor: const Color(0xFF3B82F6),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ));
                  Navigator.pop(context);
                } else {
                  setState(() => _currentStep++);
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    isLast ? 'Complete Module ✓' : 'Next Step →',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
