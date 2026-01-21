// lib/models/booking_model.dart
class Booking {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String paketId;
  final String paketName;
  final String paketRoute;
  final double paketPrice; // ✅ Tetap double
  final DateTime tanggalBooking;
  final int jumlahOrang;
  final double totalHarga;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final String? specialRequest;
  final String? emergencyContact;
  final String? idNumber;

  Booking({
    this.id = '',
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.paketId,
    required this.paketName,
    required this.paketRoute,
    required this.paketPrice, // ✅ double
    required this.tanggalBooking,
    required this.jumlahOrang,
    required this.totalHarga,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.specialRequest,
    this.emergencyContact,
    this.idNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'paketId': paketId,
      'paketName': paketName,
      'paketRoute': paketRoute,
      'paketPrice': paketPrice, // ✅ double
      'tanggalBooking': tanggalBooking.toIso8601String(),
      'jumlahOrang': jumlahOrang,
      'totalHarga': totalHarga,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'specialRequest': specialRequest,
      'emergencyContact': emergencyContact,
      'idNumber': idNumber,
    };
  }

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userPhone: map['userPhone'] ?? '',
      paketId: map['paketId'] ?? '',
      paketName: map['paketName'] ?? '',
      paketRoute: map['paketRoute'] ?? '',
      paketPrice: (map['paketPrice'] as num).toDouble(), // ✅ Convert ke double
      tanggalBooking: DateTime.parse(map['tanggalBooking']),
      jumlahOrang: (map['jumlahOrang'] as num).toInt(), // ✅ Convert ke int dengan benar
      totalHarga: (map['totalHarga'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'bank_transfer',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt']),
      specialRequest: map['specialRequest'],
      emergencyContact: map['emergencyContact'],
      idNumber: map['idNumber'],
    );
  }
}