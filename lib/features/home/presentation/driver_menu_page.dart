import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/core/theme/theme_provider.dart';
import 'package:barq_driver/core/providers/locale_provider.dart';
import 'package:barq_driver/core/providers/driver_orders_provider.dart';
import 'package:barq_driver/features/home/domain/driver_status.dart';
import 'package:barq_driver/features/home/presentation/analytics_screen.dart';
import 'package:barq_driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverMenuPage extends ConsumerWidget {
  final DriverStatus status;
  const DriverMenuPage({super.key, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark        = Theme.of(context).brightness == Brightness.dark;
    final themeMode   = ref.watch(themeModeProvider);
    final locale      = ref.watch(localeProvider);
    final l           = AppLocalizations.of(context)!;
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
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
          child: Text(t, style: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: textSec)),
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
            Expanded(child: Text(label, style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary))),
            if (value != null) ...[const SizedBox(width: AppDimens.sm), Text(value, style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: textSec)), const SizedBox(width: 4)],
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

    Widget languageTrailing() {
      final isAr = locale.languageCode == 'ar';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: 5),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          isAr ? _LibyanFlag(size: 12) : const Text('🇬🇧', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(isAr ? l.languageArabic : l.languageEnglish, style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
        ]),
      );
    }

    Widget appearanceTrailing() {
      final labels = {ThemeMode.system: l.themeSystem, ThemeMode.light: l.themeLight, ThemeMode.dark: l.themeDark};
      final icons = {ThemeMode.system: Icons.brightness_auto_rounded, ThemeMode.light: Icons.light_mode_rounded, ThemeMode.dark: Icons.dark_mode_rounded};
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: 5),
        decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icons[themeMode]!, size: 13, color: textPrimary),
          const SizedBox(width: 4),
          Text(labels[themeMode]!, style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
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
            Text(l.menu, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4)),
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
                _StatCard(icon: Icons.account_balance_wallet_rounded, label: l.earnedToday, value: 'LYD 0.00', textPrimary: textPrimary, textSec: textSec, borderColor: borderColor, cardBg: cardBg),
                const SizedBox(width: AppDimens.sm),
                _StatCard(icon: Icons.delivery_dining_rounded, label: l.deliveries, value: '0', textPrimary: textPrimary, textSec: textSec, borderColor: borderColor, cardBg: cardBg),
                const SizedBox(width: AppDimens.sm),
                _StatCard(icon: Icons.star_rounded, label: l.rating, value: '4.9', textPrimary: textPrimary, textSec: textSec, borderColor: borderColor, cardBg: cardBg),
              ]),

              // PREFERENCES
              sectionLabel(l.preferences),
              settingsCard([
                settingsRow(
                  icon: Icons.dark_mode_rounded,
                  label: l.appearance,
                  trailing: appearanceTrailing(),
                  onTap: () { HapticFeedback.selectionClick(); final next = themeMode == ThemeMode.system ? ThemeMode.light : themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.system; ref.read(themeModeProvider.notifier).state = next; },
                  isFirst: true,
                ),
                settingsRow(
                  icon: Icons.language_rounded,
                  label: l.language,
                  trailing: languageTrailing(),
                  onTap: () => _showLanguageSheet(context, ref, dark, textPrimary, textSec, bg, borderColor, locale),
                  isLast: true,
                ),
              ]),

              // DRIVER
              sectionLabel(l.driverSection),
              settingsCard([
                settingsRow(icon: Icons.bar_chart_rounded, label: l.analytics, isFirst: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverAnalyticsScreen()))),
                settingsRow(icon: Icons.history_rounded, label: l.deliveryHistory, onTap: () {}),
                settingsRow(icon: Icons.account_balance_wallet_rounded, label: l.walletEarnings, onTap: () {}),
                settingsRow(icon: Icons.star_rounded, label: l.myRating, value: '4.9', isLast: true, onTap: () {}),
              ]),

              // SUPPORT
              sectionLabel(l.supportSection),
              settingsCard([
                settingsRow(icon: Icons.support_agent_rounded, label: l.supportRow, isFirst: true, onTap: () {}),
                settingsRow(icon: Icons.tune_rounded, label: l.settings, isLast: true, onTap: () {}),
              ]),

              const SizedBox(height: AppDimens.xl),

              // Sign out
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/login');
                },
                child: Container(
                  height: AppDimens.buttonHeight,
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: AppColors.error.withValues(alpha: 0.20))),
                  alignment: Alignment.center,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(l.signOut, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.error)),
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
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(l.requestDeletion, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.error)),
                  ]),
                ),
              ),

              const SizedBox(height: AppDimens.lg),
              Center(child: Text('Barq Driver v1.0.0', style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textSec.withValues(alpha: 0.50)))),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    bool dark,
    Color textPrimary,
    Color textSec,
    Color bg,
    Color borderColor,
    Locale currentLocale,
  ) {
    final l       = AppLocalizations.of(context)!;
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    final sheetBg = dark ? AppColors.surfaceDark : Colors.white;
    final cardBg  = dark ? AppColors.cardDark    : AppColors.cardLight;
    final divider = dark ? AppColors.dividerDark  : AppColors.dividerLight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          final selected = ref.read(localeProvider).languageCode;

          Widget option({
            required String code,
            required Widget flagWidget,
            required String label,
            required String sublabel,
            required bool isFirst,
            required bool isLast,
          }) {
            final isSelected = selected == code;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                HapticFeedback.selectionClick();
                await ref.read(localeProvider.notifier).setLocale(Locale(code));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.base, vertical: AppDimens.md + 2),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: (isFirst && isLast)
                      ? BorderRadius.circular(AppDimens.radiusLg)
                      : isFirst
                          ? const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg))
                          : isLast
                              ? const BorderRadius.vertical(bottom: Radius.circular(AppDimens.radiusLg))
                              : BorderRadius.zero,
                  border: isFirst ? null : Border(top: BorderSide(color: divider, width: 0.5)),
                ),
                child: Row(children: [
                  flagWidget,
                  const SizedBox(width: AppDimens.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                    Text(sublabel, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textSec)),
                  ])),
                  if (isSelected)
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                    )
                  else
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: borderColor, width: 1.5)),
                    ),
                ]),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: dark ? Border.all(color: Colors.white.withValues(alpha: 0.10)) : null,
            ),
            padding: EdgeInsets.fromLTRB(AppDimens.xl, 0, AppDimens.xl, MediaQuery.of(context).padding.bottom + AppDimens.xl),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: AppDimens.lg),
              Text(l.language, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text(l.chooseLanguage, style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: textSec)),
              const SizedBox(height: AppDimens.xl),
              option(code: 'en', flagWidget: const Text('🇬🇧', style: TextStyle(fontSize: 26)), label: l.languageEnglish, sublabel: 'English', isFirst: true, isLast: false),
              option(code: 'ar', flagWidget: _LibyanFlag(size: 26), label: l.languageArabic, sublabel: 'Arabic', isFirst: false, isLast: true),
              const SizedBox(height: AppDimens.md),
            ]),
          );
        },
      ),
    );
  }

  void _showDeleteSheet(BuildContext context, bool dark, Color textPrimary, Color textSec, Color borderColor) {
    final l = AppLocalizations.of(context)!;
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
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
          Text(l.deleteAccountTitle, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.error, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          Text(l.deleteAccountBody, style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: textSec)),
          const SizedBox(height: AppDimens.xl),
          GestureDetector(
            onTap: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
            child: Container(height: AppDimens.buttonHeight, decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppDimens.radiusMd)), alignment: Alignment.center,
              child: Text(l.requestDeletion, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(height: AppDimens.buttonHeight, decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: borderColor)), alignment: Alignment.center,
              child: Text(l.cancel, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
            ),
          ),
        ]),
      ),
    );
  }
}

