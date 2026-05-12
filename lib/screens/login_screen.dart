import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart' show AppColors;
import '../repositories/auth_repository.dart';
import '../utils/legal_copy.dart';
import '../widgets/vs_logo.dart';

// ─────────────────────────────────────────────────────────────
// Login Screen — Login + Sign Up tabs
// ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  bool _showSignUp = false;

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
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    if (remember) {
      final savedEmail = prefs.getString('remembered_email') ?? '';
      setState(() {
        _rememberMe = remember;
        _loginEmailCtrl.text = savedEmail;
      });
    }
  }

  @override
  void dispose() {
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

    final result = await AuthRepository.instance.login(
      _loginEmailCtrl.text,
      _loginPasswordCtrl.text,
    );
    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _loginLoading = false;
        _loginPasswordError = result.errorMessage;
      });
      return;
    }

    // Persist remember-me preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    if (_rememberMe) {
      await prefs.setString(
        'remembered_email',
        _loginEmailCtrl.text.trim().toLowerCase(),
      );
    } else {
      await prefs.remove('remembered_email');
    }

    if (!mounted) return;
    setState(() => _loginLoading = false);
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
            style: GoogleFonts.inter(
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
    _saveSignUp();
  }

  Future<void> _saveSignUp() async {
    final result = await AuthRepository.instance.signUp(
      name: _signUpNameCtrl.text,
      center: _signUpCentreCtrl.text,
      district: _signUpDistrictCtrl.text,
      email: _signUpEmailCtrl.text,
      phone: _signUpPhoneCtrl.text,
      password: _signUpPasswordCtrl.text,
      role: _selectedRole,
    );
    if (!mounted) return;
    if (!result.success) {
      setState(() => _signUpEmailError = result.errorMessage);
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

  void _goSignUp() {
    _scrollCtrl.jumpTo(0);
    setState(() => _showSignUp = true);
  }

  void _goLogin() {
    _scrollCtrl.jumpTo(0);
    setState(() => _showSignUp = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Green hero zone (no tab switcher) ──
          _AuthHeroZone(isSignUp: _showSignUp),

          // ── White scrollable form area ──
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                20,
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
                child: !_showSignUp
                    ? _NewLoginForm(
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
                        onTogglePassword: () => setState(
                          () => _loginPasswordVisible = !_loginPasswordVisible,
                        ),
                        onEmailChanged: (v) async {
                          setState(() => _loginEmailError = null);
                          if (_rememberMe) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                              'remembered_email',
                              v.trim().toLowerCase(),
                            );
                          }
                        },
                        onPasswordChanged: (_) =>
                            setState(() => _loginPasswordError = null),
                        onRememberMeChanged: (v) async {
                          setState(() => _rememberMe = v);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('remember_me', v);
                          if (v) {
                            await prefs.setString(
                              'remembered_email',
                              _loginEmailCtrl.text.trim().toLowerCase(),
                            );
                          } else {
                            await prefs.remove('remembered_email');
                          }
                        },
                        onLogin: _login,
                        onGoSignUp: _goSignUp,
                      )
                    : _NewSignUpForm(
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
                        onTogglePassword: () => setState(
                          () =>
                              _signUpPasswordVisible = !_signUpPasswordVisible,
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
                        onCentreChanged: (_) =>
                            setState(() => _signUpCentreError = null),
                        onDistrictChanged: (_) =>
                            setState(() => _signUpDistrictError = null),
                        onEmailChanged: (_) =>
                            setState(() => _signUpEmailError = null),
                        onPhoneChanged: (_) =>
                            setState(() => _signUpPhoneError = null),
                        onPasswordChanged: (v) => setState(() {
                          _signUpPasswordError = null;
                          _signUpPasswordValue = v;
                        }),
                        onConfirmPasswordChanged: (_) =>
                            setState(() => _signUpConfirmPasswordError = null),
                        onSignUp: _signUp,
                        onGoLogin: _goLogin,
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
// Auth Hero Zone — animated entry + logo bounce
// ─────────────────────────────────────────────────────────────
// Auth Hero Zone — teal gradient + Sight Mark logo + animations
// ─────────────────────────────────────────────────────────────
class _AuthHeroZone extends StatefulWidget {
  const _AuthHeroZone({required this.isSignUp});
  final bool isSignUp;

  @override
  State<_AuthHeroZone> createState() => _AuthHeroZoneState();
}

class _AuthHeroZoneState extends State<_AuthHeroZone>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _shimmerCtrl;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _heroOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _logoCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _logoCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _heroSlide,
      child: FadeTransition(
        opacity: _heroOpacity,
        child: ClipPath(
          clipper: _WaveClipper(),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF134E4A), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Dot pattern
                Positioned.fill(child: CustomPaint(painter: _HeroDotPainter())),
                // Decorative arcs
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                // Content
                SafeArea(
                  bottom: false,
                  child: SizedBox.expand(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with pulsing rings — same as splash screen
                        ScaleTransition(
                          scale: _logoScale,
                          child: VsPulsingRings(
                            color: Colors.white,
                            size: 220,
                            child: VsLogoAnimated(size: 110),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // App name — "Vision" white shimmer, "Screen" black shimmer
                        AnimatedBuilder(
                          animation: _shimmerAnim,
                          builder: (context, child) {
                            List<double> stops(double v) => [
                              (v - 0.35).clamp(0.0, 1.0),
                              v.clamp(0.0, 1.0),
                              (v + 0.35).clamp(0.0, 1.0),
                            ];
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.55),
                                      Colors.white,
                                      Colors.white.withValues(alpha: 0.55),
                                    ],
                                    stops: stops(_shimmerAnim.value),
                                  ).createShader(bounds),
                                  child: Text(
                                    'Vision',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -1.0,
                                    ),
                                  ),
                                ),
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      const Color(
                                        0xFF1A1A1A,
                                      ).withValues(alpha: 0.7),
                                      Colors.black,
                                      const Color(
                                        0xFF1A1A1A,
                                      ).withValues(alpha: 0.7),
                                    ],
                                    stops: stops(_shimmerAnim.value),
                                  ).createShader(bounds),
                                  child: Text(
                                    'Screen',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                      letterSpacing: -1.0,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            widget.isSignUp
                                ? 'Create your CHW account'
                                : 'Sign in to continue',
                            key: ValueKey(widget.isSignUp),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.80),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ), // SizedBox.expand
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Dot pattern for hero
class _HeroDotPainter extends CustomPainter {
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
  bool shouldRepaint(_HeroDotPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// New Login Form — staggered entry + error shake
// ─────────────────────────────────────────────────────────────
class _NewLoginForm extends StatefulWidget {
  const _NewLoginForm({
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
    required this.onGoSignUp,
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
  final VoidCallback onGoSignUp;
  final String? emailError;
  final String? passwordError;
  final ValueChanged<String>? onEmailChanged;
  final ValueChanged<String>? onPasswordChanged;

  @override
  State<_NewLoginForm> createState() => _NewLoginFormState();
}

class _NewLoginFormState extends State<_NewLoginForm>
    with TickerProviderStateMixin {
  late final AnimationController _staggerCtrl;
  late final AnimationController _shakeCtrl;
  late final List<Animation<double>> _itemOpacity;
  late final List<Animation<Offset>> _itemSlide;
  late final Animation<double> _shakeAnim;

  static const _itemCount = 5; // heading, email, password, row, button

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _itemOpacity = List.generate(_itemCount, (i) {
      final start = i * 0.15;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _itemSlide = List.generate(_itemCount, (i) {
      final start = i * 0.15;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _staggerCtrl.forward();
  }

  @override
  void didUpdateWidget(_NewLoginForm old) {
    super.didUpdateWidget(old);
    // Shake when a new error appears
    if ((widget.emailError != null && old.emailError == null) ||
        (widget.passwordError != null && old.passwordError == null)) {
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Widget _stagger(int index, Widget child) {
    return FadeTransition(
      opacity: _itemOpacity[index],
      child: SlideTransition(position: _itemSlide[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stagger(
            0,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Hello ',
                        style: TextStyle(color: AppColors.greenDark),
                      ),
                      TextSpan(
                        text: 'Again!',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to continue to VisionScreen.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _stagger(
            1,
            _UnderlineInputField(
              controller: widget.emailCtrl,
              label: 'Email',
              hint: 'yourname@gmail.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              inputAction: TextInputAction.next,
              hasError: widget.emailError != null,
              errorText: widget.emailError,
              onChanged: widget.onEmailChanged,
            ),
          ),
          const SizedBox(height: 18),

          _stagger(
            2,
            _UnderlineInputField(
              controller: widget.passwordCtrl,
              label: 'Password',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: !widget.passwordVisible,
              inputAction: TextInputAction.done,
              hasError: widget.passwordError != null,
              errorText: widget.passwordError,
              onChanged: widget.onPasswordChanged,
              suffixIcon: GestureDetector(
                onTap: widget.onTogglePassword,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    widget.passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          _stagger(
            3,
            Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onRememberMeChanged(!widget.rememberMe),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: widget.rememberMe
                              ? AppColors.green
                              : Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: widget.rememberMe
                                ? AppColors.green
                                : AppColors.borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: widget.rememberMe
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
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushNamed('/forgot-password'),
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _stagger(
            4,
            Column(
              children: [
                _GreenPillButton(
                  label: 'Sign In',
                  icon: Icons.login_rounded,
                  loading: widget.loading,
                  onTap: widget.onLogin,
                ),
                const SizedBox(height: 28),
                Center(
                  child: GestureDetector(
                    onTap: widget.onGoSignUp,
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        children: [
                          const TextSpan(text: 'New User? '),
                          TextSpan(
                            text: 'Create Account',
                            style: TextStyle(
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.w700,
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// New Sign Up Form — staggered entry
// ─────────────────────────────────────────────────────────────
class _NewSignUpForm extends StatefulWidget {
  const _NewSignUpForm({
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
    required this.onGoLogin,
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
  final VoidCallback onGoLogin;
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
  State<_NewSignUpForm> createState() => _NewSignUpFormState();
}

class _NewSignUpFormState extends State<_NewSignUpForm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _opacity;
  late final List<Animation<Offset>> _slide;

  static const _count = 10;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = List.generate(_count, (i) {
      final s = (i * 0.09).clamp(0.0, 0.9);
      final e = (s + 0.3).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );
    });
    _slide = List.generate(_count, (i) {
      final s = (i * 0.09).clamp(0.0, 0.9);
      final e = (s + 0.3).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );
    });
    _staggerCtrl.forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Widget _s(int i, Widget child) => FadeTransition(
    opacity: _opacity[i],
    child: SlideTransition(position: _slide[i], child: child),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _s(
          0,
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
              children: [
                const TextSpan(
                  text: 'Create ',
                  style: TextStyle(color: AppColors.greenDark),
                ),
                TextSpan(
                  text: 'Account',
                  style: TextStyle(color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        _s(
          0,
          Text(
            'Fill in your details to get started.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 22),
        _s(
          1,
          _UnderlineInputField(
            controller: widget.nameCtrl,
            label: 'Full Name',
            hint: 'Your full name',
            prefixIcon: Icons.person_outline_rounded,
            inputAction: TextInputAction.next,
            hasError: widget.nameError != null,
            errorText: widget.nameError,
            onChanged: widget.onNameChanged,
          ),
        ),
        const SizedBox(height: 18),
        _s(
          2,
          _UnderlineInputField(
            controller: widget.centreCtrl,
            label: 'Health Center',
            hint: 'e.g. Nakawa HC III',
            prefixIcon: Icons.local_hospital_outlined,
            inputAction: TextInputAction.next,
            hasError: widget.centreError != null,
            errorText: widget.centreError,
            onChanged: widget.onCentreChanged,
          ),
        ),
        const SizedBox(height: 18),
        _s(
          3,
          _UnderlineInputField(
            controller: widget.districtCtrl,
            label: 'District',
            hint: 'e.g. Kampala',
            prefixIcon: Icons.location_on_outlined,
            inputAction: TextInputAction.next,
            hasError: widget.districtError != null,
            errorText: widget.districtError,
            onChanged: widget.onDistrictChanged,
          ),
        ),
        const SizedBox(height: 18),
        _s(
          4,
          _UnderlineInputField(
            controller: widget.emailCtrl,
            label: 'Email Address',
            hint: 'yourname@gmail.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            inputAction: TextInputAction.next,
            hasError: widget.emailError != null,
            errorText: widget.emailError,
            onChanged: widget.onEmailChanged,
          ),
        ),
        const SizedBox(height: 18),
        _s(
          5,
          _UnderlinePhoneField(
            controller: widget.phoneCtrl,
            hasError: widget.phoneError != null,
            errorText: widget.phoneError,
            onChanged: widget.onPhoneChanged,
          ),
        ),
        const SizedBox(height: 18),
        _s(
          6,
          _UnderlineInputField(
            controller: widget.passwordCtrl,
            label: 'Password',
            hint: 'Create a strong password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: !widget.passwordVisible,
            inputAction: TextInputAction.next,
            hasError: widget.passwordError != null,
            errorText: widget.passwordError,
            onChanged: widget.onPasswordChanged,
            suffixIcon: GestureDetector(
              onTap: widget.onTogglePassword,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  widget.passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
        if (widget.passwordValue.isNotEmpty) ...[
          const SizedBox(height: 8),
          _s(6, _GreenPasswordStrength(password: widget.passwordValue)),
        ],
        const SizedBox(height: 18),
        _s(
          7,
          _UnderlineInputField(
            controller: widget.confirmPasswordCtrl,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: !widget.confirmPasswordVisible,
            inputAction: TextInputAction.done,
            hasError: widget.confirmPasswordError != null,
            errorText: widget.confirmPasswordError,
            onChanged: widget.onConfirmPasswordChanged,
            suffixIcon: GestureDetector(
              onTap: widget.onToggleConfirmPassword,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  widget.confirmPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _s(
          8,
          _GreenTermsRow(
            agreed: widget.termsAgreed,
            onChanged: widget.onTermsAgreedChanged,
          ),
        ),
        const SizedBox(height: 22),
        _s(
          9,
          Column(
            children: [
              _GreenPillButton(
                label: 'Create Account',
                icon: Icons.person_add_outlined,
                onTap: widget.onSignUp,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: widget.onGoLogin,
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: AppColors.greenDark,
                            fontWeight: FontWeight.w700,
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
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Phase 5 supporting widgets
// ─────────────────────────────────────────────────────────────

// Underline phone field with +256 prefix (light theme)
class _UnderlinePhoneField extends StatefulWidget {
  const _UnderlinePhoneField({
    required this.controller,
    this.hasError = false,
    this.errorText,
    this.onChanged,
  });
  final TextEditingController controller;
  final bool hasError;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  State<_UnderlinePhoneField> createState() => _UnderlinePhoneFieldState();
}

class _UnderlinePhoneFieldState extends State<_UnderlinePhoneField> {
  final _focus = FocusNode();
  bool _focused = false;
  String _network = '';
  Color _networkColor = Colors.transparent;

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
    final lineColor = widget.hasError
        ? const Color(0xFFEF4444)
        : _focused
        ? AppColors.green
        : AppColors.borderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            // +256 badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _focused
                    ? AppColors.green.withValues(alpha: 0.08)
                    : AppColors.greenHero,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _focused
                      ? AppColors.green.withValues(alpha: 0.4)
                      : AppColors.borderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇺🇬', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '+256',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _focused
                          ? AppColors.greenDark
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
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
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                  letterSpacing: 1.2,
                ),
                cursorColor: AppColors.green,
                decoration: InputDecoration(
                  hintText: '7XX XXX XXX',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    letterSpacing: 0.5,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            if (_network.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _networkColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _networkColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  _network,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _network == 'MTN'
                        ? const Color(0xFF92700A)
                        : const Color(0xFFB0001F),
                  ),
                ),
              ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 2,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        if (widget.hasError && widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 12,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.errorText!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'MTN or Airtel Uganda · 9 digits',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _UgandaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Green password strength bar
class _GreenPasswordStrength extends StatelessWidget {
  const _GreenPasswordStrength({required this.password});
  final String password;

  int get _score {
    if (password.isEmpty) return 0;
    int s = 0;
    if (password.length >= 8) s++;
    if (password.length >= 12) s++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password)) {
      s++;
    }
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) s++;
    if (s >= 4) return 3;
    if (s >= 2) return 2;
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
      AppColors.green,
    ];
    final color = colors[score];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: i < score ? color : AppColors.borderColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              'Password strength: ${labels[score]}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// Green terms checkbox row
class _GreenTermsRow extends StatelessWidget {
  const _GreenTermsRow({required this.agreed, required this.onChanged});
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
              ? AppColors.green.withValues(alpha: 0.06)
              : AppColors.greenHero,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: agreed ? AppColors.green : AppColors.borderColor,
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
                color: agreed ? AppColors.green : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: agreed ? AppColors.green : AppColors.borderColor,
                  width: 1.5,
                ),
                boxShadow: agreed
                    ? [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.3),
                          blurRadius: 6,
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
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: 'I have read and agree to the '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => showTermsOfService(context),
                        child: Text(
                          'Terms of Service',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.greenDark,
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
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.greenDark,
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
// _HeroSectionState (kept for reference, no longer rendered)
// ─────────────────────────────────────────────────────────────
class _HeroSection extends StatefulWidget {
  const _HeroSection();
  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with TickerProviderStateMixin {
  AnimationController? _blinkCtrl;
  Animation<double>? _blinkAnim;
  AnimationController? _entryCtrl;
  Animation<double>? _entryOpacity;
  Animation<Offset>? _entrySlide;
  AnimationController? _shimmerCtrl;
  Animation<double>? _shimmerAnim;
  AnimationController? _badgeCtrl;
  Animation<double>? _badgeOpacity;
  final String _fullTagline = 'Offline-first | Tumbling E | CHW workflow';
  int _typedChars = 0;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _entryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl!,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl!, curve: Curves.easeOutCubic));
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _blinkAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    ]).animate(_blinkCtrl!);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _blinkCtrl!.forward();
    });
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _shimmerCtrl!, curve: Curves.easeInOut));
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _badgeOpacity = CurvedAnimation(parent: _badgeCtrl!, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 900), _startTyping);
  }

  void _startTyping() {
    if (!mounted) return;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 38));
      if (!mounted) return false;
      setState(() => _typedChars++);
      if (_typedChars >= _fullTagline.length) {
        _badgeCtrl?.forward();
        return false;
      }
      return true;
    });
  }

  @override
  void dispose() {
    _blinkCtrl?.dispose();
    _entryCtrl?.dispose();
    _shimmerCtrl?.dispose();
    _badgeCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagline = _fullTagline.substring(0, _typedChars);
    return SafeArea(
      bottom: false,
      child: SlideTransition(
        position: _entrySlide ?? const AlwaysStoppedAnimation(Offset.zero),
        child: FadeTransition(
          opacity: _entryOpacity ?? const AlwaysStoppedAnimation(1.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _shimmerCtrl ?? const AlwaysStoppedAnimation(0),
                builder: (context, child) => Positioned.fill(
                  child: CustomPaint(
                    painter: _ShimmerPainter(
                      progress: _shimmerAnim?.value ?? 0.0,
                    ),
                  ),
                ),
              ),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.teal.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _blinkCtrl ?? const AlwaysStoppedAnimation(1),
                    builder: (context, child) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.ink2, AppColors.ink3],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.4),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: _blinkAnim?.value ?? 1.0,
                        child: Center(
                          child: CustomPaint(
                            size: const Size(38, 38),
                            painter: _HeaderEyePainter(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 32,
                        letterSpacing: -1.0,
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tagline,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.teal3.withValues(alpha: 0.65),
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (_typedChars < _fullTagline.length)
                        const _BlinkingCursor(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _badgeOpacity ?? const AlwaysStoppedAnimation(0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _HeroBadge(Icons.remove_red_eye_outlined, 'Tumbling E'),
                        SizedBox(width: 8),
                        _HeroBadge(Icons.people_outline_rounded, 'CHW'),
                        SizedBox(width: 8),
                        _HeroBadge(Icons.cloud_off_rounded, 'Offline-First'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (context, child) => Opacity(
      opacity: _ctrl.value,
      child: Text(
        '|',
        style: GoogleFonts.inter(
          fontSize: 10,
          color: AppColors.teal2,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.teal.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppColors.teal2),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.teal3.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

class _ShimmerPainter extends CustomPainter {
  const _ShimmerPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * progress;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                AppColors.teal.withValues(alpha: 0.06),
                AppColors.teal3.withValues(alpha: 0.12),
                AppColors.teal.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ).createShader(
              Rect.fromLTWH(x - size.width * 0.5, 0, size.width, size.height),
            ),
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
// Tab switcher — Login / Sign Up
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// Role selector button
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// Uganda Phone Field — +256 prefix badge + network hint
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// Terms of Service bottom sheet
// ─────────────────────────────────────────────────────────────
List<_LegalSection> _buildLegalSections(Iterable<LegalSectionData> sections) {
  return sections
      .map(
        (section) => _LegalSection(
          heading: section.heading,
          body: section.body,
        ),
      )
      .toList(growable: false);
}

void showTermsOfService(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LegalSheet(
      title: 'Terms of Service',
      icon: Icons.gavel_rounded,
      iconColor: AppColors.teal,
      sections: _buildLegalSections(termsOfServiceSections),
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
    builder: (_) => _LegalSheet(
      title: 'Privacy Policy',
      icon: Icons.lock_outline_rounded,
      iconColor: Color(0xFF38BDF8),
      sections: _buildLegalSections(privacyPolicySections),
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
                          'VisionScreen | Community Screening',
                          style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.teal,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          section.body,
          style: GoogleFonts.inter(
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

// ─────────────────────────────────────────────────────────────
// Phase 3 — Shared Auth UI Components
// ─────────────────────────────────────────────────────────────

// Underline-only input field (green focus border)
class _UnderlineInputField extends StatefulWidget {
  const _UnderlineInputField({
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
  State<_UnderlineInputField> createState() => _UnderlineInputFieldState();
}

class _UnderlineInputFieldState extends State<_UnderlineInputField> {
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
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.prefixIcon != null) ...[
              Icon(
                widget.prefixIcon,
                size: 16,
                color: _focused ? AppColors.green : AppColors.textMuted,
              ),
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
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                cursorColor: AppColors.green,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  suffixIcon: widget.suffixIcon,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
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
            color: lineColor,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        if (widget.hasError && widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 12,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.errorText!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Full-width green pill gradient button
class _GreenPillButton extends StatefulWidget {
  const _GreenPillButton({
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
  State<_GreenPillButton> createState() => _GreenPillButtonState();
}

class _GreenPillButtonState extends State<_GreenPillButton> {
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
                      AppColors.greenDark.withValues(alpha: 0.5),
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
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Curved wave clipper — white wave transition from hero to form
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 40,
      size.width,
      size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}
