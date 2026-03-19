import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:barq_driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  bool _loading = true;
  double _avgRating    = 0;
  int    _ratingCount  = 0;
  int    _deliveries   = 0;
  final Map<int, int> _distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) { setState(() => _loading = false); return; }
    try {
      // Fetch all delivered orders — use delivery_fee count as proxy for deliveries
      // and check for driver_rating column if it exists.
      final rows = await Supabase.instance.client
          .from('orders')
          .select('driver_rating, status')
          .eq('driver_id', userId);
      int count = 0;
      double sum = 0;
      int deliveries = 0;
      final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (final row in rows) {
        if (row['status'] == 'delivered') deliveries++;
        final r = row['driver_rating'];
        if (r != null) {
          final rating = (r as num).toInt().clamp(1, 5);
          sum += r;
          count++;
          dist[rating] = (dist[rating] ?? 0) + 1;
        }
      }
      setState(() {
        _loading      = false;
        _avgRating    = count > 0 ? sum / count : 0;
        _ratingCount  = count;
        _deliveries   = deliveries;
        _distribution.addAll(dist);
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

    final hasRating = _ratingCount > 0;

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
                  title: Text(l.myRating, style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.4)),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(AppDimens.base, AppDimens.base, AppDimens.base, MediaQuery.paddingOf(context).bottom + AppDimens.xl),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (!hasRating)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 80),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.star_border_rounded, size: 64, color: textSec.withValues(alpha: 0.30)),
                              const SizedBox(height: AppDimens.base),
                              Text(l.noRatingYet, style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                              const SizedBox(height: 4),
                              Text(l.noRatingSub, style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: textSec), textAlign: TextAlign.center),
                            ]),
                          ),
                        )
                      else ...[
                        // Big rating card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppDimens.xl),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(_avgRating.toStringAsFixed(1),
                                  style: TextStyle(fontFamily: fontFamily, fontSize: 64, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -3)),
                              const SizedBox(width: 8),
                              Icon(Icons.star_rounded, size: 36, color: AppColors.warning),
                            ]),
                            const SizedBox(height: 4),
                            Text(l.ratingSubtitle, style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: textSec)),
                            const SizedBox(height: 4),
                            Text('$_ratingCount ratings · $_deliveries deliveries',
                                style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textSec.withValues(alpha: 0.70))),
                          ]),
                        ),

                        const SizedBox(height: AppDimens.base),

                        // Distribution bars
                        Container(
                          padding: const EdgeInsets.all(AppDimens.base),
                          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: borderColor)),
                          child: Column(
                            children: [5, 4, 3, 2, 1].map((star) {
                              final count = _distribution[star] ?? 0;
                              final fraction = _ratingCount > 0 ? count / _ratingCount : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(children: [
                                  Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                                  const SizedBox(width: 4),
                                  Text('$star', style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: textSec, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: AppDimens.sm),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: fraction,
                                        backgroundColor: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                                        valueColor: AlwaysStoppedAnimation(AppColors.warning),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimens.sm),
                                  SizedBox(
                                    width: 24,
                                    child: Text('$count', style: TextStyle(fontFamily: fontFamily, fontSize: 11, color: textSec), textAlign: TextAlign.right),
                                  ),
                                ]),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}
