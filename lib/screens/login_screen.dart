import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _signUp() {
    setState(() {
      _signUpNameError = _validateRequired(_signUpNameCtrl.text, 'Full name');
      _signUpCentreError = _validateRequired(_signUpCentreCtrl.text, 'Health center');
      _signUpDistrictError = _validateRequired(_signUpDistrictCtrl.text, 'District');
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
        _signUpConfirmPasswordError != null) return;
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
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validatePhone(String value) {
    if (value.trim().isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r'^(\+256|0)[0-9]{9}$');
    if (!phoneRegex.hasMatch(value.trim())) return 'Enter a valid Uganda phone number';
    return null;
  }

  String? _validateConfirmPassword(String password, String confirm) {
    if (confirm.isEmpty) return 'Please confirm your password';
    if (confirm != password) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 100;
    final isSignUp = _tabCtrl.index == 1;
    final heroVisible = _heroVisible && !keyboardOpen && !isSignUp;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Dark header ──
          _AuthHeader(visible: heroVisible),

          // ── Scrollable body ──
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tab switcher ──
                  _TabSwitcher(controller: _tabCtrl),
                  const SizedBox(height: 22),

                  // ── Tab content ──
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
                            onRoleChanged: (r) => setState(() => _selectedRole = r),
                            onTogglePassword: () => setState(() => _loginPasswordVisible = !_loginPasswordVisible),
                            onEmailChanged: (_) => setState(() => _loginEmailError = null),
                            onPasswordChanged: (_) => setState(() => _loginPasswordError = null),
                            onRememberMeChanged: (v) => setState(() => _rememberMe = v),
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
                            confirmPasswordCtrl: _signUpConfirmPasswordCtrl,
                            passwordVisible: _signUpPasswordVisible,
                            confirmPasswordVisible: _signUpConfirmPasswordVisible,
                            passwordValue: _signUpPasswordValue,
                            nameError: _signUpNameError,
                            centreError: _signUpCentreError,
                            districtError: _signUpDistrictError,
                            emailError: _signUpEmailError,
                            phoneError: _signUpPhoneError,
                            passwordError: _signUpPasswordError,
                            confirmPasswordError: _signUpConfirmPasswordError,
                            onTogglePassword: () => setState(() => _signUpPasswordVisible = !_signUpPasswordVisible),
                            onToggleConfirmPassword: () => setState(() => _signUpConfirmPasswordVisible = !_signUpConfirmPasswordVisible),
                            onNameChanged: (_) => setState(() => _signUpNameError = null),
                            onCentreChanged: (_) => setState(() => _signUpCentreError = null),
                            onDistrictChanged: (_) => setState(() => _signUpDistrictError = null),
                            onEmailChanged: (_) => setState(() => _signUpEmailError = null),
                            onPhoneChanged: (_) => setState(() => _signUpPhoneError = null),
                            onPasswordChanged: (v) => setState(() {
                              _signUpPasswordError = null;
                              _signUpPasswordValue = v;
                            }),
                            onConfirmPasswordChanged: (_) => setState(() => _signUpConfirmPasswordError = null),
                            onSignUp: _signUp,
                          ),
                  ),
                ],
              ),
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
  const _AuthHeader({required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      height: visible ? topPad + 100 : 0,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, AppColors.ink2],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),
          SafeArea(
            bottom: false,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: visible ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.teal, AppColors.teal2],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(22, 22),
                          painter: _HeaderEyePainter(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22,
                          color: Colors.white,
                          letterSpacing: -0.5,
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
              ),
            ),
          ),
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
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F7),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.all(3),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
    );
  }

  Widget _buildTab(String label, bool active) {
    return Tab(
      child: Text(
        label,
        style: GoogleFonts.sora(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.teal : const Color(0xFF8FA0B4),
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
        const SizedBox(height: 16),
        _FieldLabel(label: 'Email Address'),
        const SizedBox(height: 5),
        _InputField(
          controller: emailCtrl,
          hint: 'health@worker.ug',
          prefix: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          inputAction: TextInputAction.next,
          hasError: emailError != null,
          onChanged: onEmailChanged,
        ),
        _ErrorText(error: emailError),
        const SizedBox(height: 13),
        _FieldLabel(label: 'Password'),
        const SizedBox(height: 5),
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
              passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF8FA0B4),
            ),
          ),
        ),
        _ErrorText(error: passwordError),
        const SizedBox(height: 10),
        Row(
          children: [
            // Remember me toggle
            GestureDetector(
              onTap: () => onRememberMeChanged(!rememberMe),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: rememberMe ? AppColors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: rememberMe ? AppColors.teal : const Color(0xFFDDE4EC),
                        width: 1.5,
                      ),
                    ),
                    child: rememberMe
                        ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Remember me',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: const Color(0xFF5E7291),
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
                  color: AppColors.teal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _PrimaryButton(
          label: 'Login',
          icon: Icons.login_rounded,
          loading: loading,
          onTap: onLogin,
        ),
        const SizedBox(height: 24),
        _OfflineNote(),
        const SizedBox(height: 20),
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
        const SizedBox(height: 5),
        _InputField(
          controller: nameCtrl,
          hint: 'Your full name',
          prefix: Icons.person_outline_rounded,
          inputAction: TextInputAction.next,
          hasError: nameError != null,
          onChanged: onNameChanged,
        ),
        _ErrorText(error: nameError),
        const SizedBox(height: 13),
        _FieldLabel(label: 'Health Center'),
        const SizedBox(height: 5),
        _InputField(
          controller: centreCtrl,
          hint: 'e.g. Nakawa HC III, Wakiso District',
          prefix: Icons.local_hospital_outlined,
          inputAction: TextInputAction.next,
          hasError: centreError != null,
          onChanged: onCentreChanged,
        ),
        _ErrorText(error: centreError),
        const SizedBox(height: 13),
        _FieldLabel(label: 'District'),
        const SizedBox(height: 5),
        _InputField(
          controller: districtCtrl,
          hint: 'e.g. Kampala',
          prefix: Icons.location_on_outlined,
          inputAction: TextInputAction.next,
          hasError: districtError != null,
          onChanged: onDistrictChanged,
        ),
        _ErrorText(error: districtError),
        const SizedBox(height: 13),
        _FieldLabel(label: 'Email Address'),
        const SizedBox(height: 5),
        _InputField(
          controller: emailCtrl,
          hint: 'your@email.ug',
          prefix: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          inputAction: TextInputAction.next,
          hasError: emailError != null,
          onChanged: onEmailChanged,
        ),
        _ErrorText(error: emailError),
        const SizedBox(height: 13),
        _FieldLabel(label: 'Phone Number'),
        const SizedBox(height: 5),
        _InputField(
          controller: phoneCtrl,
          hint: '+256 7XX XXX XXX',
          prefix: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputAction: TextInputAction.next,
          hasError: phoneError != null,
          onChanged: onPhoneChanged,
        ),
        _ErrorText(error: phoneError),
        const SizedBox(height: 13),
        _FieldLabel(label: 'Password'),
        const SizedBox(height: 5),
        _InputField(
          controller: passwordCtrl,
          hint: 'Create a strong password',
          prefix: Icons.lock_outline_rounded,
          obscure: !passwordVisible,
          inputAction: TextInputAction.next,
          hasError: passwordError != null,
          onChanged: onPasswordChanged,
          suffix: GestureDetector(
            onTap: onTogglePassword,
            child: Icon(
              passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF8FA0B4),
            ),
          ),
        ),
        _ErrorText(error: passwordError),
        if (passwordValue.isNotEmpty) ...[
          const SizedBox(height: 8),
          _PasswordStrength(password: passwordValue),
        ],
        const SizedBox(height: 13),
        _FieldLabel(label: 'Confirm Password'),
        const SizedBox(height: 5),
        _InputField(
          controller: confirmPasswordCtrl,
          hint: 'Re-enter your password',
          prefix: Icons.lock_outline_rounded,
          obscure: !confirmPasswordVisible,
          inputAction: TextInputAction.done,
          hasError: confirmPasswordError != null,
          onChanged: onConfirmPasswordChanged,
          suffix: GestureDetector(
            onTap: onToggleConfirmPassword,
            child: Icon(
              confirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF8FA0B4),
            ),
          ),
        ),
        _ErrorText(error: confirmPasswordError),
        const SizedBox(height: 22),
        _PrimaryButton(
          label: 'Create Account',
          icon: Icons.person_add_outlined,
          loading: false,
          onTap: onSignUp,
        ),
        const SizedBox(height: 20),
        _TermsNote(),
        const SizedBox(height: 16),
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
          color: active ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.teal : const Color(0xFFDDE4EC),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? AppColors.teal : const Color(0xFF8FA0B4),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.teal : const Color(0xFF5E7291),
                height: 1.3,
              ),
            ),
          ],
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
        fontWeight: FontWeight.w700,
        color: const Color(0xFF5E7291),
        letterSpacing: 0.8,
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
        : _focused
        ? AppColors.teal
        : const Color(0xFFDDE4EC);
    final glowColor = widget.hasError
        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
        : AppColors.teal.withValues(alpha: 0.22);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.hasError ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: (_focused || widget.hasError)
            ? [BoxShadow(color: glowColor, blurRadius: 0, spreadRadius: 3)]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.inputAction,
        onChanged: widget.onChanged,
        style: GoogleFonts.sora(fontSize: 13, color: const Color(0xFF1A2A3D)),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.sora(
            fontSize: 13,
            color: const Color(0xFFC4CFDB),
          ),
          prefixIcon: widget.prefix != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    widget.prefix,
                    size: 16,
                    color: _focused
                        ? AppColors.teal
                        : const Color(0xFFB0BEC5),
                  ),
                )
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: widget.suffix,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.prefix != null ? 4 : 14,
            vertical: 12,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
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
                    color: filled ? color : const Color(0xFFDDE4EC),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (score < 3) ...[
                const SizedBox(width: 6),
                Text(
                  score == 1
                      ? '· Add uppercase, numbers & symbols'
                      : '· Add symbols to strengthen',
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    color: const Color(0xFF8FA0B4),
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
                      fontSize: 11,
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
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
      onTapDown: (_) { if (!widget.loading) setState(() => _pressed = true); },
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.loading
                  ? [AppColors.teal.withValues(alpha: 0.6), AppColors.teal2.withValues(alpha: 0.6)]
                  : [AppColors.teal, AppColors.teal2],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 4),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
    return Center(
      child: Text(
        'VisionScreen v1.0.0 · Uganda MOH · WHO Compliant',
        style: GoogleFonts.sora(
          fontSize: 10,
          color: const Color(0xFFB0BEC5),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
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
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.teal),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'VisionScreen works fully offline. All patient data is stored securely on your device using SQLite.',
              style: GoogleFonts.sora(
                fontSize: 11,
                color: const Color(0xFF0369A1),
                height: 1.6,
              ),
            ),
          ),
        ],
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
              fontSize: 11,
              color: const Color(0xFF8FA0B4),
              height: 1.6,
            ),
          ),
          GestureDetector(
            onTap: () => showTermsOfService(context),
            child: Text(
              'Terms of Service',
              style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.teal,
                height: 1.6,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.teal,
              ),
            ),
          ),
          Text(
            ' and ',
            style: GoogleFonts.sora(
              fontSize: 11,
              color: const Color(0xFF8FA0B4),
              height: 1.6,
            ),
          ),
          GestureDetector(
            onTap: () => showPrivacyPolicy(context),
            child: Text(
              'Privacy Policy',
              style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.teal,
                height: 1.6,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.teal,
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
                            fontSize: 20,
                            color: const Color(0xFF1A2A3D),
                          ),
                        ),
                        Text(
                          'VisionScreen · Uganda MOH',
                          style: GoogleFonts.sora(
                            fontSize: 11,
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.teal,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          section.body,
          style: GoogleFonts.sora(
            fontSize: 12,
            color: const Color(0xFF3D5470),
            height: 1.75,
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    const step = 22.0;
    const radius = 1.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
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
        width: size.width * 0.9,
        height: size.height * 0.5,
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.18,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.09,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
