import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class DriverAnalyticsScreen extends StatefulWidget {
  const DriverAnalyticsScreen({super.key});

  @override
  State<DriverAnalyticsScreen> createState() => _DriverAnalyticsScreenState();
}

class _DriverAnalyticsScreenState extends State<DriverAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  int _period = 1; // 0=week 1=month 2=year

  // Mock data
  static const _weeklyEarnings = [45.0, 82.0, 61.0, 110.0, 94.0, 128.0, 55.0];

  @override
  Widget build(BuildContext context) {
    final dark         = Theme.of(context).brightness == Brightness.dark;
    final l            = AppLocalizations.of(context)!;
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    final bg           = dark ? AppColors.backgroundDark   : AppColors.backgroundLight;
    final textPrimary  = dark ? AppColors.textPrimaryDark  : AppColors.textPrimaryLight;
    final textSec      = dark ? AppColors.textSecondaryDark: AppColors.textSecondaryLight;
    final cardBg       = dark ? AppColors.cardDark         : AppColors.cardLight;
    final borderColor  = dark ? AppColors.dividerDark      : AppColors.dividerLight;
    final divider      = dark ? AppColors.dividerDark      : AppColors.dividerLight;

    final maxBar = _weeklyEarnings.reduce((a, b) => a > b ? a : b);
    final weekLabels = [l.dayMon, l.dayTue, l.dayWed, l.dayThu, l.dayFri, l.daySat, l.daySun];

    Widget pill(String label, int i) => GestureDetector(
          onTap: () => setState(() => _period = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.md, vertical: AppDimens.xs),
            decoration: BoxDecoration(
              color: _period == i
                  ? (dark ? Colors.white : Colors.black)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              border: Border.all(
                color: _period == i
                    ? Colors.transparent
                    : (dark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _period == i
                    ? (dark ? Colors.black : Colors.white)
                    : textSec,
              ),
            ),
          ),
        );

    Widget statCard(String label, String value, String sub,
            Color accent, IconData icon) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                value,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontFamily: fontFamily, fontSize: 11, color: textSec)),
              const SizedBox(height: AppDimens.xs),
              Text(sub,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  )),
            ]),
          ),
        );

    Widget sectionTitle(String t) => Padding(
          padding:
              const EdgeInsets.fromLTRB(0, AppDimens.xl, 0, AppDimens.md),
          child: Text(
            t,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        );

    Widget deliveryRow(String label, int count, int total, Color color,
            {bool isFirst = false}) =>
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.base, vertical: AppDimens.md),
          decoration: BoxDecoration(
            border: isFirst
                ? null
                : Border(top: BorderSide(color: divider, width: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: AppDimens.xs),
                Text(
                  '(${total > 0 ? (count / total * 100).toStringAsFixed(0) : 0}%)',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 12,
                    color: textSec,
                  ),
                ),
              ]),
              const SizedBox(height: AppDimens.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.xs),
                child: SizedBox(
                  height: 5,
                  child: Stack(children: [
                    Container(
                      color: dark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                    ),
                    FractionallySizedBox(
                      widthFactor:
                          total > 0 ? (count / total).clamp(0.0, 1.0) : 0,
                      child: Container(color: color),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(AppDimens.sm),
                decoration: BoxDecoration(
                  color: dark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Icon(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    size: AppDimens.iconSm,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
            title: Text(
              l.analytics,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.base,
                AppDimens.sm,
                AppDimens.base,
                MediaQuery.paddingOf(context).bottom + AppDimens.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  Row(children: [
                    pill(l.week, 0),
                    const SizedBox(width: AppDimens.sm),
                    pill(l.month, 1),
                    const SizedBox(width: AppDimens.sm),
                    pill(l.year, 2),
                  ]),
                  const SizedBox(height: AppDimens.xl),

                  // Stat cards row 1
                  Row(children: [
                    statCard(l.earnings, '575 LYD', '+18% vs last month',
                        AppColors.primaryGreen, Icons.trending_up_rounded),
                    const SizedBox(width: AppDimens.sm),
                    statCard(l.deliveries, '48', '+6 vs last month',
                        AppColors.info, Icons.delivery_dining_rounded),
                  ]),
                  const SizedBox(height: AppDimens.sm),

                  // Stat cards row 2
                  Row(children: [
                    statCard(l.avgPerDelivery, '11.98 LYD', 'per trip',
                        AppColors.warning, Icons.calculate_rounded),
                    const SizedBox(width: AppDimens.sm),
                    statCard(l.rating, '4.9 ★', 'from 127 reviews',
                        AppColors.warning, Icons.star_rounded),
                  ]),

                  // Bar chart
                  sectionTitle(l.earningsThisWeek),
                  Container(
                    padding: const EdgeInsets.all(AppDimens.base),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(children: [
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(
                            _weeklyEarnings.length,
                            (i) {
                              const barMaxH = 90.0;
                              final ratio = (_weeklyEarnings[i] / maxBar)
                                  .clamp(0.08, 1.0);
                              final barH = barMaxH * ratio;
                              final isToday = i == DateTime.now().weekday - 1;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _weeklyEarnings[i].toStringAsFixed(0),
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 9,
                                      color: isToday
                                          ? AppColors.primaryGreen
                                          : textSec,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 28,
                                    height: barH,
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? AppColors.primaryGreen
                                          : (dark
                                              ? AppColors.dividerDark
                                              : AppColors.dividerLight),
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top: Radius.circular(AppDimens.xs),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: weekLabels
                            .map((lbl) => Text(
                                  lbl,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 11,
                                    color: textSec,
                                  ),
                                ))
                            .toList(),
                      ),
                    ]),
                  ),

                  // Delivery status
                  sectionTitle(l.deliveryStatus),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(children: [
                      deliveryRow(
                          l.completed, 42, 48, AppColors.success,
                          isFirst: true),
                      deliveryRow(
                          l.cancelled, 4, 48, AppColors.error),
                      deliveryRow(
                          l.failed, 2, 48, AppColors.warning),
                    ]),
                  ),

                  // Distance breakdown
                  sectionTitle(l.distanceBreakdown),
                  Container(
                    padding: const EdgeInsets.all(AppDimens.base),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(children: [
                      _KmRow(
                        label: l.totalKmDriven,
                        value: '312 km',
                        textPrimary: textPrimary,
                        textSec: textSec,
                        divider: divider,
                        isFirst: true,
                      ),
                      _KmRow(
                        label: l.avgPerDeliveryKm,
                        value: '6.5 km',
                        textPrimary: textPrimary,
                        textSec: textSec,
                        divider: divider,
                      ),
                      _KmRow(
                        label: l.longestTrip,
                        value: '18.2 km',
                        textPrimary: textPrimary,
                        textSec: textSec,
                        divider: divider,
                        isLast: true,
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppDimens.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KmRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSec;
  final Color divider;
  final bool isFirst;
  final bool isLast;
  const _KmRow({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSec,
    required this.divider,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : Border(top: BorderSide(color: divider, width: 0.5)),
      ),
      child: Row(children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSec,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ]),
    );
  }
}
