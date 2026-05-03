import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

// ─────────────────────────────────────────────────────────────
// FaceDistanceScreen
//
// Uses the front camera + ML Kit face detection to:
//   1. Draw a live bounding box around the detected face
//   2. Estimate the patient's distance from the screen
//   3. Guide the CHW to position the patient at exactly 3 metres
//
// When the patient is at the correct distance for 3+ seconds,
// it auto-calls [onDistanceConfirmed] to proceed to the test.
// ─────────────────────────────────────────────────────────────

class FaceDistanceScreen extends StatefulWidget {
  const FaceDistanceScreen({
    super.key,
    required this.onDistanceConfirmed,
    this.targetDistanceM = 2.0,
    this.toleranceM = 0.25,
  });

  /// Called when patient holds correct distance for 3 seconds
  final VoidCallback onDistanceConfirmed;

  /// Target distance in metres (default 3m for Snellen test)
  final double targetDistanceM;

  /// Acceptable tolerance in metres (±0.3m)
  final double toleranceM;

  @override
  State<FaceDistanceScreen> createState() => _FaceDistanceScreenState();
}

class _FaceDistanceScreenState extends State<FaceDistanceScreen>
    with TickerProviderStateMixin {
  // ── Camera ──────────────────────────────────────────────────
  CameraController? _camCtrl;
  bool _camReady = false;
  bool _processing = false;

  // ── ML Kit ──────────────────────────────────────────────────
  late final FaceDetector _detector;

  // ── Detection state ─────────────────────────────────────────
  Face? _face;
  double? _distanceM;
  Size _previewSize = Size.zero;

  // ── Countdown when at correct distance ──────────────────────
  int _holdSeconds = 0;
  Timer? _holdTimer;
  static const _holdRequired = 3;

  // ── Animations ──────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  // ── Average IPD (interpupillary distance) in mm ─────────────
  // WHO standard adult average: 63mm
  static const double _ipdMm = 63.0;

  // ── Focal length — set from first real CameraImage ──────────
  double _focalLengthPx = 0.0;
  int _rawImageW = 0;

  // ── Text-to-Speech ──────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  String _lastSpoken = '';
  DateTime _lastSpeakTime = DateTime(2000);
  static const _speakCooldown = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();

    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: false,
        enableTracking: false,
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));

    _initCamera();
    _initTts().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _speak('Position the patient two metres from the screen.');
      });
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // Warm up the engine with a silent speak so first real call is instant
    await _tts.speak(' ');
    await _tts.stop();
  }

  // ── Speak with cooldown per unique message ───────────────────
  // Different messages always play immediately.
  // Same message repeats only after cooldown expires.
  Future<void> _speak(String text) async {
    final now = DateTime.now();
    final sameMessage = text == _lastSpoken;
    final cooldownExpired = now.difference(_lastSpeakTime) >= _speakCooldown;

    if (sameMessage && !cooldownExpired) return;

    _lastSpoken = text;
    _lastSpeakTime = now;
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _camCtrl?.dispose();
    _detector.close();
    _tts.stop();
    _pulseCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  // ── Smoothing buffer — median filter to reject outliers ──────
  final List<double> _distBuffer = [];
  static const _bufferSize = 6;

  double _smoothedDistance(double raw) {
    _distBuffer.add(raw);
    if (_distBuffer.length > _bufferSize) _distBuffer.removeAt(0);
    final sorted = List<double>.from(_distBuffer)..sort();
    return sorted[sorted.length ~/ 2];
  }

  // ── Camera init ─────────────────────────────────────────────
  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _camReady = false);
      return;
    }

    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _camCtrl = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _camCtrl!.initialize();
    if (!mounted) return;

    setState(() {
      _camReady = true;
      _previewSize = Size(
        _camCtrl!.value.previewSize!.height, // portrait width
        _camCtrl!.value.previewSize!.width,  // portrait height
      );
    });

    _camCtrl!.startImageStream(_onFrame);
  }

  // ── Process each camera frame ────────────────────────────────
  Future<void> _onFrame(CameraImage image) async {
    if (_processing || !mounted) return;
    _processing = true;

    // ── Calculate focal length from REAL image dimensions ─────
    // This runs once on the first frame using the actual pixel
    // dimensions that ML Kit receives — not the display preview size.
    // image.width = landscape width (longer side, e.g. 640)
    // image.height = landscape height (shorter side, e.g. 480)
    // Eye landmarks are in image coordinates, so focal length must
    // use the same axis as the eye distance measurement.
    // Eyes are separated horizontally → use image.width (landscape).
    // HFOV 68° is the measured average for Android front cameras.
    if (_focalLengthPx == 0.0 && image.width > 0) {
      _rawImageW = image.width;
      const hFovDeg = 68.0;
      final hFovRad = hFovDeg * pi / 180.0;
      _focalLengthPx = image.width / (2.0 * tan(hFovRad / 2.0));
    }

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) { _processing = false; return; }

      final faces = await _detector.processImage(inputImage);

      if (!mounted) { _processing = false; return; }

      if (faces.isEmpty) {
        setState(() { _face = null; _distanceM = null; });
        _stopHoldTimer();
        _processing = false;
        return;
      }

      // Use the largest face (closest to camera)
      final face = faces.reduce((a, b) =>
          a.boundingBox.width > b.boundingBox.width ? a : b);

      // ── Distance estimation using hardware focal length ──────
      // dist_mm = (realSize_mm × focalLength_px) / apparentSize_px
      // IPD average = 63mm (WHO standard)
      final leftEye  = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];

      double? distM;

      if (leftEye != null && rightEye != null && _focalLengthPx > 0) {
        // ML Kit returns landmark positions in the raw image coordinate
        // system (landscape). The horizontal separation between eyes
        // corresponds to image.width axis → same axis as _focalLengthPx.
        final dx = (leftEye.position.x - rightEye.position.x).toDouble();
        final dy = (leftEye.position.y - rightEye.position.y).toDouble();
        // Use only horizontal component for consistency with focal length axis
        // (eyes are primarily separated horizontally in a face-on view)
        final eyeDistPx = dx.abs() > dy.abs()
            ? sqrt(dx * dx + dy * dy)  // face-on: use full distance
            : dx.abs();                // tilted head: use horizontal only

        if (eyeDistPx > 8) {
          // dist_mm = (IPD_mm × focalLength_px) / eyeDistPx
          // IPD = 63mm (WHO adult average)
          final distMm = (_ipdMm * _focalLengthPx) / eyeDistPx;
          distM = distMm / 1000.0;
        }
      } else if (_focalLengthPx > 0) {
        // Fallback: bounding box width vs average face width (150mm)
        final boxW = face.boundingBox.width;
        if (boxW > 8) {
          final distMm = (150.0 * _focalLengthPx) / boxW;
          distM = distMm / 1000.0;
        }
      }

      // Clamp to reasonable range (0.3m – 6m) then smooth
      if (distM != null) {
        distM = distM.clamp(0.3, 6.0);
        distM = _smoothedDistance(distM);
      }

      setState(() {
        _face = face;
        _distanceM = distM;
      });

      // ── Voice guidance ───────────────────────────────────────
      if (distM != null) {
        if (_isAtTarget(distM)) {
          if (_holdSeconds == 0) _speak('Perfect. Hold still.');
        } else if (distM < widget.targetDistanceM - widget.toleranceM) {
          final diff = (widget.targetDistanceM - distM);
          if (diff > 0.5) {
            _speak('Move back about ${diff.toStringAsFixed(1)} metres.');
          } else {
            _speak('A little further back.');
          }
        } else {
          final diff = (distM - widget.targetDistanceM);
          if (diff > 0.5) {
            _speak('Move closer about ${diff.toStringAsFixed(1)} metres.');
          } else {
            _speak('A little closer.');
          }
        }
      } else {
        _speak('No face detected. Please look at the camera.');
      }

      // ── Hold timer logic ─────────────────────────────────────
      if (distM != null && _isAtTarget(distM)) {
        _startHoldTimer();
      } else {
        _stopHoldTimer();
      }
    } catch (_) {}

    _processing = false;
  }

  // ── Build ML Kit InputImage from CameraImage ─────────────────
  InputImage? _buildInputImage(CameraImage image) {
    if (_camCtrl == null) return null;
    final camera = _camCtrl!.description;

    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // ── Distance helpers ─────────────────────────────────────────
  bool _isAtTarget(double d) =>
      (d - widget.targetDistanceM).abs() <= widget.toleranceM;

  void _startHoldTimer() {
    if (_holdTimer != null) return;
    _speak('Good. Hold still.');
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _holdSeconds++);
      if (_holdSeconds == 1) _speak('Two.');
      if (_holdSeconds == 2) _speak('One.');
      if (_holdSeconds >= _holdRequired) {
        t.cancel();
        _speak('Perfect distance confirmed. Starting test.');
        _checkCtrl.forward();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) widget.onDistanceConfirmed();
        });
      }
    });
  }

  void _stopHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_holdSeconds > 0) setState(() => _holdSeconds = 0);
  }

  // ── UI helpers ───────────────────────────────────────────────
  Color get _statusColor {
    if (_distanceM == null) return const Color(0xFF94A3B8);
    if (_isAtTarget(_distanceM!)) return const Color(0xFF22C55E);
    if (_distanceM! < widget.targetDistanceM - widget.toleranceM) {
      return const Color(0xFFEF4444); // too close
    }
    return const Color(0xFFF59E0B); // too far
  }

  String get _statusLabel {
    if (_distanceM == null) return 'No face detected';
    final d = _distanceM!;
    if (_isAtTarget(d)) {
      return _holdSeconds > 0
          ? 'Hold still... $_holdSeconds/$_holdRequired'
          : '✓ Perfect distance!';
    }
    if (d < widget.targetDistanceM - widget.toleranceM) {
      final diff = (widget.targetDistanceM - d).toStringAsFixed(1);
      return 'Move back ${diff}m';
    }
    final diff = (d - widget.targetDistanceM).toStringAsFixed(1);
    return 'Move closer ${diff}m';
  }

  String get _distanceText {
    if (_distanceM == null) return '—';
    return '${_distanceM!.toStringAsFixed(1)}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ──────────────────────────────────
          if (_camReady && _camCtrl != null)
            Center(child: CameraPreview(_camCtrl!))
          else
            _buildPermissionState(),

          // ── Face bounding box overlay ───────────────────────
          if (_camReady && _face != null)
            CustomPaint(
              painter: _FaceBoxPainter(
                face: _face!,
                previewSize: _previewSize,
                screenSize: MediaQuery.of(context).size,
                color: _statusColor,
              ),
            ),

          // ── Top header ──────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
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
                            Text('DISTANCE CHECK',
                                style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    letterSpacing: 1.8)),
                            const SizedBox(height: 2),
                            Text('Position Patient at 2m',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                      // Distance badge
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, child) => Transform.scale(
                          scale: _isAtTarget(_distanceM ?? 0)
                              ? _pulse.value
                              : 1.0,
                          child: child,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color: _statusColor.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            _distanceText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _statusColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Target ring overlay ──────────────────────────────
          if (_camReady)
            Center(
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _TargetRingPainter(
                  color: _statusColor,
                  progress: _holdSeconds / _holdRequired,
                ),
              ),
            ),

          // ── Bottom status panel ──────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.92),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, 32, 24,
                  MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── Live distance meter ──────────────────────
                  _buildDistanceMeter(),
                  const SizedBox(height: 16),

                  // ── Status message ───────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _statusLabel,
                      key: ValueKey(_statusLabel),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ask the patient to stand ${widget.targetDistanceM.toStringAsFixed(0)} metres away\nfrom the screen for accurate vision testing',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Hold progress bar ────────────────────────
                  if (_holdSeconds > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _holdSeconds / _holdRequired,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hold still for ${_holdRequired - _holdSeconds} more second${_holdRequired - _holdSeconds == 1 ? '' : 's'}...',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Skip button ──────────────────────────────
                  GestureDetector(
                    onTap: widget.onDistanceConfirmed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'Skip — proceed manually',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Success checkmark overlay ────────────────────────
          AnimatedBuilder(
            animation: _checkScale,
            builder: (_, __) {
              if (_checkScale.value == 0) return const SizedBox.shrink();
              return Container(
                color: Colors.black.withValues(alpha: 0.5 * _checkScale.value),
                child: Center(
                  child: Transform.scale(
                    scale: _checkScale.value,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E)
                                .withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 60),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Animated distance meter ──────────────────────────────────
  Widget _buildDistanceMeter() {
    final target = widget.targetDistanceM;
    final current = _distanceM;

    // Meter range: 0m to 4m, target at 2m
    const minM = 0.0, maxM = 4.0;
    final fillRatio = current == null
        ? 0.0
        : ((current - minM) / (maxM - minM)).clamp(0.0, 1.0);
    final targetRatio = (target - minM) / (maxM - minM);

    return Column(
      children: [
        // Big live distance number
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Text(
            current == null ? '— m' : '${current.toStringAsFixed(2)} m',
            key: ValueKey(current?.toStringAsFixed(1)),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: _statusColor,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Target: ${target.toStringAsFixed(1)} m',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal ruler bar
        LayoutBuilder(builder: (_, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Track background
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              // Fill bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 10,
                width: w * fillRatio,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              // Target marker line
              Positioned(
                left: w * targetRatio - 1.5,
                top: -4,
                child: Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              // Target label
              Positioned(
                left: (w * targetRatio - 16).clamp(0.0, w - 32),
                top: 16,
                child: Text(
                  '${target.toStringAsFixed(0)}m',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 8),
        // Scale labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0m', style: GoogleFonts.inter(
                fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
            Text('1m', style: GoogleFonts.inter(
                fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
            Text('2m', style: GoogleFonts.inter(
                fontSize: 9, color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700)),
            Text('3m', style: GoogleFonts.inter(
                fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
            Text('4m', style: GoogleFonts.inter(
                fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionState() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Color(0xFF0D9488), size: 32),
            ),
            const SizedBox(height: 16),
            Text('Camera permission required',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Allow camera access to detect\npatient distance',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _initCamera,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('Grant Permission',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Face bounding box painter
// ─────────────────────────────────────────────────────────────
class _FaceBoxPainter extends CustomPainter {
  const _FaceBoxPainter({
    required this.face,
    required this.previewSize,
    required this.screenSize,
    required this.color,
  });

  final Face face;
  final Size previewSize;
  final Size screenSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factor from preview coords to screen coords
    final scaleX = screenSize.width / previewSize.width;
    final scaleY = screenSize.height / previewSize.height;

    final box = face.boundingBox;

    // Mirror X for front camera
    final left   = screenSize.width - box.right  * scaleX;
    final right  = screenSize.width - box.left   * scaleX;
    final top    = box.top    * scaleY;
    final bottom = box.bottom * scaleY;

    final rect = Rect.fromLTRB(left, top, right, bottom);

    // Corner bracket style (not full rectangle — more clinical)
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + cornerLen),
        Offset(rect.left, rect.top), paint);
    canvas.drawLine(Offset(rect.left, rect.top),
        Offset(rect.left + cornerLen, rect.top), paint);
    // Top-right
    canvas.drawLine(Offset(rect.right - cornerLen, rect.top),
        Offset(rect.right, rect.top), paint);
    canvas.drawLine(Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + cornerLen), paint);
    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - cornerLen),
        Offset(rect.left, rect.bottom), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left + cornerLen, rect.bottom), paint);
    // Bottom-right
    canvas.drawLine(Offset(rect.right - cornerLen, rect.bottom),
        Offset(rect.right, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - cornerLen), paint);

    // Subtle fill
    canvas.drawRect(
      rect,
      Paint()..color = color.withValues(alpha: 0.06)..style = PaintingStyle.fill,
    );

    // Eye landmark dots
    final leftEye  = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    for (final eye in [leftEye, rightEye]) {
      if (eye == null) continue;
      final ex = screenSize.width - eye.position.x.toDouble() * scaleX;
      final ey = eye.position.y.toDouble() * scaleY;
      canvas.drawCircle(Offset(ex, ey), 5,
          Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(ex, ey), 5,
          Paint()..color = Colors.white.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_FaceBoxPainter old) =>
      old.face != face || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Target ring painter — shows progress arc when at correct dist
// ─────────────────────────────────────────────────────────────
class _TargetRingPainter extends CustomPainter {
  const _TargetRingPainter({required this.color, required this.progress});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width / 2 - 4;

    // Background ring
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    // Center crosshair
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx + 12, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - 12), Offset(cx, cy + 12), crossPaint);
  }

  @override
  bool shouldRepaint(_TargetRingPainter old) =>
      old.color != color || old.progress != progress;
}
