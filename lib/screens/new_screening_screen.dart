import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

const _ink = Color(0xFF04091A);
const _ink2 = Color(0xFF0B1530);
const _teal = Color(0xFF0D9488);
const _teal3 = Color(0xFF5EEAD4);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _green = Color(0xFF22C55E);
const double _kMinLux = 80.0;

class NewScreeningScreen extends StatefulWidget {
  const NewScreeningScreen({super.key});
  @override
  State<NewScreeningScreen> createState() => _NewScreeningScreenState();
}

class _NewScreeningScreenState extends State<NewScreeningScreen>
    with TickerProviderStateMixin {

  int _step = 0;

  // Feature 1
  double _currentLux = 0.0;
  bool _luxChecked = false;
  bool _luxSufficient = false;

  // Feature 2
  int? _selectedDistance;

  // Feature 3
  CameraController? _cameraCtrl;
  bool _cameraPermissionGranted = false;
  bool _cameraInitialized = false;
  bool _faceDetected = false;
  bool _faceAtCorrectDistance = false;
  Timer? _faceSimTimer;

  // Feature 4
  String? _selectedPatientId;
  final _patientSearchCtrl = TextEditingController();
  String _patientQuery = '';

  static const _patients = [
    {'id': 'PAT-00312', 'name': 'Akello Mercy',    'age': '34', 'gender': 'F', 'village': 'Nakawa, Kampala'},
    {'id': 'PAT-00298', 'name': 'Okello James',    'age': '58', 'gender': 'M', 'village': 'Bwaise, Kampala'},
    {'id': 'PAT-00301', 'name': 'Nakato Aisha',    'age': '27', 'gender': 'F', 'village': 'Ntinda, Kampala'},
    {'id': 'PAT-00315', 'name': 'Mugisha Wilson',  'age': '45', 'gender': 'M', 'village': 'Kireka, Wakiso'},
    {'id': 'PAT-00289', 'name': 'Kyomuhendo Rose', 'age': '19', 'gender': 'F', 'village': 'Rubaga, Kampala'},
    {'id': 'PAT-00276', 'name': 'Byaruhanga Sam',  'age': '62', 'gender': 'M', 'village': 'Kawempe, Kampala'},
    {'id': 'PAT-00261', 'name': 'Tendo Kevin',     'age': '9',  'gender': 'M', 'village': 'Nansana, Wakiso'},
    {'id': 'PAT-00254', 'name': 'Apio Norah',      'age': '8',  'gender': 'F', 'village': 'Kira, Wakiso'},
  ];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _checkBrightness();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _cameraCtrl?.dispose();
    _faceSimTimer?.cancel();
    _patientSearchCtrl.dispose();
    super.dispose();
  }

  void _checkBrightness() {
    setState(() => _luxChecked = false);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      const simLux = 120.0;
      setState(() {
        _currentLux = simLux;
        _luxChecked = true;
        _luxSufficient = simLux >= _kMinLux;
      });
    });
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _cameraPermissionGranted = false);
      return;
    }
    setState(() => _cameraPermissionGranted = true);
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraCtrl = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _cameraCtrl!.initialize();
    if (!mounted) return;
    setState(() => _cameraInitialized = true);
    _startFaceDetection();
  }

  void _startFaceDetection() {
    int tick = 0;
    _faceSimTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      tick++;
      setState(() {
        if (tick >= 2) _faceDetected = true;
        if (tick >= 4) _faceAtCorrectDistance = true;
      });
      if (_faceAtCorrectDistance) _faceSimTimer?.cancel();
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
            child: _step == 0
                ? _buildBrightnessStep()
                : _step == 1
                    ? _buildDistanceSelector()
                    : _step == 2
                        ? _buildFaceDetection()
                        : _buildPatientSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Screening',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Tumbling E · LogMAR Scale',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _teal3.withValues(alpha: 0.6))),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _teal3.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye_rounded, size: 12, color: _teal3),
                    const SizedBox(width: 5),
                    Text('WHO Standard',
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700, color: _teal3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrightnessStep() {
    if (!_luxChecked) return _buildCheckingLight();
    if (!_luxSufficient) return _buildLowLightWarning();
    return _buildLightOk();
  }

  Widget _buildCheckingLight() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _amber.withValues(alpha: 0.1),
                  border: Border.all(color: _amber.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.wb_sunny_rounded, size: 48, color: _amber),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Checking Room Lighting...',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 8),
          Text('Please wait while we measure ambient light',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4))),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: _teal, strokeWidth: 2),
        ],
      ),
    );
  }

  Widget _buildLowLightWarning() {
    final luxDisplay = _currentLux > 0 ? '${_currentLux.toStringAsFixed(0)} lux' : '-';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _red.withValues(alpha: 0.08),
              border: Border.all(color: _red.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.wb_sunny_outlined, size: 52, color: _red),
          ),
          const SizedBox(height: 24),
          Text('Insufficient Lighting',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 10),
          Text(
            'The room lighting is too low for a clinically accurate vision screening.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5E7291), height: 1.6),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _red.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Level',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF8FA0B4),
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(luxDisplay,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 28, fontWeight: FontWeight.w800, color: _red)),
                    ],
                  ),
                ),
                Container(width: 1, height: 50, color: _red.withValues(alpha: 0.15)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Required Minimum',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: const Color(0xFF8FA0B4),
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('${_kMinLux.toInt()} lux',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 28, fontWeight: FontWeight.w800, color: _green)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _amber.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.tips_and_updates_rounded, size: 16, color: _amber),
                  const SizedBox(width: 8),
                  Text('How to improve lighting',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2A3D))),
                ]),
                const SizedBox(height: 12),
                ...[
                  'Move to a room with natural daylight or bright overhead lighting',
                  'Turn on all available lights in the room',
                  'Avoid conducting the test in shadows or dim corridors',
                  'Ensure the patient faces the light source',
                ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 5, height: 5,
                        decoration: const BoxDecoration(color: _amber, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(tip,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF5E7291), height: 1.5))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checkBrightness,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: Text('Re-check Lighting',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Screening cannot proceed until lighting meets the clinical threshold.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLightOk() {
    final luxDisplay = _currentLux > 0
        ? '${_currentLux.toStringAsFixed(0)} lux'
        : 'Sensor unavailable';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _green.withValues(alpha: 0.1),
                border: Border.all(color: _green.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.wb_sunny_rounded, size: 48, color: _green),
            ),
            const SizedBox(height: 20),
            Text('Lighting is Good',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2A3D))),
            const SizedBox(height: 8),
            Text(luxDisplay,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _green)),
            const SizedBox(height: 8),
            Text(
              'Room lighting meets the clinical threshold for accurate screening.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF8FA0B4), height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _step = 1),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                label: Text('Continue to Setup',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator({required int current, required int total}) {
    return Row(
      children: List.generate(total, (i) {
        final active = i + 1 <= current;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? _teal : const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDistanceSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildStepIndicator(current: 2, total: 4),
          const SizedBox(height: 28),
          Text('Testing Distance',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 8),
          Text(
            'Select the distance between the patient and the screen. '
            'Ensure the patient is seated at exactly this distance.',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF5E7291), height: 1.6),
          ),
          const SizedBox(height: 28),
          _distanceCard(
            metres: 3,
            label: '3 Metres',
            description: 'Standard CHW field screening distance',
            recommended: true,
            icon: Icons.social_distance_rounded,
          ),
          const SizedBox(height: 14),
          _distanceCard(
            metres: 6,
            label: '6 Metres',
            description: 'Clinical facility standard distance',
            recommended: false,
            icon: Icons.straighten_rounded,
          ),
          if (_selectedDistance != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _teal.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: _teal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Mark the floor at exactly $_selectedDistance metres from the screen before starting.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF5E7291), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedDistance == null
                  ? null
                  : () {
                      setState(() => _step = 2);
                      _initCamera();
                    },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              label: Text('Continue',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedDistance == null
                    ? const Color(0xFF8FA0B4) : _teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          if (_selectedDistance == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text('Select a testing distance to continue',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF8FA0B4))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _distanceCard({
    required int metres,
    required String label,
    required String description,
    required bool recommended,
    required IconData icon,
  }) {
    final selected = _selectedDistance == metres;
    return GestureDetector(
      onTap: () => setState(() => _selectedDistance = metres),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? _teal.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _teal : const Color(0xFFEEF2F6),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? _teal.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? _teal.withValues(alpha: 0.12)
                    : const Color(0xFFF0F4F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 26,
                  color: selected ? _teal : const Color(0xFF8FA0B4)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: selected ? _teal : const Color(0xFF1A2A3D))),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: _green.withValues(alpha: 0.3)),
                          ),
                          child: Text('Recommended',
                              style: GoogleFonts.inter(
                                  fontSize: 9, fontWeight: FontWeight.w700, color: _green)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF8FA0B4))),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _teal : Colors.transparent,
                border: Border.all(
                  color: selected ? _teal : const Color(0xFFDDE4EC),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceDetection() {
    if (!_cameraPermissionGranted && !_cameraInitialized) {
      return _buildCameraPermissionDenied();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildStepIndicator(current: 3, total: 4),
          const SizedBox(height: 28),
          Text('Distance Calibration',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 8),
          Text(
            'Position the patient\'s face in the camera frame. '
            'The system will verify they are at the correct '
            '$_selectedDistance metre distance.',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF5E7291), height: 1.6),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 300, width: double.infinity,
              color: const Color(0xFF1A2A3D),
              child: _cameraInitialized && _cameraCtrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraCtrl!),
                        CustomPaint(
                          painter: _FaceOverlayPainter(
                            faceDetected: _faceDetected,
                            correctDistance: _faceAtCorrectDistance,
                          ),
                        ),
                        Positioned(
                          bottom: 16, left: 16, right: 16,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _faceAtCorrectDistance
                                  ? _green.withValues(alpha: 0.85)
                                  : _faceDetected
                                      ? _amber.withValues(alpha: 0.85)
                                      : Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _faceAtCorrectDistance
                                      ? Icons.check_circle_rounded
                                      : _faceDetected
                                          ? Icons.warning_rounded
                                          : Icons.face_rounded,
                                  color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _faceAtCorrectDistance
                                      ? 'Face detected - distance confirmed'
                                      : _faceDetected
                                          ? 'Adjusting distance...'
                                          : 'Looking for face...',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, __) => Transform.scale(
                              scale: _pulseAnim.value,
                              child: const Icon(Icons.camera_front_rounded,
                                  size: 56, color: _teal3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Initialising camera...',
                              style: GoogleFonts.inter(fontSize: 13, color: _teal3)),
                          const SizedBox(height: 12),
                          const CircularProgressIndicator(color: _teal, strokeWidth: 2),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _teal.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.tips_and_updates_rounded, size: 15, color: _teal),
                  const SizedBox(width: 8),
                  Text('Positioning guide',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2A3D))),
                ]),
                const SizedBox(height: 10),
                ...[
                  'Ask the patient to sit or stand facing the device',
                  'Ensure their full face is visible in the frame',
                  'Confirm they are exactly $_selectedDistance metres away',
                  'Good lighting helps the camera detect the face',
                ].map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 5, height: 5,
                        decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF5E7291), height: 1.5))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _faceAtCorrectDistance
                  ? () {
                      _cameraCtrl?.dispose();
                      _cameraCtrl = null;
                      setState(() => _step = 3);
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              label: Text('Begin Screening',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _faceAtCorrectDistance ? _teal : const Color(0xFF8FA0B4),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          if (!_faceAtCorrectDistance)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  'Face must be detected at the correct distance to proceed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _red.withValues(alpha: 0.08),
                border: Border.all(color: _red.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.no_photography_rounded, size: 44, color: _red),
            ),
            const SizedBox(height: 20),
            Text('Camera Permission Required',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2A3D))),
            const SizedBox(height: 10),
            Text(
              'Camera access is required to verify the patient is at the correct testing distance.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF5E7291), height: 1.6),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _initCamera,
                icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                label: Text('Grant Camera Access',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelector() {
    final filtered = _patients.where((p) {
      if (_patientQuery.isEmpty) return true;
      final q = _patientQuery.toLowerCase();
      return p['name']!.toLowerCase().contains(q) ||
          p['id']!.toLowerCase().contains(q) ||
          p['village']!.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(current: 4, total: 4),
              const SizedBox(height: 20),
              Text('Select Patient',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A2A3D))),
              const SizedBox(height: 6),
              Text('Search and select the patient to be screened.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF5E7291))),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
                ),
                child: TextField(
                  controller: _patientSearchCtrl,
                  onChanged: (v) => setState(() => _patientQuery = v),
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A2A3D)),
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID or village...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFF8FA0B4)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: Color(0xFF8FA0B4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No patients found',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: const Color(0xFF8FA0B4))))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    final isSelected = _selectedPatientId == p['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPatientId = p['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _teal.withValues(alpha: 0.06)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? _teal : const Color(0xFFEEF2F6),
                            width: isSelected ? 2 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _teal.withValues(alpha: 0.12)
                                    : const Color(0xFFF0F4F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  p['name']!.split(' ').map((w) => w[0]).take(2).join(),
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14, fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? _teal : const Color(0xFF8FA0B4)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['name']!,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13, fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? _teal : const Color(0xFF1A2A3D))),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${p['gender']} · ${p['age']} yrs · ${p['village']}',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF8FA0B4)),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: _teal, size: 20)
                            else
                              Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFDDE4EC), width: 2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_selectedPatientId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: proceed to eye test
                },
                icon: const Icon(Icons.visibility_rounded,
                    size: 18, color: Colors.white),
                label: Text('Start Eye Test',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  final bool faceDetected;
  final bool correctDistance;
  const _FaceOverlayPainter({required this.faceDetected, required this.correctDistance});

  @override
  void paint(Canvas canvas, Size size) {
    final color = correctDistance ? _green : faceDetected ? _amber : _teal3;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.55;
    final h = size.height * 0.65;
    const len = 28.0;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    // corners
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + len, rect.top), paint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left, rect.top + len), paint);
    canvas.drawLine(Offset(rect.right - len, rect.top), Offset(rect.right, rect.top), paint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + len), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom - len), Offset(rect.left, rect.bottom), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + len, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right - len, rect.bottom), Offset(rect.right, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right, rect.bottom - len), Offset(rect.right, rect.bottom), paint);
  }

  @override
  bool shouldRepaint(_FaceOverlayPainter old) =>
      old.faceDetected != faceDetected || old.correctDistance != correctDistance;
}
