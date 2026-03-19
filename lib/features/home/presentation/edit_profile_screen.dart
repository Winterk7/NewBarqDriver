import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/core/providers/driver_orders_provider.dart';
import 'package:barq_driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading  = false;
  bool _saving   = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) { setState(() => _loading = false); return; }
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('full_name, phone')
          .eq('id', userId)
          .limit(1);
      if (rows.isNotEmpty) {
        final data = rows.first;
        _nameCtrl.text  = (data['full_name'] as String? ?? '').trim();
        _phoneCtrl.text = (data['phone'] as String? ?? '').trim();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save(AppLocalizations l) async {
    final name  = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() { _saving = true; _error = null; });
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) { setState(() => _saving = false); return; }
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'full_name': name, 'phone': phone})
          .eq('id', userId);
      // Invalidate cached profile so menu page reflects the change.
      ref.invalidate(driverProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.profileUpdated),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
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

    Widget field({
      required TextEditingController ctrl,
      required String label,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text,
    }) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: textSec, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: TextStyle(fontFamily: fontFamily, fontSize: 15, color: textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: textSec),
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          ),
        ),
        const SizedBox(height: AppDimens.base),
      ]);
    }

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
                  title: Text(l.editProfile, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4)),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(AppDimens.base, AppDimens.base, AppDimens.base, MediaQuery.paddingOf(context).bottom + AppDimens.xl),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Avatar placeholder
                      Center(
                        child: Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: dark ? [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)] : [const Color(0xFFE5E7EB), const Color(0xFFF3F4F6)]),
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'D',
                              style: TextStyle(fontFamily: fontFamily, fontSize: 34, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.xl),

                      // Card
                      Container(
                        padding: const EdgeInsets.all(AppDimens.base),
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(AppDimens.radiusXl), border: Border.all(color: borderColor)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          field(ctrl: _nameCtrl,  label: l.fullName,    icon: Icons.person_rounded),
                          field(ctrl: _phoneCtrl, label: l.phoneNumber, icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
                        ]),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: AppDimens.md),
                        Container(
                          padding: const EdgeInsets.all(AppDimens.md),
                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                          child: Text(_error!, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: AppColors.error)),
                        ),
                      ],

                      const SizedBox(height: AppDimens.xl),

                      GestureDetector(
                        onTap: _saving ? null : () { HapticFeedback.mediumImpact(); _save(l); },
                        child: Container(
                          height: AppDimens.buttonHeight,
                          decoration: BoxDecoration(
                            color: _saving ? AppColors.primaryGreen.withValues(alpha: 0.60) : AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          ),
                          alignment: Alignment.center,
                          child: _saving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                              : Text(l.saveChanges, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
