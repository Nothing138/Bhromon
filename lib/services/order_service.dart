// services/order_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  final supabase = Supabase.instance.client;

  factory OrderService() {
    return _instance;
  }

  OrderService._internal();

  // Create a new order in database
  Future<Order?> createOrder({
    required String orderId,
    required List<CartItem> items,
    required double subtotal,
    required double gst,
    required double deliveryCharges,
    required double grandTotal,
    required String paymentId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String deliveryAddress,
    required String userId,
  }) async {
    try {
      final orderData = {
        'order_id': orderId,
        'user_id': userId,
        'payment_id': paymentId,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'delivery_address': deliveryAddress,
        'items_json': items
            .map(
              (item) => {
                'id': item.id,
                'name': item.name,
                'price': item.price,
                'quantity': item.quantity,
                'image': item.image,
              },
            )
            .toList(),
        'subtotal': subtotal,
        'gst': gst,
        'delivery_charges': deliveryCharges,
        'grand_total': grandTotal,
        'status': 'confirmed',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      return Order(
        orderId: orderId,
        items: items,
        subtotal: subtotal,
        gst: gst,
        deliveryCharges: deliveryCharges,
        grandTotal: grandTotal,
        paymentId: paymentId,
        status: 'confirmed',
        createdAt: DateTime.now(),
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        deliveryAddress: deliveryAddress,
      );
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  // Get order by ID
  Future<Order?> getOrder(String orderId) async {
    try {
      final response = await supabase
          .from('orders')
          .select()
          .eq('order_id', orderId)
          .single();

      return Order.fromJson(response);
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }

  // Get all orders for a user
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final response = await supabase
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((order) => Order.fromJson(order)).toList();
    } catch (e) {
      print('Error fetching user orders: $e');
      return [];
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await supabase
          .from('orders')
          .update({'status': status})
          .eq('order_id', orderId);
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // Delete order (for cancellation)
  Future<bool> cancelOrder(String orderId) async {
    try {
      await supabase
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('order_id', orderId);
      return true;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }
}
