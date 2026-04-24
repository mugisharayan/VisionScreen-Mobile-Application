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
      'icon': Icons.remove_red_eye_rounded,
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1574258495973-f010dfbb5371?w=400&q=80',
      'title': 'The Tumbling E Test',
      'body': 'VisionScreen uses the ETDRS Tumbling E optotype — a letter "E" that rotates in 4 directions (right, left, up, down).\n\n'
          'The patient points or gestures which way the E is facing. This works for:\n'
          '• Patients who cannot read\n'
          '• Children\n'
          '• Elderly patients\n'
          '• Patients who speak different languages\n\n'
          'The E is drawn on a 5×5 grid with a bounding box — clinically validated for accurate visual acuity measurement.',
      'tip': 'Demonstrate the E direction yourself first — show the patient how to point left, right, up or down before starting.',
    },
    {
      'icon': Icons.straighten_rounded,
      'color': Color(0xFF0D9488),
      'image': 'https://images.unsplash.com/photo-1584515933487-779824d29309?w=400&q=80',
      'title': 'Testing Distance & Setup',
      'body': 'DISTANCE VISION TEST:\n'
          '• Patient sits exactly 2 metres from the screen\n'
          '• Mark the floor at 2m before starting\n'
          '• Screen brightness is automatically set to 100%\n'
          '• Ambient light is checked (minimum 80 lux)\n\n'
          'NEAR VISION TEST (individual screening only):\n'
          '• Patient holds the device at 40cm (arm\'s length)\n'
          '• Both eyes open — no covering needed\n'
          '• Patient wears reading glasses if they use them\n\n'
          'The app auto-calculates E size using your device\'s screen DPI.',
      'tip': 'If the light check fails, move to a brighter room or turn on all available lights before proceeding.',
    },
    {
      'icon': Icons.visibility_rounded,
      'color': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&q=80',
      'title': 'Testing Each Eye',
      'body': 'The test follows this order:\n\n'
          '1. OD (Right Eye) — ask patient to cover LEFT eye with palm\n'
          '2. OS (Left Eye) — ask patient to cover RIGHT eye with palm\n'
          '3. OU Near Vision — both eyes open at 40cm (individual only)\n\n'
          'Between each eye, a "Cover Eye Reminder" screen appears with a visual illustration showing which eye to cover.\n\n'
          'Tap the direction arrow buttons to record the patient\'s response. Tap "Can\'t Tell" if the patient cannot identify the direction.',
      'tip': 'Make sure the patient covers their eye completely with their palm — not just closing it. Peeking gives inaccurate results.',
    },
    {
      'icon': Icons.bar_chart_rounded,
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1494869042583-f6c911f04b4c?w=400&q=80',
      'title': 'The Staircase Algorithm',
      'body': 'VisionScreen uses an adaptive staircase algorithm:\n\n'
          '• Starts at LogMAR 1.0 (large E) and jumps to smaller sizes\n'
          '• Each row has 5 letters — patient must get 4/5 correct to pass\n'
          '• If patient passes → jumps to a harder (smaller) row\n'
          '• If patient fails → fine-searches around the threshold\n'
          '• Records the last row the patient passed correctly\n\n'
          'The 5-dot progress indicator at the top shows how many letters have been shown in the current row.',
      'tip': 'The algorithm is self-terminating — it stops automatically when the threshold is found. Do not rush the patient.',
    },
    {
      'icon': Icons.check_circle_rounded,
      'color': Color(0xFF22C55E),
      'image': 'https://images.unsplash.com/photo-1516307365426-bea591f05011?w=400&q=80',
      'title': 'Understanding Results',
      'body': 'Results are shown in both LogMAR and Snellen:\n\n'
          '• LogMAR 0.0 = Snellen 6/6 (Normal)\n'
          '• LogMAR 0.3 = Snellen 6/12 (Near Normal)\n'
          '• LogMAR 0.5 = Snellen 6/18 (Moderate VI) → REFER\n'
          '• LogMAR 1.0 = Snellen 6/60 (Severe VI) → REFER\n\n'
          'REFERRAL THRESHOLD: Any eye with LogMAR > 0.5 triggers a referral recommendation.\n\n'
          'A visual blur simulation shows the patient\'s approximate view at their measured acuity level.',
      'tip': 'Always explain the result to the patient in simple terms — "Your right eye sees well, but your left eye needs a check-up at the clinic."',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final color = step['color'] as Color;
    final isLast = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(children: [
        _buildHeader(color),
        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _buildStepContent(step, color, key: ValueKey(_currentStep)),
        )),
        _buildNavBar(color, isLast),
      ]),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF04091A), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(width: 38, height: 38,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white.withOpacity(0.2))),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Module 2', style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.6), letterSpacing: 1.0)),
            Text('Vision Testing', style: GoogleFonts.barlow(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
            child: Text('${_currentStep + 1} / ${_steps.length}',
                style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: List.generate(_steps.length, (i) => Expanded(child: Row(children: [
          Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 300), height: 4,
              decoration: BoxDecoration(color: i <= _currentStep ? Colors.white : Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(99)))),
          if (i < _steps.length - 1) const SizedBox(width: 4),
        ])))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_steps[_currentStep]['title'] as String,
              style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
          Text('${((_currentStep + 1) / _steps.length * 100).toInt()}% complete',
              style: GoogleFonts.ibmPlexSans(fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ]),
      ]),
    );
  }

  Widget _buildStepContent(Map step, Color color, {required Key key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            Image.network(step['image'] as String, height: 160, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 160, color: color.withOpacity(0.15),
                    child: Icon(step['icon'] as IconData, size: 60, color: color))),
            Container(height: 160, decoration: BoxDecoration(gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                begin: Alignment.bottomCenter, end: Alignment.topCenter))),
            Positioned(bottom: 14, left: 14, child: Container(width: 44, height: 44,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                child: Icon(step['icon'] as IconData, color: Colors.white, size: 22))),
          ]),
        ),
        const SizedBox(height: 20),
        Text(step['title'] as String, style: GoogleFonts.barlow(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1A2A3D))),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Text(step['body'] as String, style: GoogleFonts.ibmPlexSans(fontSize: 13, color: const Color(0xFF1A2A3D), height: 1.7)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lightbulb_rounded, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(step['tip'] as String, style: GoogleFonts.ibmPlexSans(fontSize: 12, color: const Color(0xFF1A2A3D), height: 1.5))),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildNavBar(Color color, bool isLast) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: () => setState(() => _currentStep--),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4F7), borderRadius: BorderRadius.circular(12)),
                  child: Text('← Back', style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF5E7291)))),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: GestureDetector(
            onTap: () {
              if (isLast) {
                widget.onCompleted?.call();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Module 2 completed! 🎉', style: GoogleFonts.ibmPlexSans(fontSize: 12, color: Colors.white)),
                  backgroundColor: color, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ));
                Navigator.pop(context);
              } else {
                setState(() => _currentStep++);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(child: Text(isLast ? 'Complete Module ✓' : 'Next Step →',
                  style: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
          )),
        ]),
      ),
    );
  }
}
