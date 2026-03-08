// lib/core/services/location_service.dart
//
// Publishes the driver's GPS position to the `driver_locations` Supabase table
// every 10 seconds while they are online or on delivery.
// Clears the row when the driver goes offline.

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static Timer? _timer;
  static bool _running = false;

  // ── Permission helper ────────────────────────────────────────────────────
  static Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ── Start publishing ─────────────────────────────────────────────────────
  static Future<void> start() async {
    if (_running) return;
    final granted = await requestPermission();
    if (!granted) return;
    _running = true;
    await _publish(); // first tick immediately
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _publish());
  }

  // ── Stop publishing and remove the row ──────────────────────────────────
  static Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
    await _clearLocation();
  }

  // ── Internal: get GPS and upsert to Supabase ─────────────────────────────
  static Future<void> _publish() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await Supabase.instance.client.from('driver_locations').upsert({
        'driver_id': userId,
        'lat': position.latitude,
        'lng': position.longitude,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Silently ignore — GPS unavailable or network error.
    }
  }

  // ── Internal: delete the driver's row when offline ───────────────────────
  static Future<void> _clearLocation() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('driver_locations')
          .delete()
          .eq('driver_id', userId);
    } catch (_) {}
  }
}
