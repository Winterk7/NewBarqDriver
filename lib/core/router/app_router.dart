import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barq_driver/core/providers/auth_provider.dart';
import 'package:barq_driver/features/auth/presentation/splash_screen.dart';
import 'package:barq_driver/features/auth/presentation/language_picker_screen.dart';
import 'package:barq_driver/features/auth/presentation/onboarding_screen.dart';
import 'package:barq_driver/features/auth/presentation/login_screen.dart';
import 'package:barq_driver/features/home/presentation/home_screen.dart';
import 'package:barq_driver/features/home/presentation/analytics_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // ref.read — NOT ref.watch — prevents router recreation on auth change
  // which caused duplicate GlobalKey exceptions
  final authNotifier = ref.read(authNotifierProvider);
  authNotifier.addListener(() {});  // trigger refreshListenable pattern
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isLoggedIn;
      final loc = state.matchedLocation;
      final isPublic = loc == '/splash' ||
          loc == '/language-picker' ||
          loc == '/onboarding' ||
          loc == '/login';
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
        path: '/language-picker',
        builder: (context, state) => const LanguagePickerScreen(),
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
