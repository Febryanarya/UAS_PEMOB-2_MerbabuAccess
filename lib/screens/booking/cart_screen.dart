import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../../core/routes/app_routes.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  late Future<List<CartItem>> _cartFuture;
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _cartFuture = _cartService.getCartItems();
    _calculateTotal();
  }

  Future<void> _calculateTotal() async {
    final total = await _cartService.getTotalPrice();
    setState(() {
      _totalPrice = total;
    });
  }

  Future<void> _refreshCart() async {
    setState(() {
      _cartFuture = _cartService.getCartItems();
    });
    await _calculateTotal();
  }

  Future<void> _removeItem(CartItem item) async {
    await _cartService.removeFromCart(item.paketId, item.tanggalBooking);
    await _refreshCart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.paketName} dihapus dari keranjang'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) return;
    
    await _cartService.updateQuantity(
      item.paketId, 
      item.tanggalBooking, 
      newQuantity
    );
    await _refreshCart();
  }

  void _proceedToCheckout() {
    if (_totalPrice == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang kosong'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    Navigator.pushNamed(context, AppRoutes.checkout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCart,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<CartItem>>(
              future: _cartFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 50),
                        const SizedBox(height: 16),
                        const Text('Error memuat keranjang'),
                        ElevatedButton(
                          onPressed: _refreshCart,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final cartItems = snapshot.data ?? [];

                if (cartItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Keranjang Kosong',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tambahkan paket pendakian ke keranjang',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.explore),
                          label: const Text('Jelajahi Paket'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final dateFormat = DateFormat('dd MMM yyyy');
                    final timeFormat = DateFormat('HH:mm');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Paket Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Paket Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.paketName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    item.paketRoute,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Date & Time
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        dateFormat.format(item.tanggalBooking),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.access_time, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeFormat.format(item.tanggalBooking),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  
                                  // Quantity Controls
                                  Row(
                                    children: [
                                      const Icon(Icons.people, size: 14),
                                      const SizedBox(width: 4),
                                      const Text('Jumlah: '),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle, size: 20),
                                        color: Colors.red,
                                        onPressed: () {
                                          _updateQuantity(item, item.jumlahOrang - 1);
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${item.jumlahOrang}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle, size: 20),
                                        color: Colors.green,
                                        onPressed: () {
                                          _updateQuantity(item, item.jumlahOrang + 1);
                                        },
                                      ),
                                    ],
                                  ),
                                  
                                  // Price
                                  Text(
                                    'Rp ${item.totalHarga.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Total & Checkout Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembayaran:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp ${_totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text(
                      'LANJUT KE PEMBAYARAN',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _proceedToCheckout,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}