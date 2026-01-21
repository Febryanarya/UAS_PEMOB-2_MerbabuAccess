import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic>? args;

  const CheckoutScreen({super.key, this.args});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedPayment = 'bank_transfer';
  bool _isSubmitting = false;
  bool _isLoading = false;
  Booking? _booking;
  bool _isFromCart = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initializeData() {
    if (widget.args != null) {
      if (widget.args!['booking'] is Booking) {
        _booking = widget.args!['booking'] as Booking;
        _isFromCart = false;
      } else {
        // Dari CartScreen (hanya ada total & discount)
        _isFromCart = true;
      }
      setState(() {});
    } else {
      _isLoading = true;
      _loadLatestBooking();
    }
  }

  Future<void> _loadLatestBooking() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        _booking = Booking.fromMap(doc.id, doc.data());
      }
    } catch (e) {
      print('Error loading booking: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Text('Pembayaran Berhasil'),
          ],
        ),
        content: const Text('Booking Anda berhasil diproses. Apa yang ingin Anda lakukan selanjutnya?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigasi ke Riwayat Booking
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.riwayatBooking,
                (route) => false,
              );
            },
            child: const Text('Lihat Riwayat'),
          ),
          if (_booking != null) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigasi ke Tiket
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.ticket,
                  (route) => false,
                  arguments: _booking,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Lihat Tiket', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _processPayment(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackbar('Anda harus login terlebih dahulu', Colors.orange);
      return;
    }

    if (!_isFromCart && _booking == null) {
      _showSnackbar('Data booking tidak ditemukan', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? bookingId;
      
      if (_isFromCart) {
        // Dari Cart: Buat booking baru dari cart items
        final cartProvider = context.read<CartProvider>();
        final cartItems = cartProvider.cartItems;
        
        if (cartItems.isEmpty) {
          _showSnackbar('Keranjang kosong', Colors.red);
          return;
        }

        // Buat booking untuk setiap item di cart
        for (final item in cartItems) {
          final booking = Booking(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_${item.paketId}',
            userId: user.uid,
            userName: user.displayName ?? 'User',
            userEmail: user.email ?? '',
            userPhone: '',
            paketId: item.paketId,
            paketName: item.paketName,
            paketRoute: item.paketRoute,
            paketPrice: item.paketPrice,
            tanggalBooking: item.tanggalBooking,
            jumlahOrang: item.jumlahOrang,
            totalHarga: item.totalHarga,
            paymentMethod: _selectedPayment,
            status: 'pending_payment',
            createdAt: DateTime.now(),
          );

          await _firestore
              .collection('bookings')
              .doc(booking.id)
              .set(booking.toMap());

          bookingId = booking.id;
        }

        // Clear cart setelah checkout
        await cartProvider.clearCart();

      } else {
        // Dari BookingForm: Update booking yang sudah ada
        bookingId = _booking!.id;
        
        String newStatus = _selectedPayment == 'cash' ? 'pending' : 'pending_payment';

        await _firestore
            .collection('bookings')
            .doc(_booking!.id)
            .update({
              'status': newStatus,
              'paymentMethod': _selectedPayment,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      // Show success message
      _showSnackbar('✅ Pembayaran berhasil dikonfirmasi', Colors.green);

      // Wait a moment then show success dialog
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        _showSuccessDialog(context);
      }

    } catch (e) {
      _showSnackbar('❌ Gagal memproses pembayaran: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }



  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double total = widget.args?['total'] as double? ?? _booking?.totalHarga ?? 0;
    final double discount = widget.args?['discount'] as double? ?? 0;
    final double subtotal = total + discount;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isFromCart ? 'Checkout dari Keranjang' : 'Checkout Booking'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isFromCart ? 'Checkout Keranjang' : 'Checkout Booking',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _booking?.paketName ?? 'Selesaikan pembayaran',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // RINGKASAN BOOKING (jika dari booking form)
                        if (_booking != null && !_isFromCart)
                          _buildBookingSummaryCard(),

                        // INFO JIKA DARI CART
                        if (_isFromCart)
                          _buildCartSummaryInfo(),

                        const SizedBox(height: 16),

                        // RINGKASAN PEMBAYARAN
                        _buildPaymentSummaryCard(subtotal, discount, total),
                        const SizedBox(height: 24),

                        // METODE PEMBAYARAN
                        _buildPaymentMethodSection(),
                        const SizedBox(height: 32),

                        // INSTRUKSI PEMBAYARAN
                        _buildPaymentInstructions(total),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // TOMBOL KONFIRMASI
                _buildCheckoutButton(),
              ],
            ),
    );
  }

  Widget _buildBookingSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.confirmation_number, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Detail Booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Paket', _booking!.paketName),
            _buildDetailRow('Tanggal', 
              DateFormat('dd MMMM yyyy').format(_booking!.tanggalBooking)),
            _buildDetailRow('Jumlah Orang', '${_booking!.jumlahOrang} orang'),
            _buildDetailRow('Status', _getStatusText(_booking!.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummaryInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.shopping_cart, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Checkout dari Keranjang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      return Text(
                        '${cartProvider.itemCount} item di keranjang',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard(double subtotal, double discount, double total) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Ringkasan Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Subtotal', subtotal),
            if (discount > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Diskon', -discount, isDiscount: true),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildPriceRow('Total Bayar', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metode Pembayaran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentOption('bank_transfer', 'Transfer Bank', Icons.account_balance),
        _buildPaymentOption('qris', 'QRIS', Icons.qr_code),
        _buildPaymentOption('cash', 'Bayar di Tempat', Icons.money),
      ],
    );
  }

  Widget _buildPaymentInstructions(double total) {
    if (_selectedPayment == 'bank_transfer') {
      return _buildInstructionCard(
        'Transfer Bank',
        [
          '1. Transfer ke rekening BNI: 1234-5678-9012',
          '2. Atas nama: PT Merbabu Access',
          '3. Jumlah: Rp ${_formatPrice(total)}',
          '4. Upload bukti transfer di halaman riwayat booking',
        ],
        Colors.blue,
      );
    } else if (_selectedPayment == 'qris') {
      return _buildInstructionCard(
        'QRIS',
        [
          '1. Scan QR Code yang akan muncul setelah konfirmasi',
          '2. Gunakan e-wallet atau mobile banking',
          '3. Jumlah: Rp ${_formatPrice(total)}',
          '4. Pembayaran diverifikasi otomatis',
        ],
        Colors.green,
      );
    } else {
      return _buildInstructionCard(
        'Bayar di Tempat',
        [
          '1. Datang ke kantor Merbabu Access',
          '2. Alamat: Jl. Merbabu No. 123, Salatiga',
          '3. Bayar pada hari H-3 sebelum pendakian',
          '4. Bawa bukti booking dan KTP',
        ],
        Colors.orange,
      );
    }
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : () => _processPayment(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'KONFIRMASI PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, {bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.green : Colors.black,
          ),
        ),
        Text(
          'Rp ${_formatPrice(value.abs())}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.primaryColor : 
                  isDiscount ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    return NumberFormat('#,##0', 'id_ID').format(price);
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _selectedPayment == value;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.primaryColor : Colors.black,
          ),
        ),
        trailing: Radio(
          value: value,
          groupValue: _selectedPayment,
          onChanged: (val) => setState(() => _selectedPayment = val!),
          activeColor: AppTheme.primaryColor,
        ),
        onTap: () {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 100), () {
            setState(() => _selectedPayment = value);
          });
        },
      ),
    );
  }

  Widget _buildInstructionCard(
    String title,
    List<String> instructions,
    MaterialColor color,
  ) {
    return Card(
      color: color.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: color.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Instruksi $title',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...instructions.map((instruction) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                instruction,
                style: TextStyle(
                  color: color.shade800,
                  fontSize: 13,
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Terkonfirmasi';
      case 'paid':
        return 'Sudah Dibayar';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}