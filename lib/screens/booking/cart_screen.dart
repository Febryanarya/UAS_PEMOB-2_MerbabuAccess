import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:merbabuaccess_app/models/cart_item_model.dart';
import 'package:merbabuaccess_app/models/paket_pendakian.dart';
import 'package:merbabuaccess_app/services/cart_service.dart';
import 'package:merbabuaccess_app/services/paket_service.dart';
import 'package:merbabuaccess_app/core/routes/app_routes.dart';
import 'package:merbabuaccess_app/core/theme/app_theme.dart';
import 'package:merbabuaccess_app/providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final PaketService _paketService = PaketService();
  late Future<List<CartItem>> _cartFuture;
  double _totalPrice = 0;
  double _discount = 0;
  final TextEditingController _voucherController = TextEditingController();
  bool _isApplyingVoucher = false;
  bool _voucherApplied = false;
  Timer? _quantityUpdateTimer;
  final NumberFormat _priceFormatter = NumberFormat('#,##0', 'id_ID');
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    _quantityUpdateTimer?.cancel();
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() {
      _cartFuture = _cartService.getCartItems();
    });
    await _calculateTotal();
    // Update cart provider
    context.read<CartProvider>().refreshCart();
  }

  Future<void> _calculateTotal() async {
    final total = await _cartService.getTotalPrice();
    if (mounted) {
      setState(() {
        _totalPrice = total;
      });
    }
  }

  void _updateQuantityDebounced(CartItem item, int newQuantity) {
    if (newQuantity < 1) return;

    _quantityUpdateTimer?.cancel();
    _quantityUpdateTimer = Timer(const Duration(milliseconds: 300), () {
      _updateQuantity(item, newQuantity);
    });
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    await _cartService.updateQuantity(
      item.paketId,
      item.tanggalBooking,
      newQuantity,
    );
    await _loadCart();
  }

  Future<void> _removeItem(CartItem item) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Hapus Item',
      message: 'Hapus ${item.paketName} dari keranjang?',
      confirmText: 'Hapus',
      confirmColor: AppTheme.errorColor,
    );

    if (confirmed) {
      await _cartService.removeFromCart(item.paketId, item.tanggalBooking);
      await _loadCart();
      _showSuccessSnackbar('${item.paketName} dihapus dari keranjang');
    }
  }

  Future<void> _applyVoucher() async {
    final voucherCode = _voucherController.text.trim();
    if (voucherCode.isEmpty) return;

    setState(() => _isApplyingVoucher = true);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    final isValid = _validateVoucher(voucherCode);
    
    if (mounted) {
      setState(() {
        if (isValid) {
          _discount = _totalPrice * 0.1;
          _voucherApplied = true;
          _showSuccessSnackbar('Voucher berhasil diterapkan!');
        } else {
          _showErrorSnackbar('Kode voucher tidak valid');
        }
        _isApplyingVoucher = false;
      });
    }
  }

  bool _validateVoucher(String code) {
    final validCodes = {'merbabu10', 'gunung10'};
    return validCodes.contains(code.toLowerCase());
  }

  void _removeVoucher() {
    setState(() {
      _discount = 0;
      _voucherApplied = false;
      _voucherController.clear();
    });
  }

