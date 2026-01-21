class WeatherData {
  final String location;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final int pressure;
  final String condition;
  final String description;
  final String icon;
  final double windSpeed;
  final String lastUpdated;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.pressure,
    required this.condition,
    required this.description,
    required this.icon,
    required this.windSpeed,
    required this.lastUpdated,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      // 🔥 FIX UTAMA: lokasi DIKUNCI
      location: 'Gunung Merbabu',
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      pressure: json['main']['pressure'] as int,
      condition: json['weather'][0]['main'],
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }

  String get iconUrl =>
      'https://openweathermap.org/img/wn/$icon@2x.png';

  // ===== LOGIKA CUACA (AMAN) =====
  bool get isStormy => condition.toLowerCase().contains('thunder');
  bool get isRainy => condition.toLowerCase().contains('rain');
  bool get isWindy => windSpeed > 10; // m/s
  bool get isCold => temperature < 10;
  bool get isGoodWeather =>
      !isStormy && !isRainy && !isWindy && temperature >= 10 && temperature <= 25;
}
