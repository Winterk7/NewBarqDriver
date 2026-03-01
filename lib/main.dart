import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barq_driver/core/router/app_router.dart';
import 'package:barq_driver/core/theme/theme.dart';
import 'package:barq_driver/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: BarqDriverApp()));
}

class BarqDriverApp extends ConsumerWidget {
  const BarqDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Barq Driver',
      debugShowCheckedModeBanner: false,
      theme: BarqLightTheme.theme,
      darkTheme: BarqDarkTheme.theme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
