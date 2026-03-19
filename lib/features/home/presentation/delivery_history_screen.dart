import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) { setState(() => _loading = false); return; }
    try {
      final rows = await Supabase.instance.client
          .from('orders')
          .select('id, created_at, delivery_fee, stores(name, address)')
          .eq('driver_id', userId)
          .eq('status', 'delivered')
          .order('created_at', ascending: false)
          .limit(100);
      setState(() => _orders = (rows as List).cast<Map<String, dynamic>>());
    } catch (_) {}
    setState(() => _loading = false);
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
    final divider     = dark ? AppColors.dividerDark     : AppColors.dividerLight;

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
            title: Text(l.deliveryHistory, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4)),
          ),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_orders.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.delivery_dining_rounded, size: 56, color: textSec.withValues(alpha: 0.35)),
                  const SizedBox(height: AppDimens.base),
                  Text(l.noDeliveriesYet, style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 4),
                  Text(l.noDeliveriesSub, style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: textSec)),
                ]),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(AppDimens.base, AppDimens.sm, AppDimens.base, MediaQuery.paddingOf(context).bottom + AppDimens.xl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final order = _orders[i];
                    final store = (order['stores'] as Map<String, dynamic>?);
                    final storeName = store?['name'] as String? ?? '—';
                    final storeAddr = store?['address'] as String? ?? '';
                    final fee = (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
                    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '')?.toLocal();
                    final dateStr = createdAt != null ? DateFormat('d MMM y · h:mm a').format(createdAt) : '—';
                    final shortId = (order['id'] as String? ?? '').replaceAll('-', '').substring(0, 6).toUpperCase();

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppDimens.sm),
                      padding: const EdgeInsets.all(AppDimens.base),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 22),
                        ),
                        const SizedBox(width: AppDimens.md),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(storeName, style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                          const SizedBox(height: 2),
                          Text(storeAddr, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textSec), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(dateStr, style: TextStyle(fontFamily: fontFamily, fontSize: 11, color: textSec.withValues(alpha: 0.70))),
                        ])),
                        const SizedBox(width: AppDimens.sm),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('LYD ${fee.toStringAsFixed(2)}', style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: divider, borderRadius: BorderRadius.circular(4)),
                            child: Text('#$shortId', style: TextStyle(fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w700, color: textSec)),
                          ),
                        ]),
                      ]),
                    );
                  },
                  childCount: _orders.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
