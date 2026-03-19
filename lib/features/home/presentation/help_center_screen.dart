import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final Set<int> _expanded = {};

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
    final divider     = dark ? AppColors.dividerDark     : AppColors.dividerLight;

    final faqs = [
      (q: l.faqQ1, a: l.faqA1),
      (q: l.faqQ2, a: l.faqA2),
      (q: l.faqQ3, a: l.faqA3),
      (q: l.faqQ4, a: l.faqA4),
    ];

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
            title: Text(l.helpCenter, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppDimens.base, AppDimens.base, AppDimens.base, MediaQuery.paddingOf(context).bottom + AppDimens.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Search-like decorative header
                Container(
                  padding: const EdgeInsets.all(AppDimens.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGreen.withValues(alpha: 0.15), AppColors.primaryGreen.withValues(alpha: 0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.20)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                      child: const Icon(Icons.headset_mic_rounded, color: AppColors.primaryGreen, size: 24),
                    ),
                    const SizedBox(width: AppDimens.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.howCanWeHelp, style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                      const SizedBox(height: 2),
                      Text(l.contactSupportSub, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textSec)),
                    ])),
                  ]),
                ),

                const SizedBox(height: AppDimens.xl),

                Text(l.faqTitle, style: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w700, color: textSec, letterSpacing: 0.8)),
                const SizedBox(height: AppDimens.sm),

                // FAQ accordion
                Container(
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: borderColor)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: List.generate(faqs.length, (i) {
                      final isOpen = _expanded.contains(i);
                      final isLast = i == faqs.length - 1;
                      return Column(children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (isOpen) { _expanded.remove(i); }
                              else { _expanded.add(i); }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppDimens.base, vertical: AppDimens.md),
                            child: Row(children: [
                              Expanded(child: Text(faqs[i].q, style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary))),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                duration: const Duration(milliseconds: 200),
                                turns: isOpen ? 0.25 : 0,
                                child: Icon(Icons.chevron_right_rounded, size: 18, color: textSec),
                              ),
                            ]),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Container(
                            padding: EdgeInsets.fromLTRB(AppDimens.base, 0, AppDimens.base, AppDimens.md),
                            child: Text(faqs[i].a, style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: textSec, height: 1.5)),
                          ),
                          crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                        if (!isLast) Divider(height: 0.5, thickness: 0.5, color: divider),
                      ]);
                    }),
                  ),
                ),

                const SizedBox(height: AppDimens.xl),

                // Quick contact buttons
                Text(l.contactSupportTitle, style: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w700, color: textSec, letterSpacing: 0.8)),
                const SizedBox(height: AppDimens.sm),
                Row(children: [
                  _ContactBtn(
                    icon: Icons.chat_rounded,
                    label: l.whatsApp,
                    color: const Color(0xFF25D366),
                    dark: dark,
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/218910000000');
                      if (await canLaunchUrl(uri)) { launchUrl(uri, mode: LaunchMode.externalApplication); }
                    },
                  ),
                  const SizedBox(width: AppDimens.sm),
                  _ContactBtn(
                    icon: Icons.call_rounded,
                    label: l.callSupport,
                    color: AppColors.primaryGreen,
                    dark: dark,
                    onTap: () async {
                      final uri = Uri.parse('tel:+218910000000');
                      if (await canLaunchUrl(uri)) { launchUrl(uri); }
                    },
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool dark;
  final VoidCallback onTap;
  const _ContactBtn({required this.icon, required this.label, required this.color, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fontFamily  = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.mediumImpact(); onTap(); },
        child: Container(
          height: 54,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: color.withValues(alpha: 0.30))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ),
    );
  }
}