Future<void> _clearCart() async {
  final confirmed = await _showConfirmationDialog(
    title: 'Kosongkan Keranjang',
    message: 'Hapus semua item dari keranjang?',
    confirmText: 'Kosongkan',
    confirmColor: AppTheme.errorColor,
  );

  if (confirmed) {
    await _cartService.clearCart();
    await _loadCart();
    _showSuccessSnackbar('Keranjang berhasil dikosongkan');
    context.read<CartProvider>().clearCart(); // METHOD SUDAH BENAR
  }
}

  void _proceedToCheckout() {
    if (_totalPrice == 0) {
      _showWarningSnackbar('Keranjang kosong');
      return;
    }

    Navigator.pushNamed(context, AppRoutes.checkout, arguments: {
      'total': _totalPrice - _discount,
      'discount': _discount,
    });
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
            ),
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWarningSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.warningColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double get _finalPrice => _totalPrice - _discount;

  // ============ PERUBAHAN 1: TAMBAH METHOD _goToBookingForm ============
  Future<void> _goToBookingForm(CartItem item) async {
    try {
      final paket = await _paketService.getPaketById(item.paketId);
      if (paket != null && context.mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.bookingForm,
          arguments: paket,
        );
        
        // Info bahwa data dari cart bisa digunakan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Buka form booking dari keranjang'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _showErrorSnackbar('Paket tidak ditemukan');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar('Gagal membuka form booking');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Booking'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCart,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          const _PromoBanner(),
          Expanded(
            child: FutureBuilder<List<CartItem>>(
              future: _cartFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingState();
                }

                if (snapshot.hasError) {
                  return _ErrorState(onRetry: _loadCart);
                }

                final cartItems = snapshot.data ?? [];
                if (cartItems.isEmpty) {
                  return const _EmptyState();
                }

                // ============ PERUBAHAN 2: UPDATE ListView.builder ============
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return _CartItemCard(
                      item: item,
                      dateFormatter: _dateFormatter,
                      priceFormatter: _priceFormatter,
                      onUpdateQuantity: (cartItem, newQuantity) =>
                          _updateQuantityDebounced(cartItem, newQuantity),
                      onRemove: _removeItem,
                      onTapItem: () => _goToPackageDetail(item),
                      onBookNow: () => _goToBookingForm(item), // ✅ TAMBAH INI
                    );
                  },
                );
              },
            ),
          ),
          _CartSummary(
            totalPrice: _totalPrice,
            discount: _discount,
            finalPrice: _finalPrice,
            voucherController: _voucherController,
            isApplyingVoucher: _isApplyingVoucher,
            voucherApplied: _voucherApplied,
            onApplyVoucher: _applyVoucher,
            onRemoveVoucher: _removeVoucher,
            onClearCart: _clearCart,
            onCheckout: _proceedToCheckout,
          ),
        ],
      ),
    );
  }

  Future<void> _goToPackageDetail(CartItem item) async {
    try {
      final paket = await _paketService.getPaketById(item.paketId);
      if (paket != null && context.mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.detailPaket,
          arguments: paket,
        );
      } else {
        _showErrorSnackbar('Paket tidak ditemukan');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar('Gagal memuat detail paket');
      }
    }
  }
}



// ============================================
// SUB-COMPONENTS (Extracted for better performance)
// ============================================

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.primaryColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_offer, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gunakan kode "MERBABU10" untuk diskon 10%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'Memuat keranjang...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gagal memuat keranjang',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Terjadi kesalahan saat mengambil data',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Keranjang Kosong',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tambahkan paket pendakian ke keranjang untuk memulai petualanganmu',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Jelajahi Paket'),
              // ✅ FIX: Empty Cart Flow ke Home, bukan pop
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ PERUBAHAN 3: UPDATE CLASS _CartItemCard ============
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final DateFormat dateFormatter;
  final NumberFormat priceFormatter;
  final Function(CartItem, int) onUpdateQuantity;
  final Function(CartItem) onRemove;
  final VoidCallback onTapItem;
  final VoidCallback onBookNow; // ✅ PARAMETER BARU

  const _CartItemCard({
    required this.item,
    required this.dateFormatter,
    required this.priceFormatter,
    required this.onUpdateQuantity,
    required this.onRemove,
    required this.onTapItem,
    required this.onBookNow, // ✅ TAMBAH INI
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('${item.paketId}-${item.tanggalBooking}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppTheme.errorColor,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Item'),
            content: Text('Hapus ${item.paketName} dari keranjang?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) => onRemove(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian atas: gambar dan detail
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PackageImage(imageUrl: item.imageUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PackageDetails(
                      item: item,
                      dateFormatter: dateFormatter,
                      priceFormatter: priceFormatter,
                      onUpdateQuantity: onUpdateQuantity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // ✅ BAGIAN BARU: TOMBOL ACTION
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onBookNow,
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: const Text('Booking Langsung'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: AppTheme.primaryColor),
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onTapItem,
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Lihat Detail'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageImage extends StatelessWidget {
  final String imageUrl;

  const _PackageImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.terrain,
                    size: 40,
                    color: AppTheme.primaryColor,
                  );
                },
              )
            : const Icon(
                Icons.terrain,
                size: 40,
                color: AppTheme.primaryColor,
              ),
      ),
    );
  }
}

class _PackageDetails extends StatelessWidget {
  final CartItem item;
  final DateFormat dateFormatter;
  final NumberFormat priceFormatter;
  final Function(CartItem, int) onUpdateQuantity;

