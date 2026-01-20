import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Buat booking baru
  Future<void> createBooking(Booking booking) async {
    try {
      await _firestore.collection('bookings').add(booking.toMap());
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  // Ambil semua booking user
  Future<List<Booking>> fetchUserBookings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      rethrow;
    }
  }
}