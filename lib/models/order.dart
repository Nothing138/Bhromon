// models/order.dart

import 'cart_item.dart';

class Order {
  final String orderId;
  final List<CartItem> items;
  final double subtotal;
  final double gst;
  final double deliveryCharges;
  final double grandTotal;
  final String paymentId;
  final String status;
  final DateTime createdAt;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String deliveryAddress;

  Order({
    required this.orderId,
    required this.items,
    required this.subtotal,
    required this.gst,
    required this.deliveryCharges,
    required this.grandTotal,
    required this.paymentId,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.deliveryAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'items': items
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
            },
          )
          .toList(),
      'subtotal': subtotal,
      'gst': gst,
      'deliveryCharges': deliveryCharges,
      'grandTotal': grandTotal,
      'paymentId': paymentId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'] ?? '',
      items:
          (json['items'] as List?)
              ?.map(
                (item) => CartItem(
                  id: item['id'] ?? '',
                  name: item['name'] ?? '',
                  price: (item['price'] ?? 0).toDouble(),
                  image: item['image'] ?? '',
                  quantity: item['quantity'] ?? 1,
                ),
              )
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      gst: (json['gst'] ?? 0).toDouble(),
      deliveryCharges: (json['deliveryCharges'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      paymentId: json['paymentId'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
    );
  }
}
