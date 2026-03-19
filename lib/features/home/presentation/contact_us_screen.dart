import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

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

    Future<void> launch(String url) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    Widget contactRow({required IconData icon, required String title, required String subtitle, required Color iconColor, required VoidCallback onTap}) =>
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () { HapticFeedback.mediumImpact(); onTap(); },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.base, vertical: AppDimens.md + 2),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                Text(subtitle, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textSec)),
              ])),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSec.withValues(alpha: 0.40)),
            ]),
          ),
        );

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
            title: Text(l.contactUs, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppDimens.base, AppDimens.base, AppDimens.base, MediaQuery.paddingOf(context).bottom + AppDimens.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppDimens.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF25D366).withValues(alpha: 0.12), const Color(0xFF25D366).withValues(alpha: 0.03)],
                    ),
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.20)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                      child: const Icon(Icons.support_agent_rounded, color: Color(0xFF25D366), size: 24),
                    ),
                    const SizedBox(width: AppDimens.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.contactSupportTitle, style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                      const SizedBox(height: 2),
                      Text(l.contactSupportSub, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textSec)),
                    ])),
                  ]),
                ),

                const SizedBox(height: AppDimens.xl),

                Container(
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: borderColor)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    contactRow(
                      icon: Icons.chat_rounded,
                      title: l.whatsApp,
                      subtitle: '+218 91 000 0000',
                      iconColor: const Color(0xFF25D366),
                      onTap: () => launch('https://wa.me/218910000000'),
                    ),
                    Divider(height: 0.5, thickness: 0.5, indent: AppDimens.base, color: dark ? AppColors.dividerDark : AppColors.dividerLight),
                    contactRow(
                      icon: Icons.call_rounded,
                      title: l.callSupport,
                      subtitle: '+218 91 000 0000',
                      iconColor: AppColors.primaryGreen,
                      onTap: () => launch('tel:+218910000000'),
                    ),
                    Divider(height: 0.5, thickness: 0.5, indent: AppDimens.base, color: dark ? AppColors.dividerDark : AppColors.dividerLight),
                    contactRow(
                      icon: Icons.email_rounded,
                      title: l.emailSupport,
                      subtitle: 'support@barq.ly',
                      iconColor: const Color(0xFF6366F1),
                      onTap: () => launch('mailto:support@barq.ly'),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
