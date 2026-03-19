import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPassCtrl  = TextEditingController();
  final _confPassCtrl = TextEditingController();
  bool _saving  = false;
  bool _obscNew = true;
  bool _obscCon = true;
  String? _error;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l) async {
    final np = _newPassCtrl.text.trim();
    final cp = _confPassCtrl.text.trim();
    if (np.length < 8) { setState(() => _error = l.passwordTooShort); return; }
    if (np != cp)       { setState(() => _error = l.passwordsDontMatch); return; }
    setState(() { _saving = true; _error = null; });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: np),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.passwordChanged),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryGreen,
        ));
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final dark        = Theme.of(context).brightness == Brightness.dark;
    final l           = AppLocalizations.of(context)!;
    final fontFamily  = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    final bg          = dark ? AppColors.backgroundDark  : AppColors.backgroundLight;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSec     = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardBg      = dark ? AppColors.cardDark        : AppColors.cardLight;
    final borderColor = dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.09);
    final inputFill   = dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    InputDecoration inputDeco({required String hint, required bool obscure, required VoidCallback toggle}) =>
        InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontFamily: fontFamily, color: textSec.withValues(alpha: 0.50)),
          filled: true,
          fillColor: inputFill,
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: textSec),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd), borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        );

    Widget fieldRow(String label, TextEditingController ctrl, bool obscure, VoidCallback toggleObscure) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: textSec, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            obscureText: obscure,
            style: TextStyle(fontFamily: fontFamily, fontSize: 15, color: textPrimary),
            decoration: inputDeco(hint: '••••••••', obscure: obscure, toggle: toggleObscure),
          ),
          const SizedBox(height: AppDimens.base),
        ]);

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
            title: Text(l.changePassword, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppDimens.base, AppDimens.base, AppDimens.base, MediaQuery.paddingOf(context).bottom + AppDimens.xl),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(AppDimens.base),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(AppDimens.radiusXl), border: Border.all(color: borderColor)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    fieldRow(l.newPassword, _newPassCtrl, _obscNew, () => setState(() => _obscNew = !_obscNew)),
                    fieldRow(l.confirmPassword, _confPassCtrl, _obscCon, () => setState(() => _obscCon = !_obscCon)),
                  ]),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppDimens.md),
                  Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                    child: Row(children: [
                      const Icon(Icons.error_rounded, size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_error!, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: AppColors.error))),
                    ]),
                  ),
                ],
                const SizedBox(height: AppDimens.xl),
                GestureDetector(
                  onTap: _saving ? null : () { HapticFeedback.mediumImpact(); _submit(l); },
                  child: Container(
                    height: AppDimens.buttonHeight,
                    decoration: BoxDecoration(
                      color: _saving ? AppColors.primaryGreen.withValues(alpha: 0.60) : AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : Text(l.updatePassword, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
