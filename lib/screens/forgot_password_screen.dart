import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart' show AppColors;
import 'auth_widgets.dart';
import '../db/database_helper.dart';
import '../repositories/auth_repository.dart';
import '../widgets/vs_logo.dart';

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

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  // ── Animations ────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _shimmerCtrl;
  late final Animation<double>   _logoScale;
  late final Animation<double>   _shimmerAnim;

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
  int _step = 1;
  String _verifiedEmail = '';

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 200),
        () { if (mounted) _logoCtrl.forward(); });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _shimmerCtrl.dispose();
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
    await AuthRepository.instance.resetPassword(
      _verifiedEmail,
      _newPasswordCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _resetLoading = false;
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Hero zone — teal gradient ──
          ClipPath(
            clipper: AuthWaveClipper(),
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF134E4A), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _ForgotDotPainter()),
                  ),
                  Positioned(
                    top: -40, right: -40,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                            width: 1)),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: SizedBox.expand(
                      child: Stack(
                        children: [
                          // Back button — pinned top-left, doesn't affect centering
                          Positioned(
                            top: 4, left: 16,
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
                          // Centered content
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo — elastic scale + animated blink (same as login)
                                ScaleTransition(
                                  scale: _logoScale,
                                  child: Container(
                                    width: 88, height: 88,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.35),
                                          width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.18),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: VsLogoAnimated(size: 50, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // App name with shimmer (same as login)
                                AnimatedBuilder(
                                  animation: _shimmerAnim,
                                  builder: (_, child) => ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.65),
                                        Colors.white,
                                        Colors.white.withValues(alpha: 0.65),
                                      ],
                                      stops: [
                                        (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                                        _shimmerAnim.value.clamp(0.0, 1.0),
                                        (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                                      ],
                                    ).createShader(bounds),
                                    child: child!,
                                  ),
                                  child: Text(
                                    'VisionScreen',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('Reset Password',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 14),
                                // Step dots
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
                        ],
                      ),
                    ),
                  ),
                ],
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
            style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(
          'Enter the email address linked to your VisionScreen account.',
          style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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
            style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(
          'Your new password must be at least 8 characters.',
          style: GoogleFonts.inter(
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
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 10),
        Text(
          'Your password has been successfully reset.\nYou can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
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


// ── Dot pattern painter ──────────────────────────────────────
class _ForgotDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.6, p);
      }
    }
  }
  @override
  bool shouldRepaint(_ForgotDotPainter old) => false;
}

