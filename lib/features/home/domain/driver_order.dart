// lib/features/home/domain/driver_order.dart
//
// Real order model for the driver app, parsed from Supabase rows.
// Matches the `orders` table schema from the Barq platform.

class DriverOrder {
  final String id;
  final String storeName;
  final String pickupAddress;
  final String dropoffAddress;
  final String customerName;
  final double earnings;
  final String status; // 'accepted' | 'picked_up'

  const DriverOrder({
    required this.id,
    required this.storeName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.customerName,
    required this.earnings,
    required this.status,
  });

  factory DriverOrder.fromRow(Map<String, dynamic> row) {
    final store = row['stores'] as Map<String, dynamic>? ?? {};
    return DriverOrder(
      id: row['id'] as String,
      storeName: store['name'] as String? ?? 'Store',
      pickupAddress: (store['address'] as String?) ?? '',
      dropoffAddress: (row['address'] as String?) ?? '',
      customerName: (row['customer_name'] as String?) ?? 'Customer',
      earnings: (row['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      status: row['status'] as String? ?? 'accepted',
    );
  }

  bool get isPickedUp => status == 'picked_up';
}
