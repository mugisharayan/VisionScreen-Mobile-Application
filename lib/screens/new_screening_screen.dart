import 'dart:async';
import 'dart:io';
import 'dart:math' show sqrt;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'referral_letter_screen.dart';
import 'face_distance_screen.dart';
import '../features/screening/screening_constants.dart';
import '../features/screening/screening_flow_controller.dart';
import '../services/permission_coordinator.dart';
import '../utils/patient_validators.dart';
import '../utils/visual_acuity.dart';
import '../widgets/vs_ambient_light_check.dart';
import '../widgets/vs_environment_check.dart';
import '../widgets/vs_toast.dart';
import '../widgets/vs_ui.dart';

// ── Colours ──────────────────────────────────────────────────────────────────
const _ink = Color(0xFF04091A);
const _teal = Color(0xFF0D9488);
const _teal3 = Color(0xFF5EEAD4);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _green = Color(0xFF22C55E);

// ── Steps ─────────────────────────────────────────────────────────────────────
// 0=patient, 1=checklist, 2=coverEye, 3=chart, 4=eyeResult, 5=summary
// ── Eye order ─────────────────────────────────────────────────────────────────
const _eyeOrder = screeningEyeOrder;

// ── LogMAR rows (single E per row) ───────────────────────────────────────────
// LogMAR rows — sizes in mm at 2m (formula: 29.1 × 10^(logmar-1.0))
// Source: Visual Acuity app measurements at 2m testing distance
const _rows = screeningRows;

// Convert mm to logical pixels using device DPI
// Uses dart:ui window.physicalSize and devicePixelRatio to derive actual physical DPI.
// physicalDpi = sqrt(physicalW² + physicalH²) / diagonalInches
// Since Flutter doesn't expose diagonalInches, we use the validated approximation
// physicalDpi = 160 × devicePixelRatio, which matches most Android/iOS devices.
// For clinical accuracy, the CHW should verify on a known-DPI device.
double _mmToPx(double mm, BuildContext context) {
  final mq = MediaQuery.of(context);
  final physicalW = mq.size.width * mq.devicePixelRatio;
  final physicalH = mq.size.height * mq.devicePixelRatio;
  // Derive physical DPI from screen diagonal physical pixels.
  // We assume a standard 5-inch diagonal as a baseline fallback.
  // diagonal physical pixels / diagonal inches = physical DPI
  // Without the actual diagonal inches from the OS, we use:
  // physicalDpi ≈ sqrt(physicalW² + physicalH²) / 5.0  (5" baseline)
  // This is more accurate than 160×dpr on non-standard screens.
  final diagonalPx = sqrt(physicalW * physicalW + physicalH * physicalH);
  // Use 5.5" as a representative modern smartphone diagonal
  const assumedDiagonalInches = 5.5;
  final physicalDpi = diagonalPx / assumedDiagonalInches;
  return (mm / 25.4) * (physicalDpi / mq.devicePixelRatio);
}

class NewScreeningScreen extends StatefulWidget {
  final bool startWithNewPatient;
  final String? existingPatientId;
  const NewScreeningScreen({
    super.key,
    this.startWithNewPatient = false,
    this.existingPatientId,
  });
  @override
  State<NewScreeningScreen> createState() => _NewScreeningScreenState();
}

