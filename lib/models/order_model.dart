class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    this.total = 0,
    this.deliveryAddress,
    this.riderName,
    this.riderPhone,
    this.cookName,
    this.cookPhone,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    String? rName;
    String? rPhone;
    if (json['rider'] is Map) {
      final r = json['rider'] as Map<String, dynamic>;
      rName = r['name'] as String?;
      rPhone = r['phone'] as String?;
    }

    String? cName;
    String? cPhone;
    if (json['cook'] is Map) {
      final c = json['cook'] as Map<String, dynamic>;
      cName = (c['kitchenName'] as String?)?.isNotEmpty == true
          ? c['kitchenName'] as String
          : c['name'] as String?;
      cPhone = c['phone'] as String?;
    }

    return OrderModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      deliveryAddress: json['deliveryAddress'] as String?,
      riderName: rName,
      riderPhone: rPhone,
      cookName: cName,
      cookPhone: cPhone,
    );
  }

  final String id;
  final String status;
  final double total;
  final String? deliveryAddress;
  final String? riderName;
  final String? riderPhone;
  final String? cookName;
  final String? cookPhone;
}
