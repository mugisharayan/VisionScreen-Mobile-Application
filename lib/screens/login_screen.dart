import 'package:flutter/material.dart';
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

  // Login form
  final _loginEmailCtrl    = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  bool _loginPasswordVisible = false;
  String _selectedRole = 'chw'; // 'chw' | 'admin'

  // Sign up form
  final _signUpNameCtrl     = TextEditingController();
  final _signUpCentreCtrl   = TextEditingController();
  final _signUpDistrictCtrl = TextEditingController();
  final _signUpEmailCtrl    = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();
  bool _signUpPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signUpNameCtrl.dispose();
    _signUpCentreCtrl.dispose();
    _signUpDistrictCtrl.dispose();
    _signUpEmailCtrl.dispose();
    _signUpPasswordCtrl.dispose();
    super.dispose();
  }

  void _login() {
    // Navigate to home (placeholder — replace with real auth)
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _signUp() {
    // Navigate to home (placeholder — replace with real auth)
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Dark header ──
          _AuthHeader(selectedRole: _selectedRole),

          // ── Scrollable body ──
          Expanded(
            child: SingleChildScrollView(
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
                            onRoleChanged: (r) =>
                                setState(() => _selectedRole = r),
                            onTogglePassword: () => setState(
                                () => _loginPasswordVisible =
                                    !_loginPasswordVisible),
                            onLogin: _login,
                          )
                        : _SignUpForm(
                            key: const ValueKey('signup'),
                            nameCtrl: _signUpNameCtrl,
                            centreCtrl: _signUpCentreCtrl,
                            districtCtrl: _signUpDistrictCtrl,
                            emailCtrl: _signUpEmailCtrl,
                            passwordCtrl: _signUpPasswordCtrl,
                            passwordVisible: _signUpPasswordVisible,
                            onTogglePassword: () => setState(
                                () => _signUpPasswordVisible =
                                    !_signUpPasswordVisible),
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
// Dark header — gradient background, dot pattern, logo + title
// ─────────────────────────────────────────────────────────────
class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.selectedRole});
  final String selectedRole;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, AppColors.ink2],
          stops: [0.0, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Dot pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _DotPatternPainter()),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo row
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.teal, AppColors.teal2],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: CustomPaint(
                            size: const Size(18, 18),
                            painter: _HeaderEyePainter(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 19,
                            color: Colors.white,
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

                  const SizedBox(height: 20),

                  // Title
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 28,
                        color: Colors.white,
                        height: 1.25,
                      ),
                      children: const [
                        TextSpan(text: 'Welcome\n'),
                        TextSpan(text: 'Back 👋'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'Sign in to begin community screening',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: AppColors.teal3.withValues(alpha: 0.6),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Clinical compliance badges ──
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ClinicalBadge(
                        icon: Icons.verified_outlined,
                        label: 'WHO Vision Standards',
                        color: AppColors.teal3,
                      ),
                      _ClinicalBadge(
                        icon: Icons.local_hospital_outlined,
                        label: 'MOH Uganda Approved',
                        color: const Color(0xFF38BDF8),
                      ),
                      _ClinicalBadge(
                        icon: Icons.visibility_outlined,
                        label: 'Tumbling E · LogMAR',
                        color: AppColors.teal2,
                      ),
                    ],
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
  });

  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool passwordVisible;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Role selector ──
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

        // ── Email ──
        _FieldLabel(label: 'Email Address'),
        const SizedBox(height: 5),
        _InputField(
          controller: emailCtrl,
          hint: 'health@worker.ug',
          keyboardType: TextInputType.emailAddress,
          inputAction: TextInputAction.next,
        ),
        const SizedBox(height: 13),

        // ── Password ──
        _FieldLabel(label: 'Password'),
        const SizedBox(height: 5),
        _InputField(
          controller: passwordCtrl,
          hint: '••••••••',
          obscure: !passwordVisible,
          inputAction: TextInputAction.done,
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
        const SizedBox(height: 6),

        // ── Forgot password ──
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
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
        ),
        const SizedBox(height: 22),

        // ── Login button ──
        _PrimaryButton(
          label: 'Login',
          icon: Icons.login_rounded,
          onTap: onLogin,
        ),
        const SizedBox(height: 24),

        // ── Divider ──
        _OrDivider(),
        const SizedBox(height: 20),

        // ── Offline note ──
        _OfflineNote(),
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
    required this.passwordCtrl,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.onSignUp,
  });

  final TextEditingController nameCtrl;
  final TextEditingController centreCtrl;
  final TextEditingController districtCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Full name ──
        _FieldLabel(label: 'Full Name'),
        const SizedBox(height: 5),
        _InputField(
          controller: nameCtrl,
          hint: 'Your full name',
          inputAction: TextInputAction.next,
        ),
        const SizedBox(height: 13),

        // ── Health centre ──
        _FieldLabel(label: 'Health Center'),
        const SizedBox(height: 5),
        _InputField(
          controller: centreCtrl,
          hint: 'e.g. Nakawa HC III, Wakiso District',
          inputAction: TextInputAction.next,
        ),
        const SizedBox(height: 13),

        // ── District ──
        _FieldLabel(label: 'District'),
        const SizedBox(height: 5),
        _InputField(
          controller: districtCtrl,
          hint: 'e.g. Kampala',
          inputAction: TextInputAction.next,
        ),
        const SizedBox(height: 13),

        // ── Email ──
        _FieldLabel(label: 'Email Address'),
        const SizedBox(height: 5),
        _InputField(
          controller: emailCtrl,
          hint: 'your@email.ug',
          keyboardType: TextInputType.emailAddress,
          inputAction: TextInputAction.next,
        ),
        const SizedBox(height: 13),

        // ── Password ──
        _FieldLabel(label: 'Password'),
        const SizedBox(height: 5),
        _InputField(
          controller: passwordCtrl,
          hint: 'Create a strong password',
          obscure: !passwordVisible,
          inputAction: TextInputAction.done,
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
        const SizedBox(height: 22),

        // ── Sign up button ──
        _PrimaryButton(
          label: 'Create Account',
          icon: Icons.person_add_outlined,
          onTap: onSignUp,
        ),
        const SizedBox(height: 20),

        // ── Terms note ──
        _TermsNote(),
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
      onTap: onTap,
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
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction inputAction;
  final Widget? suffix;

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focused ? AppColors.teal : const Color(0xFFDDE4EC),
          width: 1.5,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.22),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.inputAction,
        style: GoogleFonts.sora(
          fontSize: 13,
          color: const Color(0xFF1A2A3D),
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.sora(
            fontSize: 13,
            color: const Color(0xFFC4CFDB),
          ),
          suffixIcon: widget.suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: widget.suffix,
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
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
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.teal, AppColors.teal2],
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
          child: Row(
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
// OR divider
// ─────────────────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: const Color(0xFFDDE4EC)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Offline Mode',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8FA0B4),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: const Color(0xFFDDE4EC)),
        ),
      ],
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
          const Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: AppColors.teal,
          ),
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
          body: 'VisionScreen is a clinical-grade mobile application designed exclusively for use by trained Community Health Workers (CHWs) and authorised health administrators operating under the Uganda Ministry of Health (MOH) framework. The application facilitates vision screening using the Tumbling E optotype chart, aligned with WHO Visual Acuity Assessment Guidelines (WHO/PBL/01.71).',
        ),
        _LegalSection(
          heading: '2. Clinical Standards & Compliance',
          body: 'All vision assessments follow the WHO-recommended Tumbling E protocol. Pass/fail thresholds per age group:\n\n• Children (6–12 yrs): Pass ≥ 6/9 (LogMAR 0.18)\n• Adults (13–60 yrs): Pass ≥ 6/12 (LogMAR 0.30)\n• Elderly (60+ yrs): Pass ≥ 6/18 (LogMAR 0.48)\n• Pre-school (3–5 yrs): Pass ≥ 6/12 (LogMAR 0.30)\n\nResults are screening indicators only and do not constitute a clinical diagnosis. All referrals must be reviewed by a qualified ophthalmologist or optometrist.',
        ),
        _LegalSection(
          heading: '3. Authorised Use',
          body: 'This application is authorised for use only by:\n\n• Registered Community Health Workers under a recognised Ugandan Health Centre (HC II–HC IV)\n• Health administrators with valid MOH credentials\n• Supervised trainees under direct CHW oversight\n\nUnauthorised use, sharing of login credentials or use outside a supervised health programme is strictly prohibited.',
        ),
        _LegalSection(
          heading: '4. Patient Data & Confidentiality',
          body: 'All patient data is subject to the Uganda Data Protection and Privacy Act 2019. CHWs are legally obligated to:\n\n• Obtain verbal informed consent before screening\n• Explain the purpose of data collection to each patient\n• Never share patient records with unauthorised persons\n• Report any data breach immediately to their supervising health officer',
        ),
        _LegalSection(
          heading: '5. Clinical Limitations & Disclaimer',
          body: 'VisionScreen is a screening tool, not a diagnostic instrument. A failed result indicates the need for further clinical evaluation and does not confirm any specific ocular pathology. CHWs must not:\n\n• Diagnose any eye condition based on screening results\n• Prescribe glasses or medication\n• Advise patients to discontinue existing treatment\n\nAll clinical decisions must be made by a licensed eye care professional.',
        ),
        _LegalSection(
          heading: '6. Device & Screen Calibration',
          body: 'Accurate vision screening requires proper device calibration. VisionScreen automatically detects screen PPI and physical dimensions to render optotypes at clinically correct sizes. Users must:\n\n• Ensure the device screen is clean and undamaged\n• Maintain the correct 3-metre testing distance\n• Conduct tests in adequate lighting (minimum 80 lux)\n• Recalibrate if the device or screen is changed',
        ),
        _LegalSection(
          heading: '7. Referral Obligations',
          body: 'When a patient fails the screening threshold, the CHW is obligated to:\n\n• Generate a formal referral document within VisionScreen\n• Communicate the referral to the patient clearly\n• Follow up within 14 days to confirm attendance\n• Record the outcome in the patient screening history\n\nFailure to follow up may constitute a breach of duty of care under the Uganda Allied Health Professionals Act.',
        ),
        _LegalSection(
          heading: '8. Amendments',
          body: 'These Terms may be updated periodically to reflect changes in clinical guidelines, MOH policy or application functionality. Users will be notified of material changes upon next login. Continued use of VisionScreen constitutes acceptance of the updated terms.',
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
          body: 'VisionScreen is operated under the supervision of the Uganda Ministry of Health Community Health Division. The data controller responsible for patient information is the registered health facility to which the CHW is assigned.',
        ),
        _LegalSection(
          heading: '2. What Data We Collect',
          body: 'VisionScreen collects the following data:\n\n• Patient demographics: name, age, gender, village, phone number\n• Clinical data: visual acuity scores (OD, OS, OU), LogMAR values, test date and time\n• Referral data: facility name, appointment date, referral status, follow-up outcomes\n• Device data: screen PPI, device model (for calibration only)\n• Account data: CHW name, health centre, district, email address',
        ),
        _LegalSection(
          heading: '3. How We Use Your Data',
          body: 'Data collected is used exclusively for:\n\n• Conducting and recording vision screening assessments\n• Generating clinical referral documents\n• Tracking referral follow-up and patient outcomes\n• Programme monitoring and public health analytics (anonymised)\n• Improving screening accuracy and application performance\n\nData is never sold, rented or shared with commercial third parties.',
        ),
        _LegalSection(
          heading: '4. Data Storage & Security',
          body: 'Patient data is stored locally on your device using SQLite encryption. When internet is available, data syncs to a secure MongoDB Atlas cloud instance compliant with ISO/IEC 27001.\n\nSecurity measures include:\n\n• AES-256 encryption for data at rest\n• TLS 1.3 encryption for data in transit\n• Role-based access control (CHW vs Administrator)\n• Automatic session timeout after 30 minutes of inactivity',
        ),
        _LegalSection(
          heading: '5. Patient Consent',
          body: 'Before screening, CHWs must obtain informed verbal consent from the patient or guardian (for minors). Patients have the right to:\n\n• Refuse screening without consequence\n• Request deletion of their records\n• Access their own screening history\n• Know how their data will be used',
        ),
        _LegalSection(
          heading: '6. Data Retention',
          body: 'Patient screening records are retained for a minimum of 5 years in accordance with the Uganda National Health Records and Information Policy. After this period, records may be anonymised for research or permanently deleted upon request from the supervising health officer.',
        ),
        _LegalSection(
          heading: '7. Your Rights',
          body: 'Under the Uganda Data Protection and Privacy Act 2019, you have the right to:\n\n• Access personal data held about you\n• Correct inaccurate or incomplete data\n• Request erasure of your data\n• Object to processing of your data\n• Lodge a complaint with the Personal Data Protection Office of Uganda',
        ),
        _LegalSection(
          heading: '8. Contact',
          body: 'For any privacy-related concerns, data requests or breach reports, contact the VisionScreen Programme Coordinator through your district health office or the Uganda MOH Community Health Division.',
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
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, i) => _LegalSectionWidget(section: sections[i]),
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
// Clinical compliance badge
// ─────────────────────────────────────────────────────────────
class _ClinicalBadge extends StatelessWidget {
  const _ClinicalBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dot pattern painter for the header background
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