class _NewScreeningScreenState extends State<NewScreeningScreen>
    with TickerProviderStateMixin {
  late final ScreeningFlowController _controller;
  final _patientSearchCtrl = TextEditingController();
  final _newNameCtrl = TextEditingController();
  final _newVillageCtrl = TextEditingController();
  final _newPhoneCtrl = TextEditingController();
  CameraController? _photoCtrl;
  bool _showPhotoCamera = false;
  bool _newPatientSheetOpen = false;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _controller = ScreeningFlowController()
      ..addListener(_handleControllerChanged);
    unawaited(
      _controller.initialize(
        startWithNewPatient: widget.startWithNewPatient,
        existingPatientId: widget.existingPatientId,
      ),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..disposeResources()
      ..dispose();
    _pulseCtrl.dispose();
    _photoCtrl?.dispose();
    _patientSearchCtrl.dispose();
    _newNameCtrl.dispose();
    _newVillageCtrl.dispose();
    _newPhoneCtrl.dispose();
    super.dispose();
  }

  int get _step => _controller.step;
  String? get _selectedPatientId => _controller.selectedPatientId;
  String get _patientQuery => _controller.patientQuery;
  bool get _shouldOpenNewPatientSheet => _controller.shouldOpenNewPatientSheet;
  String get _newGender => _controller.newGender;
  DateTime? get _newDob => _controller.newDob;
  bool get _detectingLocation => _controller.detectingLocation;
  List<String> get _newConditions => _controller.newConditions;
  String? get _newPhotoPath => _controller.newPhotoPath;
  List<Map<String, String>> get _patientListRuntime =>
      _controller.patientListRuntime;
  int? get _savedScreeningId => _controller.savedScreeningId;
  int get _currentEyeIndex => _controller.currentEyeIndex;
  int get _currentRow => _controller.currentRow;
  int get _currentRotation => _controller.currentRotation;
  int get _letterIndex => _controller.letterIndex;
  List<Map<String, dynamic>> get _eyeResults => _controller.eyeResults;
  int get _nearRow => _controller.nearRow;
  int get _nearLetterIndex => _controller.nearLetterIndex;
  int get _nearRotation => _controller.nearRotation;
  Map<String, dynamic>? get _nearResult => _controller.nearResult;
  bool get _isOffline => _controller.isOffline;
  int get _countdown => _controller.countdown;
  int get _nearCountdown => _controller.nearCountdown;
  String get _testDuration => _controller.testDuration;
  bool get _needsReferral => _controller.needsReferral;

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (_step == 0 && _shouldOpenNewPatientSheet && !_newPatientSheetOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            _step != 0 ||
            !_shouldOpenNewPatientSheet ||
            _newPatientSheetOpen) {
          return;
        }
        unawaited(_showNewPatientSheet());
      });
    }
  }

  Future<void> _showNewPatientSheet() async {
    if (_newPatientSheetOpen) {
      return;
    }
    _controller.clearNewPatientSheetRequest();
    setState(() => _newPatientSheetOpen = true);

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.88,
                minChildSize: 0.58,
                maxChildSize: 0.94,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      child: SafeArea(
                        top: false,
                        child: Column(
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
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: _teal.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person_add_rounded,
                                    color: _teal,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add Patient',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1A2A3D),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Register the patient, then continue screening.',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF5E7291),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(false),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFF8FA0B4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _newPatientForm(closeOnSuccess: true),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );

    if (!mounted) {
      return;
    }
    setState(() => _newPatientSheetOpen = false);
  }

  Future<void> _openPhotoCamera() async {
    final permission = await PermissionCoordinator.instance
        .requestPatientPhotoCamera(context);
    if (!permission.isGranted || !mounted) return;
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _photoCtrl = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _photoCtrl!.initialize();
    if (!mounted) return;
    setState(() => _showPhotoCamera = true);
  }

  Future<void> _takePhoto() async {
    if (_photoCtrl == null || !_photoCtrl!.value.isInitialized) return;
    try {
      final file = await _photoCtrl!.takePicture();
      // Copy to permanent app documents directory so it survives camera disposal
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'patient_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentPath = '${appDir.path}/$fileName';
      await File(file.path).copy(permanentPath);
      final ctrl = _photoCtrl;
      _photoCtrl = null;
      _controller.setNewPhotoPath(permanentPath);
      setState(() {
        _showPhotoCamera = false;
      });
      await ctrl?.dispose();
    } catch (e) {
      final ctrl = _photoCtrl;
      _photoCtrl = null;
      if (mounted) setState(() => _showPhotoCamera = false);
      await ctrl?.dispose();
    }
  }

  void _closePhotoCamera() {
    final ctrl = _photoCtrl;
    _photoCtrl = null;
    if (mounted) setState(() => _showPhotoCamera = false);
    ctrl?.dispose();
  }

  void _showPhotoOptions() => _openPhotoCamera();

  void _startCountdown() {
    _controller.startDistanceChart();
  }

  void _startNearCountdown() {
    _controller.startNearChart();
  }

  void _recordResponse(bool correct) {
    _controller.recordResponse(correct);
  }

  void _recordCantTell() {
    _controller.recordCantTell();
  }

  void _goToFinalSummary() => _controller.goToFinalSummary();

  void _recordNearResponse(bool correct) {
    _controller.recordNearResponse(correct);
  }

  void _recordNearCantTell() {
    _controller.recordNearCantTell();
  }

  // ── VA helpers ────────────────────────────────────────────────────────────
  Color _vaColor(String logmar) {
    final v = double.tryParse(logmar);
    if (v == null) return _red;
    if (v <= 0.3) return _green;
    if (v <= 0.5) return _amber;
    return _red;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_showPhotoCamera &&
        _photoCtrl != null &&
        _photoCtrl!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_photoCtrl!),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: VsIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close camera',
                    onTap: _closePhotoCamera,
                    foreground: Colors.white,
                    tint: Colors.black.withValues(alpha: 0.5),
                    size: 40,
                    iconSize: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _takePhoto,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(),
          if (_isOffline) _offlineBanner(),
          Expanded(child: _buildStep()),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildPatientSelector();
      case 1:
        return _buildChecklist();
      case 2:
        return _buildCoverEyeReminder();
      case 3:
        return _buildEChart();
      case 4:
        return _buildEyeResult();
      case 5:
        return _buildSummary();
      case 6:
        return _buildNearVisionIntro();
      case 7:
        return _buildNearChart();
      case 8:
        return _buildNearResult();
      default:
        return const SizedBox();
    }
  }

  Widget _offlineBanner() => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      border: Border(
        left: BorderSide(color: _amber, width: 4),
        bottom: BorderSide(color: _amber.withValues(alpha: 0.2), width: 1),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _amber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.wifi_off_rounded, size: 14, color: _amber),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are offline',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF92400E),
                ),
              ),
              Text(
                'Results saved locally — sync when connected.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            'LOCAL',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF92400E),
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    ),
  );

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final isDistanceChart = _step == 3;
    final isNearChart = _step == 7;
    final isChecklist = _step == 1;

    // Step labels for the progress bar
    const stepLabels = [
      'Patient',
      'Check',
      'Cover',
      'Test',
      'Result',
      'Summary',
    ];
    // Map internal step (0-8) to display step (0-5)
    final displayStep = _step.clamp(0, 5);

    // On checklist step: minimal header
    if (isChecklist) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF134E4A), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _backButton(),
                    const SizedBox(width: 12),
                    Text(
                      'Environment Check',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStepProgressBar(displayStep, stepLabels),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF134E4A), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _backButton(),
                      const SizedBox(width: 12),
                      if (isDistanceChart) ...[
                        // Eye label
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            _eyeOrder[_currentEyeIndex],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'LogMAR ${_rows[_currentRow]['logmar']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        // Letter counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '$_letterIndex/5',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.timer_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _testDuration,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ] else if (isNearChart) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'OU — 40cm',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'LogMAR ${_rows[_nearRow]['logmar']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
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
                          ),
                          child: Text(
                            '$_nearLetterIndex/5',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.timer_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _testDuration,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Vision Screening',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Hide the multi-step stepper during the chart steps —
                  // the examiner is mid-test and already sees per-letter progress.
                  if (!isDistanceChart && !isNearChart) ...[
                    const SizedBox(height: 12),
                    _buildStepProgressBar(displayStep, stepLabels),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return VsBackTile(
      size: 36,
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  Widget _buildStepProgressBar(int current, List<String> labels) {
    return Row(
      children: List.generate(labels.length, (i) {
        final done = i < current;
        final active = i == current;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    // Bar segment
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      height: 3,
                      decoration: BoxDecoration(
                        color: done || active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Label
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        color: active
                            ? Colors.white
                            : done
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.35),
                      ),
                      child: Text(labels[i], textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
              if (i < labels.length - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────────
  Widget _stepBar(int current) {
    const total = 6;
    return Row(
      children: List.generate(
        total,
        (i) => Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    color: i < current
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ── Location detection ────────────────────────────────────────────────────────────
  Future<void> _detectLocation() async {
    _controller.setDetectingLocation(true);
    final permission = await PermissionCoordinator.instance
        .requestScreeningLocation(context);
    if (!mounted) return;
    if (!permission.isGranted) {
      _controller.setDetectingLocation(false);
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (!mounted) return;
      // Warn if Android 12+ granted only approximate location
      try {
        final accuracy = await Geolocator.getLocationAccuracy();
        if (accuracy == LocationAccuracyStatus.reduced && mounted) {
          VsToast.showText(
            context,
            'Only approximate location available. Village name may be imprecise.',
            backgroundColor: _amber,
          );
        }
      } catch (_) {}
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).toList();
        _newVillageCtrl.text = parts.take(2).join(', ');
      }
    } catch (_) {}
    if (mounted) {
      _controller.setDetectingLocation(false);
    }
  }

  int _calcAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  // ── Step 0: Patient Selector ─────────────────────────────────────────────
  Widget _buildPatientSelector() {
    final filtered = _patientListRuntime.where((p) {
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
              _stepBar(1),
              const SizedBox(height: 20),
              Text(
                'Select Patient',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Search for a registered patient or add a new one.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF5E7291),
                ),
              ),
              const SizedBox(height: 16),
              _searchBar(),
              const SizedBox(height: 12),
              _addPatientButton(),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No patients found',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF8FA0B4),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _patientCard(filtered[index]),
                ),
        ),
        if (_selectedPatientId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _continueBtn('Continue to setup', _controller.runChecklist),
          ),
      ],
    );
  }

  Widget _addPatientButton() => OutlinedButton.icon(
    onPressed: () => unawaited(_showNewPatientSheet()),
    icon: const Icon(Icons.person_add_rounded, size: 18),
    label: Text(
      'Add patient',
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: _teal,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFDDE4EC), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size.fromHeight(46),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
    ),
  );

  Widget _searchBar() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
    ),
    child: TextField(
      controller: _patientSearchCtrl,
      onChanged: _controller.setPatientQuery,
      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A2A3D)),
      decoration: InputDecoration(
        hintText: 'Search by name, ID or village...',
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF8FA0B4),
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: Color(0xFF8FA0B4),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    ),
  );

  Widget _newPatientForm({required bool closeOnSuccess}) {
    const conditions = [
      {'label': 'Red Eyes', 'icon': Icons.remove_red_eye_rounded},
      {'label': 'Swollen Eyes', 'icon': Icons.visibility_off_rounded},
      {'label': 'Eye Discharge', 'icon': Icons.water_drop_rounded},
      {'label': 'Blurred Vision', 'icon': Icons.blur_on_rounded},
      {'label': 'Eye Pain', 'icon': Icons.warning_amber_rounded},
      {'label': 'Previous Surgery', 'icon': Icons.medical_services_rounded},
      {'label': 'Wears Glasses', 'icon': Icons.remove_red_eye_outlined},
      {'label': 'Diabetes', 'icon': Icons.monitor_heart_rounded},
      {'label': 'Hypertension', 'icon': Icons.favorite_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo capture
        Center(
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _showPhotoOptions,
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: _newPhotoPath != null
                          ? Colors.transparent
                          : _teal.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _newPhotoPath != null
                            ? _teal
                            : const Color(0xFFDDE4EC),
                        width: 2,
                      ),
                    ),
                    child:
                        _newPhotoPath != null &&
                            File(_newPhotoPath!).existsSync()
                        ? ClipOval(
                            child: Image.file(
                              File(_newPhotoPath!),
                              fit: BoxFit.cover,
                              width: 90,
                              height: 90,
                              errorBuilder: (context, error, stackTrace) =>
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 24,
                                        color: _teal,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Photo',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _teal,
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.camera_alt_rounded,
                                size: 24,
                                color: _teal,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Photo',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _teal,
                                ),
                              ),
                            ],
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Full name
        _newField(_newNameCtrl, 'Full name', Icons.person_rounded),
        const SizedBox(height: 8),
        // DOB + Gender
        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(
                        const Duration(days: 365 * 25),
                      ),
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                      helpText: 'Select date of birth',
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: _teal,
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      _controller.setNewDob(picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _newDob != null
                            ? _teal.withValues(alpha: 0.4)
                            : const Color(0xFFEEF2F6),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cake_rounded,
                          size: 16,
                          color: _newDob != null
                              ? _teal
                              : const Color(0xFF8FA0B4),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _newDob == null
                              ? Text(
                                  'Date of birth',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF8FA0B4),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_newDob!.day}/${_newDob!.month}/${_newDob!.year}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF1A2A3D),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_calcAge(_newDob!)} years old',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: _teal,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Color(0xFF8FA0B4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              ),
              child: Row(
                children: ['M', 'F'].map((g) {
                  final active = _newGender == g;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => _controller.setNewGender(g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: active ? _teal : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          g,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : const Color(0xFF8FA0B4),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Village / Area with auto-detect
        Row(
          children: [
            Expanded(
              child: _newField(
                _newVillageCtrl,
                'Village / area',
                Icons.location_on_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _detectingLocation ? null : _detectLocation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _detectingLocation
                        ? const Color(0xFFEEF2F6)
                        : _teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _detectingLocation
                          ? const Color(0xFFEEF2F6)
                          : _teal.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: _detectingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _teal,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          size: 20,
                          color: _teal,
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Phone number
        _newField(
          _newPhoneCtrl,
          'Phone number',
          Icons.phone_rounded,
          inputType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        // Current conditions
        Text(
          'Current eye conditions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A2A3D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select all that apply',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF8FA0B4),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: conditions.map((c) {
            final label = c['label'] as String;
            final icon = c['icon'] as IconData;
            final selected = _newConditions.contains(label);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: () => _controller.toggleNewCondition(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? _teal.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected ? _teal : const Color(0xFFDDE4EC),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 13,
                        color: selected ? _teal : const Color(0xFF8FA0B4),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected ? _teal : const Color(0xFF5E7291),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Register button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final name = _newNameCtrl.text.trim();
              final vil = _newVillageCtrl.text.trim();
              final phone = _newPhoneCtrl.text.trim();

              // ── Validation ──────────────────────────────
              final nameErr = PatientValidators.validateName(name);
              final dobErr = PatientValidators.validateDob(_newDob);
              final vilErr = PatientValidators.validateVillage(vil);
              final phoneErr = PatientValidators.validatePhone(phone);

              final firstError = nameErr ?? dobErr ?? vilErr ?? phoneErr;
              if (firstError != null) {
                VsToast.showText(
                  context,
                  firstError,
                  backgroundColor: _red,
                  duration: const Duration(seconds: 3),
                );
                return;
              }

              final age = _calcAge(_newDob!);

              // ── Duplicate detection ──────────────────────
              final duplicates = await _controller.findPotentialDuplicates(
                name: name,
                age: age,
                village: vil,
              );

              if (duplicates.isNotEmpty && mounted) {
                final proceed = await showDialog<bool>(
                  context: context,
                  builder: (_) => _DuplicateWarningDialog(
                    newName: name,
                    duplicates: duplicates,
                  ),
                );
                if (proceed != true) return;
              }

              await _controller.registerNewPatient(
                name: name,
                age: age,
                dob: _newDob!,
                village: vil,
                phone: phone,
              );
              if (!mounted) return;
              _newNameCtrl.clear();
              _newVillageCtrl.clear();
              _newPhoneCtrl.clear();
              if (closeOnSuccess && mounted) {
                Navigator.of(context).pop(true);
              }
            },
            icon: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              'Register patient',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _patientCard(Map<String, String> p) {
    final isSelected = _selectedPatientId == p['id'];
    final isNew = p['id']!.startsWith('PAT-NEW');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _controller.selectPatient(p['id']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? _teal.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _teal : const Color(0xFFEEF2F6),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? _teal : const Color(0xFF8FA0B4),
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
                            p['name']!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? _teal
                                  : const Color(0xFF1A2A3D),
                            ),
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'New',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _amber,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${p['gender']} · ${p['age']} yrs · ${p['village']}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8FA0B4),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: _teal, size: 20)
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFDDE4EC),
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
    ),
    child: TextField(
      controller: ctrl,
      keyboardType: inputType,
      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A2A3D)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF8FA0B4),
        ),
        prefixIcon: Icon(icon, size: 16, color: const Color(0xFF8FA0B4)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    ),
  );

  // ── Shared continue button ────────────────────────────────────────────────
  Widget _continueBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(
        Icons.arrow_forward_rounded,
        size: 18,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _teal,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
  );

  bool _lightBlocked = false;

  // PLACEHOLDERS
  Widget _buildChecklist() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepBar(2),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _teal.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: _teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mark the floor at exactly 2 metres from the screen before starting.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF5E7291),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.checklist_rounded,
                          size: 15,
                          color: _teal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Pre-test checklist',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A2A3D),
                        ),
                      ),

                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEF2F6)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VsAmbientLightCheck(
                        onStatusChanged: (blocked) {
                          if (_lightBlocked != blocked) {
                            setState(() => _lightBlocked = blocked);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      VsEnvironmentCheck(
                        onReady: () {
                          if (_lightBlocked) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FaceDistanceScreen(
                                onDistanceConfirmed: () {
                                  Navigator.pop(context);
                                  _controller.prepareNextEye();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverEyeReminder() {
    final eye = _eyeOrder[_currentEyeIndex];
    final isOD = eye == 'OD';
    final isOU = eye == 'OU';
    final label = isOU
        ? 'Both Eyes Open'
        : isOD
        ? 'Cover Left Eye'
        : 'Cover Right Eye';
    final sub = isOU
        ? 'Test both eyes together — no cover needed'
        : isOD
        ? 'Ask the patient to cover their LEFT eye with their palm'
        : 'Ask the patient to cover their RIGHT eye with their palm';
    final eyeLabel = isOU
        ? 'OU'
        : isOD
        ? 'OD'
        : 'OS';
    final eyeFull = isOU
        ? 'Both Eyes'
        : isOD
        ? 'Right Eye'
        : 'Left Eye';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _stepBar(3),
          const SizedBox(height: 24),
          // Eye order chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_eyeOrder.length, (i) {
              final done = i < _currentEyeIndex;
              final active = i == _currentEyeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: done
                      ? _green.withValues(alpha: 0.12)
                      : active
                      ? _teal
                      : const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _eyeOrder[i],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: done
                        ? _green
                        : active
                        ? Colors.white
                        : const Color(0xFF8FA0B4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          // Animated eye illustration
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _teal.withValues(alpha: 0.08),
                  border: Border.all(
                    color: _teal.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.remove_red_eye_rounded,
                      size: 72,
                      color: _teal.withValues(alpha: 0.3),
                    ),
                    if (!isOU)
                      Positioned(
                        left: isOD ? 16 : null,
                        right: isOD ? null : 16,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _ink.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.back_hand_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'Testing: $eyeLabel — $eyeFull',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _teal,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A2A3D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF5E7291),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          if (_countdown > 0)
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Container(
                  key: ValueKey(_countdown),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _teal.withValues(alpha: 0.1),
                    border: Border.all(color: _teal, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: GoogleFonts.inter(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: _teal,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _startCountdown,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_teal, const Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _teal.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.remove_red_eye_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isOD
                                ? 'Start right eye test'
                                : 'Start left eye test',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Patient is ready. Tap to start the 3-second countdown.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEChart() {
    final row = _rows[_currentRow];
    // Size based on fixed 2m testing distance
    final baseMm = row['mm'] as double;
    final size = _mmToPx(baseMm, context);

    // ── Normal chart ─────────────────────────────────────────────────────
    return Column(
      children: [
        // Single E display with bounding box — header counter shows letter progress
        Expanded(
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // E with ETDRS bounding box (hidden when examiner masking on)
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final maxH = constraints.maxHeight * 0.9;
                    final maxW = constraints.maxWidth * 0.45;
                    final s = size.clamp(0.0, maxH < maxW ? maxH : maxW);
                    return CustomPaint(
                      painter: _BoundingBoxPainter(size: s),
                      child: Padding(
                        padding: EdgeInsets.all(s * 0.6),
                        child: RotatedBox(
                          quarterTurns: _currentRotation,
                          child: CustomPaint(
                            size: Size(s * 0.8, s),
                            painter: _ETumbleEPainter(color: _ink),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            color: const Color(0xFFF8FAFB),
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Which way is the E facing?',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF8FA0B4),
                  ),
                ),
                const SizedBox(height: 5),
                _dirBtn(Icons.arrow_upward_rounded, 3),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dirBtn(Icons.arrow_back_rounded, 2),
                    const SizedBox(width: 80),
                    _dirBtn(Icons.arrow_forward_rounded, 0),
                  ],
                ),
                const SizedBox(height: 5),
                _dirBtn(Icons.arrow_downward_rounded, 1),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _recordCantTell,
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      size: 16,
                      color: Color(0xFF8FA0B4),
                    ),
                    label: Text(
                      "Can't Tell",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5E7291),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      side: const BorderSide(
                        color: Color(0xFFDDE4EC),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dirBtn(IconData icon, int quarterTurns) {
    return _directionButton(
      icon: icon,
      onTap: () => _recordResponse(quarterTurns == _currentRotation),
    );
  }

  Widget _buildEyeResult() {
    if (_eyeResults.isEmpty) return const SizedBox();
    final r = _eyeResults.last;
    final eye = r['eye'] as String;
    final logmar = r['logmar'] as String;
    final dur = r['duration'] as String;
    final cantTel = r['cantTell'] as int;
    final cls = VisualAcuity.classification(logmar);
    final col = _vaColor(logmar);
    final isLastEye = _currentEyeIndex >= _eyeOrder.length - 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepBar(4),
          const SizedBox(height: 24),
          // Eye chip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_eyeOrder.length, (i) {
              final done = i <= _currentEyeIndex;
              final active = i == _currentEyeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: done
                      ? _green.withValues(alpha: 0.12)
                      : const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(99),
                  border: active ? Border.all(color: _green, width: 1.5) : null,
                ),
                child: Text(
                  _eyeOrder[i],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: done ? _green : const Color(0xFF8FA0B4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          // Result card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: col.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: col.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: col.withValues(alpha: 0.1),
                    border: Border.all(
                      color: col.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      eye,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: col,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  eye == 'OD'
                      ? 'Right Eye'
                      : eye == 'OS'
                      ? 'Left Eye'
                      : 'Both Eyes',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8FA0B4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  double.tryParse(logmar) != null
                      ? VisualAcuity.toSnellen(logmar)
                      : logmar,
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: col,
                  ),
                ),
                if (double.tryParse(logmar) != null)
                  Text(
                    'LogMAR $logmar',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: col.withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    cls,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: col,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip(Icons.timer_rounded, dur, 'Duration'),
                    const SizedBox(width: 12),
                    _statChip(
                      Icons.help_outline_rounded,
                      '$cantTel',
                      "Can't Tell",
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Blur simulation
          _blurPreview(logmar),
          const SizedBox(height: 28),
          if (!isLastEye)
            _continueBtn(
              'Test Next Eye (${_eyeOrder[_currentEyeIndex + 1]})',
              _controller.prepareNextEye,
            )
          else
            _continueBtn('View Near Vision Test', _controller.jumpToNearIntro),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8FA0B4)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A2A3D),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF8FA0B4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurPreview(String logmar) {
    final v = double.tryParse(logmar);
    final cls = VisualAcuity.classification(logmar);
    final col = _vaColor(logmar);

    // Description of what the patient likely experiences
    final description = switch (cls) {
      'Normal' => 'Patient can read small print and see fine detail clearly.',
      'Near Normal' =>
        'Slight blur on fine detail. Functional for most daily tasks.',
      'Moderate Impairment' =>
        'Difficulty reading standard print. May struggle with faces at distance.',
      'Severe Impairment' =>
        'Only large objects visible. Cannot read standard print unaided.',
      'Profound Impairment' =>
        'Very limited vision. Counts fingers only at close range.',
      _ => 'Vision level could not be classified.',
    };

    final snellen = v != null ? VisualAcuity.toSnellen(logmar) : logmar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What the patient sees',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A2A3D),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: col.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.remove_red_eye_rounded,
                  color: col,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          snellen,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: col,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: col.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            cls,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: col,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF5E7291),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 6: Near Vision Intro ─────────────────────────────────────────────────────
  Widget _buildNearVisionIntro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _stepBar(5),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _teal.withValues(alpha: 0.08),
                  border: Border.all(
                    color: _teal.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 64,
                  color: _teal.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'Near Vision — Both Eyes Open',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _teal,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Near Vision Test',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A2A3D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Distance tests are complete. Now test near vision.\n'
            'Ask the patient to hold the device at 40 cm (arm\'s length) '
            'with BOTH eyes open.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF5E7291),
              height: 1.6,
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
                Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_rounded,
                      size: 15,
                      color: _amber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Setup instructions',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2A3D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...[
                  'Patient keeps BOTH eyes open — no covering needed',
                  'Hold device at exactly 40 cm from the eyes',
                  'Device should be at eye level',
                  'Patient wears reading glasses if they use them',
                  'Ensure screen brightness is at maximum',
                ].map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: _amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF5E7291),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (_nearCountdown > 0)
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Container(
                  key: ValueKey(_nearCountdown),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _teal.withValues(alpha: 0.1),
                    border: Border.all(color: _teal, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '$_nearCountdown',
                      style: GoogleFonts.inter(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: _teal,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  // Show 40cm face distance check before near vision test
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FaceDistanceScreen(
                        targetDistanceM: 0.4,
                        toleranceM: 0.08,
                        onDistanceConfirmed: () {
                          Navigator.pop(context);
                          _startNearCountdown();
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_teal, Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _teal.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Distance confirmed. Start test.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap when the device is 40 cm from the eyes.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 7: Near Vision Chart ───────────────────────────────────────────────────
  // -- Step 7: Near Vision Chart
  Widget _buildNearChart() {
    // ── Near chart (40cm confirmed) ───────────────────────────────────────────────
    final row = _rows[_nearRow];
    // Near vision at 40cm = 0.4m (base measurements at 2m, scale by 0.4/2.0)
    final baseMm = row['mm'] as double;
    final scaledMm = baseMm * (400.0 / 2000.0);
    final size = _mmToPx(scaledMm, context);

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  painter: _BoundingBoxPainter(size: size),
                  child: Padding(
                    padding: EdgeInsets.all(size * 0.6),
                    child: RotatedBox(
                      quarterTurns: _nearRotation,
                      child: CustomPaint(
                        size: Size(size * 0.8, size),
                        painter: _ETumbleEPainter(color: _ink),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            color: const Color(0xFFF8FAFB),
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Which way is the E facing?',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF8FA0B4),
                  ),
                ),
                const SizedBox(height: 5),
                _nearDirBtn(Icons.arrow_upward_rounded, 3),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _nearDirBtn(Icons.arrow_back_rounded, 2),
                    const SizedBox(width: 80),
                    _nearDirBtn(Icons.arrow_forward_rounded, 0),
                  ],
                ),
                const SizedBox(height: 5),
                _nearDirBtn(Icons.arrow_downward_rounded, 1),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _recordNearCantTell,
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      size: 16,
                      color: Color(0xFF8FA0B4),
                    ),
                    label: Text(
                      "Can't Tell",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5E7291),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      side: const BorderSide(
                        color: Color(0xFFDDE4EC),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _nearDirBtn(IconData icon, int quarterTurns) => _directionButton(
    icon: icon,
    onTap: () => _recordNearResponse(quarterTurns == _nearRotation),
  );

  Widget _directionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE4EC), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 26, color: _ink),
        ),
      ),
    );
  }

  // ── Step 8: Near Vision Result ──────────────────────────────────────────────────
  Widget _buildNearResult() {
    if (_nearResult == null) return const SizedBox();
    final logmar = _nearResult!['logmar'] as String;
    final dur = _nearResult!['duration'] as String;
    final ct = _nearResult!['cantTell'] as int;
    final cls = VisualAcuity.classification(logmar);
    final col = _vaColor(logmar);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepBar(6),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: col.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: col.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: col.withValues(alpha: 0.1),
                    border: Border.all(
                      color: col.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'OU',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Near Vision — Both Eyes',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8FA0B4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  double.tryParse(logmar) != null
                      ? VisualAcuity.toSnellen(logmar)
                      : logmar,
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: col,
                  ),
                ),
                if (double.tryParse(logmar) != null)
                  Text(
                    'LogMAR $logmar',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: col.withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    cls,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: col,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip(Icons.timer_rounded, dur, 'Duration'),
                    const SizedBox(width: 12),
                    _statChip(Icons.help_outline_rounded, '$ct', "Can't Tell"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _blurPreview(logmar),
          const SizedBox(height: 28),
          _continueBtn('View Full Summary', _goToFinalSummary),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final patient = _patientListRuntime
        .where((p) => p['id'] == _selectedPatientId)
        .firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepBar(6),
          const SizedBox(height: 24),
          // Patient banner
          if (patient != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        patient['name']!
                            .split(' ')
                            .map((w) => w[0])
                            .take(2)
                            .join(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _teal3,
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
                          patient['name']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${patient['gender']} · ${patient['age']} yrs · ${patient['village']}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Offline',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _amber,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Screening Results',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A2A3D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Distance Vision (Monocular)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8FA0B4),
            ),
          ),
          const SizedBox(height: 12),
          // Per-eye result cards
          ..._eyeResults.map((r) {
            final eye = r['eye'] as String;
            final logmar = r['logmar'] as String;
            final dur = r['duration'] as String;
            final ct = r['cantTell'] as int;
            final cls = VisualAcuity.classification(logmar);
            final col = _vaColor(logmar);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: col.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        eye,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: col,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eye == 'OD'
                              ? 'Right Eye'
                              : eye == 'OS'
                              ? 'Left Eye'
                              : 'Both Eyes',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF8FA0B4),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cls,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A2A3D),
                          ),
                        ),
                        if (ct > 0)
                          Text(
                            "$ct can't tell response${ct > 1 ? 's' : ''}",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: _amber,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        double.tryParse(logmar) != null
                            ? VisualAcuity.toSnellen(logmar)
                            : logmar,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: col,
                        ),
                      ),
                      if (double.tryParse(logmar) != null)
                        Text(
                          'LogMAR $logmar',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: col.withValues(alpha: 0.7),
                          ),
                        ),
                      Text(
                        dur,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF8FA0B4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          // Near vision result card
          if (_nearResult != null) ...[
            const SizedBox(height: 16),
            Text(
              'Near Vision (Binocular — 40cm)',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8FA0B4),
              ),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (_) {
                final logmar = _nearResult!['logmar'] as String;
                final dur = _nearResult!['duration'] as String;
                final ct = _nearResult!['cantTell'] as int;
                final cls = VisualAcuity.classification(logmar);
                final col = _vaColor(logmar);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEEF2F6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: col.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'OU',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: col,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Both Eyes — Near',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF8FA0B4),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cls,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2A3D),
                              ),
                            ),
                            if (ct > 0)
                              Text(
                                "$ct can't tell",
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: _amber,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            double.tryParse(logmar) != null
                                ? VisualAcuity.toSnellen(logmar)
                                : logmar,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: col,
                            ),
                          ),
                          if (double.tryParse(logmar) != null)
                            Text(
                              'LogMAR $logmar',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: col.withValues(alpha: 0.7),
                              ),
                            ),
                          Text(
                            dur,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF8FA0B4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          // Referral banner
          if (_needsReferral) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_hospital_rounded,
                    color: _red,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Referral Recommended',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _red,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vision below 6/12 in one or more eyes. '
                          'Refer to nearest eye clinic.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF5E7291),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          if (_needsReferral)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final patient = _patientListRuntime
                        .where((p) => p['id'] == _selectedPatientId)
                        .firstOrNull;
                    if (patient == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReferralLetterScreen(
                          patient: patient,
                          eyeResults: _eyeResults,
                          nearResult: _nearResult,
                          screeningDate: DateTime.now().toString().substring(
                            0,
                            10,
                          ),
                          screeningId: _savedScreeningId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.description_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Generate referral letter',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(
                Icons.save_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                _isOffline ? 'Save Locally & Finish' : 'Save & Finish',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _isOffline
                  ? 'Saved locally. Use Sync Now from Home or Settings to upload when ready.'
                  : 'Results will be saved to the patient record',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF8FA0B4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ETDRS bounding box — stroke = 1/5 of E size, gap = 1/2 of E size
class _BoundingBoxPainter extends CustomPainter {
  final double size;
  const _BoundingBoxPainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final strokeW = size / 5; // arm thickness = 1 unit
    final gap = size / 2; // gap between E and box
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;
    final half = size / 2 + gap + strokeW / 2;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: half * 2,
      height: half * 2,
    );
    final paint = Paint()
      ..color = const Color(0xFF04091A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_BoundingBoxPainter old) => old.size != size;
}

// ETDRS Tumbling E — drawn on a 5×5 grid
// Unit (u) = size/5
// Letter: width=4u, height=5u
// 3 arms: top, middle, bottom — each 1u thick
// 2 gaps between arms: each 1u
// Spine on left: 1u wide, full 5u height
class _ETumbleEPainter extends CustomPainter {
  final Color color;
  const _ETumbleEPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.height / 5;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    // Spine
    canvas.drawRect(Rect.fromLTWH(0, 0, u, size.height), paint);
    // Top arm
    canvas.drawRect(Rect.fromLTWH(0, 0, u * 4, u), paint);
    // Middle arm — 4u wide per ETDRS 5×5 rule (same as top/bottom)
    canvas.drawRect(Rect.fromLTWH(0, u * 2, u * 4, u), paint);
    // Bottom arm
    canvas.drawRect(Rect.fromLTWH(0, u * 4, u * 4, u), paint);
  }

  @override
  bool shouldRepaint(_ETumbleEPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Duplicate patient warning dialog
// ─────────────────────────────────────────────────────────────
class _DuplicateWarningDialog extends StatelessWidget {
  const _DuplicateWarningDialog({
    required this.newName,
    required this.duplicates,
  });
  final String newName;
  final List<Map<String, dynamic>> duplicates;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Possible Duplicate',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A2A3D),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A patient with a similar name and age already exists:',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF5E7291),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...duplicates
              .take(3)
              .map(
                (p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (p['name'] as String)
                                .split(' ')
                                .map((w) => w.isEmpty ? '' : w[0])
                                .take(2)
                                .join(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2A3D),
                              ),
                            ),
                            Text(
                              '${p['gender']} · ${p['age']} yrs · ${p['village']}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF8FA0B4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 4),
          Text(
            'Is "$newName" a different person?',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A2A3D),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Use existing',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8FA0B4),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D9488),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: Text(
            'Register patient',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
