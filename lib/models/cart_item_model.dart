class CartItem {
  final String paketId;
  final String paketName;
  final String paketRoute;
  final double paketPrice; // ✅ Tetap double
  final String imageUrl;
  DateTime tanggalBooking;
  int jumlahOrang;
  double totalHarga;

  CartItem({
    required this.paketId,
    required this.paketName,
    required this.paketRoute,
    required this.paketPrice, // ✅ double
    required this.imageUrl,
    required this.tanggalBooking,
    required this.jumlahOrang,
  }) : totalHarga = paketPrice * jumlahOrang; // ✅ double * int = double

  // Update total harga
  void updateTotal() {
    totalHarga = paketPrice * jumlahOrang; // ✅ double * int
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'paketId': paketId,
      'paketName': paketName,
      'paketRoute': paketRoute,
      'paketPrice': paketPrice, // ✅ double
      'imageUrl': imageUrl,
      'tanggalBooking': tanggalBooking.toIso8601String(),
      'jumlahOrang': jumlahOrang,
      'totalHarga': totalHarga,
    };
  }

  // From Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      paketId: map['paketId'],
      paketName: map['paketName'],
      paketRoute: map['paketRoute'],
      paketPrice: (map['paketPrice'] as num).toDouble(), // ✅ Convert ke double
      imageUrl: map['imageUrl'],
      tanggalBooking: DateTime.parse(map['tanggalBooking']),
      jumlahOrang: map['jumlahOrang'],
    );
  }
}