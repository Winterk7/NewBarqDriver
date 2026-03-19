// lib/features/home/domain/driver_order.dart
//
// Real order model for the driver app, parsed from Supabase rows.
// Matches the `orders` table schema from the Barq platform.

class DriverOrderItem {
  final String name;
  final int quantity;
  final double unitPrice;

  const DriverOrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory DriverOrderItem.fromRow(Map<String, dynamic> row) {
    return DriverOrderItem(
      name: row['product_name'] as String? ?? '',
      quantity: (row['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (row['unit_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DriverOrder {
  final String id;
  final String storeName;
  final String pickupAddress;
  final String dropoffAddress;
  final String customerName;
  final String customerPhone;
  final double earnings;
  final String status; // 'accepted' | 'picked_up'
  final List<DriverOrderItem> items;

  const DriverOrder({
    required this.id,
    required this.storeName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.customerName,
    required this.customerPhone,
    required this.earnings,
    required this.status,
    required this.items,
  });

  factory DriverOrder.fromRow(Map<String, dynamic> row) {
    final store = row['stores'] as Map<String, dynamic>? ?? {};
    final profile = row['profiles'] as Map<String, dynamic>? ?? {};
    final rawItems = row['order_items'] as List<dynamic>? ?? [];
    return DriverOrder(
      id: row['id'] as String,
      storeName: store['name'] as String? ?? 'Store',
      pickupAddress: (store['address'] as String?) ?? '',
      dropoffAddress: (row['address'] as String?) ?? '',
      customerName: (row['customer_name'] as String?) ?? 'Customer',
      customerPhone: (profile['phone'] as String?) ?? '',
      earnings: (row['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      status: row['status'] as String? ?? 'accepted',
      items: rawItems.map((e) => DriverOrderItem.fromRow(e as Map<String, dynamic>)).toList(),
    );
  }

  bool get isPickedUp => status == 'picked_up';

  /// Short display ID, e.g. #A1B2C3D4
  String get shortId => '#${id.substring(0, 8).toUpperCase()}';
}
