class Booking {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String paketId;
  final String paketName;
  final String paketRoute; // ✅ TAMBAH INI
  final int paketPrice; // ✅ int (sesuai PaketPendakian)
  final DateTime tanggalBooking;
  final int jumlahOrang;
  final double totalHarga;
  final String status;
  final DateTime createdAt;

  Booking({
    this.id = '',
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.paketId,
    required this.paketName,
    required this.paketRoute, // ✅ TAMBAH
    required this.paketPrice, // ✅ int
    required this.tanggalBooking,
    required this.jumlahOrang,
    required this.totalHarga,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'paketId': paketId,
      'paketName': paketName,
      'paketRoute': paketRoute, // ✅ TAMBAH
      'paketPrice': paketPrice, // ✅ int
      'tanggalBooking': tanggalBooking.toIso8601String(),
      'jumlahOrang': jumlahOrang,
      'totalHarga': totalHarga,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      paketId: map['paketId'] ?? '',
      paketName: map['paketName'] ?? '',
      paketRoute: map['paketRoute'] ?? '', // ✅ TAMBAH
      paketPrice: map['paketPrice'] ?? 0, // ✅ int
      tanggalBooking: DateTime.parse(map['tanggalBooking']),
      jumlahOrang: map['jumlahOrang'] ?? 0,
      totalHarga: (map['totalHarga'] as num).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}