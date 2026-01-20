import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/paket_pendakian.dart';
import '../../models/booking_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/booking_service.dart';
import '../../services/cart_service.dart';
import '../../core/routes/app_routes.dart';

class BookingFormScreen extends StatefulWidget {
  final PaketPendakian paket;

  const BookingFormScreen({super.key, required this.paket});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final BookingService _bookingService = BookingService();
  final CartService _cartService = CartService();

  // Form controllers
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _jumlahOrangController = TextEditingController(text: '1');
  DateTime? _selectedDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _selectedDate = DateTime.now().add(const Duration(days: 7));
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _namaController.text = user.displayName ?? user.email!.split('@')[0];
        _emailController.text = user.email ?? '';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal booking terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User tidak login');

      final jumlahOrang = int.tryParse(_jumlahOrangController.text) ?? 1;
      // ✅ FIX: Hitung total harga
      final totalHarga = (widget.paket.price * jumlahOrang).toDouble();

      final booking = Booking(
        userId: user.uid,
        userName: _namaController.text.trim(),
        userEmail: _emailController.text.trim(),
        paketId: widget.paket.id,
        paketName: widget.paket.name,
        paketRoute: widget.paket.route, // ✅ TAMBAH
        paketPrice: widget.paket.price, // ✅ int
        tanggalBooking: _selectedDate!,
        jumlahOrang: jumlahOrang,
        totalHarga: totalHarga,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _bookingService.createBooking(booking);

      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil! Cek di riwayat booking.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addToCart() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi form dengan benar')),
      );
      return;
    }
    
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal booking terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final jumlahOrang = int.tryParse(_jumlahOrangController.text) ?? 1;

      final cartItem = CartItem(
        paketId: widget.paket.id,
        paketName: widget.paket.name,
        paketRoute: widget.paket.route,
        paketPrice: widget.paket.price.toDouble(), // ✅ Convert ke double
        imageUrl: widget.paket.image,
        tanggalBooking: _selectedDate!,
        jumlahOrang: jumlahOrang,
      );
      
      await _cartService.addToCart(cartItem);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.paket.name} ditambahkan ke keranjang'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Tampilkan pilihan
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Berhasil!'),
            content: const Text('Paket telah ditambahkan ke keranjang.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Lanjutkan Belanja'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamed(context, AppRoutes.cart);
                },
                child: const Text('Lihat Keranjang'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jumlahOrang = int.tryParse(_jumlahOrangController.text) ?? 1;
    final totalHarga = (widget.paket.price * jumlahOrang).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // INFO PAKET
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.paket.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rute: ${widget.paket.route}'),
                          Text(
                            'Rp ${widget.paket.price.toStringAsFixed(0)}/orang',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // FORM INPUT
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan nama lengkap';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan email';
                  }
                  if (!value.contains('@')) {
                    return 'Email tidak valid';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // TANGGAL BOOKING
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Pendakian',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Pilih tanggal'
                            : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                      ),
                      const Icon(Icons.calendar_month, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _jumlahOrangController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Orang',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                  suffixText: 'orang',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan jumlah orang';
                  }
                  final jumlah = int.tryParse(value);
                  if (jumlah == null || jumlah < 1) {
                    return 'Minimal 1 orang';
                  }
                  if (jumlah > 10) {
                    return 'Maksimal 10 orang per booking';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 32),

              // TOTAL HARGA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Harga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp $totalHarga',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // DUA TOMBOL: TAMBAH KE KERANJANG & BOOKING LANGSUNG
              Column(
                children: [
                  // TOMBOL TAMBAH KE KERANJANG
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addToCart,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text(
                        'Tambah ke Keranjang',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // TOMBOL BOOKING LANGSUNG
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitBooking,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.rocket_launch),
                      label: Text(
                        _isLoading ? 'Memproses...' : 'Booking Langsung',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // INFO
                  Card(
                    color: Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '"Tambah ke Keranjang" untuk booking multiple paket. '
                              '"Booking Langsung" untuk langsung konfirmasi.',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
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