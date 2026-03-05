import 'package:barq_driver/core/theme/theme_provider.dart';
import 'package:barq_driver/features/home/domain/driver_status.dart';
import 'package:barq_driver/features/home/presentation/driver_menu_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ── Mapbox tile helper ─────────────────────────────────────────────────────────
const _kMapboxToken =
    'pk.eyJ1Ijoid2ludGVyayIsImEiOiJjbW00NnRycTgwM3hmMzJyMXM0ZDZsZWRmIn0'
    '.7zvME7NODb4xyJozscm5JQ';

String _mapboxTile(String style) =>
    'https://api.mapbox.com/styles/v1/mapbox/$style/tiles/256/{z}/{x}/{y}@2x'
    '?access_token=$_kMapboxToken';

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
  DriverStatus _status = DriverStatus.offline;
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
      _status = _status == DriverStatus.offline
          ? DriverStatus.online
          : DriverStatus.offline;
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
      _status = DriverStatus.online;
    });
    _sheetCtrl
      ..reset()
      ..forward();
  }

  void _openMenu() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (ctx, anim, _) => DriverMenuPage(status: _status),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final topPad = MediaQuery.paddingOf(context).top;
    final appIsDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    // Map tile follows theme only — online/offline status does not affect it
    final tileStyle = appIsDark ? 'dark-v11' : 'streets-v12';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: appIsDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: appIsDark ? Brightness.light : Brightness.dark,
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
                  urlTemplate: _mapboxTile(tileStyle),
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
                        isOnline: _status != DriverStatus.offline,
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
                  _StatusPill(status: _status, dark: appIsDark),
                  const Spacer(),
                  // Earnings chip
                  if (_status != DriverStatus.offline)
                    _EarningsChip(amount: _activeOrder?.earnings ?? 0, dark: appIsDark),
                  const SizedBox(width: AppDimens.sm),
                  // Theme toggle
                  _MapIconButton(
                    icon: appIsDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final cur = ref.read(themeModeProvider);
                      ref.read(themeModeProvider.notifier).state =
                          cur == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                    },
                    dark: appIsDark,
                  ),
                  const SizedBox(width: AppDimens.sm),
                  // Menu
                  _MapIconButton(
                    icon: Icons.menu_rounded,
                    onTap: _openMenu,
                    dark: appIsDark,
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
                dark: appIsDark,
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
      case DriverStatus.offline:
        return 200 + bottomPad;
      case DriverStatus.online:
        return 190 + bottomPad;
      case DriverStatus.onDelivery:
        return 280 + bottomPad;
    }
  }

  Widget _buildSheet(double bottomPad) {
    switch (_status) {
      case DriverStatus.offline:
        return _OfflineSheet(
          bottomPad: bottomPad,
          onGoOnline: _toggleOnline,
        );
      case DriverStatus.online:
        return _OnlineSheet(
          bottomPad: bottomPad,
          onGoOffline: _toggleOnline,
        );
      case DriverStatus.onDelivery:
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white : AppColors.backgroundDark;
    final fg = isDark ? AppColors.backgroundDark : Colors.white;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.delivery_dining_rounded,
            color: fg,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// ── Top-bar widgets ───────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final DriverStatus status;
  final bool dark;
  const _StatusPill({required this.status, required this.dark});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      DriverStatus.offline    => 'Offline',
      DriverStatus.online     => 'Online',
      DriverStatus.onDelivery => 'On Delivery',
    };
    final dotColor = switch (status) {
      DriverStatus.offline    => dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      DriverStatus.online     => AppColors.primaryGreen,
      DriverStatus.onDelivery => AppColors.warning,
    };
    final bgColor  = dark ? Colors.black.withValues(alpha: 0.75) : Colors.white;
    final txtColor = dark ? Colors.white : AppColors.textPrimaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: txtColor)),
        ],
      ),
    );
  }
}

class _EarningsChip extends StatelessWidget {
  final double amount;
  final bool dark;
  const _EarningsChip({required this.amount, required this.dark});

  @override
  Widget build(BuildContext context) {
    final bgColor  = dark ? Colors.black.withValues(alpha: 0.75) : Colors.white;
    final txtColor = dark ? Colors.white : AppColors.textPrimaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: dark ? AppColors.warning : AppColors.textPrimaryLight, size: 14),
          const SizedBox(width: 4),
          Text(
            'LYD ${amount > 0 ? amount.toStringAsFixed(1) : "\u2013"}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: txtColor,
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

class _OnlineSheet extends StatefulWidget {
  final double bottomPad;
  final VoidCallback onGoOffline;
  const _OnlineSheet({required this.bottomPad, required this.onGoOffline});

  @override
  State<_OnlineSheet> createState() => _OnlineSheetState();
}

class _OnlineSheetState extends State<_OnlineSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.xl, AppDimens.lg, AppDimens.xl, widget.bottomPad + AppDimens.lg,
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
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.lg),

          // Compact search row
          Row(
            children: [
              // Three bouncing dots
              _BouncingDots(cs: cs),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Searching for orders',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      "You'll be notified when an order is assigned",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.lg),

          // Go Offline button
          SizedBox(
            width: double.infinity,
            height: AppDimens.buttonHeight,
            child: ElevatedButton(
              onPressed: widget.onGoOffline,
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
                'Go Offline',
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

// ── Bouncing dots indicator ───────────────────────────────────────────────────
class _BouncingDots extends StatefulWidget {
  final ColorScheme cs;
  const _BouncingDots({required this.cs});
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 7.0;
    final col = widget.cs.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final anim = Tween<double>(begin: 0.25, end: 1.0).animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: Interval(i / 3, (i + 1) / 3, curve: Curves.easeInOut),
          ),
        );
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
          child: AnimatedBuilder(
            animation: anim,
            builder: (_, __) => Opacity(
              opacity: anim.value,
              child: Container(
                width: size, height: size,
                decoration: BoxDecoration(color: col, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      }),
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
    final cs = Theme.of(context).colorScheme;
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
          const SizedBox(height: AppDimens.md),

          // Order ID + earnings row
          Row(
            children: [
              Text(
                order.id,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.55),
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
            Container(width: 2, height: 32, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
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
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                pickupAddress,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: AppDimens.md),
              Text(
                customerName,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                dropoffAddress,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
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
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
