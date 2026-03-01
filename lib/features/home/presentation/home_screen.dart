import 'package:barq_driver/core/config/secrets.dart';
import 'package:barq_driver/core/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ── Mapbox tile helper ─────────────────────────────────────────────────────────
String _mapboxTile(String style) =>
    'https://api.mapbox.com/styles/v1/mapbox/$style/tiles/256/{z}/{x}/{y}@2x'
    '?access_token=$kMapboxToken';

// ── Driver status ─────────────────────────────────────────────────────────────
enum _DriverStatus { offline, online, onDelivery }

// ── Mock active order ─────────────────────────────────────────────────────────
class _ActiveOrder {
  final String id;
  final String customerName;
  final String pickupAddress;
  final String dropoffAddress;
  final String storeName;
  final double earnings;
  final double distanceKm;
  final int estimatedMins;

  const _ActiveOrder({
    required this.id,
    required this.customerName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.storeName,
    required this.earnings,
    required this.distanceKm,
    required this.estimatedMins,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Default centre: Riyadh, SA
  static const _defaultCenter = LatLng(24.7136, 46.6753);

  final _mapCtrl = MapController();
  _DriverStatus _status = _DriverStatus.offline;
  _ActiveOrder? _activeOrder;

  // Bottom sheet animation
  late final AnimationController _sheetCtrl;
  late final Animation<Offset> _sheetSlide;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  // ── Status toggle ─────────────────────────────────────────────────────────
  void _toggleOnline() {
    HapticFeedback.mediumImpact();
    setState(() {
      _status = _status == _DriverStatus.offline
          ? _DriverStatus.online
          : _DriverStatus.offline;
      _activeOrder = null;
    });
    _sheetCtrl
      ..reset()
      ..forward();
  }

  void _completeDelivery() {
    HapticFeedback.mediumImpact();
    setState(() {
      _activeOrder = null;
      _status = _DriverStatus.online;
    });
    _sheetCtrl
      ..reset()
      ..forward();
  }

  void _showMenuSheet(BuildContext context) {
    final isDark = ref.read(themeModeProvider) == ThemeMode.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MenuSheet(
        status: _status,
        isDarkMode: isDark,
        onToggleTheme: () {
          HapticFeedback.lightImpact();
          final cur = ref.read(themeModeProvider);
          ref.read(themeModeProvider.notifier).state =
              cur == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        },
      ),
    );
  }

  // ── Map tile style: dark when online, light when offline ─────────────────
  String get _tileStyle => _status == _DriverStatus.offline
      ? 'streets-v12'
      : 'dark-v11';

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final topPad = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness:
            _status == _DriverStatus.offline ? Brightness.light : Brightness.dark,
        statusBarIconBrightness:
            _status == _DriverStatus.offline ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── MAP ─────────────────────────────────────────────────────
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 14.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _mapboxTile(_tileStyle),
                  userAgentPackageName: 'com.barq.driver',
                  retinaMode: true,
                ),
                // Driver location marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _defaultCenter,
                      width: 56,
                      height: 56,
                      child: _DriverMarker(
                        isOnline: _status != _DriverStatus.offline,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── TOP BAR ─────────────────────────────────────────────────
            Positioned(
              top: topPad + AppDimens.md,
              left: AppDimens.base,
              right: AppDimens.base,
              child: Row(
                children: [
                  // Status pill
                  _StatusPill(status: _status),
                  const Spacer(),
                  // Earnings chip
                  if (_status != _DriverStatus.offline)
                    _EarningsChip(amount: _activeOrder?.earnings ?? 0),
                  const SizedBox(width: AppDimens.sm),
                  // Theme toggle
                  _MapIconButton(
                    icon: ref.watch(themeModeProvider) == ThemeMode.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final cur = ref.read(themeModeProvider);
                      ref.read(themeModeProvider.notifier).state =
                          cur == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                    },
                    dark: _status != _DriverStatus.offline,
                  ),
                  const SizedBox(width: AppDimens.sm),
                  // Menu
                  _MapIconButton(
                    icon: Icons.menu_rounded,
                    onTap: () => _showMenuSheet(context),
                    dark: _status != _DriverStatus.offline,
                  ),
                ],
              ),
            ),

