import 'package:barq_driver/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barq_driver/core/router/app_router.dart';
import 'package:barq_driver/core/theme/theme.dart';
import 'package:barq_driver/core/theme/theme_provider.dart';
import 'package:barq_driver/core/providers/locale_provider.dart';
import 'package:barq_driver/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hqhifevvyvmelmsoarya.supabase.co',
    anonKey:
        'sb_publishable_2kS_dsRp3aMu4Q1QzNDRHw_vO6hqPy4',
  );
  await NotificationService.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: BarqDriverApp()));
}

class BarqDriverApp extends ConsumerWidget {
  const BarqDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    ThemeData withCairo(ThemeData t) => isArabic
        ? t.copyWith(
            textTheme: t.textTheme.apply(fontFamily: 'Cairo'),
            primaryTextTheme: t.primaryTextTheme.apply(fontFamily: 'Cairo'),
          )
        : t;

    return MaterialApp.router(
      title: 'Barq Driver',
      debugShowCheckedModeBanner: false,
      theme: withCairo(BarqLightTheme.theme),
      darkTheme: withCairo(BarqDarkTheme.theme),
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
    );
  }
}
