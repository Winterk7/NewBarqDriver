// lib/core/providers/driver_orders_provider.dart
//
// Streams the current driver's active order from Supabase (realtime).
// An "active" order is one assigned to this driver with status
// 'accepted' (store accepted, driver heading to pick up) or
// 'picked_up' (driver heading to customer).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barq_driver/features/home/domain/driver_order.dart';

// ─────────────────────────────────────────────────────────────────────────────
// driverActiveOrderProvider
//   StreamProvider<DriverOrder?> — fires on every change to orders
//   assigned to the current driver. Returns the most recent active order
//   or null if none.
// ─────────────────────────────────────────────────────────────────────────────
final driverActiveOrderProvider = StreamProvider<DriverOrder?>((ref) {
  final sb = Supabase.instance.client;
  final userId = sb.auth.currentUser?.id;

  // Not logged in → empty stream.
  if (userId == null) return Stream.value(null);

  // Subscribe to realtime changes on orders assigned to this driver.
  // The asyncMap re-fetches with joins on every update.
  return sb
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('driver_id', userId)
      .asyncMap((_) async {
        final List<Map<String, dynamic>> rows = await sb
            .from('orders')
            .select('*, stores(name, address)')
            .eq('driver_id', userId)
            .inFilter('status', ['accepted', 'preparing', 'ready', 'picked_up'])
            .order('created_at', ascending: false)
            .limit(1);

        if (rows.isEmpty) return null;
        return DriverOrder.fromRow(rows.first);
      });
});

// ─────────────────────────────────────────────────────────────────────────────
// driverProfileProvider
//   Fetches the current driver's profile (full_name, phone, avatar_url).
// ─────────────────────────────────────────────────────────────────────────────
final driverProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  final rows = await Supabase.instance.client
      .from('profiles')
      .select('full_name, phone, avatar_url')
      .eq('id', userId)
      .limit(1);
  final list = rows as List<dynamic>;
  return list.isEmpty ? null : list.first as Map<String, dynamic>;
});

// ─────────────────────────────────────────────────────────────────────────────
// setDriverAvailability
//   Writes is_available to the driver's profile row so barq-partner can
//   filter for online drivers when assigning orders.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> setDriverAvailability(bool isAvailable) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  await Supabase.instance.client
      .from('profiles')
      .update({'is_available': isAvailable})
      .eq('id', userId);
}

// ─────────────────────────────────────────────────────────────────────────────
// markOrderPickedUp
//   Updates an order status from 'accepted' to 'picked_up'.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> markOrderPickedUp(String orderId) async {
  await Supabase.instance.client
      .from('orders')
      .update({'status': 'picked_up'})
      .eq('id', orderId);
}

// ─────────────────────────────────────────────────────────────────────────────
// markOrderDelivered
//   Updates an order status to 'delivered'.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> markOrderDelivered(String orderId) async {
  await Supabase.instance.client
      .from('orders')
      .update({'status': 'delivered'})
      .eq('id', orderId);
}
