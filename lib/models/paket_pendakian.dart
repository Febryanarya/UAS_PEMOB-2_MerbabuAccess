class PaketPendakian {
  final String id;
  final String name;
  final int price;
  final String route;
  final String quota;
  final String duration;
  final String description;
  final String image;

  PaketPendakian({
    required this.id,
    required this.name,
    required this.price,
    required this.route,
    required this.quota,
    required this.duration,
    required this.description,
    required this.image,
  });

  factory PaketPendakian.fromJson(Map<String, dynamic> json) {
    return PaketPendakian(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      route: json['route'] ?? '',
      quota: json['quota']?.toString() ?? '0',
      duration: json['duration'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
    );
  }
}