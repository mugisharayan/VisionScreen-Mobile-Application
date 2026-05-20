import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screen_brightness/screen_brightness.dart';

const _green = Color(0xFF22C55E);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _slate = Color(0xFF94A3B8);

// Lux thresholds for real ambient light sensor
const _minLux = 50.0;   // below = too dark for screening
const _maxLux = 5000.0; // above = too bright / glare

// Fallback screen-brightness thresholds (0.0–1.0)
const _minBrightness = 0.15;
const _maxBrightness = 0.92;

const _luxChannel = MethodChannel('com.visionscreen/ambient_light');

enum _LightStatus { reading, ok, tooDark, tooBright, unavailable }

class VsAmbientLightCheck extends StatefulWidget {
  const VsAmbientLightCheck({super.key, required this.onStatusChanged});

  final ValueChanged<bool> onStatusChanged;

  @override
  State<VsAmbientLightCheck> createState() => _VsAmbientLightCheckState();
}

class _VsAmbientLightCheckState extends State<VsAmbientLightCheck> {
  _LightStatus _status = _LightStatus.ok;
  double? _lux;
  bool _usedLuxSensor = false;
  bool _measuring = false;

  @override
  void initState() {
    super.initState();
    // Pre-ticked: report ok immediately, sensor check skipped for now
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onStatusChanged(false),
    );
  }

  Future<void> _measure() async {
    if (_measuring) return;
    _measuring = true;
    if (mounted) setState(() => _status = _LightStatus.reading);
    try {
      final raw = await _luxChannel.invokeMethod<double>('getLux');
      if (!mounted) return;
      if (raw != null) {
        _usedLuxSensor = true;
        _LightStatus s;
        if (raw < _minLux) {
          s = _LightStatus.tooDark;
        } else if (raw > _maxLux) {
          s = _LightStatus.tooBright;
        } else {
          s = _LightStatus.ok;
        }
        _update(s, raw);
        _measuring = false;
        return;
      }
    } catch (_) {
      // sensor unavailable — fall through to brightness fallback
    }

    // Fallback: use screen brightness
    _usedLuxSensor = false;
    try {
      final value = await ScreenBrightness().system;
      if (!mounted) return;
      _LightStatus s;
      if (value < _minBrightness) {
        s = _LightStatus.tooDark;
      } else if (value > _maxBrightness) {
        s = _LightStatus.tooBright;
      } else {
        s = _LightStatus.ok;
      }
      _update(s, value);
    } catch (_) {
      if (mounted) _update(_LightStatus.unavailable, null);
    }
    _measuring = false;
  }

  void _update(_LightStatus s, double? value) {
    if (!mounted) return;
    setState(() {
      _status = s;
      _lux = value;
    });
    final blocked = s == _LightStatus.tooDark || s == _LightStatus.tooBright;
    widget.onStatusChanged(blocked);
  }

  String _valueLabel() {
    if (_lux == null) return '';
    if (_usedLuxSensor) return '${_lux!.round()} lux';
    return '${(_lux! * 100).round()}% brightness';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, subtitle) = switch (_status) {
      _LightStatus.reading => (
          null,
          _slate,
          'Ambient Light',
          'Checking lighting conditions…',
        ),
      _LightStatus.ok => (
          Icons.check_circle_rounded,
          _green,
          'Ambient Light',
          'Good lighting',
        ),
      _LightStatus.tooDark => (
          Icons.warning_rounded,
          _red,
          'Too Dark',
          'Move to a brighter area — ${_valueLabel()}',
        ),
      _LightStatus.tooBright => (
          Icons.warning_rounded,
          _amber,
          'Too Bright',
          'Reduce glare or direct sunlight — ${_valueLabel()}',
        ),
      _LightStatus.unavailable => (
          Icons.check_circle_rounded,
          _green,
          'Ambient Light',
          'Could not measure — proceed with care',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.wb_sunny_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A2A3D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
                if (_status == _LightStatus.tooDark ||
                    _status == _LightStatus.tooBright) ...[  
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _measure,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 13, color: color),
                        const SizedBox(width: 4),
                        Text(
                          'Retry',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_status == _LightStatus.reading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF94A3B8),
              ),
            )
          else if (_status == _LightStatus.tooDark ||
              _status == _LightStatus.tooBright)
            GestureDetector(
              onTap: _measure,
              child: Icon(icon, color: color, size: 22),
            )
          else
            Icon(icon, color: color, size: 22),
        ],
      ),
    );
  }
}
