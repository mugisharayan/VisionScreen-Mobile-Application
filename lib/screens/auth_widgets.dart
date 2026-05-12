import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_theme.dart';

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
        ? VsColors.rose
        : _focused
        ? VsColors.brand
        : VsColors.border;
    final iconColor = _focused ? VsColors.brand : VsColors.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: VsText.label()),
        const SizedBox(height: VsSpace.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.prefixIcon != null) ...[
              Icon(widget.prefixIcon, size: 16, color: iconColor),
              const SizedBox(width: VsSpace.sm),
            ],
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                obscureText: widget.obscure,
                keyboardType: widget.keyboardType,
                textInputAction: widget.inputAction,
                onChanged: widget.onChanged,
                style: VsText.body(color: VsColors.text, w: FontWeight.w500),
                cursorColor: VsColors.brand,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: VsText.body(color: VsColors.subtle),
                  suffixIcon: widget.suffixIcon,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: VsSpace.sm,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 2,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(VsRadius.pill),
          ),
        ),
        if (widget.hasError && widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: VsSpace.xs + 1),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 12,
                  color: VsColors.rose,
                ),
                const SizedBox(width: VsSpace.xs),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: VsText.label(
                      color: VsColors.rose,
                      w: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

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
    final background = widget.loading
        ? VsColors.brand.withValues(alpha: 0.55)
        : VsColors.brand;

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.loading) {
          setState(() => _pressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.loading) return;
        setState(() => _pressed = false);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: VsSpace.xl),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(VsRadius.pill),
            boxShadow: VsShadows.elevated,
          ),
          child: widget.loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: Colors.white),
                      const SizedBox(width: VsSpace.sm),
                    ],
                    Text(widget.label, style: VsText.button()),
                  ],
                ),
        ),
      ),
    );
  }
}
