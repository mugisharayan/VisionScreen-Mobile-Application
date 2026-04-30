import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart' show AppColors;
import 'auth_widgets.dart';
import '../db/database_helper.dart';

// ─────────────────────────────────────────────────────────────
// Forgot Password Screen — 3 steps:
//   1. Enter email → verify exists in DB
//   2. Enter new password + confirm
//   3. Success view
// ─────────────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Step 1
  final _emailCtrl = TextEditingController();
  String? _emailError;
  bool _emailLoading = false;

  // Step 2
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _newPasswordError;
  String? _confirmPasswordError;
  bool _resetLoading = false;

  // Flow state
  int _step = 1; // 1 = email, 2 = new password, 3 = success
  String _verifiedEmail = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Email address is required';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
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

  Future<void> _verifyEmail() async {
    final error = _validateEmail(_emailCtrl.text);
    setState(() => _emailError = error);
    if (error != null) return;

    setState(() => _emailLoading = true);
    final email = _emailCtrl.text.trim().toLowerCase();
    final profile = await DatabaseHelper.instance.getChwProfileByEmail(email);
    if (!mounted) return;
    setState(() => _emailLoading = false);

    if (profile == null) {
      setState(() => _emailError = 'No account found with this email address');
      return;
    }

    setState(() {
      _verifiedEmail = email;
      _step = 2;
    });
  }

  Future<void> _resetPassword() async {
    setState(() {
      _newPasswordError = _validatePassword(_newPasswordCtrl.text);
      _confirmPasswordError = _validateConfirm(
          _newPasswordCtrl.text, _confirmPasswordCtrl.text);
    });
    if (_newPasswordError != null || _confirmPasswordError != null) return;

    setState(() => _resetLoading = true);
    final hashed = DatabaseHelper.hashPassword(_newPasswordCtrl.text);
    await DatabaseHelper.instance.updateChwPassword(_verifiedEmail, hashed);
    if (!mounted) return;
    setState(() {
      _resetLoading = false;
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Hero zone ──
          ClipPath(
            clipper: AuthWaveClipper(),
            child: Container(
              width: double.infinity,
              height: 360,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.greenDark, AppColors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: GestureDetector(
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pushReplacementNamed('/login');
                            }
                          },
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5),
                      ),
                      child: const Center(
                        child: CustomPaint(
                          size: Size(52, 52),
                          painter: AuthEyePainter(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.nunito(
                            fontSize: 38, fontWeight: FontWeight.w900),
                        children: const [
                          TextSpan(
                              text: 'Vision',
                              style: TextStyle(color: Colors.white)),
                          TextSpan(
                              text: 'Screen',
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.nunito(
                            fontSize: 18, fontWeight: FontWeight.w700),
                        children: const [
                          TextSpan(
                              text: 'Reset ',
                              style: TextStyle(color: Colors.white)),
                          TextSpan(
                              text: 'Password',
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final active = _step > i;
                        final current = _step == i + 1;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: current ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active || current
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form area ──
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24,
                  MediaQuery.of(context).viewInsets.bottom + 32),
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
                child: _step == 1
                    ? _EmailStep(
                        key: const ValueKey('step1'),
                        emailCtrl: _emailCtrl,
                        emailError: _emailError,
                        loading: _emailLoading,
                        onEmailChanged: (_) =>
                            setState(() => _emailError = null),
                        onSubmit: _verifyEmail,
                        onBackToLogin: () => Navigator.of(context).pop(),
                      )
                    : _step == 2
                        ? _NewPasswordStep(
                            key: const ValueKey('step2'),
                            newPasswordCtrl: _newPasswordCtrl,
                            confirmPasswordCtrl: _confirmPasswordCtrl,
                            newPasswordVisible: _newPasswordVisible,
                            confirmPasswordVisible: _confirmPasswordVisible,
                            newPasswordError: _newPasswordError,
                            confirmPasswordError: _confirmPasswordError,
                            loading: _resetLoading,
                            onToggleNew: () => setState(
                                () => _newPasswordVisible = !_newPasswordVisible),
                            onToggleConfirm: () => setState(() =>
                                _confirmPasswordVisible =
                                    !_confirmPasswordVisible),
                            onNewPasswordChanged: (_) =>
                                setState(() => _newPasswordError = null),
                            onConfirmPasswordChanged: (_) =>
                                setState(() => _confirmPasswordError = null),
                            onSubmit: _resetPassword,
                          )
                        : _SuccessStep(
                            key: const ValueKey('step3'),
                            onBackToLogin: () =>
                                Navigator.of(context).pop(),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Email verification ──
class _EmailStep extends StatelessWidget {
  const _EmailStep({
    super.key,
    required this.emailCtrl,
    required this.emailError,
    required this.loading,
    required this.onEmailChanged,
    required this.onSubmit,
    required this.onBackToLogin,
  });

  final TextEditingController emailCtrl;
  final String? emailError;
  final bool loading;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Find your account',
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(
          'Enter the email address linked to your VisionScreen account.',
          style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textMuted, height: 1.6),
        ),
        const SizedBox(height: 28),
        AuthUnderlineField(
          controller: emailCtrl,
          label: 'Email Address',
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
          loading: loading,
          onTap: onSubmit,
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: onBackToLogin,
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textMuted),
                children: [
                  const TextSpan(text: 'Remembered it? '),
                  TextSpan(
                    text: 'Sign In',
                    style: TextStyle(
                        color: AppColors.greenDark,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step 2: New password entry ──
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
        Text('Create new password',
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(
          'Your new password must be at least 8 characters.',
          style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textMuted, height: 1.6),
        ),
        const SizedBox(height: 28),
        AuthUnderlineField(
          controller: newPasswordCtrl,
          label: 'New Password',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscure: !newPasswordVisible,
          inputAction: TextInputAction.next,
          hasError: newPasswordError != null,
          errorText: newPasswordError,
          onChanged: onNewPasswordChanged,
          suffixIcon: GestureDetector(
            onTap: onToggleNew,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                newPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        AuthUnderlineField(
          controller: confirmPasswordCtrl,
          label: 'Confirm New Password',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          obscure: !confirmPasswordVisible,
          inputAction: TextInputAction.done,
          hasError: confirmPasswordError != null,
          errorText: confirmPasswordError,
          onChanged: onConfirmPasswordChanged,
          suffixIcon: GestureDetector(
            onTap: onToggleConfirm,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                confirmPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        AuthGreenPillButton(
          label: 'Reset Password',
          icon: Icons.lock_reset_rounded,
          loading: loading,
          onTap: onSubmit,
        ),
      ],
    );
  }
}

// ── Step 3: Success ──
class _SuccessStep extends StatelessWidget {
  const _SuccessStep({super.key, required this.onBackToLogin});
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.green.withValues(alpha: 0.3), width: 2),
          ),
          child: const Icon(Icons.check_rounded, size: 40, color: AppColors.green),
        ),
        const SizedBox(height: 20),
        Text('Password updated!',
            style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 10),
        Text(
          'Your password has been successfully reset.\nYou can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textMuted, height: 1.6),
        ),
        const SizedBox(height: 32),
        AuthGreenPillButton(
          label: 'Back to Sign In',
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
