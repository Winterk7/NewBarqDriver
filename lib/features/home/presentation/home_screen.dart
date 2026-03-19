import 'dart:async';

import 'package:barq_driver/core/theme/theme_provider.dart';
import 'package:barq_driver/core/providers/driver_orders_provider.dart';
import 'package:barq_driver/core/services/location_service.dart';
import 'package:barq_driver/core/services/notification_service.dart';
import 'package:barq_driver/features/home/domain/driver_order.dart';
import 'package:barq_driver/features/home/domain/driver_status.dart';
import 'package:barq_driver/features/home/presentation/driver_menu_page.dart';
import 'package:barq_driver/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barq_driver/core/constants/app_colors.dart';
import 'package:barq_driver/core/constants/app_dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

// ── Mapbox tile helper ─────────────────────────────────────────────────────────
const _kMapboxToken =
    'pk.eyJ1Ijoid2ludGVyayIsImEiOiJjbW00NnRycTgwM3hmMzJyMXM0ZDZsZWRmIn0'
    '.7zvME7NODb4xyJozscm5JQ';

String _mapboxTile(String style) =>
    'https://api.mapbox.com/styles/v1/mapbox/$style/tiles/256/{z}/{x}/{y}@2x'
    '?access_token=$_kMapboxToken';

// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Default centre: Tripoli, Libya
  static const _defaultCenter = LatLng(32.8872, 13.1913);

  final _mapCtrl = MapController();
  bool _mapReady = false;
  DriverStatus _status = DriverStatus.offline;
  DriverOrder? _activeOrder;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionSub;

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

    // Wire notification router + register FCM token now that user is authenticated.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.router = GoRouter.of(context);
      NotificationService.initFCM().ignore();
      // Request location permission immediately on entry.
      LocationService.requestPermission().then((granted) {
        if (granted && mounted) _startPositionStream();
      });
    });
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _sheetCtrl.dispose();
    // MapController.dispose() is called after super.dispose() to avoid
    // accessing it during Flutter's framework teardown.
    super.dispose();
    _mapCtrl.dispose();
  }

  // ── Status toggle ─────────────────────────────────────────────────────────
  void _toggleOnline() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_status == DriverStatus.offline) {
        _status = DriverStatus.online;
      } else {
        _status = DriverStatus.offline;
        _activeOrder = null;
      }
    });
    // Persist availability to Supabase so partner can filter online drivers.
    setDriverAvailability(_status != DriverStatus.offline);
    // Start/stop GPS publishing + live map marker.
    if (_status != DriverStatus.offline) {
      LocationService.start();
      _startPositionStream();
    } else {
      LocationService.stop();
      _positionSub?.cancel();
      _positionSub = null;
    }
    _sheetCtrl
      ..reset()
      ..forward();
  }

  void _completeDelivery() {
    HapticFeedback.mediumImpact();
    if (_activeOrder != null) {
      markOrderDelivered(_activeOrder!.id); // fire-and-forget; stream clears the order
    }
    setState(() {
      _activeOrder = null;
      _status = DriverStatus.online;
    });
    _sheetCtrl
      ..reset()
      ..forward();
  }

  void _markPickedUp() {
    HapticFeedback.mediumImpact();
    if (_activeOrder != null) {
      markOrderPickedUp(_activeOrder!.id); // fire-and-forget; stream updates status
    }
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

    // ── Live order listener ────────────────────────────────────────────────
    // React to Supabase realtime: when an order is assigned/updated react here.
    ref.listen<AsyncValue<DriverOrder?>>(driverActiveOrderProvider, (_, next) {
      next.whenData((order) {
        if (!mounted) return;
        if (order != null && _status != DriverStatus.offline) {
          // New or updated active order
          if (_activeOrder?.id != order.id ||
              _activeOrder?.status != order.status ||
              _status != DriverStatus.onDelivery) {
            // Notify driver only on a brand-new assignment.
            final isNewOrder = _activeOrder?.id != order.id;
            setState(() {
              _activeOrder = order;
              _status = DriverStatus.onDelivery;
            });
            if (isNewOrder) {
              NotificationService.showNewOrder(order.storeName);
            }
            _sheetCtrl
              ..reset()
              ..forward();
          } else {
            // Update status silently (e.g. accepted → picked_up)
            setState(() => _activeOrder = order);
          }
        } else if (order == null && _status == DriverStatus.onDelivery) {
          // Order completed or unassigned
          setState(() {
            _activeOrder = null;
            _status = DriverStatus.online;
          });
          _sheetCtrl
            ..reset()
            ..forward();
        }
      });
    });

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
                onMapReady: () {
                  if (mounted) setState(() => _mapReady = true);
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _mapboxTile(tileStyle),
                  userAgentPackageName: 'com.barq.driver',
                  retinaMode: true,
                  maxZoom: 19,
                  keepBuffer: 3,
                  panBuffer: 1,
                  // Silently swallow tile-fetch errors — shows blank tiles
                  // instead of crashing the app when network is unreliable.
                  errorTileCallback: (tile, error, stackTrace) {
                    // ignore: avoid_print
                    debugPrint('[TileLayer] tile error (ignored): $error');
                  },
                  evictErrorTileStrategy:
                      EvictErrorTileStrategy.dispose,
                ),
                // Driver location marker — only shown once real GPS is known
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 64,
                        height: 72,
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
                      ref.read(themeModeProvider.notifier).setTheme(
                          cur == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
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
                  HapticFeedback.lightImpact();
                  if (_mapReady) {
                    _mapCtrl.move(
                        _currentPosition ?? _defaultCenter, 15.0);
                  }
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
        return 380 + bottomPad; // extra room for items list + phone
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
          onPickedUp: _markPickedUp,
          onComplete: _completeDelivery,
        );
    }
  }
}

