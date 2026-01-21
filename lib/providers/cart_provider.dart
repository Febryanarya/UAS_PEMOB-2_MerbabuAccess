import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  
  List<CartItem> _cartItems = [];
  int _itemCount = 0;
  double _totalPrice = 0;
  bool _isLoading = false;
  
  List<CartItem> get cartItems => _cartItems;
  int get itemCount => _itemCount;
  double get totalPrice => _totalPrice;
  bool get isLoading => _isLoading;
  
  CartProvider() {
    loadCart();
  }
  
  Future<void> loadCart() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _cartItems = await _cartService.getCartItems();
      _itemCount = _cartItems.length;
      _calculateTotal();
    } catch (e) {
      print('Error loading cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _calculateTotal() {
    _totalPrice = 0;
    for (var item in _cartItems) {
      _totalPrice += item.totalHarga;
    }
  }
  
  Future<void> addToCart(CartItem item) async {
    await _cartService.addToCart(item);
    await loadCart();
  }
  
  Future<void> removeFromCart(String paketId, DateTime tanggalBooking) async {
    await _cartService.removeFromCart(paketId, tanggalBooking);
    await loadCart();
  }
  
  Future<void> updateQuantity(String paketId, DateTime tanggalBooking, int newQuantity) async {
    await _cartService.updateQuantity(paketId, tanggalBooking, newQuantity);
    await loadCart();
  }
  
  Future<void> clearCart() async {
    await _cartService.clearCart();
    _cartItems = [];
    _itemCount = 0;
    _totalPrice = 0;
    notifyListeners();
  }
  
  Future<void> refreshCart() async {
    await loadCart();
  }
  
  // Alias method untuk kompatibilitas
  Future<void> loadCartCount() async => loadCart();
  Future<void> updateCartCount() async => loadCart();
}