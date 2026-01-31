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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    _quantityUpdateTimer?.cancel();
    _voucherController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() {
      _cartFuture = _cartService.getCartItems();
    });
    await _calculateTotal();
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
      context.read<CartProvider>().clearCart();
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

  Future<void> _goToBookingForm(CartItem item) async {
    try {
      final paket = await _paketService.getPaketById(item.paketId);
      if (paket != null && context.mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.bookingForm,
          arguments: paket,
        );
        
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Gunakan LayoutBuilder untuk mendeteksi ukuran layar
            final isSmallScreen = constraints.maxHeight < 600;
            
            return Column(
              children: [
                if (!isSmallScreen) const _PromoBanner(),
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

                      return _CartContent(
                        cartItems: cartItems,
                        isSmallScreen: isSmallScreen,
                        scrollController: _scrollController,
                        dateFormatter: _dateFormatter,
                        priceFormatter: _priceFormatter,
                        onUpdateQuantityDebounced: _updateQuantityDebounced,
                        onRemove: _removeItem,
                        onGoToPackageDetail: _goToPackageDetail,
                        onGoToBookingForm: _goToBookingForm,
                      );
                    },
                  ),
                ),
                // SUMMARY - DIPINDAH KE BOTTOM NAVIGATION BAR
                _CartSummaryBottomBar(
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
                  onExpandSummary: _showSummaryBottomSheet,
                ),
              ],
            );
          },
        ),
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

  void _showSummaryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => _CartSummaryBottomSheet(
        totalPrice: _totalPrice,
        discount: _discount,
        finalPrice: _finalPrice,
        voucherController: _voucherController,
        isApplyingVoucher: _isApplyingVoucher,
        voucherApplied: _voucherApplied,
        onApplyVoucher: _applyVoucher,
        onRemoveVoucher: _removeVoucher,
        onCheckout: _proceedToCheckout,
      ),
    );
  }
}

// ============================================
// SUB-COMPONENTS
// ============================================

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.primaryColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_offer, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gunakan "MERBABU10" untuk diskon 10%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 30,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 16),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 50,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Keranjang Kosong',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tambahkan paket pendakian ke keranjang untuk memulai petualanganmu',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Jelajahi Paket'),
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
                  horizontal: 24,
                  vertical: 14,
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

// ============ KONTEN UTAMA KERANJANG ============
class _CartContent extends StatelessWidget {
  final List<CartItem> cartItems;
  final bool isSmallScreen;
  final ScrollController scrollController;
  final DateFormat dateFormatter;
  final NumberFormat priceFormatter;
  final Function(CartItem, int) onUpdateQuantityDebounced;
  final Function(CartItem) onRemove;
  final Function(CartItem) onGoToPackageDetail;
  final Function(CartItem) onGoToBookingForm;