// ── Driver map marker ─────────────────────────────────────────────────────────

class _DriverMarker extends StatefulWidget {
  final bool isOnline;
  const _DriverMarker({required this.isOnline});

  @override
  State<_DriverMarker> createState() => _DriverMarkerState();
}

class _DriverMarkerState extends State<_DriverMarker>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _floatY;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 2.4).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _floatY = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _floatCtrl]),
      builder: (context, _) => SizedBox(
        width: 64,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing glow ring (only when online)
            if (widget.isOnline)
              Transform.scale(
                scale: _pulseScale.value,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGreen
                          .withValues(alpha: _pulseOpacity.value),
                      width: 2,
                    ),
                  ),
                ),
              ),
            // Drop shadow ellipse
            Positioned(
              bottom: 4,
              child: Container(
                width: 30,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withValues(alpha: 0.25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            // Floating car (translated on Y axis)
            Transform.translate(
              offset: Offset(0, _floatY.value),
              child: CustomPaint(
                size: const Size(32, 52),
                painter: _CarPainter(isOnline: widget.isOnline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top-down car silhouette painter — sleek black map-marker style.
class _CarPainter extends CustomPainter {
  final bool isOnline;
  const _CarPainter({required this.isOnline});

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    // ── Shadow ─────────────────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, h * 0.70, w * 0.76, h * 0.22),
          const Radius.circular(6)),
      shadowPaint,
    );

    // ── Body ───────────────────────────────────────────────────────────────
    final bodyPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;
    final bodyPath = Path()
      ..moveTo(w * 0.10, h * 0.30)
      ..lineTo(w * 0.10, h * 0.78)
      ..quadraticBezierTo(w * 0.10, h * 0.89, w * 0.24, h * 0.91)
      ..lineTo(w * 0.76, h * 0.91)
      ..quadraticBezierTo(w * 0.90, h * 0.89, w * 0.90, h * 0.78)
      ..lineTo(w * 0.90, h * 0.30)
      ..quadraticBezierTo(w * 0.90, h * 0.22, w * 0.78, h * 0.20)
      ..lineTo(w * 0.22, h * 0.20)
      ..quadraticBezierTo(w * 0.10, h * 0.22, w * 0.10, h * 0.30)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // ── Roof / cabin ───────────────────────────────────────────────────────
    final roofPaint = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.fill;
    final roofPath = Path()
      ..moveTo(w * 0.25, h * 0.20)
      ..lineTo(w * 0.30, h * 0.03)
      ..quadraticBezierTo(w * 0.32, h * 0.01, w * 0.40, h * 0.01)
      ..lineTo(w * 0.60, h * 0.01)
      ..quadraticBezierTo(w * 0.68, h * 0.01, w * 0.70, h * 0.03)
      ..lineTo(w * 0.75, h * 0.20)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // ── Windshield glass ──────────────────────────────────────────────────
    final glassPaint = Paint()
      ..color = const Color(0xFF3A5A7A).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final windshieldPath = Path()
      ..moveTo(w * 0.27, h * 0.19)
      ..lineTo(w * 0.32, h * 0.04)
      ..lineTo(w * 0.68, h * 0.04)
      ..lineTo(w * 0.73, h * 0.19)
      ..close();
    canvas.drawPath(windshieldPath, glassPaint);

    // Windshield glare
    final glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final glarePath = Path()
      ..moveTo(w * 0.30, h * 0.18)
      ..lineTo(w * 0.33, h * 0.05)
      ..lineTo(w * 0.48, h * 0.05)
      ..lineTo(w * 0.44, h * 0.18)
      ..close();
    canvas.drawPath(glarePath, glarePaint);

    // ── Side highlight (simulates 3-D curvature) ──────────────────────────
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.38, h * 0.21, w * 0.22, h * 0.36),
          const Radius.circular(4)),
      highlightPaint,
    );

    // ── Headlights (front) ────────────────────────────────────────────────
    final headPaint = Paint()
      ..color = isOnline
          ? const Color(0xFFFFE566)
          : const Color(0xFF555555)
      ..style = PaintingStyle.fill;
    if (isOnline) {
      headPaint.maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 3);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.11, h * 0.21, w * 0.22, h * 0.07),
          const Radius.circular(2)),
      headPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.67, h * 0.21, w * 0.22, h * 0.07),
          const Radius.circular(2)),
      headPaint,
    );

    // ── Taillights (rear) ────────────────────────────────────────────────
    final tailPaint = Paint()
      ..color = isOnline
          ? const Color(0xFFFF3333)
          : const Color(0xFF444444)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.11, h * 0.80, w * 0.22, h * 0.07),
          const Radius.circular(2)),
      tailPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.67, h * 0.80, w * 0.22, h * 0.07),
          const Radius.circular(2)),
      tailPaint,
    );

    // ── Wheels ────────────────────────────────────────────────────────────
    final wheelPaint = Paint()
      ..color = const Color(0xFF080808)
      ..style = PaintingStyle.fill;
    // Front-left
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.04, h * 0.27, w * 0.16, h * 0.18),
          const Radius.circular(3)),
      wheelPaint,
    );
    // Front-right
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.88, h * 0.27, w * 0.16, h * 0.18),
          const Radius.circular(3)),
      wheelPaint,
    );
    // Rear-left
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.04, h * 0.62, w * 0.16, h * 0.18),
          const Radius.circular(3)),
      wheelPaint,
    );
    // Rear-right
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.88, h * 0.62, w * 0.16, h * 0.18),
          const Radius.circular(3)),
      wheelPaint,
    );

    // Wheel rims
    final rimPaint = Paint()
      ..color = const Color(0xFF555555)
      ..style = PaintingStyle.fill;
    for (final rect in [
      Rect.fromLTWH(-w * 0.01, h * 0.30, w * 0.10, h * 0.12),
      Rect.fromLTWH(w * 0.91, h * 0.30, w * 0.10, h * 0.12),
      Rect.fromLTWH(-w * 0.01, h * 0.65, w * 0.10, h * 0.12),
      Rect.fromLTWH(w * 0.91, h * 0.65, w * 0.10, h * 0.12),
    ]) {
      canvas.drawOval(rect, rimPaint);
    }
  }

  @override
  bool shouldRepaint(_CarPainter old) => old.isOnline != isOnline;
}


