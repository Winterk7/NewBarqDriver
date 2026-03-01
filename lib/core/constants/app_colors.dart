import 'package:flutter/material.dart';

/// Barq brand colors — identical tokens shared across barq apps.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF0D9F6C);
  static const Color primaryGreenLight = Color(0xFF34D399);
  static const Color primaryGreenDark = Color(0xFF047857);

  // ── Neutrals (Light) ──────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color cardLight = Color(0xFFFFFFFF);

  // ── Neutrals (Dark) ───────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280);
  static const Color dividerDark = Color(0xFF2D2D2D);
  static const Color cardDark = Color(0xFF1E1E1E);

  // ── Semantic ──────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);

  // ── Misc ──────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color overlay = Color(0x80000000);

  // ── Feature screen tokens ─────────────────────────────
  static const Color featureBgDark = Color(0xFF0E0E0E);
  static const Color featureBgLight = Color(0xFFF5F5F5);
  static const Color sheetDark = Color(0xFF1C1C1C);
  static const Color contentTextPrimaryLight = Color(0xFF111111);
  static const Color videoFallbackMid = Color(0xFF16213E);
}
