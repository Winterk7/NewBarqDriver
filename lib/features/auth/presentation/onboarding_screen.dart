import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

// ── Page data ──────────────────────────────────────────────────────────────
class _OnboardingPageData {
  final String title;
  final String subtitle;
  final Color accent;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}

const _pages = [
  _OnboardingPageData(
    title: 'Accept deliveries\ninstantly',
    subtitle:
        'Get notified the moment an order is ready for pickup. Confirm with one tap and hit the road.',
    accent: Color(0xFF0D9F6C),
  ),
  _OnboardingPageData(
    title: 'Navigate your\nroute',
    subtitle:
        'Turn-by-turn guidance keeps you moving fast. Deliver more, earn more, every single day.',
    accent: Color(0xFFD97706),
  ),
  _OnboardingPageData(
    title: 'Earn with every\ndelivery',
    subtitle:
        'Watch your earnings grow in real time. Withdraw to your wallet whenever you want.',
    accent: Color(0xFF2563EB),
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  final _pageCtrl = PageController();
  int _current = 0;
  bool _videoInitialized = false;
  bool _videoError = false;

  late final AnimationController _fadeController;
  late final AnimationController _iconController;
  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _iconFade = CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _iconController.forward();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(
          'https://videos.pexels.com/video-files/18069164/18069164-hd_1080_1920_24fps.mp4',
        ),
      );
      await _videoController!.initialize();
      if (mounted) {
        _videoController!.setLooping(true);
        _videoController!.setVolume(0);
        _videoController!.play();
        setState(() => _videoInitialized = true);
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) setState(() => _videoError = true);
    }
  }

  void _onPageChanged(int i) {
    HapticFeedback.lightImpact();
    setState(() => _current = i);
    _iconController.reset();
    _iconController.forward();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('driver_onboarded', true);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageCtrl.dispose();
    _fadeController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final page = _pages[_current];
    final isLast = _current == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video background or fallback ────────────────────────────────
          if (_videoInitialized && _videoController != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else if (_videoError)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1a1a2e),
                      Color(0xFF16213e),
                      Color(0xFF0f0f0f),
                    ],
                  ),
                ),
              ),
            )
          else
            Positioned.fill(child: Container(color: Colors.black)),

          // ── Dark gradient scrim ─────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.30),
                    Colors.black.withValues(alpha: 0.78),
                    Colors.black.withValues(alpha: 0.94),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // ── Per-slide accent colour wash ─────────────────────────────────
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              color: page.accent.withValues(alpha: 0.13),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 3),

                  // ── Logo ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.xxl),
                    child: Center(
                      child: FadeTransition(
                        opacity: _iconFade,
                        child: ScaleTransition(
                          scale: _iconScale,
                          child: Image.asset(
                            'assets/images/barq_logo.png',
                            width: 44,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Text pages ─────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeController,
                    child: SizedBox(
                      height: 195,
                      child: PageView.builder(
                        controller: _pageCtrl,
                        itemCount: _pages.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (_, i) {
                          final p = _pages[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.xl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -1.0,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: AppDimens.md),
                                Text(
                                  p.subtitle,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimens.xl),

                  // ── Indicators + buttons ───────────────────────────────
                  FadeTransition(
                    opacity: _fadeController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dots
                          Row(
                            children: List.generate(
                              _pages.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.only(right: 6),
                                height: 3,
                                width: i == _current ? 28 : 8,
                                decoration: BoxDecoration(
                                  color: i == _current
                                      ? _pages[_current].accent
                                      : Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusFull,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppDimens.xxl),

                          // CTA button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                            width: double.infinity,
                            height: AppDimens.buttonHeight,
                            decoration: BoxDecoration(
                              color: _pages[_current].accent,
                              borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMd),
                            ),
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  isLast ? 'Get Started' : 'Continue',
                                  key: ValueKey(_current),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppDimens.md),

                          // Sign in link
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.go('/login');
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Colors.white
                                        .withValues(alpha: 0.5),
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Sign in',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_current < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }
}
