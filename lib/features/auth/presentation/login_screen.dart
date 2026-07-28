import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/core/utils/app_haptics.dart';
import 'package:barq_driver/core/utils/snack_helper.dart';
import 'package:barq_driver/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();

  bool _obscure  = true;
  bool _loading  = false;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeIn;
  late final Animation<Offset>   _slideUp;

  late final AnimationController _glowCtrl;
  late final Animation<double>   _glowAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _glowAnim =
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _animCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      setState(() => _emailError = AppLocalizations.of(context)!.enterValidEmail);
      ok = false;
    } else {
      setState(() => _emailError = null);
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _passwordError = AppLocalizations.of(context)!.passwordTooShort);
      ok = false;
    } else {
      setState(() => _passwordError = null);
    }
    return ok;
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    AppHaptics.medium();
    if (!_validate()) {
      AppHaptics.error();
      return;
    }
    setState(() { _loading = true; _generalError = null; });
    final l = AppLocalizations.of(context)!;
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', res.user!.id)
          .maybeSingle();
      if ((profile?['role'] as String?) != 'driver') {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        setState(() { _loading = false; _generalError = l.errorWrongRole; });
        AppHaptics.error();
        return;
      }
      AppHaptics.success();
      // Router refreshListenable handles navigation automatically
    } on AuthException catch (_) {
      if (!mounted) return;
      AppHaptics.error();
      setState(() { _loading = false; _generalError = l.errorInvalidCredentials; });
    } catch (_) {
      if (!mounted) return;
      AppHaptics.error();
      setState(() { _loading = false; _generalError = l.errorGeneric; });
    }
  }

  Future<void> _forgotPassword() async {
    AppHaptics.light();
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = AppLocalizations.of(context)!.enterValidEmail);
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      showBarqSnack(context, 'Password reset email sent. Check your inbox.',
          isSuccess: true);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _generalError = e.message);
    }
  }

  Widget _formCard(bool isDark, String fontFamily) {
    final textPrimary   = isDark ? Colors.white : AppColors.contentTextPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppDimens.xl),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.08))
            : Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLabel(l.emailAddress, textPrimary),
          const SizedBox(height: 6),
          _InputField(
            controller:      _emailCtrl,
            focusNode:       _emailFocus,
            nextFocus:       _passFocus,
            errorText:       _emailError,
            isDark:          isDark,
            textPrimary:     textPrimary,
            textSecondary:   textSecondary,
            textInputAction: TextInputAction.next,
            keyboardType:    TextInputType.emailAddress,
          ),

          const SizedBox(height: AppDimens.md),

          _FieldLabel(l.password, textPrimary),
          const SizedBox(height: 6),
          _InputField(
            controller:      _passCtrl,
            focusNode:       _passFocus,
            errorText:       _passwordError,
            isDark:          isDark,
            textPrimary:     textPrimary,
            textSecondary:   textSecondary,
            obscureText:     _obscure,
            textInputAction: TextInputAction.done,
            keyboardType:    TextInputType.visiblePassword,
            onSubmitted:     (_) => _signIn(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                size:  18,
                color: textSecondary,
              ),
              onPressed: () {
                AppHaptics.select();
                setState(() => _obscure = !_obscure);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final bg            = isDark ? AppColors.featureBgDark : AppColors.featureBgLight;
    final textPrimary   = isDark ? Colors.white : AppColors.contentTextPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final topPadding    = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final languageCode  = Localizations.localeOf(context).languageCode;
    final fontFamily    = languageCode == 'ar' ? 'Cairo' : 'Inter';
    final l             = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Breathing glow ────────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) {
                final t         = _glowAnim.value;
                final cx        = 0.20 + t * 0.60;
                final intensity = isDark
                    ? (0.06 + t * 0.07)
                    : (0.04 + t * 0.05);
                final glowColor = isDark
                    ? Color.fromRGBO(255, 160, 60,  intensity.clamp(0.0, 1.0))
                    : Color.fromRGBO(255, 200, 120, intensity.clamp(0.0, 1.0));
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(cx * 2 - 1, -0.6),
                      radius: 0.9,
                      colors: [glowColor, Colors.transparent],
                    ),
                  ),
                );
              },
            ),
          ),

          Column(
            children: [
              // ── App bar: back arrow + title ────────────────────────────────
              SizedBox(
                height: topPadding + 60,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      AppDimens.xl, topPadding + AppDimens.md, AppDimens.xl, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          AppHaptics.light();
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/onboarding');
                          }
                        },
                        child: Container(
                          width:  38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusMd),
                            border: isDark
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.08))
                                : null,
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Icon(
                              languageCode == 'ar'
                                  ? Icons.arrow_forward_ios_rounded
                                  : Icons.arrow_back_ios_new_rounded,
                              size:  16,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        l.signIn,
                        style: TextStyle(
                          fontFamily:    fontFamily,
                          fontSize:      AppDimens.textH3,
                          fontWeight:    FontWeight.w700,
                          color:         textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Scrollable body ────────────────────────────────────────────
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                          AppDimens.xl, 0, AppDimens.xl,
                          bottomPadding + AppDimens.xl),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: FadeTransition(
                            opacity: _fadeIn,
                            child: SlideTransition(
                              position: _slideUp,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  const Spacer(flex: 2),

                                  // ── Logo ──────────────────────────────
                                  Center(
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        isDark ? Colors.white : Colors.black,
                                        BlendMode.srcIn,
                                      ),
                                      child: Image.asset(
                                          'assets/images/barq_logo.png',
                                          width: 36),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.lg),

                                  // ── Subtitle ──────────────────────────
                                  Center(
                                    child: Text(
                                      l.signInToStartDelivering,
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontSize:   AppDimens.textBase,
                                        color:      textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.xl),

                                  // ── Glass form card ────────────────────
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        AppDimens.radiusXl),
                                    child: isDark
                                        ? BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 12, sigmaY: 12),
                                            child: _formCard(isDark, fontFamily),
                                          )
                                        : _formCard(isDark, fontFamily),
                                  ),

                                  // ── General error ──────────────────────
                                  if (_generalError != null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.error
                                            .withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(
                                            AppDimens.radiusSm),
                                        border: Border.all(
                                            color: AppColors.error
                                                .withValues(alpha: 0.25)),
                                      ),
                                      child: Text(
                                        _generalError!,
                                        style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize:   AppDimens.textMd,
                                          color:      AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: AppDimens.xl),

                                  // ── Submit button ──────────────────────
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    height: AppDimens.buttonHeight,
                                    decoration: BoxDecoration(
                                      color: _loading
                                          ? (isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.35)
                                              : Colors.black
                                                  .withValues(alpha: 0.35))
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black),
                                      borderRadius: BorderRadius.circular(
                                          AppDimens.radiusMd),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _signIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:  Colors.transparent,
                                        shadowColor:      Colors.transparent,
                                        foregroundColor:
                                            isDark ? Colors.black : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppDimens.radiusMd),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _loading
                                          ? SizedBox(
                                              width:  20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                        isDark
                                                            ? Colors.black
                                                            : Colors.white),
                                              ),
                                            )
                                          : Text(
                                              l.signIn,
                                              style: TextStyle(
                                                fontFamily:    fontFamily,
                                                fontSize:      AppDimens.textXl,
                                                fontWeight:    FontWeight.w600,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                    ),
                                  ),

                                  // ── Forgot password ────────────────────
                                  const SizedBox(height: AppDimens.lg),
                                  GestureDetector(
                                    onTap: _forgotPassword,
                                    child: Center(
                                      child: Text(
                                        l.forgotPassword,
                                        style: TextStyle(
                                          fontFamily:      fontFamily,
                                          fontSize:        AppDimens.textBase,
                                          fontWeight:      FontWeight.w500,
                                          color:           textSecondary,
                                          decoration:      TextDecoration.underline,
                                          decorationColor: textSecondary
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const Spacer(flex: 3),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color  color;
  const _FieldLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    final fontFamily =
        Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    return Text(
      text,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize:   AppDimens.textMd,
        fontWeight: FontWeight.w600,
        color:      color,
      ),
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final FocusNode?            nextFocus;
  final String?               errorText;
  final bool                  isDark;
  final Color                 textPrimary;
  final Color                 textSecondary;
  final bool                  obscureText;
  final TextInputAction       textInputAction;
  final TextInputType         keyboardType;
  final Widget?               suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    this.errorText,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    this.obscureText       = false,
    this.textInputAction   = TextInputAction.next,
    this.keyboardType      = TextInputType.text,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final fontFamily =
        Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: Border.all(
              color: errorText != null
                  ? AppColors.error.withValues(alpha: 0.5)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.10)),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: TextField(
            controller:      controller,
            focusNode:       focusNode,
            obscureText:     obscureText,
            textInputAction: textInputAction,
            keyboardType:    keyboardType,
            autocorrect:     false,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize:   AppDimens.textLg,
              color:      textPrimary,
            ),
            cursorColor: textPrimary,
            onSubmitted: onSubmitted ??
                (nextFocus != null
                    ? (_) => FocusScope.of(context).requestFocus(nextFocus)
                    : null),
            decoration: InputDecoration(
              suffixIcon:     suffixIcon,
              filled:         true,
              fillColor:      Colors.transparent,
              border:         InputBorder.none,
              enabledBorder:  InputBorder.none,
              focusedBorder:  InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize:   AppDimens.textXs,
              color:      AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
