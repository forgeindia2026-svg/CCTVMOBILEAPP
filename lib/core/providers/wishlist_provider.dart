import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class WishlistProvider extends ChangeNotifier {
  static const String _wishlistKey = 'user_wishlist_products';
  List<ProductModel> _items = [];

  List<ProductModel> get items => _items;

  WishlistProvider() {
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistString = prefs.getString(_wishlistKey);
      if (wishlistString != null && wishlistString.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(wishlistString);
        _items = decodedList.map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item))).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    }
  }

  Future<void> _saveWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedList = _items.map((item) => item.toJson()).toList();
      await prefs.setString(_wishlistKey, jsonEncode(encodedList));
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving wishlist: $e');
    }
  }

  bool isWishlisted(String productId) {
    return _items.any((item) => item.id == productId);
  }

  void toggleWishlist(ProductModel product) {
    final index = _items.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _items.removeAt(index);
    } else {
      _items.add(product);
    }
    _saveWishlist();
  }

  void addToWishlist(ProductModel product) {
    if (!isWishlisted(product.id)) {
      _items.add(product);
      _saveWishlist();
    }
  }

  void removeFromWishlist(String productId) {
    _items.removeWhere((item) => item.id == productId);
    _saveWishlist();
  }

  void clearWishlist() {
    _items.clear();
    _saveWishlist();
  }

  int get itemCount => _items.length;
}