// ── Top-bar widgets ───────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final DriverStatus status;
  final bool dark;
  const _StatusPill({required this.status, required this.dark});

  @override
  Widget build(BuildContext context) {
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    final label = switch (status) {
      DriverStatus.offline    => AppLocalizations.of(context)!.statusOffline,
      DriverStatus.online     => AppLocalizations.of(context)!.statusOnline,
      DriverStatus.onDelivery => AppLocalizations.of(context)!.statusOnDelivery,
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
          Text(label, style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: txtColor)),
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
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
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
              fontFamily: fontFamily,
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
    final l = AppLocalizations.of(context)!;
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
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
            l.youreOffline,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: AppDimens.xs),
          Text(
            l.goOnlineSub,
            style: TextStyle(
              fontFamily: fontFamily,
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
              child: Text(
                l.goOnline,
                style: TextStyle(
                  fontFamily: fontFamily,
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
    final l = AppLocalizations.of(context)!;
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
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
                      l.searchingForOrders,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      l.searchingForOrdersSub,
                      style: TextStyle(
                        fontFamily: fontFamily,
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
              child: Text(
                l.goOffline,
                style: TextStyle(
                  fontFamily: fontFamily,
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

class _DeliverySheet extends StatefulWidget {
  final DriverOrder order;
  final double bottomPad;
  final VoidCallback onPickedUp;
  final VoidCallback onComplete;
  const _DeliverySheet({
    required this.order,
    required this.bottomPad,
    required this.onPickedUp,
    required this.onComplete,
  });

  @override
  State<_DeliverySheet> createState() => _DeliverySheetState();
}

class _DeliverySheetState extends State<_DeliverySheet> {
  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    // Try Apple Maps first, fall back to Google Maps web
    final appleUri = Uri.parse('maps:?q=$encoded');
    final googleUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(appleUri)) {
      await launchUrl(appleUri);
    } else {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmPickup() async {
    final l = AppLocalizations.of(context)!;
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.pickedUpFromStore, style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700)),
        content: Text(
          'Confirm you have picked up the order from ${widget.order.storeName}?',
          style: TextStyle(fontFamily: fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel, style: TextStyle(fontFamily: fontFamily)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            child: Text(l.pickedUpFromStore, style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onPickedUp();
  }

  Future<void> _confirmDeliver() async {
    final l = AppLocalizations.of(context)!;
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.markAsDelivered, style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700)),
        content: Text(
          'Confirm delivery to ${widget.order.customerName}?',
          style: TextStyle(fontFamily: fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel, style: TextStyle(fontFamily: fontFamily)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            child: Text(l.markAsDelivered, style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.xl,
        AppDimens.lg,
        AppDimens.xl,
        widget.bottomPad + AppDimens.lg,
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

          // Short order ID + earnings row
          Row(
            children: [
              Text(
                order.shortId,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
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
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.md),

          // Route (dropoff address is tappable)
          _RouteRow(
            pickupLabel: order.storeName,
            pickupAddress: order.pickupAddress,
            dropoffAddress: order.dropoffAddress,
            customerName: order.customerName,
            onDropoffTap: order.dropoffAddress.isNotEmpty
                ? () => _launchMaps(order.dropoffAddress)
                : null,
          ),

          // Customer phone row
          if (order.customerPhone.isNotEmpty) ...[
            const SizedBox(height: AppDimens.sm),
            InkWell(
              onTap: () => _launchPhone(order.customerPhone),
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.phone_rounded, size: 15, color: AppColors.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      order.customerPhone,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 13,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Order items list
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: AppDimens.sm),
            Container(
              padding: const EdgeInsets.all(AppDimens.sm),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '${item.quantity}×',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Text(
                        'LYD ${item.unitPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],

          const SizedBox(height: AppDimens.lg),

          // Action button — confirmation dialog before proceeding
          SizedBox(
            width: double.infinity,
            height: AppDimens.buttonHeight,
            child: ElevatedButton(
              onPressed: order.isPickedUp ? _confirmDeliver : _confirmPickup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
              child: Text(
                order.isPickedUp ? l.markAsDelivered : l.pickedUpFromStore,
                style: TextStyle(
                  fontFamily: fontFamily,
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
  final VoidCallback? onDropoffTap;
  const _RouteRow({
    required this.pickupLabel,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.customerName,
    this.onDropoffTap,
  });

  @override
  Widget build(BuildContext context) {
    final fontFamily = Localizations.localeOf(context).languageCode == 'ar' ? 'Cairo' : 'Inter';
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
                  fontFamily: fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                pickupAddress,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: AppDimens.md),
              Text(
                customerName,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              // Tappable dropoff address
              GestureDetector(
                onTap: onDropoffTap,
                child: Text(
                  dropoffAddress,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 12,
                    color: onDropoffTap != null
                        ? AppColors.primaryGreen
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    decoration: onDropoffTap != null ? TextDecoration.underline : null,
                    decorationColor: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