            // ── LOCATE FAB ──────────────────────────────────────────────
            Positioned(
              right: AppDimens.base,
              bottom: _bottomSheetHeight(bottomPad) + AppDimens.md,
              child: _MapIconButton(
                icon: Icons.my_location_rounded,
                onTap: () {
                  _mapCtrl.move(_defaultCenter, 15.0);
                  HapticFeedback.lightImpact();
                },
                dark: _status != _DriverStatus.offline,
              ),
            ),

            // ── BOTTOM SHEET ─────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _sheetSlide,
                child: _buildSheet(bottomPad),
              ),
            ),


          ],
        ),
      ),
    );
  }

  double _bottomSheetHeight(double bottomPad) {
    switch (_status) {
      case _DriverStatus.offline:
        return 200 + bottomPad;
      case _DriverStatus.online:
        return 110 + bottomPad;
      case _DriverStatus.onDelivery:
        return 280 + bottomPad;
    }
  }

  Widget _buildSheet(double bottomPad) {
    switch (_status) {
      case _DriverStatus.offline:
        return _OfflineSheet(
          bottomPad: bottomPad,
          onGoOnline: _toggleOnline,
        );
      case _DriverStatus.online:
        return _OnlineSheet(
          bottomPad: bottomPad,
          onGoOffline: _toggleOnline,
        );
      case _DriverStatus.onDelivery:
        return _DeliverySheet(
          order: _activeOrder!,
          bottomPad: bottomPad,
          onComplete: _completeDelivery,
        );
    }
  }
}

// ── Driver map marker ─────────────────────────────────────────────────────────