// Profile card
class _ProfileCard extends ConsumerWidget {
  final DriverStatus status;
  final bool dark;
  final Color textPrimary;
  final Color textSec;
  final Color borderColor;
  final Color cardBg;
  const _ProfileCard({required this.status, required this.dark, required this.textPrimary, required this.textSec, required this.borderColor, required this.cardBg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    final isOnline = status != DriverStatus.offline;
    final profileAsync = ref.watch(driverProfileProvider);
    final profile = profileAsync.valueOrNull;
    final name = (profile?['full_name'] as String?)?.trim();
    final phone = (profile?['phone'] as String?)?.trim() ?? '';
    final initial = (name != null && name.isNotEmpty) ? name[0].toUpperCase() : 'D';
    final displayName = (name != null && name.isNotEmpty) ? name : 'Driver';
    return Container(
      padding: const EdgeInsets.all(AppDimens.xl),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(AppDimens.radiusXl), border: Border.all(color: borderColor)),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06), shape: BoxShape.circle, border: Border.all(color: borderColor, width: 2)),
            child: Center(child: Text(initial, style: TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary))),
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
          Text(displayName, style: TextStyle(fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.3)),
          const SizedBox(height: 3),
          if (phone.isNotEmpty)
            Text(phone, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textSec)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
            child: Text(
              switch (status) {
                DriverStatus.offline   => AppLocalizations.of(context)!.statusOffline,
                DriverStatus.online    => AppLocalizations.of(context)!.statusOnline,
                DriverStatus.onDelivery => AppLocalizations.of(context)!.statusOnDelivery,
              },
              style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w700, color: textSec),
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
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.base, horizontal: AppDimens.sm),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: borderColor)),
        child: Column(children: [
          Icon(icon, size: 18, color: textSec),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily, fontSize: 10, color: textSec)),
        ]),
      ),
    );
  }
}

// ── Pre-2011 Libya flag: solid green rectangle ────────────────────────────────
class _LibyanFlag extends StatelessWidget {
  final double size;
  const _LibyanFlag({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 1.5,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF009A00),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
