import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

const _green = Color(0xFF22C55E);

class VsEnvironmentCheck extends StatefulWidget {
  const VsEnvironmentCheck({super.key, required this.onReady});

  final VoidCallback onReady;

  @override
  State<VsEnvironmentCheck> createState() => _VsEnvironmentCheckState();
}

class _VsEnvironmentCheckState extends State<VsEnvironmentCheck> {
  bool _brightnessSet = false;
  double? _originalBrightness;

  @override
  void initState() {
    super.initState();
    _setBrightness();
  }

  @override
  void dispose() {
    _restoreBrightness();
    super.dispose();
  }

  Future<void> _setBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
      await WakelockPlus.enable();
    } catch (_) {}
    if (mounted) {
      setState(() => _brightnessSet = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReady();
      });
    }
  }

  Future<void> _restoreBrightness() async {
    try {
      await WakelockPlus.disable();
      if (_originalBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
      } else {
        await ScreenBrightness().resetScreenBrightness();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (_brightnessSet ? _green : const Color(0xFF94A3B8))
              .withValues(alpha: 0.25),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (_brightnessSet ? _green : const Color(0xFF94A3B8))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.brightness_high_rounded,
              color: _brightnessSet ? _green : const Color(0xFF94A3B8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Screen Brightness',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A2A3D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _brightnessSet
                      ? 'Set to 100% automatically'
                      : 'Setting screen brightness…',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _brightnessSet
              ? const Icon(Icons.check_circle_rounded,
                  color: _green, size: 22)
              : const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF94A3B8),
                  ),
                ),
        ],
      ),
    );
  }
}
