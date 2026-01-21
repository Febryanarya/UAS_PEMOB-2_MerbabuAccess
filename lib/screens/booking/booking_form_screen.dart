import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/paket_pendakian.dart';
import '../../models/booking_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class BookingFormScreen extends StatefulWidget {
  final PaketPendakian paket;

  const BookingFormScreen({super.key, required this.paket});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // FORM DATA
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _specialRequestController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  int _jumlahOrang = 1;
  String _selectedPaymentMethod = 'bank_transfer';
  int _availableQuota = 0;
  bool _isCheckingAvailability = false;
  bool _isSubmitting = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkAvailability();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _validateForm();
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          _fullNameController.text = data['fullName'] ?? user.displayName ?? '';
          _phoneController.text = data['phone'] ?? '';
          _idNumberController.text = data['idNumber'] ?? '';
        } else {
          _fullNameController.text = user.displayName ?? '';
        }
      } catch (e) {
        print('Error loading user data: $e');
        _fullNameController.text = user.displayName ?? '';
      }
    }
  }

  Future<void> _checkAvailability() async {
    setState(() => _isCheckingAvailability = true);
    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1);
      
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('paketId', isEqualTo: widget.paket.id)
          .where('tanggalBooking', isGreaterThanOrEqualTo: startOfDay)
          .where('tanggalBooking', isLessThan: endOfDay)
          .where('status', whereIn: ['pending', 'confirmed', 'paid'])
          .get();

      int bookedCount = 0;
      for (var doc in bookingsSnapshot.docs) {
        final booking = doc.data() as Map<String, dynamic>;
        bookedCount += (booking['jumlahOrang'] as num?)?.toInt() ?? 0;
      }
      
      setState(() {
        _availableQuota = widget.paket.quota - bookedCount;
        if (_availableQuota < 0) _availableQuota = 0;
        
        if (_jumlahOrang > _availableQuota && _availableQuota > 0) {
          _jumlahOrang = _availableQuota;
        }
      });
    } catch (e) {
      print('Error checking availability: $e');
      setState(() => _availableQuota = widget.paket.quota);
    } finally {
      setState(() => _isCheckingAvailability = false);
    }
  }

  Future<String?> _validateForm() async {
    String? error;
    
    if (_selectedDate.isBefore(DateTime.now().add(const Duration(days: 1)))) {
      error = 'Pilih tanggal minimal H+1 dari hari ini';
    } else if (_availableQuota <= 0) {
      error = 'Tanggal yang dipilih sudah penuh';
    } else if (_jumlahOrang > _availableQuota) {
      error = 'Kuota tersisa hanya $_availableQuota orang';
    } else if (_jumlahOrang > 10) {
      error = 'Maksimal 10 orang per booking';
    }
    
    if (error != _validationError) {
      setState(() => _validationError = error);
    }
    
    return error;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apakah data yang Anda isi sudah benar?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildConfirmationRow('Paket', widget.paket.name),
                    _buildConfirmationRow('Rute', widget.paket.route),
                    _buildConfirmationRow('Tanggal', 
                      DateFormat('dd MMMM yyyy').format(_selectedDate)),
                    _buildConfirmationRow('Jumlah Orang', '$_jumlahOrang orang'),
                    _buildConfirmationRow('Total', 
                      'Rp ${_formatPrice(_totalPrice)}'),
                    _buildConfirmationRow('Metode Bayar', 
                      _selectedPaymentMethod == 'bank_transfer' ? 'Transfer Bank' : 'QRIS'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Setelah dikonfirmasi, Anda akan diarahkan ke halaman pembayaran.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Periksa Lagi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
    
    return confirmed ?? false;
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      )
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    
    final formError = await _validateForm();
    if (formError != null) {
      _showErrorSnackbar(formError);
      return;
    }
    
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User tidak login');
      }

      final booking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        userName: _fullNameController.text.trim(),
        userEmail: _emailController.text.trim(),
        userPhone: _phoneController.text.trim(),
        paketId: widget.paket.id,
        paketName: widget.paket.name,
        paketRoute: widget.paket.route,
        paketPrice: widget.paket.price,
        tanggalBooking: _selectedDate,
        jumlahOrang: _jumlahOrang,
        totalHarga: widget.paket.price * _jumlahOrang,
        paymentMethod: _selectedPaymentMethod,
        status: 'pending_payment',
        createdAt: DateTime.now(),
        specialRequest: _specialRequestController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        idNumber: _idNumberController.text.trim(),
      );

      await _firestore
          .collection('bookings')
          .doc(booking.id)
          .set(booking.toMap());

      await _firestore.collection('users').doc(user.uid).set({
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'idNumber': _idNumberController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil dibuat!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 50),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to CHECKOUT bukan langsung ke ticket
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.checkout,
          arguments: {
            'booking': booking,
            'total': booking.totalHarga,
            'subtotal': booking.totalHarga,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat booking: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 50),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() => _selectedDate = pickedDate);
      await _checkAvailability();
      await _validateForm();
      
      if (_jumlahOrang > _availableQuota && _availableQuota > 0) {
        setState(() => _jumlahOrang = _availableQuota);
      }
    }
  }

  double get _totalPrice => widget.paket.price * _jumlahOrang;

  String _formatPrice(double price) {
    return NumberFormat('#,##0', 'id_ID').format(price);
  }

  Widget _buildPaymentMethodCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    
    return Card(
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Pemesanan'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PACKAGE SUMMARY
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.terrain,
                            size: 30,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.paket.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Jalur ${widget.paket.route} • ${widget.paket.duration}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp ${_formatPrice(widget.paket.price)} / orang',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECTION: DATA DIRI
                  Text(
                    'Data Diri Pemesan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lengkapi data diri untuk proses booking',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // NAMA LENGKAP
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama lengkap harus diisi';
                      }
                      if (value.length < 3) {
                        return 'Nama minimal 3 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // EMAIL
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email, color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email harus diisi';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // NOMOR TELEPON
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Nomor Telepon',
                      prefixIcon: Icon(Icons.phone, color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor telepon harus diisi';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'Hanya angka yang diperbolehkan';
                      }
                      if (value.length < 10 || value.length > 13) {
                        return 'Nomor telepon 10-13 digit';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // NOMOR KTP/SIM
                  TextFormField(
                    controller: _idNumberController,
                    decoration: InputDecoration(
                      labelText: 'Nomor KTP/SIM',
                      prefixIcon: Icon(Icons.badge, color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor identitas harus diisi';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'Hanya angka yang diperbolehkan';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // KONTAK DARURAT
                  TextFormField(
                    controller: _emergencyContactController,
                    decoration: InputDecoration(
                      labelText: 'Kontak Darurat (Opsional)',
                      prefixIcon: Icon(Icons.emergency, color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECTION: DETAIL PENDAKIAN
                  Text(
                    'Detail Pendakian',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tentukan tanggal dan jumlah pendaki',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TANGGAL PENDAKIAN
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tanggal Pendakian',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (_isCheckingAvailability)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: AppTheme.primaryColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      DateFormat('dd MMMM yyyy')
                                          .format(_selectedDate),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down,
                                      color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                          if (_availableQuota != widget.paket.quota)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _availableQuota <= 0 
                                  ? '⚠️ Tanggal ini sudah penuh'
                                  : '✅ Tersisa $_availableQuota kuota',
                                style: TextStyle(
                                  color: _availableQuota <= 0 ? Colors.red : Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // JUMLAH PENDAKI
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jumlah Pendaki',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (_jumlahOrang > 1) {
                                    setState(() => _jumlahOrang--);
                                    _validateForm();
                                  }
                                },
                                icon: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: const Icon(Icons.remove, size: 20),
                                ),
                                color: Colors.red,
                              ),
                              Container(
                                width: 60,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_jumlahOrang',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (_jumlahOrang < _availableQuota && 
                                      _jumlahOrang < widget.paket.quota &&
                                      _jumlahOrang < 10) {
                                    setState(() => _jumlahOrang++);
                                    _validateForm();
                                  } else {
                                    String message = '';
                                    if (_jumlahOrang >= 10) {
                                      message = 'Maksimal 10 orang per booking';
                                    } else if (_jumlahOrang >= _availableQuota) {
                                      message = 'Kuota tersisa hanya $_availableQuota orang';
                                    } else {
                                      message = 'Telah mencapai kuota maksimum paket';
                                    }
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                        backgroundColor: Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(bottom: 50),
                                      ),
                                    );
                                  }
                                },
                                icon: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: const Icon(Icons.add, size: 20),
                                ),
                                color: Colors.green,
                              ),
                              const Spacer(),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Kuota: ',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text: '${widget.paket.quota} ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    if (_availableQuota != widget.paket.quota)
                                      TextSpan(
                                        text: '($_availableQuota tersedia)',
                                        style: TextStyle(
                                          color: _availableQuota <= 3 ? Colors.orange : Colors.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // METODE PEMBAYARAN
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Metode Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              _buildPaymentMethodCard(
                                value: 'bank_transfer',
                                title: 'Transfer Bank',
                                subtitle: 'BNI, BRI, Mandiri, BCA',
                                icon: Icons.account_balance,
                              ),
                              const SizedBox(height: 8),
                              _buildPaymentMethodCard(
                                value: 'qris',
                                title: 'QRIS',
                                subtitle: 'Semua e-wallet & mobile banking',
                                icon: Icons.qr_code,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PERMINTAAN KHUSUS
                  TextFormField(
                    controller: _specialRequestController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Permintaan Khusus (Opsional)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECTION: RINGKASAN HARGA
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ringkasan Pembayaran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Harga per orang',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                'Rp ${_formatPrice(widget.paket.price)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Jumlah orang',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                '$_jumlahOrang orang',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Pembayaran',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Rp ${_formatPrice(_totalPrice)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // VALIDATION ERROR
                  if (_validationError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationError!,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitBooking,
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
                              'KONFIRMASI BOOKING',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}