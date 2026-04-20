import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart' show AppColors;

// ─────────────────────────────────────────────────────────────
// Login Screen — Login + Sign Up tabs
// ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _scrollCtrl = ScrollController();
  bool _heroVisible = true;

  // Login form
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  bool _loginPasswordVisible = false;
  String _selectedRole = 'chw'; // 'chw' | 'admin'
  String? _loginEmailError;
  String? _loginPasswordError;

  // Login form extras
  bool _rememberMe = false;
  bool _loginLoading = false;

  // Sign up form
  final _signUpNameCtrl = TextEditingController();
  final _signUpCentreCtrl = TextEditingController();
  final _signUpDistrictCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPhoneCtrl = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();
  final _signUpConfirmPasswordCtrl = TextEditingController();
  bool _signUpPasswordVisible = false;
  bool _signUpConfirmPasswordVisible = false;
  bool _termsAgreed = false;
  String? _signUpNameError;
  String? _signUpCentreError;
  String? _signUpDistrictError;
  String? _signUpEmailError;
  String? _signUpPhoneError;
  String? _signUpPasswordError;
  String? _signUpConfirmPasswordError;
  String _signUpPasswordValue = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _scrollCtrl.addListener(() {
      final shouldHide = _scrollCtrl.offset > 10;
      if (shouldHide != !_heroVisible) {
        setState(() => _heroVisible = !shouldHide);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signUpNameCtrl.dispose();
    _signUpCentreCtrl.dispose();
    _signUpDistrictCtrl.dispose();
    _signUpEmailCtrl.dispose();
    _signUpPhoneCtrl.dispose();
    _signUpPasswordCtrl.dispose();
    _signUpConfirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loginEmailError = _validateEmail(_loginEmailCtrl.text);
      _loginPasswordError = _validatePassword(_loginPasswordCtrl.text);
    });
    if (_loginEmailError != null || _loginPasswordError != null) return;
    setState(() => _loginLoading = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login_time',
        DateTime.now().toLocal().toString().substring(0, 16));
    await prefs.setString('last_login_role',
        _selectedRole == 'chw' ? 'Community Health Worker' : 'Administrator');
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _signUp() {
    if (!_termsAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink2,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Text(
            'Please read and agree to the Terms of Service & Privacy Policy.',
            style: GoogleFonts.sora(
              fontSize: 12,
              color: const Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      _signUpNameError = _validateRequired(_signUpNameCtrl.text, 'Full name');
      _signUpCentreError = _validateRequired(
        _signUpCentreCtrl.text,
        'Health center',
      );
      _signUpDistrictError = _validateRequired(
        _signUpDistrictCtrl.text,
        'District',
      );
      _signUpEmailError = _validateEmail(_signUpEmailCtrl.text);
      _signUpPhoneError = _validatePhone(_signUpPhoneCtrl.text);
      _signUpPasswordError = _validatePassword(_signUpPasswordCtrl.text);
      _signUpConfirmPasswordError = _validateConfirmPassword(
        _signUpPasswordCtrl.text,
        _signUpConfirmPasswordCtrl.text,
      );
    });
    if (_signUpNameError != null ||
        _signUpCentreError != null ||
        _signUpDistrictError != null ||
        _signUpEmailError != null ||
        _signUpPhoneError != null ||
        _signUpPasswordError != null ||
        _signUpConfirmPasswordError != null) {
      return;
    }
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // ── Validators ───────────────────────────────────────────
  String? _validateRequired(String value, String fieldName) {
    if (value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Email address is required';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');
    if (!emailRegex.hasMatch(value.trim()))
      return 'Enter a valid email address';
    const allowedDomains = [
      'gmail.com',
      'yahoo.com',
      'yahoo.co.uk',
      'outlook.com',
      'hotmail.com',
      'live.com',
      'icloud.com',
      'me.com',
      'protonmail.com',
      'proton.me',
      'aol.com',
      'zoho.com',
      'yandex.com',
      'gmx.com',
      'mail.com',
    ];
    final domain = value.trim().split('@').last.toLowerCase();
    if (!allowedDomains.contains(domain)) {
      return 'Use a standard email (e.g. Gmail, Yahoo, Outlook)';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validatePhone(String value) {
    if (value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (digits.length != 9) return 'Enter a valid 9-digit Uganda number';
    final prefix = digits.substring(0, 3);
    const mtn = [
      '770',
      '771',
      '772',
      '773',
      '774',
      '775',
      '776',
      '777',
      '778',
      '779',
      '780',
      '781',
      '782',
      '783',
      '784',
      '785',
      '786',
      '787',
      '788',
      '789',
      '760',
      '761',
      '762',
      '763',
      '764',
      '790',
      '310',
      '311',
      '312',
      '313',
      '314',
      '315',
      '316',
      '317',
      '318',
      '319',
      '390',
      '391',
      '392',
      '393',
      '394',
      '395',
      '396',
      '397',
      '398',
      '399',
    ];
    const airtel = [
      '700',
      '701',
      '702',
      '703',
      '704',
      '705',
      '706',
      '707',
      '708',
      '709',
      '750',
      '751',
      '752',
      '753',
      '754',
      '755',
      '756',
      '757',
      '758',
      '759',
      '740',
      '200',
      '201',
      '202',
      '203',
      '204',
      '205',
      '206',
      '207',
      '208',
      '209',
    ];
    if (!mtn.contains(prefix) && !airtel.contains(prefix)) {
      return 'Invalid Uganda network prefix (MTN or Airtel)';
    }
    return null;
  }

  String? _validateConfirmPassword(String password, String confirm) {
    if (confirm.isEmpty) return 'Please confirm your password';
    if (confirm != password) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Grid + mesh background ──
          CustomPaint(painter: _LoginGridPainter()),
          CustomPaint(painter: _LoginMeshPainter()),
          // ── Floating glowing orbs ──
          Positioned(
            top: -80,
            left: -60,
            child: _GlowOrb(color: AppColors.teal, size: 260),
          ),
          Positioned(
            bottom: 80,
            right: -80,
            child: _GlowOrb(color: AppColors.sky, size: 200),
          ),
          Positioned(
            top: 300,
            right: -40,
            child: _GlowOrb(color: AppColors.teal2, size: 140),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ──
                _AuthHeader(),
                // ── Scrollable body ──
                Expanded(
                  child: _GlassCard(
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TabSwitcher(controller: _tabCtrl),
                          const SizedBox(height: 22),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
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
                            child: _tabCtrl.index == 0
                                ? _LoginForm(
                                    key: const ValueKey('login'),
                                    emailCtrl: _loginEmailCtrl,
                                    passwordCtrl: _loginPasswordCtrl,
                                    passwordVisible: _loginPasswordVisible,
                                    selectedRole: _selectedRole,
                                    emailError: _loginEmailError,
                                    passwordError: _loginPasswordError,
                                    rememberMe: _rememberMe,
                                    loading: _loginLoading,
                                    onRoleChanged: (r) =>
                                        setState(() => _selectedRole = r),
                                    onTogglePassword: () => setState(
                                      () => _loginPasswordVisible =
                                          !_loginPasswordVisible,
                                    ),
                                    onEmailChanged: (_) =>
                                        setState(() => _loginEmailError = null),
                                    onPasswordChanged: (_) => setState(
                                      () => _loginPasswordError = null,
                                    ),
                                    onRememberMeChanged: (v) =>
                                        setState(() => _rememberMe = v),
                                    onLogin: _login,
                                  )
                                : _SignUpForm(
                                    key: const ValueKey('signup'),
                                    nameCtrl: _signUpNameCtrl,
                                    centreCtrl: _signUpCentreCtrl,
                                    districtCtrl: _signUpDistrictCtrl,
                                    emailCtrl: _signUpEmailCtrl,
                                    phoneCtrl: _signUpPhoneCtrl,
                                    passwordCtrl: _signUpPasswordCtrl,
                                    confirmPasswordCtrl:
                                        _signUpConfirmPasswordCtrl,
                                    passwordVisible: _signUpPasswordVisible,
                                    confirmPasswordVisible:
                                        _signUpConfirmPasswordVisible,
                                    passwordValue: _signUpPasswordValue,
                                    nameError: _signUpNameError,
                                    centreError: _signUpCentreError,
                                    districtError: _signUpDistrictError,
                                    emailError: _signUpEmailError,
                                    phoneError: _signUpPhoneError,
                                    passwordError: _signUpPasswordError,
                                    confirmPasswordError:
                                        _signUpConfirmPasswordError,
                                    onTogglePassword: () => setState(
                                      () => _signUpPasswordVisible =
                                          !_signUpPasswordVisible,
                                    ),
                                    onToggleConfirmPassword: () => setState(
                                      () => _signUpConfirmPasswordVisible =
                                          !_signUpConfirmPasswordVisible,
                                    ),
                                    termsAgreed: _termsAgreed,
                                    onTermsAgreedChanged: (v) =>
                                        setState(() => _termsAgreed = v),
                                    onNameChanged: (_) =>
                                        setState(() => _signUpNameError = null),
                                    onCentreChanged: (_) => setState(
                                      () => _signUpCentreError = null,
                                    ),
                                    onDistrictChanged: (_) => setState(
                                      () => _signUpDistrictError = null,
                                    ),
                                    onEmailChanged: (_) => setState(
                                      () => _signUpEmailError = null,
                                    ),
                                    onPhoneChanged: (_) => setState(
                                      () => _signUpPhoneError = null,
                                    ),
                                    onPasswordChanged: (v) => setState(() {
                                      _signUpPasswordError = null;
                                      _signUpPasswordValue = v;
                                    }),
                                    onConfirmPasswordChanged: (_) => setState(
                                      () => _signUpConfirmPasswordError = null,
                                    ),
                                    onSignUp: _signUp,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dark hero header — logo + app name only, top-left aligned
// Smoothly disappears when Sign Up tab is active or keyboard opens
// ─────────────────────────────────────────────────────────────
class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo row ──
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.ink2, AppColors.ink3],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(26, 26),
                    painter: _HeaderEyePainter(),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 26,
                        color: Colors.white,
                        letterSpacing: -0.8,
                      ),
                      children: const [
                        TextSpan(text: 'Vision'),
                        TextSpan(
                          text: 'Screen',
                          style: TextStyle(color: AppColors.teal3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Teal divider ──
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.teal.withValues(alpha: 0.6),
                  AppColors.teal.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab switcher — Login / Sign Up
// ─────────────────────────────────────────────────────────────
class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: TabBar(
            controller: controller,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.teal2],
              ),
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelPadding: EdgeInsets.zero,
            tabs: [
              _buildTab('Login', controller.index == 0),
              _buildTab('Sign Up', controller.index == 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Tab(
      child: Text(
        label,
        style: GoogleFonts.sora(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: active
              ? Colors.white
              : AppColors.teal3.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Login form
// ─────────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  const _LoginForm({
    super.key,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.passwordVisible,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onTogglePassword,
    required this.onLogin,
    required this.rememberMe,
    required this.loading,
    required this.onRememberMeChanged,
    this.emailError,
    this.passwordError,
    this.onEmailChanged,
    this.onPasswordChanged,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool passwordVisible;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final bool rememberMe;
  final bool loading;
  final ValueChanged<bool> onRememberMeChanged;
  final String? emailError;
  final String? passwordError;
  final ValueChanged<String>? onEmailChanged;
  final ValueChanged<String>? onPasswordChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: 'Login as'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _RoleButton(
                icon: Icons.person_outline_rounded,
                label: 'Community\nHealth Worker',
                active: selectedRole == 'chw',
                onTap: () => onRoleChanged('chw'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RoleButton(
                icon: Icons.shield_outlined,
                label: 'Administrator',
                active: selectedRole == 'admin',
                onTap: () => onRoleChanged('admin'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _FieldLabel(label: 'Email Address'),
        const SizedBox(height: 4),
        _InputField(
          controller: emailCtrl,
          hint: 'yourname@gmail.com',
          prefix: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          inputAction: TextInputAction.next,
          hasError: emailError != null,
          isValid: emailError == null && emailCtrl.text.isNotEmpty,
          onChanged: onEmailChanged,
        ),
        _ErrorText(error: emailError),
        const SizedBox(height: 10),
        _FieldLabel(label: 'Password'),
        const SizedBox(height: 4),
        _InputField(
          controller: passwordCtrl,
          hint: '••••••••',
          prefix: Icons.lock_outline_rounded,
          obscure: !passwordVisible,
          inputAction: TextInputAction.done,
          hasError: passwordError != null,
          onChanged: onPasswordChanged,
          suffix: GestureDetector(
            onTap: onTogglePassword,
            child: Icon(
              passwordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF8FA0B4),
            ),
          ),
        ),
        _ErrorText(error: passwordError),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () => onRememberMeChanged(!rememberMe),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: rememberMe ? AppColors.teal : AppColors.ink2,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: rememberMe
                            ? AppColors.teal
                            : AppColors.teal.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: rememberMe
                        ? const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Remember me',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: AppColors.teal3.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Forgot password?',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Login',
          icon: Icons.login_rounded,
          loading: loading,
          onTap: onLogin,
        ),
        const SizedBox(height: 16),
        _OfflineNote(),
        const SizedBox(height: 14),
        _VersionFooter(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sign Up form
// ─────────────────────────────────────────────────────────────
class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    super.key,
    required this.nameCtrl,
    required this.centreCtrl,
    required this.districtCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSignUp,
    required this.passwordValue,
    required this.termsAgreed,
    required this.onTermsAgreedChanged,
    this.nameError,
    this.centreError,
    this.districtError,
    this.emailError,
    this.phoneError,
    this.passwordError,
    this.confirmPasswordError,
    this.onNameChanged,
    this.onCentreChanged,
    this.onDistrictChanged,
    this.onEmailChanged,
    this.onPhoneChanged,
    this.onPasswordChanged,
    this.onConfirmPasswordChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController centreCtrl;
  final TextEditingController districtCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final String passwordValue;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSignUp;
  final bool termsAgreed;
  final ValueChanged<bool> onTermsAgreedChanged;
  final String? nameError;
  final String? centreError;
  final String? districtError;
  final String? emailError;
  final String? phoneError;
  final String? passwordError;
  final String? confirmPasswordError;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onCentreChanged;
  final ValueChanged<String>? onDistrictChanged;
  final ValueChanged<String>? onEmailChanged;
  final ValueChanged<String>? onPhoneChanged;
  final ValueChanged<String>? onPasswordChanged;
  final ValueChanged<String>? onConfirmPasswordChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: 'Full Name'),
        const SizedBox(height: 4),
        _InputField(
          controller: nameCtrl,
          hint: 'Your full name',
          prefix: Icons.person_outline_rounded,
          inputAction: TextInputAction.next,
          hasError: nameError != null,
          onChanged: onNameChanged,
        ),
        _ErrorText(error: nameError),
        const SizedBox(height: 10),
        _FieldLabel(label: 'Health Center'),
        const SizedBox(height: 4),
        _InputField(
          controller: centreCtrl,
          hint: 'e.g. Nakawa HC III, Wakiso District',
          prefix: Icons.local_hospital_outlined,
          inputAction: TextInputAction.next,
          hasError: centreError != null,
          onChanged: onCentreChanged,
        ),
        _ErrorText(error: centreError),
        const SizedBox(height: 10),
        _FieldLabel(label: 'District'),
        const SizedBox(height: 4),
        _InputField(
          controller: districtCtrl,
          hint: 'e.g. Kampala',
          prefix: Icons.location_on_outlined,
          inputAction: TextInputAction.next,
          hasError: districtError != null,
          onChanged: onDistrictChanged,
        ),
        _ErrorText(error: districtError),
        const SizedBox(height: 10),
        _FieldLabel(label: 'Email Address'),
        const SizedBox(height: 4),
        _InputField(
          controller: emailCtrl,
          hint: 'yourname@gmail.com',
          prefix: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          inputAction: TextInputAction.next,
          hasError: emailError != null,
          isValid: emailError == null && emailCtrl.text.isNotEmpty,
          onChanged: onEmailChanged,
        ),
        _ErrorText(error: emailError),
        const SizedBox(height: 10),
        _FieldLabel(label: 'Phone Number'),
        const SizedBox(height: 4),
        _UgandaPhoneField(
          controller: phoneCtrl,
          hasError: phoneError != null,
          onChanged: onPhoneChanged,
        ),
        _ErrorText(error: phoneError),
        const SizedBox(height: 10),
        _FieldLabel(label: 'Password'),
        const SizedBox(height: 4),
        _InputField(
          controller: passwordCtrl,
          hint: 'Create a strong password',
          prefix: Icons.lock_outline_rounded,
          obscure: !passwordVisible,
          inputAction: TextInputAction.next,
          hasError: passwordError != null,
          isValid: passwordError == null && passwordCtrl.text.length >= 8,
          onChanged: onPasswordChanged,
          suffix: GestureDetector(
            onTap: onTogglePassword,
            child: Icon(
              passwordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF8FA0B4),
            ),
          ),
        ),
        _ErrorText(error: passwordError),
        if (passwordValue.isNotEmpty) ...[
          const SizedBox(height: 6),
          _PasswordStrength(password: passwordValue),
        ],
        const SizedBox(height: 10),
        _FieldLabel(label: 'Confirm Password'),
        const SizedBox(height: 4),
        _InputField(
          controller: confirmPasswordCtrl,
          hint: 'Re-enter your password',
          prefix: Icons.lock_outline_rounded,
          obscure: !confirmPasswordVisible,
          inputAction: TextInputAction.done,
          hasError: confirmPasswordError != null,
          isValid:
              confirmPasswordError == null &&
              confirmPasswordCtrl.text.isNotEmpty &&
              confirmPasswordCtrl.text == passwordCtrl.text,
          onChanged: onConfirmPasswordChanged,
          suffix: GestureDetector(
            onTap: onToggleConfirmPassword,
            child: Icon(
              confirmPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF8FA0B4),
            ),
          ),
        ),
        _ErrorText(error: confirmPasswordError),
        const SizedBox(height: 16),
        _TermsAgreementRow(
          agreed: termsAgreed,
          onChanged: onTermsAgreedChanged,
        ),
        const SizedBox(height: 14),
        _PrimaryButton(
          label: 'Create Account',
          icon: Icons.person_add_outlined,
          loading: false,
          onTap: onSignUp,
        ),
        const SizedBox(height: 12),
        _VersionFooter(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Role selector button
// ─────────────────────────────────────────────────────────────
class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.teal.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.teal
                : AppColors.teal.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active
                      ? AppColors.teal2
                      : AppColors.teal3.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? AppColors.teal2
                        : AppColors.teal3.withValues(alpha: 0.45),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Field label
// ─────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.sora(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.teal3.withValues(alpha: 0.85),
        letterSpacing: 1.6,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Input field
// ─────────────────────────────────────────────────────────────
class _InputField extends StatefulWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.inputAction = TextInputAction.next,
    this.prefix,
    this.suffix,
    this.hasError = false,
    this.isValid = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction inputAction;
  final IconData? prefix;
  final Widget? suffix;
  final bool hasError;
  final bool isValid;
  final ValueChanged<String>? onChanged;

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
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
    final borderColor = widget.hasError
        ? const Color(0xFFEF4444)
        : widget.isValid
        ? const Color(0xFF22C55E)
        : _focused
        ? AppColors.teal
        : AppColors.teal.withValues(alpha: 0.2);
    final glowColor = widget.hasError
        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
        : widget.isValid
        ? const Color(0xFF22C55E).withValues(alpha: 0.15)
        : AppColors.teal.withValues(alpha: 0.18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.hasError
            ? const Color(0xFF2A0A0A).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: (_focused || widget.hasError)
            ? [BoxShadow(color: glowColor, blurRadius: 8, spreadRadius: 2)]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.inputAction,
            onChanged: widget.onChanged,
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            cursorColor: AppColors.teal2,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.sora(
                fontSize: 14,
                color: AppColors.teal3.withValues(alpha: 0.3),
              ),
              prefixIcon: widget.prefix != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        widget.prefix,
                        size: 16,
                        color: _focused
                            ? AppColors.teal2
                            : AppColors.teal3.withValues(alpha: 0.4),
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIcon: widget.suffix != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: widget.suffix,
                    )
                  : widget.isValid
                  ? const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Color(0xFF22C55E),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.prefix != null ? 4 : 14,
                vertical: 10,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Uganda Phone Field — +256 prefix badge + network hint
// ─────────────────────────────────────────────────────────────
class _UgandaPhoneField extends StatefulWidget {
  const _UgandaPhoneField({
    required this.controller,
    this.hasError = false,
    this.onChanged,
  });
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  State<_UgandaPhoneField> createState() => _UgandaPhoneFieldState();
}

class _UgandaPhoneFieldState extends State<_UgandaPhoneField> {
  final _focus = FocusNode();
  bool _focused = false;
  String _network = '';
  Color _networkColor = Colors.transparent;

  // MTN: 077X, 078X, 076X(0-4), 079X(0), 031X, 039X
  static const _mtn = [
    '770',
    '771',
    '772',
    '773',
    '774',
    '775',
    '776',
    '777',
    '778',
    '779',
    '780',
    '781',
    '782',
    '783',
    '784',
    '785',
    '786',
    '787',
    '788',
    '789',
    '760',
    '761',
    '762',
    '763',
    '764',
    '790',
    '310',
    '311',
    '312',
    '313',
    '314',
    '315',
    '316',
    '317',
    '318',
    '319',
    '390',
    '391',
    '392',
    '393',
    '394',
    '395',
    '396',
    '397',
    '398',
    '399',
  ];
  // Airtel: 070X, 075X, 074X(0), 020X
  static const _airtel = [
    '700',
    '701',
    '702',
    '703',
    '704',
    '705',
    '706',
    '707',
    '708',
    '709',
    '750',
    '751',
    '752',
    '753',
    '754',
    '755',
    '756',
    '757',
    '758',
    '759',
    '740',
    '200',
    '201',
    '202',
    '203',
    '204',
    '205',
    '206',
    '207',
    '208',
    '209',
  ];

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

  void _onChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\s'), '');
    String network = '';
    Color color = Colors.transparent;
    if (digits.length >= 3) {
      final prefix = digits.substring(0, 3);
      if (_mtn.contains(prefix)) {
        network = 'MTN';
        color = const Color(0xFFFFCC00);
      } else if (_airtel.contains(prefix)) {
        network = 'Airtel';
        color = const Color(0xFFE4002B);
      }
    }
    setState(() {
      _network = network;
      _networkColor = color;
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? const Color(0xFFEF4444)
        : _focused
        ? AppColors.teal
        : AppColors.teal.withValues(alpha: 0.2);
    final glowColor = widget.hasError
        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
        : AppColors.teal.withValues(alpha: 0.18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.hasError
                ? const Color(0xFF2A0A0A).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: (_focused || widget.hasError)
                ? [BoxShadow(color: glowColor, blurRadius: 8, spreadRadius: 2)]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Row(
                children: [
                  // ── +256 badge ──
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _focused
                          ? AppColors.teal.withValues(alpha: 0.15)
                          : AppColors.ink3,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: _focused
                            ? AppColors.teal.withValues(alpha: 0.5)
                            : AppColors.teal.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🇺🇬', style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          '+256',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _focused
                                ? AppColors.teal2
                                : AppColors.teal3.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ── Divider ──
                  Container(
                    width: 1,
                    height: 22,
                    color: AppColors.teal.withValues(alpha: 0.2),
                  ),
                  // ── Input ──
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      onChanged: _onChanged,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                        _UgandaPhoneFormatter(),
                      ],
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 1.4,
                      ),
                      cursorColor: AppColors.teal2,
                      decoration: InputDecoration(
                        hintText: '7XX XXX XXX',
                        hintStyle: GoogleFonts.sora(
                          fontSize: 14,
                          color: AppColors.teal3.withValues(alpha: 0.3),
                          letterSpacing: 0.5,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  // ── Network badge ──
                  if (_network.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _networkColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _networkColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _network,
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _network == 'MTN'
                                ? const Color(0xFF92700A)
                                : const Color(0xFFB0001F),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // ── Format hint ──
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(
            'Format: 7XX XXX XXX  ·  MTN or Airtel Uganda',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.teal3.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

// Auto-formats digits as: 7XX XXX XXX
class _UgandaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Password strength indicator
// ─────────────────────────────────────────────────────────────
class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});
  final String password;

  // Returns 0=empty 1=weak 2=fair 3=strong
  int get _score {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    if (score >= 4) return 3;
    if (score >= 2) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final labels = ['', 'Weak', 'Fair', 'Strong'];
    final colors = [
      Colors.transparent,
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF22C55E),
    ];
    final label = labels[score];
    final color = colors[score];

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3-segment bar
          Row(
            children: List.generate(3, (i) {
              final filled = i < score;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled ? color : AppColors.ink3,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),
          // Label
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                'Password strength: $label',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (score < 3) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    score == 1
                        ? '· Add uppercase, numbers & symbols'
                        : '· Add symbols to strengthen',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: AppColors.teal3.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Inline error text
// ─────────────────────────────────────────────────────────────
class _ErrorText extends StatelessWidget {
  const _ErrorText({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: error != null
          ? Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 13,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    error!,
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Primary action button — teal gradient
// ─────────────────────────────────────────────────────────────
class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.loading,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.loading
                  ? [
                      AppColors.teal.withValues(alpha: 0.4),
                      AppColors.teal2.withValues(alpha: 0.4),
                    ]
                  : [AppColors.teal, AppColors.teal2],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
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
                    Icon(widget.icon, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Version footer
// ─────────────────────────────────────────────────────────────
class _VersionFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Teal divider line ──
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.teal.withValues(alpha: 0.0),
                AppColors.teal.withValues(alpha: 0.35),
                AppColors.teal.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // ── App name row ──
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 15,
              letterSpacing: -0.3,
            ),
            children: const [
              TextSpan(
                text: 'Vision',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'Screen',
                style: TextStyle(color: AppColors.teal3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        // ── Version chip ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            'v1.0.0',
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.teal2,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // ── Badges row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 11,
              color: AppColors.teal2.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'Uganda MOH',
              style: GoogleFonts.sora(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.teal3.withValues(alpha: 0.55),
              ),
            ),
            _dot(),
            Icon(
              Icons.verified_outlined,
              size: 11,
              color: AppColors.teal2.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'WHO Compliant',
              style: GoogleFonts.sora(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.teal3.withValues(alpha: 0.55),
              ),
            ),
            _dot(),
            Icon(
              Icons.lock_outline_rounded,
              size: 11,
              color: AppColors.teal2.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'AES-256',
              style: GoogleFonts.sora(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.teal3.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // ── Copyright ──
        Text(
          '© 2025 VisionScreen · All rights reserved',
          style: GoogleFonts.sora(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: AppColors.teal3.withValues(alpha: 0.3),
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Offline note card
// ─────────────────────────────────────────────────────────────
class _OfflineNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.teal2),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'VisionScreen works fully offline. All patient data is stored securely on your device using SQLite.',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.teal3.withValues(alpha: 0.85),
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Terms agreement checkbox row
// ─────────────────────────────────────────────────────────────
class _TermsAgreementRow extends StatelessWidget {
  const _TermsAgreementRow({required this.agreed, required this.onChanged});
  final bool agreed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!agreed);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: agreed
              ? AppColors.teal.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: agreed
                ? AppColors.teal.withValues(alpha: 0.5)
                : AppColors.teal.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: agreed ? AppColors.teal : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: agreed
                      ? AppColors.teal
                      : AppColors.teal.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: agreed
                    ? [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: agreed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.teal3.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: 'I have read and agree to the '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => showTermsOfService(context),
                        child: Text(
                          'Terms of Service',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal2,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.teal2,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => showPrivacyPolicy(context),
                        child: Text(
                          'Privacy Policy',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal2,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.teal2,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' of VisionScreen.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Terms note — tappable links open bottom sheets
// ─────────────────────────────────────────────────────────────
class _TermsNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            'By creating an account you agree to our ',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.teal3.withValues(alpha: 0.6),
              height: 1.7,
            ),
          ),
          GestureDetector(
            onTap: () => showTermsOfService(context),
            child: Text(
              'Terms of Service',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.teal2,
                height: 1.7,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.teal2,
              ),
            ),
          ),
          Text(
            ' and ',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.teal3.withValues(alpha: 0.6),
              height: 1.7,
            ),
          ),
          GestureDetector(
            onTap: () => showPrivacyPolicy(context),
            child: Text(
              'Privacy Policy',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.teal2,
                height: 1.7,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.teal2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Terms of Service bottom sheet
// ─────────────────────────────────────────────────────────────
void showTermsOfService(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LegalSheet(
      title: 'Terms of Service',
      icon: Icons.gavel_rounded,
      iconColor: AppColors.teal,
      sections: [
        _LegalSection(
          heading: '1. Purpose of VisionScreen',
          body:
              'VisionScreen is a clinical-grade mobile application designed exclusively for use by trained Community Health Workers (CHWs) and authorised health administrators operating under the Uganda Ministry of Health (MOH) framework. The application facilitates vision screening using the Tumbling E optotype chart, aligned with WHO Visual Acuity Assessment Guidelines (WHO/PBL/01.71).',
        ),
        _LegalSection(
          heading: '2. Clinical Standards & Compliance',
          body:
              'All vision assessments follow the WHO-recommended Tumbling E protocol. Pass/fail thresholds per age group:\n\n• Children (6–12 yrs): Pass ≥ 6/9 (LogMAR 0.18)\n• Adults (13–60 yrs): Pass ≥ 6/12 (LogMAR 0.30)\n• Elderly (60+ yrs): Pass ≥ 6/18 (LogMAR 0.48)\n• Pre-school (3–5 yrs): Pass ≥ 6/12 (LogMAR 0.30)\n\nResults are screening indicators only and do not constitute a clinical diagnosis. All referrals must be reviewed by a qualified ophthalmologist or optometrist.',
        ),
        _LegalSection(
          heading: '3. Authorised Use',
          body:
              'This application is authorised for use only by:\n\n• Registered Community Health Workers under a recognised Ugandan Health Centre (HC II–HC IV)\n• Health administrators with valid MOH credentials\n• Supervised trainees under direct CHW oversight\n\nUnauthorised use, sharing of login credentials or use outside a supervised health programme is strictly prohibited.',
        ),
        _LegalSection(
          heading: '4. Patient Data & Confidentiality',
          body:
              'All patient data is subject to the Uganda Data Protection and Privacy Act 2019. CHWs are legally obligated to:\n\n• Obtain verbal informed consent before screening\n• Explain the purpose of data collection to each patient\n• Never share patient records with unauthorised persons\n• Report any data breach immediately to their supervising health officer',
        ),
        _LegalSection(
          heading: '5. Clinical Limitations & Disclaimer',
          body:
              'VisionScreen is a screening tool, not a diagnostic instrument. A failed result indicates the need for further clinical evaluation and does not confirm any specific ocular pathology. CHWs must not:\n\n• Diagnose any eye condition based on screening results\n• Prescribe glasses or medication\n• Advise patients to discontinue existing treatment\n\nAll clinical decisions must be made by a licensed eye care professional.',
        ),
        _LegalSection(
          heading: '6. Device & Screen Calibration',
          body:
              'Accurate vision screening requires proper device calibration. VisionScreen automatically detects screen PPI and physical dimensions to render optotypes at clinically correct sizes. Users must:\n\n• Ensure the device screen is clean and undamaged\n• Maintain the correct 3-metre testing distance\n• Conduct tests in adequate lighting (minimum 80 lux)\n• Recalibrate if the device or screen is changed',
        ),
        _LegalSection(
          heading: '7. Referral Obligations',
          body:
              'When a patient fails the screening threshold, the CHW is obligated to:\n\n• Generate a formal referral document within VisionScreen\n• Communicate the referral to the patient clearly\n• Follow up within 14 days to confirm attendance\n• Record the outcome in the patient screening history\n\nFailure to follow up may constitute a breach of duty of care under the Uganda Allied Health Professionals Act.',
        ),
        _LegalSection(
          heading: '8. Amendments',
          body:
              'These Terms may be updated periodically to reflect changes in clinical guidelines, MOH policy or application functionality. Users will be notified of material changes upon next login. Continued use of VisionScreen constitutes acceptance of the updated terms.',
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Privacy Policy bottom sheet
// ─────────────────────────────────────────────────────────────
void showPrivacyPolicy(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LegalSheet(
      title: 'Privacy Policy',
      icon: Icons.lock_outline_rounded,
      iconColor: Color(0xFF38BDF8),
      sections: [
        _LegalSection(
          heading: '1. Data Controller',
          body:
              'VisionScreen is operated under the supervision of the Uganda Ministry of Health Community Health Division. The data controller responsible for patient information is the registered health facility to which the CHW is assigned.',
        ),
        _LegalSection(
          heading: '2. What Data We Collect',
          body:
              'VisionScreen collects the following data:\n\n• Patient demographics: name, age, gender, village, phone number\n• Clinical data: visual acuity scores (OD, OS, OU), LogMAR values, test date and time\n• Referral data: facility name, appointment date, referral status, follow-up outcomes\n• Device data: screen PPI, device model (for calibration only)\n• Account data: CHW name, health centre, district, email address',
        ),
        _LegalSection(
          heading: '3. How We Use Your Data',
          body:
              'Data collected is used exclusively for:\n\n• Conducting and recording vision screening assessments\n• Generating clinical referral documents\n• Tracking referral follow-up and patient outcomes\n• Programme monitoring and public health analytics (anonymised)\n• Improving screening accuracy and application performance\n\nData is never sold, rented or shared with commercial third parties.',
        ),
        _LegalSection(
          heading: '4. Data Storage & Security',
          body:
              'Patient data is stored locally on your device using SQLite encryption. When internet is available, data syncs to a secure MongoDB Atlas cloud instance compliant with ISO/IEC 27001.\n\nSecurity measures include:\n\n• AES-256 encryption for data at rest\n• TLS 1.3 encryption for data in transit\n• Role-based access control (CHW vs Administrator)\n• Automatic session timeout after 30 minutes of inactivity',
        ),
        _LegalSection(
          heading: '5. Patient Consent',
          body:
              'Before screening, CHWs must obtain informed verbal consent from the patient or guardian (for minors). Patients have the right to:\n\n• Refuse screening without consequence\n• Request deletion of their records\n• Access their own screening history\n• Know how their data will be used',
        ),
        _LegalSection(
          heading: '6. Data Retention',
          body:
              'Patient screening records are retained for a minimum of 5 years in accordance with the Uganda National Health Records and Information Policy. After this period, records may be anonymised for research or permanently deleted upon request from the supervising health officer.',
        ),
        _LegalSection(
          heading: '7. Your Rights',
          body:
              'Under the Uganda Data Protection and Privacy Act 2019, you have the right to:\n\n• Access personal data held about you\n• Correct inaccurate or incomplete data\n• Request erasure of your data\n• Object to processing of your data\n• Lodge a complaint with the Personal Data Protection Office of Uganda',
        ),
        _LegalSection(
          heading: '8. Contact',
          body:
              'For any privacy-related concerns, data requests or breach reports, contact the VisionScreen Programme Coordinator through your district health office or the Uganda MOH Community Health Division.',
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Reusable legal bottom sheet
// ─────────────────────────────────────────────────────────────
class _LegalSheet extends StatelessWidget {
  const _LegalSheet({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.sections,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE4EC),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 22,
                            color: const Color(0xFF1A2A3D),
                          ),
                        ),
                        Text(
                          'VisionScreen · Uganda MOH',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8FA0B4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF5E7291),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Divider(color: Color(0xFFF0F4F7), thickness: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
                itemCount: sections.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, i) =>
                    _LegalSectionWidget(section: sections[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Legal section data + widget
// ─────────────────────────────────────────────────────────────
class _LegalSection {
  const _LegalSection({required this.heading, required this.body});
  final String heading;
  final String body;
}

class _LegalSectionWidget extends StatelessWidget {
  const _LegalSectionWidget({required this.section});
  final _LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            section.heading,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.teal,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          section.body,
          style: GoogleFonts.sora(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3D5470),
            height: 1.85,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Glass card — frosted panel wrapping the form
// ─────────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.18),
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.07),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Floating glow orb — soft radial blur behind the glass
// ─────────────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Grid pattern background — matches splash screen
// ─────────────────────────────────────────────────────────────
class _LoginGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Radial mesh gradient overlay — matches splash screen
// ─────────────────────────────────────────────────────────────
class _LoginMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.6),
          radius: 0.7,
          colors: [AppColors.teal.withValues(alpha: 0.18), Colors.transparent],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.6, 0.5),
          radius: 0.55,
          colors: [AppColors.sky.withValues(alpha: 0.10), Colors.transparent],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Eye painter for the header logo box
// ─────────────────────────────────────────────────────────────
class _HeaderEyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.88,
        height: size.height * 0.50,
      ),
      Paint()
        ..color = AppColors.teal3
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.18,
      Paint()
        ..color = AppColors.teal2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.09,
      Paint()..color = AppColors.teal2,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.038,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
