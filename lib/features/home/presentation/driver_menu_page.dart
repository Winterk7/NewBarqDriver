import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/core/theme/theme_provider.dart';
import 'package:barq_driver/features/home/domain/driver_status.dart';
import 'package:barq_driver/features/home/presentation/analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverMenuPage extends ConsumerWidget {
  final DriverStatus status;
  const DriverMenuPage({super.key, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark        = Theme.of(context).brightness == Brightness.dark;
    final themeMode   = ref.watch(themeModeProvider);
    final bg          = dark ? AppColors.backgroundDark  : AppColors.backgroundLight;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSec     = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final divider     = dark ? AppColors.dividerDark     : AppColors.dividerLight;
    final cardBg      = dark ? AppColors.cardDark        : AppColors.cardLight;
    final borderColor = dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07);
    final topPad      = MediaQuery.paddingOf(context).top;
    final bottomPad   = MediaQuery.paddingOf(context).bottom;

    Widget sectionLabel(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(0, AppDimens.xl, 0, AppDimens.sm),
          child: Text(t, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: textSec)),
        );

    Widget settingsRow({
      required IconData icon,
      required String label,
      String? value,
      Widget? trailing,
      VoidCallback? onTap,
      bool isFirst = false,
      bool isLast = false,
    }) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () => HapticFeedback.selectionClick(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.base, vertical: AppDimens.md + 1),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: (isFirst && isLast)
                ? BorderRadius.circular(AppDimens.radiusLg)
                : isFirst
                    ? const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg))
                    : isLast
                        ? const BorderRadius.vertical(bottom: Radius.circular(AppDimens.radiusLg))
                        : BorderRadius.zero,
            border: Border(top: isFirst ? BorderSide.none : BorderSide(color: divider, width: 0.5)),
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: textSec.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
              child: Icon(icon, size: 16, color: textSec),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary))),
            if (value != null) ...[const SizedBox(width: AppDimens.sm), Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: textSec)), const SizedBox(width: 4)],
            trailing ?? Icon(Icons.chevron_right_rounded, size: 18, color: textSec.withValues(alpha: 0.50)),
          ]),
        ),
      );
    }

    Widget settingsCard(List<Widget> rows) => Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: borderColor)),
          child: Column(children: rows),
        );

    Widget appearanceTrailing() {
      final labels = {ThemeMode.system: 'System', ThemeMode.light: 'Light', ThemeMode.dark: 'Dark'};
      final icons = {ThemeMode.system: Icons.brightness_auto_rounded, ThemeMode.light: Icons.light_mode_rounded, ThemeMode.dark: Icons.dark_mode_rounded};
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: 5),
        decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icons[themeMode]!, size: 13, color: textPrimary),
          const SizedBox(width: 4),
          Text(labels[themeMode]!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        // Header
        Container(
          color: dark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: EdgeInsets.fromLTRB(AppDimens.base, topPad + AppDimens.sm, AppDimens.base, AppDimens.base),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                child: Icon(Icons.close_rounded, size: AppDimens.iconMd, color: textPrimary),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Text('Menu', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4)),
          ]),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(AppDimens.base, AppDimens.base, AppDimens.base, bottomPad + AppDimens.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Profile card
              _ProfileCard(status: status, dark: dark, textPrimary: textPrimary, textSec: textSec, borderColor: borderColor, cardBg: cardBg),
              const SizedBox(height: AppDimens.sm),

              // Stats row
              Row(children: [
                _StatCard(icon: Icons.account_balance_wallet_rounded, label: 'Earned Today', value: 'LYD 0.00', textPrimary: textPrimary, textSec: textSec, borderColor: borderColor, cardBg: cardBg),
                const SizedBox(width: AppDimens.sm),
                _StatCard(icon: Icons.delivery_dining_rounded, label: 'Deliveries', value: '0', textPrimary: textPrimary, textSec: textSec, borderColor: borderColor, cardBg: cardBg),
                const SizedBox(width: AppDimens.sm),
                _StatCard(icon: Icons.star_rounded, label: 'Rating', value: '4.9', textPrimary: textPrimary, textSec: textSec, borderColor: borderColor, cardBg: cardBg),
              ]),

              // PREFERENCES
              sectionLabel('PREFERENCES'),
              settingsCard([
                settingsRow(
                  icon: Icons.dark_mode_rounded,
                  label: 'Appearance',
                  trailing: appearanceTrailing(),
                  onTap: () { HapticFeedback.selectionClick(); final next = themeMode == ThemeMode.system ? ThemeMode.light : themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.system; ref.read(themeModeProvider.notifier).state = next; },
                  isFirst: true, isLast: true,
                ),
              ]),

              // DRIVER
              sectionLabel('DRIVER'),
              settingsCard([
                settingsRow(icon: Icons.bar_chart_rounded, label: 'Analytics', isFirst: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverAnalyticsScreen()))),
                settingsRow(icon: Icons.history_rounded, label: 'Delivery History', onTap: () {}),
                settingsRow(icon: Icons.account_balance_wallet_rounded, label: 'Wallet & Earnings', onTap: () {}),
                settingsRow(icon: Icons.star_rounded, label: 'My Rating', value: '4.9', isLast: true, onTap: () {}),
              ]),

              // SUPPORT
              sectionLabel('SUPPORT'),
              settingsCard([
                settingsRow(icon: Icons.support_agent_rounded, label: 'Support', isFirst: true, onTap: () {}),
                settingsRow(icon: Icons.tune_rounded, label: 'Settings', isLast: true, onTap: () {}),
              ]),

              const SizedBox(height: AppDimens.xl),

              // Sign out
              GestureDetector(
                onTap: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
                child: Container(
                  height: AppDimens.buttonHeight,
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: AppColors.error.withValues(alpha: 0.20))),
                  alignment: Alignment.center,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    const Text('Sign Out', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.error)),
                  ]),
                ),
              ),

              const SizedBox(height: AppDimens.sm),

              // Request deletion
              GestureDetector(
                onTap: () => _showDeleteSheet(context, dark, textPrimary, textSec, borderColor),
                child: Container(
                  height: AppDimens.buttonHeight,
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: AppColors.error.withValues(alpha: 0.30))),
                  alignment: Alignment.center,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Request Account Deletion', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.error)),
                  ]),
                ),
              ),

              const SizedBox(height: AppDimens.lg),
              Center(child: Text('Barq Driver v1.0.0', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: textSec.withValues(alpha: 0.50)))),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showDeleteSheet(BuildContext context, bool dark, Color textPrimary, Color textSec, Color borderColor) {
    final bg = dark ? AppColors.surfaceDark : Colors.white;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), border: dark ? Border.all(color: Colors.white.withValues(alpha: 0.10)) : null),
        padding: EdgeInsets.fromLTRB(AppDimens.xl, 0, AppDimens.xl, MediaQuery.of(context).padding.bottom + AppDimens.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: AppDimens.lg),
          const Text('Delete Account?', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.error, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          Text('Your deletion request will be reviewed within 7 days. All your data will be permanently removed.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: textSec)),
          const SizedBox(height: AppDimens.xl),
          GestureDetector(
            onTap: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
            child: Container(height: AppDimens.buttonHeight, decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppDimens.radiusMd)), alignment: Alignment.center,
              child: const Text('Request Deletion', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(height: AppDimens.buttonHeight, decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: borderColor)), alignment: Alignment.center,
              child: Text('Cancel', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
            ),
          ),
        ]),
      ),
    );
  }
}