class _DriverMarker extends StatelessWidget {
  final bool isOnline;
  const _DriverMarker({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final color =
        isOnline ? AppColors.primaryGreen : AppColors.textSecondaryDark;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.delivery_dining_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// ── Top-bar widgets ───────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final _DriverStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _DriverStatus.offline => ('Offline', AppColors.textSecondaryLight),
      _DriverStatus.online => ('Online', AppColors.primaryGreen),
      _DriverStatus.onDelivery => ('On Delivery', AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: status == _DriverStatus.offline
            ? Colors.white
            : Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: status == _DriverStatus.offline
                  ? AppColors.textPrimaryLight
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsChip extends StatelessWidget {
  final double amount;
  const _EarningsChip({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.warning, size: 14),
          const SizedBox(width: 4),
          Text(
            'LYD ${amount > 0 ? amount.toStringAsFixed(1) : "–"}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  const _MapIconButton({
    required this.icon,
    required this.onTap,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: dark
              ? Colors.black.withValues(alpha: 0.75)
              : Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: dark ? Colors.white : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

// ── Bottom sheets ─────────────────────────────────────────────────────────────

class _OfflineSheet extends StatelessWidget {
  final double bottomPad;
  final VoidCallback onGoOnline;
  const _OfflineSheet({required this.bottomPad, required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.xl,
        AppDimens.lg,
        AppDimens.xl,
        bottomPad + AppDimens.lg,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.lg),

          Text(
            "You're offline",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: AppDimens.xs),
          Text(
            'Go online to start accepting delivery requests',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AppDimens.xl),

          // Go Online button — dark/neutral (not green)
          SizedBox(
            width: double.infinity,
            height: AppDimens.buttonHeight,
            child: ElevatedButton(
              onPressed: onGoOnline,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.backgroundDark,
                foregroundColor: isDark
                    ? AppColors.backgroundDark
                    : AppColors.textPrimaryDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
              child: const Text(
                'Go Online',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineSheet extends StatelessWidget {
  final double bottomPad;
  final VoidCallback onGoOffline;
  const _OnlineSheet({required this.bottomPad, required this.onGoOffline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.xl,
        AppDimens.lg,
        AppDimens.xl,
        bottomPad + AppDimens.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerDark,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.lg),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onGoOffline,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondaryDark,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Go Offline',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliverySheet extends StatelessWidget {
  final _ActiveOrder order;
  final double bottomPad;
  final VoidCallback onComplete;
  const _DeliverySheet({
    required this.order,
    required this.bottomPad,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.xl,
        AppDimens.lg,
        AppDimens.xl,
        bottomPad + AppDimens.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerDark,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.md),

          // Order ID + earnings row
          Row(
            children: [
              Text(
                order.id,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Text(
                  'LYD ${order.earnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.md),

          // Route
          _RouteRow(
            pickupLabel: order.storeName,
            pickupAddress: order.pickupAddress,
            dropoffAddress: order.dropoffAddress,
            customerName: order.customerName,
          ),

          const SizedBox(height: AppDimens.md),

          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.straighten_rounded,
                label: '${order.distanceKm} km',
              ),
              const SizedBox(width: AppDimens.sm),
              _StatChip(
                icon: Icons.schedule_rounded,
                label: '${order.estimatedMins} min',
              ),
            ],
          ),

          const SizedBox(height: AppDimens.lg),

          // Complete delivery button
          SizedBox(
            width: double.infinity,
            height: AppDimens.buttonHeight,
            child: ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
              child: const Text(
                'Mark as Delivered',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ── Menu bottom sheet ────────────────────────────────────────────────────────

class _MenuSheet extends StatelessWidget {
  final _DriverStatus status;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  const _MenuSheet({
    required this.status,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = isDarkMode;
    final bp     = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize:     0.55,
      maxChildSize:     0.95,
      snap: true,
      snapSizes: const [0.55, 0.78, 0.95],
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomScrollView(
          controller: scroll,
          slivers: [
            // Handle
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),

            // Hero profile card
            SliverToBoxAdapter(
              child: _ProfileHero(status: status, isDark: isDark, cs: cs),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Stat cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.base),
                child: Row(children: [
                  Expanded(child: _StatCard(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF10B981),
                    label: 'Earned Today', value: 'LYD 0.00',
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(
                    icon: Icons.delivery_dining_rounded,
                    iconColor: const Color(0xFF6366F1),
                    label: 'Deliveries', value: '0',
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Rating', value: '4.9 ★',
                  )),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Theme toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.base),
                child: _ThemeToggleRow(isDark: isDark, onToggle: onToggleTheme, cs: cs),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Nav items
            SliverToBoxAdapter(
              child: Column(children: [
                _NavItem(icon: Icons.history_rounded,              iconBg: const Color(0xFF6366F1), label: 'Delivery History',   sub: 'View all past trips',        onTap: () => Navigator.pop(context), cs: cs),
                _NavItem(icon: Icons.account_balance_wallet_rounded, iconBg: const Color(0xFF10B981), label: 'Wallet & Earnings',   sub: 'Balance · Payouts',          onTap: () => Navigator.pop(context), cs: cs),
                _NavItem(icon: Icons.star_rounded,                 iconBg: const Color(0xFFF59E0B), label: 'My Rating',           sub: '4.9 · 127 reviews',          onTap: () => Navigator.pop(context), cs: cs),
                _NavItem(icon: Icons.support_agent_rounded,        iconBg: const Color(0xFF8B5CF6), label: 'Support',             sub: 'Help & contact',             onTap: () => Navigator.pop(context), cs: cs),
                _NavItem(icon: Icons.tune_rounded,                 iconBg: const Color(0xFF64748B), label: 'Settings',            sub: 'Notifications · Account',    onTap: () => Navigator.pop(context), cs: cs),
              ]),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Sign out
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppDimens.base, 0, AppDimens.base, bp + 24),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                    ),
                    child: const Center(
                      child: Text('Sign Out',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444), letterSpacing: -0.2,
                        )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile hero ──────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final _DriverStatus status;
  final bool isDark;
  final ColorScheme cs;
  const _ProfileHero({required this.status, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isOnline = status != _DriverStatus.offline;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.base),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF1A1A2E), Color(0xFF0F2D1E)]
                : const [Color(0xFFF0FFF4), Color(0xFFECFDF5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.25 : 0.3),
          ),
        ),
        child: Row(children: [
          // Avatar with status dot
          Stack(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 16, offset: const Offset(0, 4),
                )],
              ),
              child: const Center(child: Text('D', style: TextStyle(
                fontFamily: 'Inter', fontSize: 26,
                fontWeight: FontWeight.w900, color: Colors.white,
              ))),
            ),
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.primaryGreen : const Color(0xFF6B7280),
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2.5),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 16),

          // Name + stars
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Driver', style: TextStyle(
                fontFamily: 'Inter', fontSize: 20,
                fontWeight: FontWeight.w800, letterSpacing: -0.5, color: cs.onSurface,
              )),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded,       color: Color(0xFFF59E0B), size: 14),
                const Icon(Icons.star_rounded,       color: Color(0xFFF59E0B), size: 14),
                const Icon(Icons.star_rounded,       color: Color(0xFFF59E0B), size: 14),
                const Icon(Icons.star_rounded,       color: Color(0xFFF59E0B), size: 14),
                const Icon(Icons.star_half_rounded,  color: Color(0xFFF59E0B), size: 14),
                const SizedBox(width: 4),
                Text('4.9', style: TextStyle(
                  fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.5),
                )),
              ]),
            ],
          )),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOnline
                  ? AppColors.primaryGreen.withValues(alpha: 0.15)
                  : cs.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              isOnline
                  ? (status == _DriverStatus.onDelivery ? 'On Delivery' : 'Online')
                  : 'Offline',
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700,
                color: isOnline ? AppColors.primaryGreen : cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.iconColor,
      required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
      ),
      child: Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(
          fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w800,
          color: cs.onSurface, letterSpacing: -0.3,
        )),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: TextStyle(
          fontFamily: 'Inter', fontSize: 10,
          color: cs.onSurface.withValues(alpha: 0.45),
        )),
      ]),
    );
  }
}

