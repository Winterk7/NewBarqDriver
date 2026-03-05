import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barq_driver/core/providers/auth_provider.dart';
import 'package:barq_driver/features/auth/presentation/splash_screen.dart';
import 'package:barq_driver/features/auth/presentation/onboarding_screen.dart';
import 'package:barq_driver/features/auth/presentation/login_screen.dart';
import 'package:barq_driver/features/home/presentation/home_screen.dart';
import 'package:barq_driver/features/home/presentation/analytics_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isLoggedIn;
      final loc = state.matchedLocation;
      final isPublic =
          loc == '/splash' || loc == '/onboarding' || loc == '/login';
      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && loc == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const DriverAnalyticsScreen(),
      ),
    ],
  );
});