// Profile card
class _ProfileCard extends StatelessWidget {
  final DriverStatus status;
  final bool dark;
  final Color textPrimary;
  final Color textSec;
  final Color borderColor;
  final Color cardBg;
  const _ProfileCard({required this.status, required this.dark, required this.textPrimary, required this.textSec, required this.borderColor, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    final isOnline = status != DriverStatus.offline;
    return Container(
      padding: const EdgeInsets.all(AppDimens.xl),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(AppDimens.radiusXl), border: Border.all(color: borderColor)),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06), shape: BoxShape.circle, border: Border.all(color: borderColor, width: 2)),
            child: Center(child: Text('D', style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary))),
          ),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.primaryGreen : (dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                shape: BoxShape.circle,
                border: Border.all(color: cardBg, width: 2),
              ),
            ),
          ),
        ]),
        const SizedBox(width: AppDimens.base),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Driver', style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.3)),
          const SizedBox(height: 3),
          Text('driver@barq.ly', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: textSec)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
            child: Text(
              switch (status) { DriverStatus.offline => 'Offline', DriverStatus.online => 'Online', DriverStatus.onDelivery => 'On Delivery' },
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: textSec),
            ),
          ),
        ])),
      ]),
    );
  }
}

// Stat card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSec;
  final Color borderColor;
  final Color cardBg;
  const _StatCard({required this.icon, required this.label, required this.value, required this.textPrimary, required this.textSec, required this.borderColor, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.base, horizontal: AppDimens.sm),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: borderColor)),
        child: Column(children: [
          Icon(icon, size: 18, color: textSec),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: textSec)),
        ]),
      ),
    );
  }
}
