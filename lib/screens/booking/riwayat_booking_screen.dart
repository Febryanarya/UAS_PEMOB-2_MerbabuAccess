import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../core/routes/app_routes.dart';

class RiwayatBookingScreen extends StatefulWidget {
  const RiwayatBookingScreen({super.key});

  @override
  State<RiwayatBookingScreen> createState() => _RiwayatBookingScreenState();
}

class _RiwayatBookingScreenState extends State<RiwayatBookingScreen> {
  final BookingService _bookingService = BookingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<List<Booking>> _bookingsFuture;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
    _bookingsFuture = _fetchBookings();
  }

  Future<List<Booking>> _fetchBookings() async {
    if (_userId == null) return [];
    return await _bookingService.fetchUserBookings(_userId!);
  }

  void _refreshBookings() {
    setState(() {
      _bookingsFuture = _fetchBookings();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
      case 'pending_payment':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBookings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
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
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshBookings,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history_toggle_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada riwayat booking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mulai booking paket pendakian pertama Anda',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Jelajahi Paket'),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking.paketName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              booking.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        booking.paketRoute,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),

                      // DETAILS
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(_formatDate(booking.tanggalBooking)),
                          const SizedBox(width: 16),
                          const Icon(Icons.people, size: 16),
                          const SizedBox(width: 8),
                          Text('${booking.jumlahOrang} orang'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 8),
                          Text(DateFormat('HH:mm').format(booking.tanggalBooking)),
                          const SizedBox(width: 16),
                          const Icon(Icons.monetization_on, size: 16),
                          const SizedBox(width: 8),
                          Text('Rp ${booking.totalHarga.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // BOOKING INFO
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID: ${booking.id.substring(0, 8)}'),
                                  Text('Booked: ${_formatDate(booking.createdAt)}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ACTION BUTTONS
                      Row(
                        children: [
                          // TOMBOL LIHAT TIKET (jika status confirmed/paid)
                          if (booking.status == 'confirmed' || booking.status == 'paid')
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.confirmation_number, size: 18),
                                label: const Text('Lihat Tiket'),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.ticket,
                                    arguments: booking,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          if (booking.status == 'confirmed' || booking.status == 'paid')
                            const SizedBox(width: 8),
                          
                          // TOMBOL KONFIRMASI PEMBAYARAN (jika pending)
                          if (booking.status == 'pending' || booking.status == 'pending_payment')
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.upload, size: 18),
                                label: const Text('Upload Bukti'),
                                onPressed: () {
                                  // TODO: Implement upload bukti
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fitur upload bukti akan segera tersedia'),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          
                          // TOMBOL BATALKAN (jika pending)
                          if (booking.status == 'pending' || booking.status == 'pending_payment')
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                                label: const Text('Batalkan', style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  // TODO: Implement cancel booking
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fitur pembatalan akan segera tersedia'),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}