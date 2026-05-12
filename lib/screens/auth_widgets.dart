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
    this.autofillHints,
    this.inputFormatters,
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
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

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
    final iconColor = _focused ? VsColors.brand : VsColors.slate500;

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
                enableSuggestions: !widget.obscure,
                autocorrect: !widget.obscure,
                keyboardType: widget.keyboardType,
                textInputAction: widget.inputAction,
                autofillHints: widget.autofillHints,
                onChanged: widget.onChanged,
                inputFormatters: widget.inputFormatters,
                style: VsText.body(
                  color: VsColors.slate900,
                  w: FontWeight.w500,
                ),
                cursorColor: VsColors.brand,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: VsText.body(color: VsColors.slate400),
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

class AuthGreenPillButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final background = loading
        ? VsColors.brand.withValues(alpha: 0.55)
        : VsColors.brand;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onTap();
              },
        style:
            ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: background,
              disabledBackgroundColor: background,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VsRadius.pill),
              ),
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: 0.08),
              ),
            ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: VsSpace.sm),
                  ],
                  Text(label, style: VsText.button()),
                ],
              ),
      ),
    );
  }
}

class AuthPasswordVisibilityButton extends StatelessWidget {
  const AuthPasswordVisibilityButton({
    super.key,
    required this.visible,
    required this.onTap,
  });

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: visible ? 'Hide password' : 'Show password',
      onPressed: onTap,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.padded,
        foregroundColor: VsColors.slate500,
      ),
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 18,
      ),
    );
  }
}
