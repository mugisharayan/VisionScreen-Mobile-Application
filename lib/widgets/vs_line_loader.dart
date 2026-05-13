import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// VsLineLoader — thin indeterminate strip loader
//
// A 2px-tall band that slides left-to-right across the available
// width, looping while [active] is true. Sits flush with whatever
// you put it under (typically a header), and collapses to zero
// height when inactive — so the layout doesn't jump on/off.
//
// Use this to signal an in-flight async action (sign-in, save,
// sync) without showing a heavy modal spinner.
// ─────────────────────────────────────────────────────────────
class VsLineLoader extends StatefulWidget {
  const VsLineLoader({
    super.key,
    required this.active,
    this.color,
    this.height = 2,
  });

  /// Whether the loader is visible and animating.
  final bool active;

  /// Band colour. Defaults to brand teal.
  final Color? color;

  /// Strip thickness in logical pixels.
  final double height;

  @override
  State<VsLineLoader> createState() => _VsLineLoaderState();
}

class _VsLineLoaderState extends State<VsLineLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(VsLineLoader old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? VsColors.brand;
    // AnimatedSize so the strip slides into view rather than popping
    // — height transitions from 0 to widget.height and back.
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: SizedBox(
        height: widget.active ? widget.height : 0,
        width: double.infinity,
        child: !widget.active
            ? const SizedBox.shrink()
            : ClipRect(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final width = constraints.maxWidth;
                    // Band is 32% of available width; total travel is
                    // (width + bandWidth) so the band enters fully from
                    // the left and exits fully to the right.
                    final bandWidth = width * 0.32;
                    final travel = width + bandWidth;
                    return Stack(
                      children: [
                        // Faint track so the strip's existence is hinted
                        // at even when the band is off-screen.
                        Container(color: color.withValues(alpha: 0.10)),
                        AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, _) {
                            // EaseInOutCubic gives the band a deliberate
                            // sweep — it accelerates from rest, glides,
                            // then settles at the right before looping.
                            final eased =
                                Curves.easeInOutCubic.transform(_ctrl.value);
                            final left = travel * eased - bandWidth;
                            return Positioned(
                              left: left,
                              top: 0,
                              bottom: 0,
                              width: bandWidth,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      color.withValues(alpha: 0.0),
                                      color,
                                      color.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
