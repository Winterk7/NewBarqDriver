import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _loading = true;
  double _totalEarned    = 0;
  double _thisMonth      = 0;
  double _thisWeek       = 0;
  double _pendingBalance = 0;
  int _deliveryCount     = 0;
  List<_EarnRow> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) { setState(() => _loading = false); return; }
    try {
      final rows = await Supabase.instance.client
          .from('orders')
          .select('id, created_at, delivery_fee, status, stores(name)')
          .eq('driver_id', userId)
          .order('created_at', ascending: false)
          .limit(200);
      final now = DateTime.now();
      final weekAgo  = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));
      double total = 0, month = 0, week = 0, pending = 0;
      int count = 0;
      final recent = <_EarnRow>[];
      for (final row in (rows as List).cast<Map<String, dynamic>>()) {
        final status  = row['status'] as String;
        final fee     = (row['delivery_fee'] as num?)?.toDouble() ?? 0.0;
        final dt      = DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ?? now;
        final store   = (row['stores'] as Map?)
?['name'] as String? ?? '—';
        if (status == 'delivered') {
          total += fee;
          count++;
          if (dt.isAfter(monthAgo)) month += fee;
          if (dt.isAfter(weekAgo))  week  += fee;
          if (recent.length < 12) recent.add(_EarnRow(store: store, fee: fee, date: dt));
        }
        if (status == 'picked_up' || status == 'accepted') pending += fee;
      }
      setState(() {
        _loading       = false;
        _totalEarned   = total;
        _thisMonth     = month;
        _thisWeek      = week;
        _pendingBalance= pending;
        _deliveryCount = count;
        _recent        = recent;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
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
    final borderColor = dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07);

    Widget statTile(String label, double amount, IconData icon, Color color) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: borderColor),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(height: AppDimens.sm),
              Text('LYD ${amount.toStringAsFixed(2)}',
                  style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontFamily: fontFamily, fontSize: 10, color: textSec)),
            ]),
          ),
        );

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
                  title: Text(l.walletEarnings, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4)),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(AppDimens.base, AppDimens.base, AppDimens.base, MediaQuery.paddingOf(context).bottom + AppDimens.xl),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Hero balance card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimens.xl),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryGreen, const Color(0xFF07805A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.totalEarned, style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: Colors.white.withValues(alpha: 0.80))),
                          const SizedBox(height: 6),
                          Text('LYD ${_totalEarned.toStringAsFixed(2)}',
                              style: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                          const SizedBox(height: 4),
                          Text('$_deliveryCount ${l.deliveries}', style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: Colors.white.withValues(alpha: 0.70))),
                        ]),
                      ),

                      const SizedBox(height: AppDimens.base),

                      // Stats row
                      Row(children: [
                        statTile(l.thisMonth, _thisMonth, Icons.calendar_month_rounded, AppColors.primaryGreen),
                        const SizedBox(width: AppDimens.sm),
                        statTile(l.week, _thisWeek, Icons.today_rounded, const Color(0xFF6366F1)),
                        const SizedBox(width: AppDimens.sm),
                        statTile(l.pendingBalance, _pendingBalance, Icons.pending_rounded, AppColors.warning),
                      ]),

                      if (_recent.isNotEmpty) ...[
                        const SizedBox(height: AppDimens.xl),
                        Text('Recent', style: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w700, color: textSec, letterSpacing: 0.8)),
                        const SizedBox(height: AppDimens.sm),
                        Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                            border: Border.all(color: borderColor),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: List.generate(_recent.length, (i) {
                              final row   = _recent[i];
                              final divB  = i < _recent.length - 1
                                  ? Border(bottom: BorderSide(color: dark ? AppColors.dividerDark : AppColors.dividerLight, width: 0.5))
                                  : null;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppDimens.base, vertical: AppDimens.md),
                                decoration: BoxDecoration(border: divB),
                                child: Row(children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                                    child: const Icon(Icons.local_shipping_rounded, size: 16, color: AppColors.primaryGreen),
                                  ),
                                  const SizedBox(width: AppDimens.md),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(row.store, style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                                    Text('${row.date.day}/${row.date.month}/${row.date.year}', style: TextStyle(fontFamily: fontFamily, fontSize: 11, color: textSec)),
                                  ])),
                                  Text('LYD ${row.fee.toStringAsFixed(2)}',
                                      style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                                ]),
                              );
                            }),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: AppDimens.xl),
                        Center(child: Column(children: [
                          Icon(Icons.account_balance_wallet_rounded, size: 48, color: textSec.withValues(alpha: 0.30)),
                          const SizedBox(height: AppDimens.sm),
                          Text(l.noEarningsYet, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                          const SizedBox(height: 4),
                          Text(l.noEarningsSub, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textSec), textAlign: TextAlign.center),
                        ])),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EarnRow {
  final String store;
  final double fee;
  final DateTime date;
  const _EarnRow({required this.store, required this.fee, required this.date});
}