  const _CartContent({
    required this.cartItems,
    required this.isSmallScreen,
    required this.scrollController,
    required this.dateFormatter,
    required this.priceFormatter,
    required this.onUpdateQuantityDebounced,
    required this.onRemove,
    required this.onGoToPackageDetail,
    required this.onGoToBookingForm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isSmallScreen) const _PromoBanner(),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return _CompactCartItemCard(
                item: item,
                dateFormatter: dateFormatter,
                priceFormatter: priceFormatter,
                onUpdateQuantity: (cartItem, newQuantity) =>
                    onUpdateQuantityDebounced(cartItem, newQuantity),
                onRemove: onRemove,
                onViewDetails: () => onGoToPackageDetail(item),
                onBookNow: () => onGoToBookingForm(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============ KARTU ITEM KOMPAK ============
class _CompactCartItemCard extends StatelessWidget {
  final CartItem item;
  final DateFormat dateFormatter;
  final NumberFormat priceFormatter;
  final Function(CartItem, int) onUpdateQuantity;
  final Function(CartItem) onRemove;
  final VoidCallback onViewDetails;
  final VoidCallback onBookNow;

  const _CompactCartItemCard({
    required this.item,
    required this.dateFormatter,
    required this.priceFormatter,
    required this.onUpdateQuantity,
    required this.onRemove,
    required this.onViewDetails,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: InkWell(
        onTap: onViewDetails,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar kecil
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                    child: item.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.terrain,
                                size: 30,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.terrain,
                            size: 30,
                            color: AppTheme.primaryColor,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Row(
                          children: [
                            Icon(
                              Icons.route,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.paketRoute,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormatter.format(item.tanggalBooking),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CompactQuantityControls(
                    quantity: item.jumlahOrang,
                    onDecrease: () => onUpdateQuantity(item, item.jumlahOrang - 1),
                    onIncrease: () => onUpdateQuantity(item, item.jumlahOrang + 1),
                  ),
                  Text(
                    'Rp ${priceFormatter.format(item.totalHarga)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBookNow,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: AppTheme.primaryColor),
                      ),
                      child: const Text(
                        'Booking',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onViewDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Detail',
                        style: TextStyle(fontSize: 12, color: Colors.white),
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

class _CompactQuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _CompactQuantityControls({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.remove,
              size: 16,
              color: quantity > 1 ? AppTheme.primaryColor : AppTheme.textDisabled,
            ),
            onPressed: quantity > 1 ? onDecrease : null,
            padding: const EdgeInsets.all(4),
          ),
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              size: 16,
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

// ============ BOTTOM BAR SUMMARY ============
class _CartSummaryBottomBar extends StatelessWidget {
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
  final VoidCallback onExpandSummary;

  const _CartSummaryBottomBar({
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
    required this.onExpandSummary,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat('#,##0', 'id_ID');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Rp ${priceFormatter.format(finalPrice)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onClearCart,
                    color: AppTheme.errorColor,
                    tooltip: 'Kosongkan Keranjang',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onExpandSummary,
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Detail'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onCheckout,
                    icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                    label: const Text('Checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (discount > 0)
            Text(
              'Diskon: Rp ${priceFormatter.format(discount)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

// ============ BOTTOM SHEET SUMMARY DETAIL ============
class _CartSummaryBottomSheet extends StatefulWidget {
  final double totalPrice;
  final double discount;
  final double finalPrice;
  final TextEditingController voucherController;
  final bool isApplyingVoucher;
  final bool voucherApplied;
  final VoidCallback onApplyVoucher;
  final VoidCallback onRemoveVoucher;
  final VoidCallback onCheckout;

  const _CartSummaryBottomSheet({
    required this.totalPrice,
    required this.discount,
    required this.finalPrice,
    required this.voucherController,
    required this.isApplyingVoucher,
    required this.voucherApplied,
    required this.onApplyVoucher,
    required this.onRemoveVoucher,
    required this.onCheckout,
  });

  @override
  State<_CartSummaryBottomSheet> createState() => _CartSummaryBottomSheetState();
}

class _CartSummaryBottomSheetState extends State<_CartSummaryBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat('#,##0', 'id_ID');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Rincian Pembayaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Voucher Input
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.voucherController,
                  decoration: InputDecoration(
                    hintText: widget.voucherApplied
                        ? 'Voucher diterapkan'
                        : 'Masukkan kode voucher',
                    prefixIcon: const Icon(
                      Icons.local_offer_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    suffixIcon: widget.voucherApplied
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: widget.onRemoveVoucher,
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
                  enabled: !widget.voucherApplied,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: widget.voucherApplied || widget.isApplyingVoucher
                    ? null
                    : widget.onApplyVoucher,
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
                child: widget.isApplyingVoucher
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.voucherApplied ? '✓' : 'Terapkan',
                        style: const TextStyle(fontSize: 14),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Price Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Subtotal',
                  value: widget.totalPrice,
                  priceFormatter: priceFormatter,
                ),
                if (widget.discount > 0) ...[
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Diskon Voucher',
                    value: -widget.discount,
                    priceFormatter: priceFormatter,
                    isDiscount: true,
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: 'Total Pembayaran',
                  value: widget.finalPrice,
                  priceFormatter: priceFormatter,
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onCheckout,
              icon: const Icon(Icons.shopping_cart_checkout, size: 24),
              label: const Text(
                'LANJUT KE PEMBAYARAN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat priceFormatter;
  final bool isDiscount;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.priceFormatter,
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
                ),
        ),
        Text(
          'Rp ${priceFormatter.format(value.abs())}',
          style: isTotal
              ? const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                )
              : TextStyle(
                  fontSize: 14,
                  color: isDiscount
                      ? AppTheme.successColor
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}