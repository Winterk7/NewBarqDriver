import 'package:flutter/material.dart';

/// Font family helpers — use [AppFonts.of(context)] everywhere instead of
/// duplicating the locale check inline across every screen.
class AppFonts {
  AppFonts._();

  static const String arabic = 'Cairo';
  static const String latin  = 'Inter';

  /// Returns 'Cairo' for Arabic locale, 'Inter' otherwise.
  static String of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? arabic : latin;

  static String forLocale(Locale locale) =>
      locale.languageCode == 'ar' ? arabic : latin;
}