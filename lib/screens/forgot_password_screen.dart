import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart' show AppColors;
import 'auth_widgets.dart';

// ─────────────────────────────────────────────────────────────
// Forgot Password Screen
// ─────────────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  String? _emailError;
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Email address is required';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  Future<void> _reset() async {
    final error = _validateEmail(_emailCtrl.text);
    setState(() => _emailError = error);
    if (error != null) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() { _loading = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Deep green hero zone ──
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
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
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
                    const SizedBox(height: 8),
                    // Eye logo
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
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.nunito(
                            fontSize: 20, fontWeight: FontWeight.w700),
                        children: const [
                          TextSpan(
                              text: 'Forgot ',
                              style: TextStyle(color: Colors.white)),
                          TextSpan(
                              text: 'Password?',
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── White form area ──
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24,
                  MediaQuery.of(context).viewInsets.bottom + 32),
              child: _sent
                  ? _SuccessView(email: _emailCtrl.text.trim())
                  : _FormView(
                      emailCtrl: _emailCtrl,
                      emailError: _emailError,
                      loading: _loading,
                      onEmailChanged: (_) =>
                          setState(() => _emailError = null),
                      onReset: _reset,
                      onBackToLogin: () => Navigator.of(context).pop(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form view ──
class _FormView extends StatelessWidget {
  const _FormView({
    required this.emailCtrl,
    required this.emailError,
    required this.loading,
    required this.onEmailChanged,
    required this.onReset,
    required this.onBackToLogin,
  });

  final TextEditingController emailCtrl;
  final String? emailError;
  final bool loading;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onReset;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reset your password',
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(
          'Enter the email address linked to your VisionScreen account and we\'ll send you a reset link.',
          style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textMuted, height: 1.6),
        ),
        const SizedBox(height: 32),

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
        const SizedBox(height: 32),

        AuthGreenPillButton(
          label: 'Reset Password',
          icon: Icons.lock_reset_rounded,
          loading: loading,
          onTap: onReset,
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

// ── Success view ──
class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email});
  final String email;

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
          child: const Icon(Icons.mark_email_read_outlined,
              size: 36, color: AppColors.green),
        ),
        const SizedBox(height: 20),
        Text('Check your inbox!',
            style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 10),
        Text(
          'A password reset link has been sent to\n$email',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textMuted, height: 1.6),
        ),
        const SizedBox(height: 32),
        AuthGreenPillButton(
          label: 'Back to Sign In',
          icon: Icons.login_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
