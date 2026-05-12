import 'package:flutter/material.dart';
import '../widgets/vs_logo.dart';
import '../widgets/onboarding_illustrations.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Onboarding — two slides, single hero gradient, no particles
// or glass cards. The illustration sells the slide; the copy
// stays out of its way.
// ─────────────────────────────────────────────────────────────

class _Slide {
  const _Slide({
    required this.headline,
    required this.body,
    required this.illustration,
  });
  final String headline;
  final String body;
  final Widget illustration;
}

const List<_Slide> _slides = [
  _Slide(
    headline: 'Built for the field',
    body: 'Screen patients on the move with a workflow designed for community health workers in low-resource settings.',
    illustration: ChwIllustration(color: Colors.white),
  ),
  _Slide(
    headline: 'Works offline',
    body: 'Run the full Tumbling-E test, generate referrals and review analytics — all without a connection. Sync when you reach signal.',
    illustration: AnalyticsIllustration(color: Colors.white),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: VsGradients.hero),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar: wordmark + skip ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VsSpace.lg, VsSpace.md, VsSpace.lg, 0,
                ),
                child: Row(
                  children: [
                    const VsLogo(size: 28, showRing: false),
                    const SizedBox(width: VsSpace.sm),
                    Text(
                      'VisionScreen',
                      style: VsText.headline(color: Colors.white),
                    ),
                    const Spacer(),
                    if (!isLast)
                      TextButton(
                        onPressed: _goToLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Skip',
                          style: VsText.button(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Slides ──
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: _slides.length,
                  itemBuilder: (_, i) => _SlideContent(slide: _slides[i]),
                ),
              ),

              // ── Footer: dots + next ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VsSpace.lg, VsSpace.md, VsSpace.lg, VsSpace.xl,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(VsRadius.pill),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: VsSpace.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: VsColors.brand,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(VsRadius.md),
                          ),
                        ),
                        child: Text(
                          isLast ? 'Get started' : 'Next',
                          style: VsText.button(color: VsColors.brand),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(VsSpace.xl, VsSpace.lg, VsSpace.xl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Center(child: slide.illustration),
          ),
          const SizedBox(height: VsSpace.lg),
          Text(
            slide.headline,
            style: VsText.display(color: Colors.white),
          ),
          const SizedBox(height: VsSpace.md),
          Text(
            slide.body,
            style: VsText.body(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: VsSpace.xl),
        ],
      ),
    );
  }
}