  const _PackageDetails({
    required this.item,
    required this.dateFormatter,
    required this.priceFormatter,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Package Name
        Text(
          item.paketName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Package Route
        Row(
          children: [
            const Icon(
              Icons.route,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              item.paketRoute,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Booking Date
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              dateFormatter.format(item.tanggalBooking),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Quantity Controls and Price
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuantityControls(
              quantity: item.jumlahOrang,
              onDecrease: () => onUpdateQuantity(item, item.jumlahOrang - 1),
              onIncrease: () => onUpdateQuantity(item, item.jumlahOrang + 1),
            ),
            Text(
              'Rp ${priceFormatter.format(item.totalHarga)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityControls({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.remove,
              size: 18,
              color: quantity > 1 ? AppTheme.primaryColor : AppTheme.textDisabled,
            ),
            onPressed: quantity > 1 ? onDecrease : null,
            padding: const EdgeInsets.all(4),
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            onPressed: onIncrease,
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double totalPrice;
  final double discount;
  final double finalPrice;
  final TextEditingController voucherController;
  final bool isApplyingVoucher;
  final bool voucherApplied;
  final VoidCallback onApplyVoucher;
  final VoidCallback onRemoveVoucher;
  final VoidCallback onClearCart;
  final VoidCallback onCheckout;

  const _CartSummary({
    required this.totalPrice,
    required this.discount,
    required this.finalPrice,
    required this.voucherController,
    required this.isApplyingVoucher,
    required this.voucherApplied,
    required this.onApplyVoucher,
    required this.onRemoveVoucher,
    required this.onClearCart,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Voucher Input
          _VoucherInput(
            controller: voucherController,
            isApplyingVoucher: isApplyingVoucher,
            voucherApplied: voucherApplied,
            onApplyVoucher: onApplyVoucher,
            onRemoveVoucher: onRemoveVoucher,
          ),
          const SizedBox(height: 20),
          // Price Breakdown
          _PriceBreakdown(
            totalPrice: totalPrice,
            discount: discount,
            finalPrice: finalPrice,
          ),
          const SizedBox(height: 20),
          // Checkout Button
          _CheckoutButton(
            onCheckout: onCheckout,
            onClearCart: onClearCart,
          ),
        ],
      ),
    );
  }
}

class _VoucherInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isApplyingVoucher;
  final bool voucherApplied;
  final VoidCallback onApplyVoucher;
  final VoidCallback onRemoveVoucher;

  const _VoucherInput({
    required this.controller,
    required this.isApplyingVoucher,
    required this.voucherApplied,
    required this.onApplyVoucher,
    required this.onRemoveVoucher,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: voucherApplied
                  ? 'Voucher diterapkan'
                  : 'Masukkan kode voucher',
              prefixIcon: const Icon(
                Icons.local_offer_outlined,
                color: AppTheme.textSecondary,
              ),
              suffixIcon: voucherApplied
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onRemoveVoucher,
                      color: AppTheme.errorColor,
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            enabled: !voucherApplied,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: voucherApplied || isApplyingVoucher ? null : onApplyVoucher,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          child: isApplyingVoucher
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  voucherApplied ? '✓' : 'Terapkan',
                  style: const TextStyle(fontSize: 14),
                ),
        ),
      ],
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  final double totalPrice;
  final double discount;
  final double finalPrice;

  const _PriceBreakdown({
    required this.totalPrice,
    required this.discount,
    required this.finalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat('#,##0', 'id_ID');

    return Column(
      children: [
        _PriceRow(
          label: 'Subtotal',
          value: totalPrice,
          priceFormatter: priceFormatter,
          isBold: false,
        ),
        if (discount > 0) ...[
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Diskon Voucher',
            value: -discount,
            priceFormatter: priceFormatter,
            isBold: false,
            isDiscount: true,
          ),
        ],
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _PriceRow(
          label: 'Total Pembayaran',
          value: finalPrice,
          priceFormatter: priceFormatter,
          isTotal: true,
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat priceFormatter;
  final bool isBold;
  final bool isDiscount;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.value,
    required this.priceFormatter,
    this.isBold = false,
    this.isDiscount = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                )
              : TextStyle(
                  fontSize: 14,
                  color: isDiscount
                      ? AppTheme.successColor
                      : AppTheme.textSecondary,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                ),
        ),
        Text(
          'Rp ${priceFormatter.format(value.abs())}',
          style: isTotal
              ? const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                )
              : TextStyle(
                  fontSize: 14,
                  color: isDiscount
                      ? AppTheme.successColor
                      : AppTheme.textPrimary,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                ),
        ),
      ],
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  final VoidCallback onCheckout;
  final VoidCallback onClearCart;

  const _CheckoutButton({
    required this.onCheckout,
    required this.onClearCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onCheckout,
            icon: const Icon(Icons.shopping_cart_checkout, size: 24),
            label: const Text(
              'LANJUT KE PEMBAYARAN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onClearCart,
          child: const Text(
            'Kosongkan Keranjang',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.errorColor,
            ),
          ),
        ),
      ],
    );
  }
}