import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/core/providers/locale_provider.dart';
import 'package:barq_driver/core/utils/app_haptics.dart';

const _kDriverOnboardedKey = 'driver_onboarded';
const _kLanguagePickedKey  = 'driver_language_picked';

class LanguagePickerScreen extends ConsumerStatefulWidget {
  const LanguagePickerScreen({super.key});

  @override
  ConsumerState<LanguagePickerScreen> createState() =>
      _LanguagePickerScreenState();
}

class _LanguagePickerScreenState
    extends ConsumerState<LanguagePickerScreen>
    with SingleTickerProviderStateMixin {
  String _selected   = 'en';
  bool   _continuing = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    // Pre-select based on system locale
    final systemCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _selected = systemCode == 'ar' ? 'ar' : 'en';

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_continuing) return;
    setState(() => _continuing = true);
    AppHaptics.medium();
    await ref.read(localeProvider.notifier).setLocale(Locale(_selected));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLanguagePickedKey, true);
    final onboarded = prefs.getBool(_kDriverOnboardedKey) ?? false;
    if (!mounted) return;
    context.go(onboarded ? '/login' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = _selected == 'ar' ? 'Cairo' : 'Inter';
    final isAr       = _selected == 'ar';

    const langs = [
      (code: 'en', label: 'English',  native: 'English',  flag: '🇬🇧'),
      (code: 'ar', label: 'Arabic',   native: 'العربية',  flag: '🟢'),
    ];

    const bg          = Color(0xFF0E0E0E);
    const cardBg      = Color(0xFF1A1A1A);
    const border      = Color(0xFF2C2C2C);
    const textPrimary = Colors.white;
    const textSec     = Color(0xFF888888);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimens.huge),

                  // ── Logo ─────────────────────────────────────────────
                  Center(
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                          Colors.white, BlendMode.srcIn),
                      child: Image.asset(
                          'assets/images/barq_logo.png',
                          width: 48, height: 48),
                    ),
                  ),
                  const SizedBox(height: AppDimens.xxxl),

                  // ── Heading ───────────────────────────────────────────
                  Text(
                    isAr ? 'اختر لغتك' : 'Choose your language',
                    style: TextStyle(
                      fontFamily:    fontFamily,
                      fontSize:      AppDimens.textH1,
                      fontWeight:    FontWeight.w800,
                      color:         textPrimary,
                      letterSpacing: -0.8,
                      height:        1.15,
                    ),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    isAr
                        ? 'يمكنك تغيير هذا في أي وقت'
                        : 'You can change this anytime in Settings',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize:   AppDimens.textBase,
                      color:      textSec,
                      height:     1.5,
                    ),
                  ),
                  const SizedBox(height: AppDimens.xxxl),

                  // ── Language options ──────────────────────────────────
                  ...langs.map((lang) {
                    final isSelected = _selected == lang.code;
                    final lf = lang.code == 'ar' ? 'Cairo' : 'Inter';
                    return GestureDetector(
                      onTap: () {
                        AppHaptics.select();
                        setState(() => _selected = lang.code);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: AppDimens.sm),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.base,
                            vertical:   AppDimens.md + 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.08)
                              : cardBg,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusXl),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.35)
                                : border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width:  44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusMd),
                              ),
                              child: Center(
                                child: lang.code == 'ar'
                                    ? Container(
                                        width:  26,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF009A00),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      )
                                    : Text(lang.flag,
                                        style: const TextStyle(fontSize: 22)),
                              ),
                            ),
                            const SizedBox(width: AppDimens.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lang.native,
                                      style: TextStyle(
                                          fontFamily:  lf,
                                          fontSize:    AppDimens.textXl,
                                          fontWeight:  FontWeight.w700,
                                          color:       textPrimary)),
                                  Text(lang.label,
                                      style: TextStyle(
                                          fontFamily: lf,
                                          fontSize:   AppDimens.textSm,
                                          color:      textSec)),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width:  22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : border,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      size: 13, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const Spacer(),

                  // ── Continue button ───────────────────────────────────
                  GestureDetector(
                    onTap: _continue,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: AppDimens.buttonHeight,
                      decoration: BoxDecoration(
                        color: _continuing
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                      ),
                      alignment: Alignment.center,
                      child: _continuing
                          ? const SizedBox(
                              width:  22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.black),
                            )
                          : Text(
                              isAr ? 'متابعة' : 'Continue',
                              style: TextStyle(
                                fontFamily:    fontFamily,
                                fontSize:      AppDimens.textXl,
                                fontWeight:    FontWeight.w700,
                                color:         Colors.black,
                                letterSpacing: -0.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
