import 'package:flutter/services.dart';

/// Standardised haptic feedback — use these everywhere instead of calling
/// HapticFeedback directly so all patterns stay consistent across all Barq apps.
class AppHaptics {
  AppHaptics._();

  /// Subtle tap — nav bar, chips, toggles, back buttons
  static void light() => HapticFeedback.lightImpact();

  /// Confident action — button press, submit, confirm
  static void medium() => HapticFeedback.mediumImpact();

  /// Strong feedback — destructive action confirmation, logout
  static void heavy() => HapticFeedback.heavyImpact();

  /// Item selection — radio, checkbox, language selection
  static void select() => HapticFeedback.selectionClick();

  /// Successful completion — order accepted, saved
  static void success() => HapticFeedback.heavyImpact();

  /// Validation failure — form error, wrong role
  static void error() => HapticFeedback.heavyImpact();
}