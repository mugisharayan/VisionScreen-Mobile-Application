import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart' show AppColors;

// ─────────────────────────────────────────────────────────────
// Shared Auth Widgets — used by login & forgot password screens
// ─────────────────────────────────────────────────────────────

// Curved wave clipper
class AuthWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
        size.width * 0.75, size.height - 40, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(AuthWaveClipper old) => false;
}

// Eye painter for hero zones
class AuthEyePainter extends CustomPainter {
  const AuthEyePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.9,
          height: size.height * 0.52),
      paint,
    );
    canvas.drawCircle(Offset(cx, cy), size.width * 0.18, paint);
    canvas.drawCircle(
        Offset(cx, cy), size.width * 0.09, Paint()..color = color);
    canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.04,
        Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(AuthEyePainter old) => old.color != color;
}

// Underline-only input field (green focus)
class AuthUnderlineField extends StatefulWidget {
  const AuthUnderlineField({
    super.key,
    required this.controller,
    required this.hint,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.inputAction = TextInputAction.next,
    this.suffixIcon,
    this.hasError = false,
    this.errorText,
    this.onChanged,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction inputAction;
  final Widget? suffixIcon;
  final bool hasError;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;

  @override
  State<AuthUnderlineField> createState() => _AuthUnderlineFieldState();
}

class _AuthUnderlineFieldState extends State<AuthUnderlineField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = widget.hasError
        ? const Color(0xFFEF4444)
        : _focused
            ? AppColors.green
            : AppColors.borderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.prefixIcon != null) ...[
              Icon(widget.prefixIcon,
                  size: 16,
                  color: _focused ? AppColors.green : AppColors.textMuted),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                obscureText: widget.obscure,
                keyboardType: widget.keyboardType,
                textInputAction: widget.inputAction,
                onChanged: widget.onChanged,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark),
                cursorColor: AppColors.green,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textMuted.withValues(alpha: 0.5)),
                  suffixIcon: widget.suffixIcon,
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 2,
          decoration: BoxDecoration(
              color: lineColor, borderRadius: BorderRadius.circular(99)),
        ),
        if (widget.hasError && widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 12, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Text(widget.errorText!,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFFEF4444),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
      ],
    );
  }
}

// Full-width green pill button
class AuthGreenPillButton extends StatefulWidget {
  const AuthGreenPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;
  final IconData? icon;

  @override
  State<AuthGreenPillButton> createState() => _AuthGreenPillButtonState();
}

class _AuthGreenPillButtonState extends State<AuthGreenPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.loading) setState(() => _pressed = true);
      },
      onTapUp: (_) {
        if (widget.loading) return;
        setState(() => _pressed = false);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.loading
                  ? [
                      AppColors.green.withValues(alpha: 0.5),
                      AppColors.greenDark.withValues(alpha: 0.5)
                    ]
                  : [AppColors.green, AppColors.greenDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: widget.loading
              ? const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text(widget.label,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3)),
                  ],
                ),
        ),
      ),
    );
  }
}
