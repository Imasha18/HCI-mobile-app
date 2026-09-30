class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    this.total = 0,
    this.deliveryAddress,
  });
  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['_id'] as String? ?? json['id'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    total: (json['total'] as num?)?.toDouble() ?? 0,
    deliveryAddress: json['deliveryAddress'] as String?,
  );
  final String id;
  final String status;
  final double total;
  final String? deliveryAddress;
}
