import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class VsCard extends StatelessWidget {
  const VsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VsSpace.lg),
    this.margin,
    this.borderColor = VsColors.border,
    this.backgroundColor = VsColors.card,
    this.shadow = false,
    this.radius = VsRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color borderColor;
  final Color backgroundColor;
  final bool shadow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow ? VsShadows.card : null,
      ),
      child: child,
    );
  }
}

class VsIconTile extends StatelessWidget {
  const VsIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
    this.iconSize = 20,
    this.backgroundAlpha = 0.12,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double backgroundAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

class VsStatTile extends StatelessWidget {
  const VsStatTile({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.caption,
    this.icon,
    this.dense = false,
  });

  final String value;
  final String label;
  final Color color;
  final String? caption;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return VsCard(
      padding: EdgeInsets.all(dense ? VsSpace.md : VsSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: VsText.display(
                    color: color,
                  ).copyWith(fontSize: dense ? 24 : 28, height: 1),
                ),
              ),
              if (icon != null) VsIconTile(icon: icon!, color: color, size: 34),
            ],
          ),
          SizedBox(height: dense ? VsSpace.xs : VsSpace.sm),
          Text(label, style: VsText.label(color: VsColors.slate700)),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(caption!, style: VsText.label(color: VsColors.slate400)),
          ],
        ],
      ),
    );
  }
}

class VsSegmentedControl extends StatelessWidget {
  const VsSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: VsColors.slate200,
        borderRadius: BorderRadius.circular(VsRadius.md),
      ),
      child: Row(
        children: options.map((option) {
          final selected = option == value;
          return Expanded(
            child: Material(
              color: selected ? VsColors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: selected ? null : () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: VsSpace.sm),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: selected ? VsShadows.card : null,
                  ),
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: VsText.body(
                      color: selected ? VsColors.brand : VsColors.slate600,
                      w: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class VsGradientHeader extends StatelessWidget {
  const VsGradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.icon,
    this.leading,
    this.trailing,
    this.topRow,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 18),
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;

  /// Optional row rendered above the title block. Use this when a screen needs
  /// its own custom chrome (avatar / bell / location chip) instead of the
  /// default leading-icon-title layout.
  final Widget? topRow;
  final Widget? bottom;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: VsGradients.hero,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: VsDotPatternPainter()),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (topRow != null) ...[
                    topRow!,
                    const SizedBox(height: VsSpace.md),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: VsSpace.md),
                      ],
                      if (icon != null) ...[
                        VsIconTile(
                          icon: icon!,
                          color: Colors.white,
                          backgroundAlpha: 0.16,
                        ),
                        const SizedBox(width: VsSpace.md),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (eyebrow != null) ...[
                              _HeaderEyebrow(label: eyebrow!),
                              const SizedBox(height: VsSpace.xs),
                            ],
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VsText.title(color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: VsText.body(
                                color: Colors.white.withValues(alpha: 0.74),
                                w: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: VsSpace.md),
                        trailing!,
                      ],
                    ],
                  ),
                  if (bottom != null) ...[
                    const SizedBox(height: VsSpace.lg),
                    bottom!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderEyebrow extends StatelessWidget {
  const _HeaderEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(VsRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label.toUpperCase(),
        style: VsText.label(
          color: Colors.white.withValues(alpha: 0.88),
          w: FontWeight.w800,
        ).copyWith(letterSpacing: 0.8),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tap-target primitives — use these instead of bare GestureDetector
// for back tiles, icon buttons, and text links so we get ripple,
// focus, and semantics for free.
// ─────────────────────────────────────────────────────────────

/// Translucent square back-tile sized for placement inside a hero header.
/// Defaults to the white-on-gradient treatment used in hero layouts; pass
/// [foreground] / [tint] to retune for a light surface.
class VsBackTile extends StatelessWidget {
  const VsBackTile({
    super.key,
    required this.onTap,
    this.tooltip = 'Back',
    this.foreground = Colors.white,
    this.tint,
    this.size = 40,
  });

  final VoidCallback onTap;
  final String tooltip;
  final Color foreground;

  /// Background tint of the tile. Defaults to a low-alpha tint of [foreground],
  /// which works on the hero gradient. For a light surface pass [VsColors.slate100].
  final Color? tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bg = tint ?? foreground.withValues(alpha: 0.14);
    final borderColor = foreground == Colors.white
        ? Colors.white.withValues(alpha: 0.18)
        : VsColors.border;
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(VsRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VsRadius.md),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VsRadius.md),
              border: Border.all(color: borderColor),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 20, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// Square icon button with Material ripple, focus, and a semantics label.
/// Use for chrome icons (notification bell, settings cog, etc).
class VsIconButton extends StatelessWidget {
  const VsIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.foreground = VsColors.slate900,
    this.tint,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color foreground;
  final Color? tint;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final bg = tint ?? Colors.transparent;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(VsRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VsRadius.md),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// Inline text link. Wraps [TextButton] so we get focus and ripple instead of
/// a bare [GestureDetector] around a [Text].
class VsTextLink extends StatelessWidget {
  const VsTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.dense = true,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final bool dense;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = (color ?? VsColors.brandDark);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: style,
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
            : null,
        minimumSize: dense ? const Size(0, 0) : null,
        tapTargetSize: dense
            ? MaterialTapTargetSize.shrinkWrap
            : MaterialTapTargetSize.padded,
      ),
      child: Text(label, style: VsText.label(color: style, w: FontWeight.w700)),
    );
  }
}

class VsDotPatternPainter extends CustomPainter {
  const VsDotPatternPainter({this.color = Colors.white, this.alpha = 0.07});

  final Color color;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    const spacing = 26.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(VsDotPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.alpha != alpha;
}