// ── Theme toggle row ──────────────────────────────────────────────────────────

class _ThemeToggleRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final ColorScheme cs;
  const _ThemeToggleRow({required this.isDark, required this.onToggle, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                  : const Color(0xFF6366F1).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isDark ? 'Light Mode' : 'Dark Mode',
                style: TextStyle(fontFamily: 'Inter', fontSize: 15,
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
              Text(isDark ? 'Switch to light theme' : 'Switch to dark theme',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.45))),
            ],
          )),
          // Animated pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: 48, height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF6366F1)
                  : cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String sub;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _NavItem({required this.icon, required this.iconBg, required this.label,
      required this.sub, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: cs.onSurface.withValues(alpha: 0.04),
      highlightColor: cs.onSurface.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.base, vertical: 10),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: iconBg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconBg, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 15,
                  fontWeight: FontWeight.w600, color: cs.onSurface)),
              Text(sub, style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.45))),
            ],
          )),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: cs.onSurface.withValues(alpha: 0.25)),
        ]),
      ),
    );
  }
}


// ── Reusable small widgets ───────────────────────────────────────────────────


class _RouteRow extends StatelessWidget {
  final String pickupLabel;
  final String pickupAddress;
  final String dropoffAddress;
  final String customerName;
  const _RouteRow({
    required this.pickupLabel,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icons column
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 2, height: 32, color: AppColors.dividerDark),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(width: AppDimens.md),
        // Text column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickupLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                pickupAddress,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: AppDimens.md),
              Text(
                customerName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                dropoffAddress,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondaryDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
