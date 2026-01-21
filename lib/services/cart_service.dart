// lib/services/cart_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item_model.dart';

class CartService {
  static const String _cartKey = 'merbabu_cart';

  // Add item to cart
  Future<void> addToCart(CartItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final List<CartItem> cartItems = await getCartItems();
    
    final existingIndex = cartItems.indexWhere((cartItem) => 
        cartItem.paketId == item.paketId && 
        _isSameDate(cartItem.tanggalBooking, item.tanggalBooking));
    
    if (existingIndex != -1) {
      // Update quantity if exists - TANPA copyWith
      cartItems[existingIndex] = CartItem(
        paketId: cartItems[existingIndex].paketId,
        paketName: cartItems[existingIndex].paketName,
        paketRoute: cartItems[existingIndex].paketRoute,
        paketPrice: cartItems[existingIndex].paketPrice,
        imageUrl: cartItems[existingIndex].imageUrl,
        tanggalBooking: cartItems[existingIndex].tanggalBooking,
        jumlahOrang: cartItems[existingIndex].jumlahOrang + item.jumlahOrang,
      );
      cartItems[existingIndex].updateTotal();
    } else {
      cartItems.add(item);
    }
    
    await _saveCart(cartItems, prefs);
  }

  // Get all cart items
  Future<List<CartItem>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartJson = prefs.getString(_cartKey);
    
    if (cartJson == null) return [];
    
    try {
      final List<dynamic> cartList = json.decode(cartJson);
      return cartList.map((item) => CartItem.fromMap(item)).toList();
    } catch (e) {
      await clearCart();
      return [];
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String paketId, DateTime tanggalBooking) async {
    final prefs = await SharedPreferences.getInstance();
    final List<CartItem> cartItems = await getCartItems();
    cartItems.removeWhere((item) => 
        item.paketId == paketId && 
        _isSameDate(item.tanggalBooking, tanggalBooking));
    await _saveCart(cartItems, prefs);
  }

  // Update item quantity
  Future<void> updateQuantity(
    String paketId, 
    DateTime tanggalBooking, 
    int newQuantity
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<CartItem> cartItems = await getCartItems();
    final index = cartItems.indexWhere((item) => 
        item.paketId == paketId && 
        _isSameDate(item.tanggalBooking, tanggalBooking));
    
    if (index != -1) {
      if (newQuantity < 1) {
        cartItems.removeAt(index);
      } else {
        cartItems[index] = CartItem(
          paketId: cartItems[index].paketId,
          paketName: cartItems[index].paketName,
          paketRoute: cartItems[index].paketRoute,
          paketPrice: cartItems[index].paketPrice,
          imageUrl: cartItems[index].imageUrl,
          tanggalBooking: cartItems[index].tanggalBooking,
          jumlahOrang: newQuantity,
        );
        cartItems[index].updateTotal();
      }
      await _saveCart(cartItems, prefs);
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  // Calculate total
  Future<double> getTotalPrice() async {
    final List<CartItem> cartItems = await getCartItems();
    double total = 0;
    for (var item in cartItems) {
      total += item.totalHarga;
    }
    return total;
  }

  // Get item count
  Future<int> getItemCount() async {
    final cartItems = await getCartItems();
    return cartItems.length;
  }

  // Check if item exists in cart
  Future<bool> itemExists(String paketId, DateTime tanggalBooking) async {
    final cartItems = await getCartItems();
    return cartItems.any((item) => 
        item.paketId == paketId && 
        _isSameDate(item.tanggalBooking, tanggalBooking));
  }

  // Save cart to SharedPreferences
  Future<void> _saveCart(List<CartItem> cartItems, SharedPreferences prefs) async {
    final List<Map<String, dynamic>> cartMaps = 
        cartItems.map((item) => item.toMap()).toList();
    await prefs.setString(_cartKey, json.encode(cartMaps));
  }

  // Helper: Compare dates (ignore time)
  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}