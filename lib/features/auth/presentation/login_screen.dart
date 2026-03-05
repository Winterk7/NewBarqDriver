import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _logoFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _formFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    ));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // Role check — only drivers can use this app
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', res.user!.id)
          .maybeSingle();
      final role = profile?['role'] as String?;
      if (role != 'driver') {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This account is not registered as a driver.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      // Router refreshListenable handles navigation
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable centre zone ─────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height -
                        MediaQuery.paddingOf(context).top -
                        MediaQuery.paddingOf(context).bottom -
                        48,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppDimens.xxxl),

                        // ── Logo ──────────────────────────────────────
                        Center(
                          child: FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: Image.asset(
                                'assets/images/barq_logo.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.contain,
                                color: isDark ? null : Colors.black,
                                colorBlendMode:
                                    isDark ? null : BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppDimens.xxl),

                        // ── Heading ───────────────────────────────────
                        SlideTransition(
                          position: _formSlide,
                          child: FadeTransition(
                            opacity: _formFade,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                    letterSpacing: -1.0,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: AppDimens.xs),
                                Text(
                                  'Sign in to start delivering',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        cs.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppDimens.xxl),

                        // ── Form ──────────────────────────────────────
                        SlideTransition(
                          position: _formSlide,
                          child: FadeTransition(
                            opacity: _formFade,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel(
                                    label: 'Email address',
                                    color:
                                        cs.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: AppDimens.sm),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                    ),
                                    decoration: _inputDeco(
                                      context: context,
                                      hint: 'you@example.com',
                                      icon: Icons.email_outlined,
                                    ),
                                    validator: (v) =>
                                        (v == null || !v.contains('@'))
                                            ? 'Enter a valid email'
                                            : null,
                                  ),
                                  const SizedBox(height: AppDimens.base),
                                  _FieldLabel(
                                    label: 'Password',
                                    color:
                                        cs.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: AppDimens.sm),
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _signIn(),
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                    ),
                                    decoration: _inputDeco(
                                      context: context,
                                      hint: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.4),
                                          size: AppDimens.iconMd,
                                        ),
                                        onPressed: () => setState(
                                            () => _obscure = !_obscure),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.length < 6)
                                            ? 'Password must be at least 6 characters'
                                            : null,
                                  ),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        foregroundColor: cs.onSurface
                                            .withValues(alpha: 0.5),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 0,
                                          vertical: AppDimens.sm,
                                        ),
                                      ),
                                      child: const Text(
                                        'Forgot password?',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: AppDimens.sm),

                                  // Sign in button
                                  SizedBox(
                                    width: double.infinity,
                                    height: AppDimens.buttonHeight,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _signIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.backgroundDark,
                                        foregroundColor: isDark
                                            ? AppColors.backgroundDark
                                            : AppColors.textPrimaryDark,
                                        disabledBackgroundColor: isDark
                                            ? AppColors.textPrimaryDark
                                                .withValues(alpha: 0.4)
                                            : AppColors.backgroundDark
                                                .withValues(alpha: 0.4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppDimens.radiusMd,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _loading
                                          ? SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: isDark
                                                    ? AppColors.backgroundDark
                                                    : AppColors.textPrimaryDark,
                                              ),
                                            )
                                          : Text(
                                              'Sign in',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.backgroundDark
                                                    : AppColors.textPrimaryDark,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppDimens.xxxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Terms bar (pinned to bottom) ───────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.xl,
                AppDimens.sm,
                AppDimens.xl,
                bottom + AppDimens.md,
              ),
              child: Text(
                'By signing in, you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurface.withValues(alpha: 0.35),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required BuildContext context,
    required String hint,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      prefixIcon: Icon(
        icon,
        size: AppDimens.iconMd,
        color: cs.onSurface.withValues(alpha: 0.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide(
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.backgroundDark,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: cs.onSurface.withValues(alpha: 0.35),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.base,
        vertical: AppDimens.md,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _FieldLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.1,
      ),
    );
  }
}
