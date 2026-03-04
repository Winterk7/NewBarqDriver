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
    final dark         = Theme.of(context).brightness == Brightness.dark;
    final bg           = dark ? AppColors.backgroundDark   : AppColors.backgroundLight;
    final surface      = dark ? AppColors.surfaceDark      : AppColors.surfaceLight;
    final cardBg       = dark ? AppColors.cardDark         : AppColors.cardLight;
    final textPrimary  = dark ? AppColors.textPrimaryDark  : AppColors.textPrimaryLight;
    final textSec      = dark ? AppColors.textSecondaryDark: AppColors.textSecondaryLight;
    final divider      = dark ? AppColors.dividerDark      : AppColors.dividerLight;
    final topPad       = MediaQuery.paddingOf(context).top;
    final bottomPad    = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            color: surface,
            padding: EdgeInsets.fromLTRB(
                AppDimens.base, topPad + AppDimens.sm, AppDimens.base, AppDimens.base),
            child: Row(
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: AppDimens.iconMd, color: textPrimary),
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Text(
                  'Menu',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable body ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  AppDimens.base, AppDimens.base, AppDimens.base, bottomPad + AppDimens.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile card ──────────────────────────────────────
                  _ProfileCard(
                    status: status,
                    dark: dark,
                    textPrimary: textPrimary,
                    textSec: textSec,
                  ),
                  const SizedBox(height: AppDimens.base),

                  // ── Stats row ─────────────────────────────────────────
                  Row(children: [
                    _StatCard(
                      icon: Icons.account_balance_wallet_rounded,
                      accent: AppColors.success,
                      label: 'Earned Today',
                      value: 'LYD 0.00',
                      dark: dark,
                      textPrimary: textPrimary,
                      textSec: textSec,
                    ),
                    const SizedBox(width: AppDimens.sm),
                    _StatCard(
                      icon: Icons.delivery_dining_rounded,
                      accent: AppColors.info,
                      label: 'Deliveries',
                      value: '0',
                      dark: dark,
                      textPrimary: textPrimary,
                      textSec: textSec,
                    ),
                    const SizedBox(width: AppDimens.sm),
                    _StatCard(
                      icon: Icons.star_rounded,
                      accent: AppColors.warning,
                      label: 'Rating',
                      value: '4.9 ★',
                      dark: dark,
                      textPrimary: textPrimary,
                      textSec: textSec,
                    ),
                  ]),
                  const SizedBox(height: AppDimens.base),

                  // ── Theme toggle ──────────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(themeModeProvider.notifier).state =
                          dark ? ThemeMode.light : ThemeMode.dark;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.base, vertical: AppDimens.md),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusLg),
                        border: Border.all(color: divider),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: dark
                                ? AppColors.warning.withValues(alpha: 0.15)
                                : AppColors.info.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            dark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: dark ? AppColors.warning : AppColors.info,
                            size: AppDimens.iconMd,
                          ),
                        ),
                        const SizedBox(width: AppDimens.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dark ? 'Light Mode' : 'Dark Mode',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                dark
                                    ? 'Switch to light theme'
                                    : 'Switch to dark theme',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: textSec,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Animated pill switch
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          width: 48,
                          height: 28,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: dark
                                ? AppColors.info
                                : AppColors.dividerLight,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusFull),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: dark
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: AppDimens.sm),

                  // ── Nav section ────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: divider),
                    ),
                    child: Column(children: [
                      _NavItem(
                        icon: Icons.bar_chart_rounded,
                        accent: AppColors.primaryGreen,
                        label: 'Analytics',
                        sub: 'Earnings, deliveries & stats',
                        divider: divider,
                        textPrimary: textPrimary,
                        textSec: textSec,
                        isFirst: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DriverAnalyticsScreen(),
                          ),
                        ),
                      ),
                      _NavItem(
                        icon: Icons.history_rounded,
                        accent: AppColors.info,
                        label: 'Delivery History',
                        sub: 'View all past trips',
                        divider: divider,
                        textPrimary: textPrimary,
                        textSec: textSec,
                        onTap: () => Navigator.pop(context),
                      ),
                      _NavItem(
                        icon: Icons.account_balance_wallet_rounded,
                        accent: AppColors.success,
                        label: 'Wallet & Earnings',
                        sub: 'Balance · Payouts',
                        divider: divider,
                        textPrimary: textPrimary,
                        textSec: textSec,
                        onTap: () => Navigator.pop(context),
                      ),
                      _NavItem(
                        icon: Icons.star_rounded,
                        accent: AppColors.warning,
                        label: 'My Rating',
                        sub: '4.9 · 127 reviews',
                        divider: divider,
                        textPrimary: textPrimary,
                        textSec: textSec,
                        onTap: () => Navigator.pop(context),
                      ),
                      _NavItem(
                        icon: Icons.support_agent_rounded,
                        accent: AppColors.primaryGreen,
                        label: 'Support',
                        sub: 'Help & contact',
                        divider: divider,
                        textPrimary: textPrimary,
                        textSec: textSec,
                        onTap: () => Navigator.pop(context),
                      ),
                      _NavItem(
                        icon: Icons.tune_rounded,
                        accent: AppColors.textSecondaryLight,
                        label: 'Settings',
                        sub: 'Notifications · Account',
                        divider: divider,
                        textPrimary: textPrimary,
                        textSec: textSec,
                        isLast: true,
                        onTap: () => Navigator.pop(context),
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppDimens.sm),

                  // ── Danger zone ───────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: divider),
                    ),
                    child: Column(children: [
                      _NavItem(
                        icon: Icons.delete_outline_rounded,
                        accent: AppColors.error,
                        label: 'Request Account Deletion',
                        sub: 'Permanently remove your account',
                        divider: divider,
                        textPrimary: AppColors.error,
                        textSec: textSec,
                        isFirst: true,
                        onTap: () => _showDeleteDialog(context, dark,
                            textPrimary, textSec, divider, cardBg),
                      ),
                      _NavItem(
                        icon: Icons.logout_rounded,
                        accent: AppColors.error,
                        label: 'Sign Out',
                        sub: '',
                        divider: divider,
                        textPrimary: AppColors.error,
                        textSec: textSec,
                        isLast: true,
                        onTap: () => Navigator.pop(context),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, bool dark, Color textPrimary,
      Color textSec, Color divider, Color cardBg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusXl)),
        title: Text(
          'Delete Account?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        content: Text(
          'Your account deletion request will be reviewed within 7 days. All your data will be permanently removed.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: textSec,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: textSec,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Request Deletion',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final DriverStatus status;
  final bool dark;
  final Color textPrimary;
  final Color textSec;
  const _ProfileCard({
    required this.status,
    required this.dark,
    required this.textPrimary,
    required this.textSec,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = status != DriverStatus.offline;
    return Container(
      padding: const EdgeInsets.all(AppDimens.base),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(
          color: dark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(children: [
        // Avatar
        Stack(children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'D',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.primaryGreen : AppColors.textSecondaryLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: dark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  width: 2.5,
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(width: AppDimens.md),

        // Name + rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                const Icon(Icons.star_half_rounded, color: AppColors.warning, size: 14),
                const SizedBox(width: AppDimens.xs),
                Text(
                  '4.9',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSec,
                  ),
                ),
              ]),
            ],
          ),
        ),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md, vertical: AppDimens.xs),
          decoration: BoxDecoration(
            color: isOnline
                ? AppColors.primaryGreen.withValues(alpha: 0.12)
                : AppColors.textSecondaryLight.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          ),
          child: Text(
            switch (status) {
              DriverStatus.offline    => 'Offline',
              DriverStatus.online     => 'Online',
              DriverStatus.onDelivery => 'On Delivery',
            },
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isOnline ? AppColors.primaryGreen : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final bool dark;
  final Color textPrimary;
  final Color textSec;
  const _StatCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.dark,
    required this.textPrimary,
    required this.textSec,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppDimens.base, horizontal: AppDimens.sm),
        decoration: BoxDecoration(
          color: dark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(
            color: dark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Column(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: AppDimens.iconSm + 2),
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: textSec,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String sub;
  final Color divider;
  final Color textPrimary;
  final Color textSec;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.accent,
    required this.label,
    required this.sub,
    required this.divider,
    required this.textPrimary,
    required this.textSec,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(AppDimens.radiusLg) : Radius.zero,
        bottom: isLast ? const Radius.circular(AppDimens.radiusLg) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.base, vertical: AppDimens.md),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : Border(top: BorderSide(color: divider, width: 0.5)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Icon(icon, color: accent, size: AppDimens.iconMd),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: textSec,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: AppDimens.iconMd,
              color: textSec.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }
}
