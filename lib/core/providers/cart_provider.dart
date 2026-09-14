import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  static const String _cartKey = 'user_cart_items';
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString(_cartKey);
    if (cartString != null && cartString.isNotEmpty) {
      final List<dynamic> decodedList = jsonDecode(cartString);
      _items = decodedList.cast<Map<String, dynamic>>();
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(_items));
    notifyListeners();
  }

  void addToCart(ProductModel product) {
    // Check if item already exists
    final existingIndex = _items.indexWhere((item) => item['productId'] == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex]['qty'] = (_items[existingIndex]['qty'] as int) + 1;
    } else {
      _items.add({
        'productId': product.id,
        'title': product.title,
        'model': product.brand, // Using brand instead of model
        'price': product.price, // It's just price
        'original': product.originalPrice ?? product.price,
        'discount': product.discountTag,
        'qty': 1,
        'image': product.fullImageUrl,
      });
    }
    _saveCart();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item['productId'] == productId);
    _saveCart();
  }

  int getItemQuantity(String productId) {
    final item = _items.firstWhere((i) => i['productId'] == productId, orElse: () => {});
    if (item.isEmpty) return 0;
    return (item['qty'] as num?)?.toInt() ?? 0;
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item['productId'] == productId);
    if (index >= 0) {
      final currentQty = (_items[index]['qty'] as num).toInt();
      if (currentQty <= 1) {
        removeFromCart(productId);
      } else {
        _items[index]['qty'] = currentQty - 1;
        _saveCart();
      }
    }
  }

  void updateQuantity(String productId, int newQty) {
    if (newQty < 1) {
      removeFromCart(productId);
      return;
    }
    final index = _items.indexWhere((item) => item['productId'] == productId);
    if (index >= 0) {
      _items[index]['qty'] = newQty;
      _saveCart();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCart();
  }

  int get totalMRP {
    int total = 0;
    for (var item in _items) {
      total += (item['original'] as num).toInt() * (item['qty'] as int);
    }
    return total;
  }

  int get totalAmount {
    int total = 0;
    for (var item in _items) {
      total += (item['price'] as num).toInt() * (item['qty'] as int);
    }
    return total;
  }

  int get itemCount {
    int total = 0;
    for (var item in _items) {
      total += item['qty'] as int;
    }
    return total;
  }
}
