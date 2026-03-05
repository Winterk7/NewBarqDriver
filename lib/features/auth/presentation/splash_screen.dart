import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;
  late final Animation<double> _scale;

  static const double _logoWidth = 80.0;

  @override
  void initState() {
    super.initState();

    // Total: 3000ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.267, curve: Curves.easeOut),
      ),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 1.0, curve: Curves.easeIn),
      ),
    );

    // Heartbeat: 1.0 → 1.07 → 1.0
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.07)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.07, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.43),
      ),
    );

    bool hapticFired = false;
    _controller.addListener(() {
      if (!hapticFired && _controller.value >= 0.33) {
        hapticFired = true;
        HapticFeedback.lightImpact();
      }
    });

    _controller.forward().then((_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool('driver_onboarded') ?? false;
      if (!mounted) return;
      // Router redirect will send to /home automatically if role is verified
      context.go(onboarded ? '/login' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            final opacity = _fadeIn.value * _fadeOut.value;
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: _scale.value,
                child: child!,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/barq_logo.png',
                width: _logoWidth,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              const Text(
                'driver',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
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
