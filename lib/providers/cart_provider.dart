// providers/cart_provider.dart

import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  int get cartCount => _cartItems.length;

  double get totalPrice {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get subtotal => totalPrice;

  double get deliveryCharges => totalPrice > 5000 ? 0 : 200;

  double get gst => (subtotal * 0.05); // 5% GST

  double get grandTotal => subtotal + gst + deliveryCharges;

  void addToCart(String id, String name, double price, String image) {
    final existingIndex = _cartItems.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
        quantity: _cartItems[existingIndex].quantity + 1,
      );
    } else {
      _cartItems.add(
        CartItem(id: id, name: name, price: price, image: image, quantity: 1),
      );
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeFromCart(id);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  bool isItemInCart(String id) {
    return _cartItems.any((item) => item.id == id);
  }

  int getItemQuantity(String id) {
    final item = _cartItems.firstWhere(
      (item) => item.id == id,
      orElse: () => CartItem(id: '', name: '', price: 0, image: ''),
    );
    return item.quantity;
  }
}
