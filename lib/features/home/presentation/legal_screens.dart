import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => _PolicyScreen(
        title: AppLocalizations.of(context)!.termsOfService,
        body: AppLocalizations.of(context)!.termsBody,
        icon: Icons.description_rounded,
        iconColor: AppColors.primaryGreen,
      );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => _PolicyScreen(
        title: AppLocalizations.of(context)!.privacyPolicy,
        body: AppLocalizations.of(context)!.privacyBody,
        icon: Icons.privacy_tip_rounded,
        iconColor: const Color(0xFF6366F1),
      );
}

class _PolicyScreen extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color iconColor;

  const _PolicyScreen({
    required this.title,
    required this.body,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final dark        = Theme.of(context).brightness == Brightness.dark;
    final l           = AppLocalizations.of(context)!;
    final fontFamily  = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    final bg          = dark ? AppColors.backgroundDark  : AppColors.backgroundLight;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSec     = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardBg      = dark ? AppColors.cardDark        : AppColors.cardLight;
    final borderColor = dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: textPrimary),
              ),
            ),
            title: Text(title, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppDimens.base, AppDimens.base, AppDimens.base, MediaQuery.paddingOf(context).bottom + AppDimens.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Icon header
                Container(
                  padding: const EdgeInsets.all(AppDimens.xl),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    border: Border.all(color: iconColor.withValues(alpha: 0.20)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: AppDimens.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                      const SizedBox(height: 2),
                      Text(l.lastUpdated, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textSec)),
                    ])),
                  ]),
                ),

                const SizedBox(height: AppDimens.xl),

                // Body text
                Container(
                  padding: const EdgeInsets.all(AppDimens.xl),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: borderColor)),
                  child: Text(body, style: TextStyle(fontFamily: fontFamily, fontSize: 14, color: textSec, height: 1.7)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
