import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_widgets.dart';
import '../repositories/auth_repository.dart';
import '../utils/app_theme.dart';
import '../widgets/vs_auth_hero.dart';
import '../widgets/vs_ui.dart';

// ─────────────────────────────────────────────────────────────
// Forgot Password Screen — 4 steps:
//   1. Enter email without confirming account existence
//   2. Confirm the phone number on file
//   3. Enter and confirm a new password
//   4. Success view
// ─────────────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Step 1: email
  final _emailCtrl = TextEditingController();
  String? _emailError;

  // Step 2: phone challenge
  final _phoneCtrl = TextEditingController();
  String? _phoneError;
  bool _phoneLoading = false;

  // Step 3: new password
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _newPasswordError;
  String? _confirmPasswordError;
  bool _resetLoading = false;

  // Flow state
  int _step = 1;
  String _verifiedEmail = '';
  String? _resetToken;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Email address is required';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateConfirm(String password, String confirm) {
    if (confirm.isEmpty) return 'Please confirm your password';
    if (confirm != password) return 'Passwords do not match';
    return null;
  }

  Future<void> _submitEmail() async {
    final error = _validateEmail(_emailCtrl.text);
    setState(() => _emailError = error);
    if (error != null) return;

    setState(() {
      _verifiedEmail = _emailCtrl.text.trim().toLowerCase();
      _step = 2;
    });
  }

  Future<void> _submitPhone() async {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) {
      setState(() => _phoneError = 'Enter the 9-digit number on file');
      return;
    }
    setState(() {
      _phoneError = null;
      _phoneLoading = true;
    });
    final token = await AuthRepository.instance.verifyResetIdentity(
      email: _verifiedEmail,
      phone: digits,
    );
    if (!mounted) return;
    setState(() => _phoneLoading = false);
    if (token == null) {
      setState(
        () => _phoneError =
            'We could not verify those details. Check the email and phone number.',
      );
      return;
    }
    setState(() {
      _resetToken = token;
      _step = 3;
    });
  }

  Future<void> _resetPassword() async {
    setState(() {
      _newPasswordError = _validatePassword(_newPasswordCtrl.text);
      _confirmPasswordError = _validateConfirm(
        _newPasswordCtrl.text,
        _confirmPasswordCtrl.text,
      );
    });
    if (_newPasswordError != null || _confirmPasswordError != null) return;
    final token = _resetToken;
    if (token == null) {
      setState(() => _step = 1);
      return;
    }

    setState(() => _resetLoading = true);
    final ok = await AuthRepository.instance.resetPasswordWithToken(
      email: _verifiedEmail,
      token: token,
      newPassword: _newPasswordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _resetLoading = false);
    if (!ok) {
      setState(() {
        _newPasswordError =
            'Reset session expired. Start again from your email.';
        _resetToken = null;
        _step = 1;
      });
      return;
    }
    setState(() => _step = 4);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: VsColors.card,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          VsAuthHero(
            compact: keyboardOpen,
            title: 'Reset password',
            subtitle: 'Verify your account and choose a new password',
            leading: VsBackTile(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ),
          if (!keyboardOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: _ResetStepIndicator(step: _step),
            ),

          // ── Form area ──
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: switch (_step) {
                  1 => _EmailStep(
                    key: const ValueKey('step1'),
                    emailCtrl: _emailCtrl,
                    emailError: _emailError,
                    onEmailChanged: (_) => setState(() => _emailError = null),
                    onSubmit: _submitEmail,
                    onBackToLogin: () => Navigator.of(context).pop(),
                  ),
                  2 => _PhoneStep(
                    key: const ValueKey('step2'),
                    phoneCtrl: _phoneCtrl,
                    phoneError: _phoneError,
                    loading: _phoneLoading,
                    onPhoneChanged: (_) => setState(() => _phoneError = null),
                    onSubmit: _submitPhone,
                    onChangeEmail: () => setState(() {
                      _step = 1;
                      _phoneError = null;
                      _phoneCtrl.clear();
                    }),
                  ),
                  3 => _NewPasswordStep(
                    key: const ValueKey('step3'),
                    newPasswordCtrl: _newPasswordCtrl,
                    confirmPasswordCtrl: _confirmPasswordCtrl,
                    newPasswordVisible: _newPasswordVisible,
                    confirmPasswordVisible: _confirmPasswordVisible,
                    newPasswordError: _newPasswordError,
                    confirmPasswordError: _confirmPasswordError,
                    loading: _resetLoading,
                    onToggleNew: () => setState(
                      () => _newPasswordVisible = !_newPasswordVisible,
                    ),
                    onToggleConfirm: () => setState(
                      () => _confirmPasswordVisible = !_confirmPasswordVisible,
                    ),
                    onNewPasswordChanged: (_) =>
                        setState(() => _newPasswordError = null),
                    onConfirmPasswordChanged: (_) =>
                        setState(() => _confirmPasswordError = null),
                    onSubmit: _resetPassword,
                  ),
                  _ => _SuccessStep(
                    key: const ValueKey('step4'),
                    onBackToLogin: () => Navigator.of(context).pop(),
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetStepIndicator extends StatelessWidget {
  const _ResetStepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Email', 'Identity', 'Reset', 'Done'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = step >= index + 1;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? VsColors.brandFaint : VsColors.slate50,
              borderRadius: BorderRadius.circular(VsRadius.pill),
              border: Border.all(
                color: active ? VsColors.brandLight : VsColors.border,
              ),
            ),
            child: Text(
              labels[index],
              textAlign: TextAlign.center,
              style: VsText.label(
                color: active ? VsColors.brandDark : VsColors.slate400,
                w: FontWeight.w700,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Step 1: Email verification ──
class _EmailStep extends StatelessWidget {
  const _EmailStep({
    super.key,
    required this.emailCtrl,
    required this.emailError,
    required this.onEmailChanged,
    required this.onSubmit,
    required this.onBackToLogin,
  });

  final TextEditingController emailCtrl;
  final String? emailError;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start password reset',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: VsColors.slate900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your VisionScreen email. You will confirm the phone number next.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: VsColors.slate500,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        AuthUnderlineField(
          controller: emailCtrl,
          label: 'Email address',
          hint: 'yourname@gmail.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          inputAction: TextInputAction.done,
          hasError: emailError != null,
          errorText: emailError,
          onChanged: onEmailChanged,
        ),
        const SizedBox(height: 28),
        AuthGreenPillButton(
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onTap: onSubmit,
        ),
        const SizedBox(height: 24),
        Center(
          child: VsTextLink(label: 'Back to sign in', onTap: onBackToLogin),
        ),
      ],
    );
  }
}

// ── Step 2: Identity challenge (phone-on-file) ──
class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    super.key,
    required this.phoneCtrl,
    required this.phoneError,
    required this.loading,
    required this.onPhoneChanged,
    required this.onSubmit,
    required this.onChangeEmail,
  });

  final TextEditingController phoneCtrl;
  final String? phoneError;
  final bool loading;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onSubmit;
  final VoidCallback onChangeEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm your identity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: VsColors.slate900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the Uganda phone number on file for this account. '
          'We use this to verify identity before changing the password.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: VsColors.slate500,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        AuthUnderlineField(
          controller: phoneCtrl,
          label: 'Phone on file',
          hint: '7XX XXX XXX',
          prefixIcon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
          inputAction: TextInputAction.done,
          hasError: phoneError != null,
          errorText: phoneError,
          onChanged: onPhoneChanged,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
        ),
        const SizedBox(height: 28),
        AuthGreenPillButton(
          label: 'Verify',
          icon: Icons.shield_outlined,
          loading: loading,
          onTap: onSubmit,
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: onChangeEmail,
            child: Text(
              'Use a different email',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: VsColors.brandDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step 3: New password entry ──
class _NewPasswordStep extends StatelessWidget {
  const _NewPasswordStep({
    super.key,
    required this.newPasswordCtrl,
    required this.confirmPasswordCtrl,
    required this.newPasswordVisible,
    required this.confirmPasswordVisible,
    required this.newPasswordError,
    required this.confirmPasswordError,
    required this.loading,
    required this.onToggleNew,
    required this.onToggleConfirm,
    required this.onNewPasswordChanged,
    required this.onConfirmPasswordChanged,
    required this.onSubmit,
  });

  final TextEditingController newPasswordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final bool newPasswordVisible;
  final bool confirmPasswordVisible;
  final String? newPasswordError;
  final String? confirmPasswordError;
  final bool loading;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConfirm;
  final ValueChanged<String> onNewPasswordChanged;
  final ValueChanged<String> onConfirmPasswordChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create new password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: VsColors.slate900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your new password must be at least 8 characters.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: VsColors.slate500,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        AuthUnderlineField(
          controller: newPasswordCtrl,
          label: 'New password',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscure: !newPasswordVisible,
          inputAction: TextInputAction.next,
          hasError: newPasswordError != null,
          errorText: newPasswordError,
          onChanged: onNewPasswordChanged,
          suffixIcon: AuthPasswordVisibilityButton(
            visible: newPasswordVisible,
            onTap: onToggleNew,
          ),
        ),
        const SizedBox(height: 20),
        AuthUnderlineField(
          controller: confirmPasswordCtrl,
          label: 'Confirm new password',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscure: !confirmPasswordVisible,
          inputAction: TextInputAction.done,
          hasError: confirmPasswordError != null,
          errorText: confirmPasswordError,
          onChanged: onConfirmPasswordChanged,
          suffixIcon: AuthPasswordVisibilityButton(
            visible: confirmPasswordVisible,
            onTap: onToggleConfirm,
          ),
        ),
        const SizedBox(height: 28),
        AuthGreenPillButton(
          label: 'Reset password',
          icon: Icons.lock_reset_rounded,
          loading: loading,
          onTap: onSubmit,
        ),
      ],
    );
  }
}

// ── Step 4: Success ──
class _SuccessStep extends StatelessWidget {
  const _SuccessStep({super.key, required this.onBackToLogin});
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: VsColors.brand.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: VsColors.brand.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 40,
            color: VsColors.brand,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Password updated',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: VsColors.slate900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your password has been successfully reset.\nYou can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: VsColors.slate500,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        AuthGreenPillButton(
          label: 'Back to sign in',
          icon: Icons.login_rounded,
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
      ],
    );
  }
}
