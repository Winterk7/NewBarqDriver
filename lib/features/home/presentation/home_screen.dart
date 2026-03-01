import 'package:barq_driver/core/config/secrets.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MenuSheet(status: _status),
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


// ── Menu bottom sheet ───────────────────────────────────────────────────────

class _MenuSheet extends StatelessWidget {
  final _DriverStatus status;
  const _MenuSheet({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(0, AppDimens.sm, 0, bottomPad + AppDimens.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppDimens.md),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.xl,
              vertical: AppDimens.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'D',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Barq Delivery',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (status == _DriverStatus.offline
                            ? cs.onSurface
                            : AppColors.primaryGreen)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    status == _DriverStatus.offline ? 'Offline' : 'Online',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: status == _DriverStatus.offline
                          ? cs.onSurface.withValues(alpha: 0.5)
                          : AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: cs.onSurface.withValues(alpha: 0.08), height: 1),
          _MenuItem(
            icon: Icons.history_rounded,
            label: 'Delivery History',
            onTap: () => Navigator.pop(context),
          ),
          _MenuItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet & Earnings',
            onTap: () => Navigator.pop(context),
          ),
          _MenuItem(
            icon: Icons.star_outline_rounded,
            label: 'My Rating',
            onTap: () => Navigator.pop(context),
          ),
          _MenuItem(
            icon: Icons.support_agent_outlined,
            label: 'Support',
            onTap: () => Navigator.pop(context),
          ),
          _MenuItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.pop(context),
          ),
          Divider(color: cs.onSurface.withValues(alpha: 0.08), height: 1),
          _MenuItem(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            color: AppColors.error,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.xl,
          vertical: AppDimens.md,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: c.withValues(alpha: color != null ? 1.0 : 0.7),
            ),
            const SizedBox(width: AppDimens.md),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: c,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
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
