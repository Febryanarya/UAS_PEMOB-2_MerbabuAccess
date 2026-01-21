import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../models/cart_item_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createBooking({
    required List<CartItem> cartItems,
    required String paymentMethod,
    required String userName,
    required String userEmail,
    required String userPhone,
    required String idNumber,
    String status = 'pending_payment',
    String? specialRequest,
    String? emergencyContact,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login');

    final batch = _firestore.batch();

    for (final item in cartItems) {
      final docRef = _firestore.collection('bookings').doc();

      final booking = Booking(
        id: docRef.id,
        userId: user.uid,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        paketId: item.paketId,
        paketName: item.paketName,
        paketRoute: item.paketRoute,
        paketPrice: item.paketPrice,
        tanggalBooking: item.tanggalBooking,
        jumlahOrang: item.jumlahOrang,
        totalHarga: item.totalHarga,
        paymentMethod: paymentMethod,
        status: status,
        createdAt: DateTime.now(),
        specialRequest: specialRequest,
        emergencyContact: emergencyContact,
        idNumber: idNumber,
      );

      batch.set(docRef, booking.toMap());
    }

    await batch.commit();
    
    await _firestore.collection('users').doc(user.uid).set({
      'fullName': userName,
      'phone': userPhone,
      'idNumber': idNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Booking>> fetchUserBookings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      rethrow;
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }

  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }
}